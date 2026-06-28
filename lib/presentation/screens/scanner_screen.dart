import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_theme.dart';
import '../../data/datasources/premium_service.dart';

class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen> with WidgetsBindingObserver {
  CameraController? _controller;
  bool _isInit = false;
  bool _isScanning = false;
  String? _result;
  int _scanCounter = 0;

  static const List<String> _simulatedScans = [
    "Sigiriya Rock Fortress Identified.\n\nBuilt by King Kasyapa (477–495 CE), Sigiriya is a UNESCO World Heritage site known as the 'Lion Rock'. Highlights include the mirror wall, ancient frescoes, and the symmetrical water gardens at the base.",
    "Temple of the Sacred Tooth Relic Identified.\n\nLocated in the royal palace complex of Kandy, this houses the relic of the tooth of the Buddha. Since ancient times, the relic has played an active role in local politics because it is believed that whoever holds the relic holds governance of the country.",
    "Galle Dutch Fort Identified.\n\nFirst built by the Portuguese in 1588 and fortified by the Dutch during the 17th century, Galle Fort is a historical, archaeological and architectural heritage monument that maintains its timeless charm.",
    "Nine Arch Bridge, Ella Identified.\n\nOne of the best examples of colonial-era railway construction in Sri Lanka, built entirely from solid stone bricks and cement without a single piece of steel.",
    "E-Ticket Validated Successfully.\n\nTicket Code: TM-9823-SL\nType: Premium Cultural Explorer Pass\nHolder: Verified Pilgrim\nStatus: ACTIVE\nAdmissions Remaining: 2/3 (Access granted to museum grounds)."
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  Future<void> _initCamera() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) return;

    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    _controller = CameraController(
      cameras.first,
      ResolutionPreset.high,
      enableAudio: false,
    );

    try {
      await _controller!.initialize();
      if (mounted) {
        setState(() => _isInit = true);
      }
    } catch (e) {
      debugPrint("Camera init error: $e");
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) {
      _controller?.dispose();
      _controller = null;
      setState(() => _isInit = false);
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  void _startScan() async {
    if (_isScanning) return;
    
    setState(() {
      _isScanning = true;
      _result = null;
    });

    // Simulate "Oracle" high-fidelity processing
    await Future.delayed(const Duration(seconds: 3));

    if (mounted) {
      setState(() {
        _isScanning = false;
        _result = _simulatedScans[_scanCounter % _simulatedScans.length];
        _scanCounter++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPremium = ref.watch(premiumNotifierProvider);

    return Scaffold(
      backgroundColor: Colors.black, // Keep camera background black
      body: Stack(
        children: [
          // Full Screen Camera or Placeholder
            Positioned.fill(
              child: _isInit && _controller != null
                ? CameraPreview(_controller!)
                : Container(
                    color: Colors.black,
                    child: Center(
                      child: Icon(Icons.photo_camera_rounded, color: AppTheme.textSecondary(context).withValues(alpha: 0.1), size: 80)
                          .animate(onPlay: (c) => c.repeat())
                          .shimmer(duration: 2.seconds),
                    ),
                  ),
            ),
            
            // Scrim for readability
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.7),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.8),
                    ],
                    stops: const [0.0, 0.4, 1.0],
                  ),
                ),
              ),
            ),

            SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: Icon(Icons.arrow_back_rounded, color: AppTheme.textPrimary(context)),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Text(
                          "ORACLE VISION",
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 4,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 48), // Spacer
                      ],
                    ),
                    const Spacer(),
                    if (!isPremium) _buildPremiumGate(),
                    if (isPremium && _result != null) _buildResultCard(),
                    SizedBox(height: 48),
                    if (isPremium)
                      SizedBox(
                        width: double.infinity,
                        height: 64,
                        child: ElevatedButton(
                          onPressed: _isScanning ? null : _startScan,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            elevation: 8,
                            shadowColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(_isScanning ? Icons.sync_rounded : Icons.filter_center_focus_rounded),
                              SizedBox(width: 12),
                              Text(
                                _isScanning ? "IDENTIFYING..." : "ANALYZE LANDMARK",
                                style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1),
                              ),
                            ],
                          ),
                        ),
                      ),
                    SizedBox(height: 40),
                  ],
                ),
              ),
            ),
            
            // Scanner Animation
            if (_isScanning) 
              Center(
                child: Container(
                  width: double.infinity,
                  height: 300,
                  margin: EdgeInsets.symmetric(horizontal: 32),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppPalette.rust.withValues(alpha: 0.5), width: 2),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: _ScanningOverlay(),
                ),
              ),
          ],
        ),
    );
  }

  Widget _buildPremiumGate() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppTheme.secondaryBorder(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.lock_person_rounded, color: Theme.of(context).colorScheme.primary, size: 56)
              .animate(onPlay: (c) => c.repeat())
              .shimmer(duration: 2.seconds),
          const SizedBox(height: 24),
          Text(
            "VISION RESERVED",
            style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.textPrimary(context), letterSpacing: 1),
          ),
          const SizedBox(height: 12),
          Text(
            "Access the Aethereal Database to identify landmarks and reveal hidden history through your lens.",
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: AppTheme.textSecondary(context), height: 1.6, fontSize: 13),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: OutlinedButton(
              onPressed: () => ref.read(premiumNotifierProvider.notifier).buyPremium(),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Theme.of(context).colorScheme.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                "UPGRADE TO LUXURY",
                style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 12, color: Theme.of(context).colorScheme.primary),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).scale(begin: const Offset(0.95, 0.95));
  }

  Widget _buildResultCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppPalette.rust.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_rounded, color: AppPalette.rust, size: 20),
              const SizedBox(width: 12),
              Text(
                "ORACLE VERIFIED",
                style: GoogleFonts.outfit(
                  color: AppPalette.rust,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            _result!,
            style: GoogleFonts.inter(color: AppTheme.textPrimary(context), height: 1.7, fontSize: 14),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1);
  }
}

class _ScanningOverlay extends StatefulWidget {
  @override
  State<_ScanningOverlay> createState() => _ScanningOverlayState();
}

class _ScanningOverlayState extends State<_ScanningOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          children: [
            Positioned(
              top: _controller.value * 300,
              left: 0,
              right: 0,
              child: Container(
                height: 2,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary.withValues(alpha: 0.0),
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.primary.withValues(alpha: 0.0),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
                      blurRadius: 20,
                      spreadRadius: 4,
                    )
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
