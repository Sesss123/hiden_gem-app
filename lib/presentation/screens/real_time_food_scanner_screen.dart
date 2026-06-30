import 'dart:async';
import 'dart:convert';
import 'dart:io' hide WebSocket;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/oracle_ui_system.dart';

/// Models representing server response payloads from ws://YOUR_BACKEND_IP:8000/ws/scan
class FoodComponent {
  final String name;
  final String estimatedPortion;
  final double portionConfidence;

  FoodComponent({
    required this.name,
    required this.estimatedPortion,
    required this.portionConfidence,
  });

  factory FoodComponent.fromJson(Map<String, dynamic> json) {
    return FoodComponent(
      name: json['name']?.toString() ?? 'Unknown item',
      estimatedPortion: json['estimated_portion']?.toString() ?? '1 portion',
      portionConfidence: (json['portion_confidence'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class NutritionFacts {
  final double calories;
  final double protein;
  final double carbs;
  final double fat;

  NutritionFacts({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  factory NutritionFacts.fromJson(Map<String, dynamic> json) {
    return NutritionFacts(
      calories: (json['calories'] as num?)?.toDouble() ?? 0.0,
      protein: (json['protein'] as num?)?.toDouble() ?? 0.0,
      carbs: (json['carbs'] as num?)?.toDouble() ?? 0.0,
      fat: (json['fat'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class ARBoundingBox {
  final double x;
  final double y;
  final double width;
  final double height;

  ARBoundingBox({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  factory ARBoundingBox.fromJson(Map<String, dynamic> json) {
    return ARBoundingBox(
      x: (json['x'] as num?)?.toDouble() ?? 0.1,
      y: (json['y'] as num?)?.toDouble() ?? 0.15,
      width: (json['width'] as num?)?.toDouble() ?? 0.8,
      height: (json['height'] as num?)?.toDouble() ?? 0.7,
    );
  }
}

class AROverlayData {
  final ARBoundingBox boundingBox;
  final String badgeColorHex;
  final String label;
  final String confidenceState;

  AROverlayData({
    required this.boundingBox,
    required this.badgeColorHex,
    required this.label,
    required this.confidenceState,
  });

  factory AROverlayData.fromJson(Map<String, dynamic> json) {
    return AROverlayData(
      boundingBox: ARBoundingBox.fromJson(json['bounding_box'] ?? {}),
      badgeColorHex: json['badge_color']?.toString() ?? '#00F0FF',
      label: json['label']?.toString() ?? 'Detected Dish',
      confidenceState: json['confidence_state']?.toString() ?? 'high',
    );
  }

  Color get badgeColor {
    try {
      String hex = badgeColorHex.replaceAll('#', '');
      if (hex.length == 6) hex = 'FF$hex';
      return Color(int.parse(hex, radix: 16));
    } catch (_) {
      return const Color(0xFF00F0FF); // Default Electric Blue
    }
  }
}

class ScannerResponse {
  final String status;
  final String dishName;
  final double confidence;
  final List<FoodComponent> components;
  final NutritionFacts nutrition;
  final String recommendation;
  final AROverlayData? arOverlay;
  final double processingTimeMs;

  ScannerResponse({
    required this.status,
    required this.dishName,
    required this.confidence,
    required this.components,
    required this.nutrition,
    required this.recommendation,
    this.arOverlay,
    required this.processingTimeMs,
  });

  factory ScannerResponse.fromJson(Map<String, dynamic> json) {
    var compsList = <FoodComponent>[];
    if (json['components'] != null) {
      compsList = (json['components'] as List)
          .map((item) => FoodComponent.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    return ScannerResponse(
      status: json['status']?.toString() ?? 'error',
      dishName: json['dish_name']?.toString() ?? 'Analyzing...',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      components: compsList,
      nutrition: NutritionFacts.fromJson(json['nutrition'] ?? {}),
      recommendation: json['recommendation']?.toString() ?? '',
      arOverlay: json['ar_overlay'] != null
          ? AROverlayData.fromJson(json['ar_overlay'] as Map<String, dynamic>)
          : null,
      processingTimeMs: (json['processing_time_ms'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// Real-Time AI Nutrition & Food Scanner Screen
class RealTimeFoodScannerScreen extends StatefulWidget {
  const RealTimeFoodScannerScreen({super.key});

  @override
  State<RealTimeFoodScannerScreen> createState() => _RealTimeFoodScannerScreenState();
}

class _RealTimeFoodScannerScreenState extends State<RealTimeFoodScannerScreen>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  
  // WebSocket Bi-directional connection
  WebSocketChannel? _channel;
  StreamSubscription? _socketSubscription;
  bool _isConnected = false;
  String _serverIp = '10.0.2.2'; // Default for Android Emulator; use 192.168.x.x for real device
  String _serverPort = '8000';

  // Throttling timer (1 frame per second)
  Timer? _frameTimer;
  bool _isProcessingFrame = false;

  // Selected User Mode: normal, weight_loss, muscle_gain, diabetic
  String _userMode = 'muscle_gain';
  final List<String> _availableModes = ['normal', 'weight_loss', 'muscle_gain', 'diabetic'];

  // Latest AI Result
  ScannerResponse? _latestResponse;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCameraAndSocket();
  }

  Future<void> _initCameraAndSocket() async {
    // Request camera permission
    final status = await Permission.camera.request();
    if (!status.isGranted) return;

    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    _cameraController = CameraController(
      cameras.first,
      ResolutionPreset.medium, // Medium resolution ensures fast frame streaming at 1 FPS
      enableAudio: false,
    );

    try {
      await _cameraController!.initialize();
      if (mounted) {
        setState(() => _isCameraInitialized = true);
        _connectWebSocket();
      }
    } catch (e) {
      debugPrint("Camera initialization error: $e");
    }
  }

  /// Establishes WebSocket connection to ws://YOUR_BACKEND_IP:8000/ws/scan
  Future<void> _connectWebSocket() async {
    _disconnectWebSocket();
    final url = 'ws://$_serverIp:$_serverPort/ws/scan';
    debugPrint("Connecting to Real-Time AI Scanner WebSocket: $url");

    try {
      _channel = WebSocketChannel.connect(Uri.parse(url));
      await _channel!.ready.timeout(const Duration(seconds: 5));

      if (!mounted) return;
      setState(() => _isConnected = true);

      _socketSubscription = _channel!.stream.listen(
        (data) {
          _handleServerMessage(data);
        },
        onDone: () {
          debugPrint("WebSocket disconnected.");
          if (mounted) setState(() => _isConnected = false);
        },
        onError: (err) {
          debugPrint("WebSocket error: $err");
          if (mounted) setState(() => _isConnected = false);
        },
      );

      _startFrameThrottler();
    } catch (e) {
      debugPrint("WebSocket connection failed: $e");
      if (mounted) setState(() => _isConnected = false);
    }
  }

  void _disconnectWebSocket() {
    _frameTimer?.cancel();
    _socketSubscription?.cancel();
    _channel?.sink.close();
    _channel = null;
    _isConnected = false;
  }

  /// Handles server JSON payload responses without freezing UI
  void _handleServerMessage(dynamic message) {
    try {
      final jsonMap = jsonDecode(message as String) as Map<String, dynamic>;
      final status = jsonMap['status']?.toString();

      // Keep scanning smoothly on skipped or error frames per Master Prompt spec
      if (status == 'skipped' || status == 'error') {
        return;
      }

      if (status == 'success') {
        final resp = ScannerResponse.fromJson(jsonMap);
        if (mounted) {
          setState(() {
            _latestResponse = resp;
          });
        }
      }
    } catch (e) {
      debugPrint("Error parsing WebSocket response: $e");
    }
  }

  /// Streams camera frames throttled to exactly 1 frame per second
  void _startFrameThrottler() {
    _frameTimer?.cancel();
    _frameTimer = Timer.periodic(const Duration(milliseconds: 1000), (timer) async {
      if (!_isConnected ||
          _isProcessingFrame ||
          _cameraController == null ||
          !_cameraController!.value.isInitialized) {
        return;
      }

      _isProcessingFrame = true;
      try {
        final imageFile = await _cameraController!.takePicture();
        final bytes = await File(imageFile.path).readAsBytes();
        
        // Clean up temporary image file to avoid storage buildup
        try {
          await File(imageFile.path).delete();
        } catch (_) {}

        final base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        final requestPayload = jsonEncode({
          'image_base64': base64Image,
          'user_mode': _userMode,
        });

        _channel?.sink.add(requestPayload);
      } catch (e) {
        debugPrint("Error capturing/sending frame: $e");
      } finally {
        _isProcessingFrame = false;
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;

    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      _disconnectWebSocket();
      _cameraController?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCameraAndSocket();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _disconnectWebSocket();
    _cameraController?.dispose();
    super.dispose();
  }

  void _showServerIpDialog() {
    final ipController = TextEditingController(text: _serverIp);
    final portController = TextEditingController(text: _serverPort);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppPaletteDark.card,
        title: OracleUI.neonText("BACKEND WS CONFIG", style: GoogleFonts.outfit(fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: ipController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: "Server IP (e.g. 192.168.1.5)", labelStyle: TextStyle(color: Colors.white70)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: portController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: "Port (e.g. 8000)", labelStyle: TextStyle(color: Colors.white70)),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("CANCEL", style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _serverIp = ipController.text.trim();
                _serverPort = portController.text.trim();
              });
              Navigator.pop(ctx);
              _connectWebSocket();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent),
            child: const Text("CONNECT", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showPortionBreakdownSheet() {
    if (_latestResponse == null || _latestResponse!.components.isEmpty) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => OracleUI.glassContainer(
        opacity: 0.95,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OracleUI.neonText("PORTION BREAKDOWN", style: GoogleFonts.outfit(fontSize: 18)),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const Divider(color: Colors.white24),
            const SizedBox(height: 12),
            ..._latestResponse!.components.map((comp) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      comp.name.toUpperCase(),
                      style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.cyanAccent.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.cyanAccent, width: 1),
                      ),
                      child: Text(
                        comp.estimatedPortion,
                        style: GoogleFonts.outfit(color: Colors.cyanAccent, fontWeight: FontWeight.w800, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Live Camera Preview
          Positioned.fill(
            child: _isCameraInitialized && _cameraController != null
                ? CameraPreview(_cameraController!)
                : const Center(child: CircularProgressIndicator(color: Colors.cyanAccent)),
          ),

          // 2. AR Bounding Box Overlay
          if (_latestResponse?.arOverlay != null)
            Positioned.fill(
              child: CustomPaint(
                painter: ARBoundingBoxPainter(_latestResponse!.arOverlay!),
              ),
            ),

          // Dark UI Gradient overlays for readability
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.85),
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.9),
                  ],
                  stops: const [0.0, 0.22, 0.6, 1.0],
                ),
              ),
            ),
          ),

          // 3. Top Navigation & User Mode Selector
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
                _buildModeSelector(),
                const Spacer(),
                // 4. AI Diet Coach Bubble & Instant Macro Dashboard
                if (_latestResponse != null) ...[
                  _buildCoachBubble(),
                  const SizedBox(height: 12),
                  _buildMacroDashboard(),
                ] else
                  _buildConnectingPrompt(),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          Column(
            children: [
              OracleUI.neonText(
                "LIVE AI FOOD SCANNER",
                style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 3, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _isConnected ? Colors.greenAccent : Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _isConnected ? "STREAMING 1 FPS (${_latestResponse?.processingTimeMs.toStringAsFixed(0) ?? 0}ms)" : "DISCONNECTED",
                    style: GoogleFonts.inter(color: _isConnected ? Colors.greenAccent : Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.settings_ethernet, color: Colors.cyanAccent),
            onPressed: _showServerIpDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildModeSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: _availableModes.map((mode) {
          final isSelected = _userMode == mode;
          final displayName = mode.replaceAll('_', ' ').toUpperCase();
          return GestureDetector(
            onTap: () => setState(() => _userMode = mode),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? Colors.cyanAccent : Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isSelected ? Colors.cyanAccent : Colors.white30, width: 1.5),
              ),
              child: Text(
                displayName,
                style: GoogleFonts.outfit(
                  color: isSelected ? Colors.black : Colors.white70,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                  letterSpacing: 1,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildConnectingPrompt() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const CircularProgressIndicator(color: Colors.cyanAccent),
          const SizedBox(height: 12),
          Text(
            _isConnected ? "Point camera at food plate for live analysis..." : "Connecting to Backend WebSocket server...",
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildCoachBubble() {
    if (_latestResponse!.recommendation.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppPaletteDark.card.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.cyanAccent, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.cyanAccent.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.cyanAccent.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.cyanAccent, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "AI DIET COACH (${_userMode.replaceAll('_', ' ').toUpperCase()})",
                  style: GoogleFonts.outfit(color: Colors.cyanAccent, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                ),
                const SizedBox(height: 4),
                Text(
                  _latestResponse!.recommendation,
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 12, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildMacroDashboard() {
    final nut = _latestResponse!.nutrition;
    return GestureDetector(
      onTap: _showPortionBreakdownSheet,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white24, width: 1),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _latestResponse!.dishName.toUpperCase(),
                    style: GoogleFonts.outfit(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      "TAP FOR PORTIONS",
                      style: GoogleFonts.inter(color: Colors.cyanAccent, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.cyanAccent, size: 16),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMacroItem("CALORIES", "${nut.calories.toStringAsFixed(0)} kcal", Colors.orangeAccent),
                _buildMacroItem("PROTEIN", "${nut.protein.toStringAsFixed(1)}g", Colors.cyanAccent),
                _buildMacroItem("CARBS", "${nut.carbs.toStringAsFixed(1)}g", Colors.greenAccent),
                _buildMacroItem("FAT", "${nut.fat.toStringAsFixed(1)}g", Colors.pinkAccent),
              ],
            ),
          ],
        ),
      ).animate().fadeIn(duration: 400.ms),
    );
  }

  Widget _buildMacroItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.outfit(color: color, fontSize: 16, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.inter(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1),
        ),
      ],
    );
  }
}

/// Custom AR Bounding Box Painter drawing glowing neon frames around detected food
class ARBoundingBoxPainter extends CustomPainter {
  final AROverlayData overlay;

  ARBoundingBoxPainter(this.overlay);

  @override
  void paint(Canvas canvas, Size size) {
    final box = overlay.boundingBox;
    
    // Convert normalized coordinates (0.0 to 1.0) to screen pixel coordinates
    final rect = Rect.fromLTWH(
      box.x * size.width,
      box.y * size.height,
      box.width * size.width,
      box.height * size.height,
    );

    final neonColor = overlay.badgeColor;

    // Glowing shadow paint
    final glowPaint = Paint()
      ..color = neonColor.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 12);

    // Crisp border paint
    final borderPaint = Paint()
      ..color = neonColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    // Draw glow and rectangle
    canvas.drawRect(rect, glowPaint);
    canvas.drawRect(rect, borderPaint);

    // Draw futuristic AR corner brackets
    final bracketLength = 20.0;
    final cornerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;

    // Top-left
    canvas.drawLine(rect.topLeft, rect.topLeft + Offset(bracketLength, 0), cornerPaint);
    canvas.drawLine(rect.topLeft, rect.topLeft + Offset(0, bracketLength), cornerPaint);
    // Top-right
    canvas.drawLine(rect.topRight, rect.topRight + Offset(-bracketLength, 0), cornerPaint);
    canvas.drawLine(rect.topRight, rect.topRight + Offset(0, bracketLength), cornerPaint);
    // Bottom-left
    canvas.drawLine(rect.bottomLeft, rect.bottomLeft + Offset(bracketLength, 0), cornerPaint);
    canvas.drawLine(rect.bottomLeft, rect.bottomLeft + Offset(0, -bracketLength), cornerPaint);
    // Bottom-right
    canvas.drawLine(rect.bottomRight, rect.bottomRight + Offset(-bracketLength, 0), cornerPaint);
    canvas.drawLine(rect.bottomRight, rect.bottomRight + Offset(0, -bracketLength), cornerPaint);

    // Draw label badge above the bounding box
    final textSpan = TextSpan(
      text: "  ${overlay.label}  ",
      style: GoogleFonts.outfit(
        color: Colors.black,
        fontSize: 12,
        fontWeight: FontWeight.w900,
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    final labelRect = Rect.fromLTWH(
      rect.left,
      (rect.top - textPainter.height - 6).clamp(0.0, size.height),
      textPainter.width,
      textPainter.height + 6,
    );

    final badgePaint = Paint()..color = neonColor;
    canvas.drawRRect(RRect.fromRectAndRadius(labelRect, const Radius.circular(6)), badgePaint);

    textPainter.paint(canvas, Offset(labelRect.left, labelRect.top + 3));
  }

  @override
  bool shouldRepaint(covariant ARBoundingBoxPainter oldDelegate) => true;
}
