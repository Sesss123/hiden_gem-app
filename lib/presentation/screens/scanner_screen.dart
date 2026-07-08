import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_theme.dart';
import '../../data/datasources/premium_service.dart';
import 'package:hidden_gems_sl/core/utils/secure_logger.dart';

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  Future<void> _initCamera() async {
    final status = await Permission.camera.request();
    if (status.isPermanentlyDenied) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Camera Permission Required'),
            content: const Text('Please enable camera access in app settings to use the scanner.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  openAppSettings();
                },
                child: const Text('Open Settings'),
              ),
            ],
          ),
        );
      }
      return;
    }
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
    } catch (e, st) {
      SecureLogger.error("Camera init error", e, st, "ScannerScreen");
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

    // Simulate connection check
    // await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _isScanning = false;
        _result = "🛰️ Live Cloud Inference Rolling Out Soon!\n\nReal-time neural landmark recognition and object detection are being deployed to our high-speed edge nodes. You will receive an alert as soon as live camera processing goes live in the upcoming update.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPremium = ref.watch(premiumProvider);

    return Scaffold(
      backgroundColor: AppTheme.colors.black, // Keep camera background black
      body: Stack(
        children: [
          // Full Screen Camera or Placeholder
            Positioned.fill(
              child: _isInit && _controller != null
                ? CameraPreview(_controller!)
                : Container(
                    color: AppTheme.colors.black,
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
                      AppTheme.colors.black.withValues(alpha: 0.7),
                      AppTheme.colors.transparent,
                      AppTheme.colors.black.withValues(alpha: 0.8),
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
                          "Landmark scanner",
                          style: GoogleFonts.outfit(
                            color: AppTheme.colors.white,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
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
                            foregroundColor: Theme.of(context).colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                            elevation: 0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(_isScanning ? Icons.sync_rounded : Icons.filter_center_focus_rounded),
                              SizedBox(width: 12),
                              Text(
                                _isScanning ? "Identifying…" : "Analyze landmark",
                                style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14),
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
                    border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5), width: 2),
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
    final secondary = Theme.of(context).colorScheme.secondary;
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppTheme.colors.black.withValues(alpha: 0.93),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppTheme.colors.black.withValues(alpha: 0.2),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: secondary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.lock_person_rounded, color: secondary, size: 26)
                .animate(onPlay: (c) => c.repeat())
                .shimmer(duration: 2.seconds),
          ),
          const SizedBox(height: 16),
          Text(
            "Unlock landmark scanning",
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.colors.white, letterSpacing: -0.3),
          ),
          const SizedBox(height: 10),
          Text(
            "Point your camera at any site to reveal its hidden history.",
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: AppTheme.colors.white.withValues(alpha: 0.7), height: 1.6, fontSize: 13),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () => ref.read(premiumProvider.notifier).buyPremium(),
              style: ElevatedButton.styleFrom(
                backgroundColor: secondary,
                foregroundColor: AppPalette.ink,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
              ),
              child: Text(
                "Upgrade to premium",
                style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).scale(begin: const Offset(0.95, 0.95));
  }

  Widget _buildResultCard() {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.verified_rounded, color: primary, size: 20),
              const SizedBox(width: 12),
              Text(
                "Oracle verified",
                style: GoogleFonts.outfit(
                  color: primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
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
