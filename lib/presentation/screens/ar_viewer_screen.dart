import 'dart:async';
import 'dart:math' as math;
import '../../core/mocks/arcore_flutter_plugin.dart';
import 'package:vector_math/vector_math_64.dart' as vector;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../core/analytics/analytics_service.dart';
import '../../core/services/ar_service.dart';
import '../../data/models/ar_place_data.dart';
import '../../core/services/asset_cache_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:gal/gal.dart';
import 'package:permission_handler/permission_handler.dart';

import 'ar_upgrade_dialog.dart';
import 'premium_hub_screen.dart';
import 'heritage_passport_screen.dart';
import '../../core/services/gamification_service.dart';
import '../../core/services/business_discovery_service.dart';
import '../../data/models/ar_artifact.dart';
import '../../data/models/business_partner.dart';
import '../../data/models/ar_session.dart';
import '../../core/services/ar_session_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/services/memory_service.dart';
import '../../data/models/community_memory.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/usage_limiter_service.dart';
import '../../data/datasources/monetization_service.dart';

// ignore_for_file: unused_import
class ARViewerScreen extends StatefulWidget {
  final ARPlaceData arData;
  final String placeName;
  final bool isDemo;

  const ARViewerScreen({
    super.key,
    required this.arData,
    required this.placeName,
    this.isDemo = false,
  });

  @override
  State<ARViewerScreen> createState() => _ARViewerScreenState();
}

