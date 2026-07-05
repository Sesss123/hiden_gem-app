import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';

import '../../core/providers/screenshot_provider.dart';
import '../../presentation/widgets/golden_tracer_indicator.dart';

class SplashScreen extends ConsumerStatefulWidget {
  final VoidCallback onFinish;
  final bool isReady;

  const SplashScreen({
    super.key,
    required this.onFinish,
    required this.isReady,
  });

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _isNavigating = false;
  int _retryCount = 0;
  static const int maxRetries = 20; // 10 seconds max retry duration

  @override
  void initState() {
    super.initState();

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    
    // Hide Screenshot button initially
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(screenshotProvider.notifier).toggleVisibility(false);
    });

    // Auto-proceed logic after a cinematic delay
    _checkReadiness();
  }

  @override
  void didUpdateWidget(covariant SplashScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isReady && !oldWidget.isReady) {
      _isNavigating = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _attemptFinish();
      });
    }
  }

  Future<void> _checkReadiness() async {
    // await Future.delayed(const Duration(seconds: 3));
    _attemptFinish();
  }

  void _attemptFinish() {
    if (widget.isReady && !_isNavigating && mounted) {
      _isNavigating = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onFinish();
      });
    } else if (mounted && !_isNavigating) {
      _retryCount++;
      if (_retryCount > maxRetries) {
        if (mounted && !_isNavigating) {
          _isNavigating = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) widget.onFinish();
          });
        }
      } else {
        Future.delayed(const Duration(milliseconds: 500), _attemptFinish);
      }
    }
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppPaletteDark.bg : AppPalette.bg;
    final primaryTextColor = isDark ? AppPaletteDark.text : AppPalette.ink;
    final accentColor = isDark ? AppPaletteDark.gold : AppPalette.rust;
    final cardColor = isDark ? AppPaletteDark.card : AppPalette.surface;

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Theme-Aware Background Gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [AppPaletteDark.bg, AppTheme.colors.primary]
                    : [AppPalette.bg, AppPalette.bg2],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // 2. Subtle Ambient Top-Right Accent Glow
          Positioned(
            top: -70,
            right: -70,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    accentColor.withValues(alpha: isDark ? 0.15 : 0.10),
                    accentColor.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),

          // 3. Subtle Ambient Bottom-Left Earth Glow
          Positioned(
            bottom: -90,
            left: -90,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    (isDark ? AppPaletteDark.gem : AppPalette.earth).withValues(alpha: isDark ? 0.12 : 0.08),
                    AppTheme.colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // 4. Safe Content Area
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(height: 40),

                // Center Brand Emblem & Typography
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Harmonious Elevated Emblem
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          // Outer Subtle Pulsing Ring
                          Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: accentColor.withValues(alpha: 0.2),
                                width: 1.5,
                              ),
                            ),
                          )
                          .animate(onPlay: (c) => c.repeat(reverse: true))
                          .scale(begin: const Offset(0.95, 0.95), end: const Offset(1.06, 1.06), duration: 1600.ms, curve: Curves.easeInOut),

                          // Inner Elevated Surface Orb
                          Container(
                            width: 104,
                            height: 104,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: cardColor,
                              border: Border.all(
                                color: accentColor.withValues(alpha: 0.35),
                                width: 1.5,
                              ),
                              boxShadow: AppTheme.premiumShadow,
                            ),
                            child: Center(
                              child: Icon(
                                Icons.explore_rounded,
                                size: 48,
                                color: accentColor,
                              ),
                            ),
                          ),
                        ],
                      )
                      .animate()
                      .fadeIn(duration: 800.ms)
                      .scale(begin: const Offset(0.85, 0.85), end: const Offset(1.0, 1.0), duration: 900.ms, curve: Curves.easeOutBack),

                      const SizedBox(height: 36),

                      // Brand Title
                      Text(
                        "HIDDEN GEMS.AI",
                        style: GoogleFonts.outfit(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: primaryTextColor,
                          letterSpacing: 5.5,
                        ),
                      )
                      .animate()
                      .fadeIn(delay: 250.ms, duration: 750.ms)
                      .slideY(begin: 0.25, end: 0, curve: Curves.easeOutQuad),

                      const SizedBox(height: 10),

                      // Subtitle matching app label style
                      Text(
                        "SRI LANKA'S PREMIER AI TRAVEL ORACLE",
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: accentColor,
                          letterSpacing: 2.5,
                        ),
                      )
                      .animate()
                      .fadeIn(delay: 500.ms, duration: 650.ms),
                    ],
                  ),
                ),

                // 5. Bottom Status Indicator
                Padding(
                  padding: const EdgeInsets.only(bottom: 40),
                  child: Column(
                    children: [
                      const ModernTracerIndicator()
                          .animate()
                          .fadeIn(delay: 600.ms),
                      const SizedBox(height: 14),
                      Text(
                        widget.isReady ? "ORACLE CONNECTED" : "INITIALIZING TRAVEL EXPERIENCE...",
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: primaryTextColor.withValues(alpha: 0.65),
                          letterSpacing: 1.8,
                        ),
                      )
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .shimmer(duration: 1600.ms, color: accentColor.withValues(alpha: 0.6)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