class _ARViewerScreenState extends State<ARViewerScreen>
    with TickerProviderStateMixin {
  final ARService _arService = ARService();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final ScreenshotController _screenshotController = ScreenshotController();

  bool _modelRequested = false;
  bool _isThenMode = false;
  bool _isAudioPlaying = false;
  bool _isMuted = false;
  bool _showHotspots = false;
  bool _showTutorial = true;
  String _currentAudioLang = 'si';
  
  // AR Photo Mode (Stage 2)
  bool _isCapturing = false;
  late AnimationController _flashController;
  late Animation<double> _flashAnimation;
  
  // Gamification logic
  final GamificationService _gamificationService = GamificationService();
  final ValueNotifier<ARArtifact?> _lastFoundArtifact = ValueNotifier(null);
  
  // High-frequency ValueNotifiers for granular rebuilds
  final ValueNotifier<double> _radarIntensityNotifier = ValueNotifier(0.0);
  final ValueNotifier<int> _demoSecondsLeftNotifier = ValueNotifier(10);
  
  Timer? _radarTimer;

  late AnimationController _scanAnimController;
  late AnimationController _thenNowController;
  late Animation<double> _thenNowAnim;

  // AR Navigation (Phase 4)
  Position? _currentPosition;
  double _bearing = 0.0;
  double _distanceToTarget = 0.0;
  StreamSubscription<Position>? _positionStream;

  // Business Integration (Phase 4)
  List<BusinessPartner> _nearbyPartners = [];
  int _currentPartnerIndex = 0;
  Timer? _partnerRotateTimer;
  
  // Demo Mode logic
  Timer? _demoTimer;

  // Multiplayer (Phase 5)
  final ARSessionService _sessionService = ARSessionService();
  ARSession? _currentSession;
  bool _isHosting = false;
  bool _isJoining = false;
  StreamSubscription<ARSession?>? _sessionSubscription;
  
  // Community Gem Clusters
  StreamSubscription? _memorySubscription;
  List<CommunityMemory> _nearbyMemories = [];

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _scanAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _thenNowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _thenNowAnim = CurvedAnimation(
        parent: _thenNowController, curve: Curves.easeInOut);

    _flashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _flashAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_flashController);

    AnalyticsService().logARSessionStarted(
        placeName: widget.placeName,
        tier: widget.arData.arTier,
        mode: 'full');

    // Auto-proceed logic after a minimum delay and when ready
    Future.delayed(const Duration(seconds: 4),
        () { if (mounted) setState(() => _showTutorial = false); });

    // Start Demo Timer if applicable
    if (widget.isDemo) {
      _startDemoTimer();
    }

    _gamificationService.init();
    _arService.onArtifactFound = _onArtifactFound;
    _arService.onNodePlaced = _onNodePlaced;
    _startRadarTimer();
    _startNavigationTracking();
    _fetchNearbyPartners();
    _initMemoryStream();
  }

  void _initMemoryStream() {
    _memorySubscription = MemoryService.getNearbyMemories(
      widget.arData.targetLat, 
      widget.arData.targetLng
    ).listen((memories) {
      if (mounted) {
        setState(() => _nearbyMemories = memories);
      }
    });
  }

  Future<void> _fetchNearbyPartners() async {
    final partners = await BusinessDiscoveryService().getNearbyPartners(
      lat: widget.arData.targetLat, 
      lng: widget.arData.targetLng
    );
    if (mounted) {
      setState(() {
        _nearbyPartners = partners;
        if (_nearbyPartners.isNotEmpty) {
          _startPartnerRotation();
        }
      });
    }
  }

  void _startPartnerRotation() {
    _partnerRotateTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      if (mounted && _nearbyPartners.length > 1) {
        setState(() {
          _currentPartnerIndex = (_currentPartnerIndex + 1) % _nearbyPartners.length;
        });
      }
    });
  }

  void _startNavigationTracking() {
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.bestForNavigation),
    ).listen((Position pos) {
      if (mounted) {
        setState(() {
          _currentPosition = pos;
          _distanceToTarget = Geolocator.distanceBetween(
            pos.latitude, pos.longitude, 
            widget.arData.targetLat, widget.arData.targetLng
          );
          _bearing = _calculateBearing(
            pos.latitude, pos.longitude,
            widget.arData.targetLat, widget.arData.targetLng
          );
        });
      }
    });
  }

  double _calculateBearing(double lat1, double lng1, double lat2, double lng2) {
    double dLng = (lng2 - lng1).toRad();
    double y = math.sin(dLng) * math.cos(lat2.toRad());
    double x = math.cos(lat1.toRad()) * math.sin(lat2.toRad()) -
        math.sin(lat1.toRad()) * math.cos(lat2.toRad()) * math.cos(dLng);
    return (math.atan2(y, x).toDeg() + 360) % 360;
  }

  void _onNodePlaced(vector.Vector3 position) {
    _arService.placeArtifacts(
      widget.arData.artifacts, 
      position, 
      _gamificationService.foundArtifactIds.value
    );
  }

  void _onArtifactFound(String artifactId) {
    try {
      final artifact = widget.arData.artifacts.firstWhere((a) => a.id == artifactId);
      _gamificationService.markArtifactAsFound(artifact);
      _lastFoundArtifact.value = artifact;
      
      HapticFeedback.heavyImpact();
      
      // Clear notification after 5 seconds
      Future.delayed(const Duration(seconds: 5), () {
        _lastFoundArtifact.value = null;
      });
    } catch (e) {
      debugPrint("Artifact not found in data list: $artifactId");
    }
  }

  void _startRadarTimer() {
    _radarTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      // In a real device, we'd check the camera position vs artifact position
      // For now, we simulate intensity based on session time or random fluctuations
      _radarIntensityNotifier.value = (_radarIntensityNotifier.value + 0.1) % 1.0;
    });
  }

  void _startDemoTimer() {
    _demoTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        if (_demoSecondsLeftNotifier.value > 0) {
          _demoSecondsLeftNotifier.value--;
        } else {
          _endDemo();
        }
      }
    });
  }

  void _endDemo() {
    _demoTimer?.cancel();
    _audioPlayer.stop();
    if (mounted) {
      Navigator.pop(context);
      ARUpgradeDialog.show(
        context,
        onUpgrade: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PremiumHubScreen()),
          );
        },
        onPreview: () {
          // Restart demo if they want another peek (or could block)
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ARViewerScreen(
                arData: widget.arData,
                placeName: widget.placeName,
                isDemo: true,
              ),
            ),
          );
        },
        onWatchAd: () {
          MonetizationService().showRewardedAd(
            context: context,
            onRewardEarned: (reward) async {
              await UsageLimiterService.provideBonusArSession();
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✨ Oracle reward active! AR session unlocked.'),
                  backgroundColor: Colors.green,
                ),
              );
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => ARViewerScreen(
                    arData: widget.arData,
                    placeName: widget.placeName,
                    isDemo: false,
                  ),
                ),
              );
            },
          );
        },
      );
    }
  }

  @override
  void dispose() {
    _memorySubscription?.cancel();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _demoTimer?.cancel();
    _radarTimer?.cancel();
    _positionStream?.cancel();
    _partnerRotateTimer?.cancel();
    _sessionSubscription?.cancel();
    _scanAnimController.dispose();
    _thenNowController.dispose();
    _flashController.dispose();
    _audioPlayer.dispose();
    _arService.dispose();
    super.dispose();
  }

  void _onArCoreViewCreated(ArCoreController controller) {
    _arService.onArCoreViewCreated(controller);
  }

  void _requestPlaceModel() async {
    await _arService.requestPlaceModel(
      modelUrl: widget.arData.arModelUrl,
      historicalModelUrl: widget.arData.arHistoricalModelUrl,
      scale: widget.arData.arModelScale,
    );
    
    if (!mounted) return;
    setState(() => _modelRequested = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('👆 Tap a flat surface to place the model',
            style: GoogleFonts.inter()),
        backgroundColor: AppTheme.cardColor(context).withValues(alpha: 0.9),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _toggleThenNow() {
    if (_currentSession != null) {
      // Phase 5: Multiplayer Sync
      final newMode = !_isThenMode;
      _sessionService.updateSessionState(_currentSession!.id, isHistorical: newMode);
      // State will be updated by the listener
    } else {
      _arService.toggleHistoricalMode();
      setState(() => _isThenMode = _arService.isHistoricalMode.value);
      _isThenMode
          ? _thenNowController.forward()
          : _thenNowController.reverse();
    }
  }

  Future<void> _toggleAudio() async {
    final url = _currentAudioLang == 'si'
        ? widget.arData.audioUrlSi
        : widget.arData.audioUrlEn;
    if (_isAudioPlaying) {
      await _audioPlayer.pause();
    } else if (url.isNotEmpty) {
      try {
        // Phase 2: Offline Heritage Mode — Check local cache for audio
        final localPath = await AssetCacheService.getLocalPath(url);
        if (localPath != null) {
          debugPrint("[Offline] Playing audio from cache: $localPath");
          await _audioPlayer.setFilePath(localPath);
        } else {
          debugPrint("[Offline] Streaming audio from remote URL.");
          await _audioPlayer.setUrl(url);
        }
        await _audioPlayer.play();
      } catch (_) {
        _showError('Could not load audio narration.');
        return;
      }
    }
    setState(() => _isAudioPlaying = !_isAudioPlaying);
  }

  Future<void> _switchLang(String lang) async {
    await _audioPlayer.stop();
    setState(() { _currentAudioLang = lang; _isAudioPlaying = false; });
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red.shade800,
          behavior: SnackBarBehavior.floating),
    );
  }

  void _showHotspotDetail(ARHotspot h) {
    AnalyticsService().logARHotspotTapped(
        placeName: widget.placeName, hotspotId: h.label);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _hotspotSheet(h),
    );
  }

  Future<void> _captureARPhoto() async {
    // 1. Check permissions first
    final status = await Permission.storage.request();
    if (status.isDenied) {
      _showError("Gallery permission denied");
      return;
    }

    HapticFeedback.heavyImpact();
    
    // 2. Hide UI for clean shot
    setState(() => _isCapturing = true);

    // Small delay to ensure UI redraws before capture
    await Future.delayed(const Duration(milliseconds: 100));

    try {
      final image = await _screenshotController.capture();
      
      if (image != null && mounted) {
        // 3. Trigger Flash Effect (Cinematic)
        _flashController.forward().then((_) => _flashController.reverse());
        
        final directory = await getTemporaryDirectory();
        final path = '${directory.path}/ar_capture_${DateTime.now().millisecondsSinceEpoch}.png';
        final file = File(path);
        await file.writeAsBytes(image);
        
        // 4. Save to Public Gallery
        await Gal.putImage(path);
        
        if (mounted) {
          _showShareSheet(path);
        }
      }
    } catch (e) {
      _showError("Failed to capture photo: $e");
    } finally {
      if (mounted) {
        setState(() => _isCapturing = false);
      }
    }
  }

  void _showShareSheet(String path) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _shareSheet(path),
    );
  }

  // ─────────────────────────── MULTIPLAYER ─────────────────────────────────────

  void _showJoinDialog() {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: AppPalette.rust.withValues(alpha: 0.3))),
        title: Text("Join Group Tour", style: GoogleFonts.outfit(color: AppTheme.textPrimary(context), fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Enter the 6-digit code provided by your guide.", 
              style: GoogleFonts.inter(color: AppTheme.textSecondary(context), fontSize: 13)),
            const SizedBox(height: 20),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              maxLength: 6,
              style: TextStyle(color: AppTheme.textPrimary(context), fontSize: 24, letterSpacing: 8),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                counterText: "",
                filled: true,
                fillColor: Colors.black.withValues(alpha: 0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("CANCEL", style: TextStyle(color: AppTheme.textSecondary(context)))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _joinSession(controller.text);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppPalette.rust),
            child: const Text("JOIN", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _hostSession() async {
    if (_isHosting || _currentSession != null) return;
    
    setState(() => _isHosting = true);
    
    // In a real device, Cloud Anchor ID comes from AR engine
    final session = await _sessionService.createSession(
      modelId: widget.arData.arModelUrl,
      cloudAnchorId: "ca_${DateTime.now().millisecondsSinceEpoch}",
    );

    if (session != null && mounted) {
      setState(() {
        _currentSession = session;
        _isHosting = false;
      });
      _listenToSession(session.id);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Group Tour Started! Code: ${session.id}"),
          backgroundColor: AppTheme.warningAmber,
          duration: const Duration(seconds: 10),
        ),
      );
    }
  }

  Future<void> _joinSession(String code) async {
    if (_isJoining || _currentSession != null) return;
    
    setState(() => _isJoining = true);
    final session = await _sessionService.joinSession(code);
    
    if (session != null && mounted) {
      setState(() {
        _currentSession = session;
        _isJoining = false;
        _setThenMode(session.isHistorical);
      });
      _listenToSession(session.id);
    } else if (mounted) {
      setState(() => _isJoining = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid Session Code")),
      );
    }
  }

  void _listenToSession(String joinCode) {
    _sessionSubscription?.cancel();
    _sessionSubscription = _sessionService.listenToSession(joinCode).listen((ARSession? session) {
      if (session != null && mounted) {
        if (session.isHistorical != _isThenMode) {
          _setThenMode(session.isHistorical);
        }
        setState(() => _currentSession = session);
      }
    });
  }

  void _setThenMode(bool val) {
    if (_isThenMode == val) return;
    setState(() {
      _isThenMode = val;
      if (val) {
        _thenNowController.forward();
        _audioPlayer.play();
      } else {
        _thenNowController.reverse();
        _audioPlayer.pause();
      }
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Screenshot(
        controller: _screenshotController,
        child: Stack(children: [
        // Camera / AR View
        RepaintBoundary(
          child: ArCoreView(
            onArCoreViewCreated: _onArCoreViewCreated,
            enableTapRecognizer: true,
            enablePlaneRenderer: true,
          ),
        ),

        // THEN sepia tint
        if (_isThenMode)
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: _thenNowAnim,
              builder: (_, __) => IgnorePointer(
                child: Opacity(
                  opacity: _thenNowAnim.value * 0.45,
                  child: Container(color: const Color(0xFFA0522D)),
                ),
              ),
            ),
          ),

        // Tutorial
        if (_showTutorial) _tutorialOverlay(),

        // Scan hint
        if (!_showTutorial && !_modelRequested) _scanHint(),

        // Demo Mode Overlay
        if (widget.isDemo) _demoOverlay(),

        // Top bar
        if (!_isCapturing) _topBar(),

        // Then/Now toggle
        if (_modelRequested && !_isCapturing)
          Positioned(top: 70, left: 0, right: 0, child: _thenNowToggle()),

        // Hotspot labels
        if (_showHotspots && !_isCapturing) ..._hotspotLabels(),

        // Loading Progress Overlay
        ValueListenableBuilder<bool>(
          valueListenable: _arService.isDownloading,
          builder: (context, downloading, _) {
            if (!downloading) return const SizedBox.shrink();
            return _productionLoadingOverlay();
          },
        ),

        // Audio bar
        if (_modelRequested && widget.arData.audioUrlSi.isNotEmpty && !_isCapturing)
          Positioned(bottom: 108, left: 16, right: 16, child: _audioBar()),

        // Bottom controls
        if (!_isCapturing)
          Positioned(bottom: 0, left: 0, right: 0, child: _bottomBar()),

        // Premium Badge (visible only in non-demo mode)
        if (!widget.isDemo && !_isCapturing) _premiumBadge(),

        // Watermark (Small & Elegant - ALWAYS visible in photo)
        _watermark(),

        // Radar UI (Phase 3: Gamification)
        if (_modelRequested && !_isCapturing) _treasureRadar(),

        // Artifact Found Notification
        if (!_isCapturing)
          ValueListenableBuilder<ARArtifact?>(
            valueListenable: _lastFoundArtifact,
            builder: (context, artifact, _) {
              if (artifact == null) return const SizedBox.shrink();
              return _artifactFoundNotification(artifact);
            },
          ),

        // Navigation Pointer (Phase 4)
        if (_currentPosition != null && !_isCapturing) _navigationPointer(),

        // AR Booking Overlay (Phase 4)
        if (_nearbyPartners.isNotEmpty && !_isCapturing) _bookingOverlay(),

        // Community Memories Overlay
        if (!_isCapturing) _communityMemoriesOverlay(),

        // Cinematic Flash Layer
        _buildFlashOverlay(),
      ]),
    ),
  );
  }

  Widget _buildFlashOverlay() => FadeTransition(
    opacity: _flashAnimation,
    child: IgnorePointer(
      child: Container(color: Colors.white),
    ),
  );

  // ─────────────────────────── TOP BAR ─────────────────────────────────────
  Widget _topBar() => Positioned(
    top: 0, left: 0, right: 0,
    child: SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _circleBtn(Icons.arrow_back, () => Navigator.pop(context)),
            Row(
              children: [
                if (_currentSession == null && !widget.isDemo) _multiplayerControls(),
                if (_currentSession != null) _sessionIndicator(),
                const SizedBox(width: 8),
                _circleBtn(_showHotspots ? Icons.visibility : Icons.visibility_off, () {
                  setState(() => _showHotspots = !_showHotspots);
                }, color: _showHotspots ? AppTheme.warningAmber : Colors.white),
                const SizedBox(width: 8),
                _circleBtn(Icons.camera_alt_outlined, _captureARPhoto),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  Widget _multiplayerControls() => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      _circleBtn(Icons.group_add_outlined, _showJoinDialog, color: AppPalette.rust),
      const SizedBox(width: 8),
      _circleBtn(Icons.podcasts_outlined, _hostSession, color: AppPalette.rust),
    ],
  );

  Widget _sessionIndicator() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: AppPalette.rust.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppPalette.rust.withValues(alpha: 0.5)),
    ),
    child: Row(
      children: [
        const Icon(Icons.group, color: AppPalette.rust, size: 14),
        const SizedBox(width: 6),
        Text(
          "CODE: ${_currentSession?.id}",
          style: GoogleFonts.inter(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () {
            _sessionSubscription?.cancel();
            setState(() => _currentSession = null);
          },
          child: const Icon(Icons.close, color: Colors.white54, size: 14),
        ),
      ],
    ),
  );

  // ──────────────────────── THEN / NOW TOGGLE ──────────────────────────────
  Widget _thenNowToggle() => Center(
    child: GestureDetector(
      onTap: _toggleThenNow,
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: Colors.black54, borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          _tab('THEN', _isThenMode, AppPalette.rust),
          _tab('NOW', !_isThenMode, Colors.white),
        ]),
      ),
    ),
  );

  Widget _tab(String label, bool active, Color c) => AnimatedContainer(
    duration: const Duration(milliseconds: 300),
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
    decoration: BoxDecoration(
      color: active ? c.withValues(alpha: 0.2) : Colors.transparent,
      borderRadius: BorderRadius.circular(27),
      border: Border.all(color: active ? c : Colors.transparent, width: 1.5),
    ),
    child: Text(label, style: GoogleFonts.outfit(
        color: active ? c : Colors.white54,
        fontWeight: FontWeight.bold, fontSize: 13)),
  );

  // ─────────────────────────── AUDIO BAR ───────────────────────────────────
  Widget _audioBar() => _pill(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    child: Row(children: [
      _langBtn('සිං', 'si'),
      const SizedBox(width: 6),
      _langBtn('EN', 'en'),
      const SizedBox(width: 12),
      GestureDetector(
        onTap: _toggleAudio,
        child: Icon(_isAudioPlaying ? Icons.pause_circle : Icons.play_circle,
            color: Colors.white, size: 28),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: StreamBuilder<Duration?>(
          stream: _audioPlayer.durationStream,
          builder: (_, ds) => StreamBuilder<Duration>(
            stream: _audioPlayer.positionStream,
            builder: (_, ps) {
              final dur = ds.data?.inSeconds.toDouble() ?? 1.0;
              final pos = (ps.data?.inSeconds.toDouble() ?? 0.0).clamp(0.0, dur);
              return SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                  trackHeight: 2,
                ),
                child: Slider(
                  value: pos, max: dur,
                  activeColor: AppTheme.warningAmber,
                  inactiveColor: Colors.white24,
                  onChanged: (v) =>
                      _audioPlayer.seek(Duration(seconds: v.toInt())),
                ),
              );
            },
          ),
        ),
      ),
      GestureDetector(
        onTap: () {
          setState(() => _isMuted = !_isMuted);
          _audioPlayer.setVolume(_isMuted ? 0 : 1);
        },
        child: Icon(_isMuted ? Icons.volume_off : Icons.volume_up,
            color: Colors.white70, size: 20),
      ),
    ]),
  );

  Widget _langBtn(String label, String lang) {
    final active = _currentAudioLang == lang;
    return GestureDetector(
      onTap: () => _switchLang(lang),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: active
              ? AppPalette.rust.withValues(alpha: 0.25)
              : Colors.white12,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: active
              ? AppPalette.rust : Colors.white24),
        ),
        child: Text(label, style: GoogleFonts.inter(
            color: active ? AppPalette.rust : Colors.white54,
            fontWeight: FontWeight.bold, fontSize: 11)),
      ),
    );
  }

  // ─────────────────────────── BOTTOM BAR ──────────────────────────────────
  Widget _bottomBar() => SafeArea(
    top: false,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter, end: Alignment.topCenter,
          colors: [Colors.black87, Colors.transparent],
        ),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
        _ctrlBtn(Icons.refresh_rounded, 'Reset', () => _arService.removeModel()),
        _ctrlBtn(Icons.add_circle_outline, 'Scale+',
                () => _arService.scaleModel(1.2)),
        _ctrlBtn(Icons.remove_circle_outline, 'Scale-',
                () => _arService.scaleModel(0.8)),
        _ctrlBtn(Icons.chat_bubble_outline, 'Memory', _showMemoryDropDialog, 
                color: AppTheme.modernGreen(context)),
        _modelRequested
            ? _ctrlBtn(Icons.delete_outline, 'Remove', () {
                _arService.removeModel();
                setState(() => _modelRequested = false);
              })
            : _ctrlBtn(Icons.touch_app_rounded, 'Place', _requestPlaceModel,
                color: AppPalette.rust),
      ]),
    ),
  );

  Widget _ctrlBtn(IconData icon, String label, VoidCallback onTap,
      {Color color = Colors.white}) =>
      GestureDetector(
        onTap: onTap,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          _pill(padding: const EdgeInsets.all(12),
              child: Icon(icon, color: color, size: 22)),
          const SizedBox(height: 4),
          Text(label, style: GoogleFonts.inter(color: Colors.white70, fontSize: 10)),
        ]),
      );

  // ──────────────────────────── HOTSPOTS ────────────────────────────────────
  List<Widget> _hotspotLabels() =>
      widget.arData.hotspots.asMap().entries.map((e) {
        final i = e.key; final h = e.value;
        return Positioned(
          top: 160.0 + i * 60, left: 30,
          child: GestureDetector(
            onTap: () => _showHotspotDetail(h),
            child: _pill(
              color: AppPalette.rust.withValues(alpha: 0.2),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.place, color: AppPalette.rust, size: 14),
                const SizedBox(width: 4),
                Text(h.label, style: GoogleFonts.inter(
                    color: Colors.white, fontSize: 12,
                    fontWeight: FontWeight.w600)),
              ]),
            ),
          ),
        );
      }).toList();

  Widget _hotspotSheet(ARHotspot h) => Container(
    padding: const EdgeInsets.all(28),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      border: Border.all(color: AppPalette.rust.withValues(alpha: 0.3)),
      boxShadow: [
        BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, -4)),
      ],
    ),
    child: Column(mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start, children: [
      Center(child: Container(width: 40, height: 4,
          decoration: BoxDecoration(color: Colors.black12,
              borderRadius: BorderRadius.circular(2)))),
      const SizedBox(height: 20),
      Row(children: [
        const Icon(Icons.museum_outlined, color: AppPalette.rust, size: 20),
        const SizedBox(width: 8),
        Text(h.label, style: GoogleFonts.outfit(color: AppTheme.textPrimary(context),
            fontSize: 20, fontWeight: FontWeight.bold)),
      ]),
      const SizedBox(height: 12),
      Text(h.description.isNotEmpty ? h.description
          : 'Historical information coming soon.',
          style: GoogleFonts.inter(color: AppTheme.textSecondary(context),
              fontSize: 14, height: 1.6)),
      const SizedBox(height: 20),
    ]),
  );

  // ──────────────────────── TUTORIAL / SCAN ────────────────────────────────
  Widget _productionLoadingOverlay() => Positioned.fill(
    child: Container(
      color: Colors.black87,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppPalette.rust),
            const SizedBox(height: 24),
            Text(
              "Preparing Heritage Assets...",
              style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ValueListenableBuilder<double>(
              valueListenable: _arService.downloadProgress,
              builder: (context, progress, _) => Column(
                children: [
                  Container(
                    width: 200,
                    height: 4,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(2)),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.transparent,
                      valueColor: const AlwaysStoppedAnimation(AppPalette.rust),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "${(progress * 100).toInt()}% • ${widget.arData.modelFileSizeMb} MB",
                    style: GoogleFonts.inter(color: Colors.white38, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            Text(
              "Model: ${widget.placeName}",
              style: GoogleFonts.inter(color: Colors.white54, fontSize: 13),
            ),
            Text(
              "Author: ${widget.arData.authorName}",
              style: GoogleFonts.inter(color: Colors.white38, fontSize: 11),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _tutorialOverlay() => IgnorePointer(
    child: Container(color: Colors.black54,
      child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        AnimatedBuilder(
          animation: _scanAnimController,
          builder: (_, __) => Transform.scale(
            scale: 0.9 + _scanAnimController.value * 0.2,
            child: Container(width: 80, height: 80,
              decoration: BoxDecoration(shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.warningAmber
                      .withValues(alpha: 1 - _scanAnimController.value),
                  width: 2)),
              child: const Icon(Icons.phone_android,
                  color: Colors.white54, size: 36)),
          ),
        ),
        const SizedBox(height: 20),
        Text('Move your phone slowly\nto scan a flat surface',
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(color: Colors.white, fontSize: 16)),
      ])),
    ),
  );

  Widget _scanHint() => Positioned(
    bottom: 180, left: 0, right: 0,
    child: Center(child: _pill(child: Text(
      '👇 Tap "Place" then tap a flat surface',
      style: GoogleFonts.inter(color: Colors.white70, fontSize: 12)))),
  );

  Widget _demoOverlay() => Positioned(
    top: 100, left: 20, right: 20,
    child: Center(
      child: ValueListenableBuilder<int>(
        valueListenable: _demoSecondsLeftNotifier,
        builder: (context, seconds, _) {
          return _pill(
            color: Colors.redAccent.withValues(alpha: 0.2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.timer_outlined, color: Colors.redAccent, size: 14),
                const SizedBox(width: 8),
                Text(
                  "DEMO MODE: $seconds REMAINING",
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 1.2
                  ),
                ),
              ],
            ),
          );
        },
      ),
    ),
  );

  Widget _premiumBadge() => Positioned(
    bottom: 156, left: 20,
    child: _pill(
      color: AppPalette.rust.withValues(alpha: 0.15),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.verified, color: AppPalette.rust, size: 14),
          const SizedBox(width: 6),
          Text(
            "PREMIUM HERITAGE SESSION",
            style: GoogleFonts.outfit(
              color: AppPalette.rust,
              fontWeight: FontWeight.w900,
              fontSize: 10,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    ),
  );

  // ─────────────────────────── HELPERS ─────────────────────────────────────
  Widget _pill({Widget? child, Color? color, EdgeInsets? padding}) =>
      ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Container(
          padding: padding ??
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color ?? Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white24, width: 0.5),
          ),
          child: child,
        ),
      );

  // ─────────────────────────── GAMIFICATION UI ──────────────────────────────
  Widget _treasureRadar() => Positioned(
    top: 150, right: 20,
    child: ValueListenableBuilder<double>(
      valueListenable: _radarIntensityNotifier,
      builder: (context, intensity, _) {
        return Column(
          children: [
            AnimatedBuilder(
              animation: _scanAnimController,
              builder: (context, child) {
                final scale = 1.0 + (intensity * 0.3 * _scanAnimController.value);
                return Container(
                  width: 50, height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppPalette.rust.withValues(alpha: 0.1),
                    border: Border.all(
                      color: AppPalette.rust.withValues(alpha: 0.3 + (intensity * 0.7)),
                      width: 2,
                    ),
                    boxShadow: [
                      if (intensity > 0.5)
                        BoxShadow(
                          color: AppPalette.rust.withValues(alpha: 0.2 * intensity),
                          blurRadius: 10 * scale,
                          spreadRadius: 2 * scale,
                        ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      Icons.radar, 
                      color: AppPalette.rust.withValues(alpha: 0.5 + (intensity * 0.5)),
                      size: 24 * scale,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            _pill(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Text(
                (intensity * 100).toInt() > 0 ? "SIGNAL: ${(intensity * 100).toInt()}%" : "SEARCHING...",
                style: GoogleFonts.inter(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    ),
  );

  Widget _artifactFoundNotification(ARArtifact artifact) => Positioned(
    top: 100, left: 20, right: 20,
    child: TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 600),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, val, child) {
        return Transform.translate(
          offset: Offset(0, (1 - val) * -20),
          child: Opacity(
            opacity: val,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFF1A1A2E), const Color(0xFF16213E).withValues(alpha: 0.9)],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppPalette.rust, width: 2),
                boxShadow: [
                  BoxShadow(color: AppPalette.rust.withValues(alpha: 0.3), blurRadius: 20, spreadRadius: 5),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppPalette.rust.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.auto_awesome, color: AppPalette.rust, size: 30),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text("ARTIFACT DISCOVERED!", style: GoogleFonts.outfit(color: AppPalette.rust, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1.5)),
                        const SizedBox(height: 4),
                        Text(artifact.name, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                        const SizedBox(height: 4),
                        Text("+${artifact.points} PTS • ${artifact.rarity.toUpperCase()}", style: GoogleFonts.inter(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );

  Widget _watermark() => Positioned(
    bottom: 120,
    right: 20,
    child: Opacity(
      opacity: 0.6,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            "HIDDEN GEMS SL",
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 10,
              letterSpacing: 2,
            ),
          ),
          Text(
            "HERITAGE AR",
            style: GoogleFonts.inter(
              color: AppPalette.rust,
              fontWeight: FontWeight.bold,
              fontSize: 8,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _shareSheet(String path) => Container(
    padding: const EdgeInsets.all(28),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      border: Border.all(color: AppPalette.rust.withValues(alpha: 0.3)),
      boxShadow: [
        BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, -4)),
      ],
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 24),
        Text("Capture Successful!", style: GoogleFonts.outfit(color: AppTheme.textPrimary(context), fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text("Share your historical discovery with the world", style: GoogleFonts.inter(color: AppTheme.textSecondary(context), fontSize: 14)),
        const SizedBox(height: 32),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: kIsWeb
              ? Image.network(path, height: 200, fit: BoxFit.cover)
              : Image.file(File(path), height: 200, fit: BoxFit.cover),
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _shareOption(Icons.camera, "Instagram", const Color(0xFFE4405F), () {
              AnalyticsService().logARPhotoShared(
                  placeName: widget.placeName, platform: "instagram");
              SharePlus.instance.share(ShareParams(files: [XFile(path)], text: "Exploring ${widget.placeName} in AR with #HiddenGemsSL"));
            }),
            _shareOption(Icons.music_note, "TikTok", Colors.black, () {
              AnalyticsService().logARPhotoShared(
                  placeName: widget.placeName, platform: "tiktok");
              SharePlus.instance.share(ShareParams(files: [XFile(path)], text: "History comes alive! #HiddenGemsSL #HeritageAR"));
            }),
            _shareOption(Icons.check_circle_outline, "Saved", Colors.green, () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text("Photo saved to your gallery!"),
                  backgroundColor: AppTheme.modernGreen(context),
                  behavior: SnackBarBehavior.floating,
                ),
              );
              Navigator.pop(context);
            }),
          ],
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.textPrimary(context).withValues(alpha: 0.05),
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: Text("Back to AR", style: GoogleFonts.outfit(color: AppTheme.textPrimary(context))),
        ),
        const SizedBox(height: 12),
      ],
    ),
  );

  Widget _shareOption(IconData icon, String label, Color color, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 12),
        Text(label, style: GoogleFonts.inter(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    ),
  );



  Widget _navigationPointer() => Positioned(
    top: 60, left: 20, right: 20,
    child: Center(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.green.withValues(alpha: 0.5)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.location_on, color: Colors.green, size: 14),
                const SizedBox(width: 8),
                Text(
                  "${_distanceToTarget.toStringAsFixed(0)}m to ${widget.placeName}",
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Rotating Arrow (Compass)
          Transform.rotate(
            angle: (_bearing * math.pi / 180.0),
            child: const Icon(Icons.navigation, color: Color(0xFFFFB300), size: 40),
          ),
        ],
      ),
    ),
  );

  Widget _bookingOverlay() {
    final partner = _nearbyPartners[_currentPartnerIndex];
    return Positioned(
      bottom: 200, left: 20, right: 20,
      child: TweenAnimationBuilder<double>(
        duration: const Duration(seconds: 1),
        tween: Tween(begin: 0.0, end: 1.0),
        key: ValueKey(partner.id),
        builder: (context, val, child) {
          return Opacity(
            opacity: val,
            child: Transform.translate(
              offset: Offset(0, (1 - val) * 20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [const Color(0xFF1A1A2E), const Color(0xFF16213E).withValues(alpha: 0.9)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppPalette.rust.withValues(alpha: 0.3)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 20, offset: const Offset(0, 5)),
                  ],
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(partner.imageUrl, width: 80, height: 80, fit: BoxFit.cover),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppPalette.rust.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text("RECOMMENDED", style: GoogleFonts.inter(color: AppPalette.rust, fontSize: 8, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(partner.name, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          Text("${partner.category.toUpperCase()} • ${partner.rating} ★", style: GoogleFonts.inter(color: Colors.white70, fontSize: 10)),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => _launchURL(partner.bookingUrl),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppPalette.rust,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      child: Text("VIEW", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showMemoryDropDialog() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Login to leave an AR memory!")));
      return;
    }

    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: AppPalette.rust.withValues(alpha: 0.3))),
        title: Text("Leave an AR Memory", style: GoogleFonts.outfit(color: AppTheme.textPrimary(context), fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          maxLines: 3,
          style: TextStyle(color: AppTheme.textPrimary(context)),
          decoration: InputDecoration(
            hintText: "What do you see here?",
            hintStyle: TextStyle(color: AppTheme.textSecondary(context).withValues(alpha: 0.5)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppPalette.rust.withValues(alpha: 0.3))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppPalette.rust)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel", style: TextStyle(color: AppTheme.textSecondary(context)))),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isEmpty) return;
              await MemoryService.dropMemory(
                userId: user.uid,
                userName: user.displayName ?? "Explorer",
                userPhotoUrl: user.photoURL ?? "",
                message: controller.text,
                lat: widget.arData.targetLat,
                lng: widget.arData.targetLng,
              );
              if (!context.mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Memory dropped into the AR universe!")));
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppPalette.rust),
            child: const Text("Drop", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _communityMemoriesOverlay() {
    if (_nearbyMemories.isEmpty) return const SizedBox.shrink();
    
    return Stack(
      children: _nearbyMemories.asMap().entries.map((e) {
        final i = e.key;
        final mem = e.value;
        return Positioned(
          top: 100 + (i * 80).toDouble(),
          right: 30,
          child: TweenAnimationBuilder<double>(
            duration: Duration(seconds: 2 + i),
            tween: Tween(begin: 0.0, end: 1.0),
              builder: (context, value, _) {
                return Opacity(
                  opacity: value,
                  child: _pill(
                    color: Colors.blueAccent.withValues(alpha: 0.2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(radius: 12, backgroundImage: NetworkImage(mem.userPhotoUrl)),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(mem.userName, style: GoogleFonts.inter(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                            Text(mem.message, style: GoogleFonts.inter(color: Colors.white70, fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }
          ),
        );
      }).toList(),
    );
  }

  Future<void> _launchURL(String url) async {
    if (url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Widget _circleBtn(IconData icon, VoidCallback onTap, {Color color = Colors.white}) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 44, height: 44,
      decoration: BoxDecoration(
        color: Colors.black45,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white24, width: 0.5)
      ),
      child: Icon(icon, color: color, size: 24)
    ),
  );
}

extension on double {
  double toRad() => this * (math.pi / 180.0);
  double toDeg() => this * (180.0 / math.pi);
}
