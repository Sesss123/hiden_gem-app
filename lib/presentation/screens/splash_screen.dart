import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/oracle_ui_system.dart';
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

  @override
  void initState() {
    super.initState();

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    
    // Hide Screenshot button initially
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(screenshotNotifierProvider.notifier).toggleVisibility(false);
    });

    // Auto-proceed logic after a cinematic delay
    _checkReadiness();
  }

  Future<void> _checkReadiness() async {
    await Future.delayed(const Duration(seconds: 4));
    _attemptFinish();
  }

  void _attemptFinish() {
    if (widget.isReady && !_isNavigating && mounted) {
      _isNavigating = true;
      widget.onFinish();
    } else if (mounted) {
      Future.delayed(const Duration(milliseconds: 500), _attemptFinish);
    }
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: OracleUI.auraBackground(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // --- The Oracle Eye (Animated Logo) ---
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.modernGreen(context).withValues(alpha: 0.1),
                          blurRadius: 80,
                          spreadRadius: 20,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.travel_explore_rounded,
                      size: 100,
                      color: AppTheme.modernGreen(context),
                    ),
                  )
                  .animate(onPlay: (c) => c.repeat())
                  .shimmer(duration: 3.seconds, color: AppTheme.textSecondary(context).withValues(alpha: 0.2))
                  .scale(begin: const Offset(0.95, 0.95), end: const Offset(1.05, 1.05), duration: 2.seconds, curve: Curves.easeInOut)
                  .shake(hz: 0.5, rotation: 0.02),

                  const SizedBox(height: 32),

                  // --- TRIPME.AI Branding ---
                  OracleUI.neonText(
                    "TRIPME.AI",
                    style: GoogleFonts.outfit(
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textPrimary(context),
                      letterSpacing: 12,
                    ),
                  )
                  .animate()
                  .fadeIn(duration: 1.seconds)
                  .blur(begin: const Offset(10, 10), end: Offset.zero, duration: 1.2.seconds),
                  
                  const SizedBox(height: 8),

                  Text(
                    "SRI LANKA'S PREMIER ORACLE",
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.modernGreen(context).withValues(alpha: 0.5),
                      letterSpacing: 6,
                    ),
                  )
                  .animate()
                  .fadeIn(delay: 500.ms, duration: 800.ms)
                  .slideY(begin: 1, end: 0),
                ],
              ),
            ),

            // --- Bottom Loading State ---
            Positioned(
              bottom: 80,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  const ModernTracerIndicator()
                      .animate()
                      .fadeIn(delay: 1.2.seconds),
                  const SizedBox(height: 24),
                  Text(
                    widget.isReady ? "CONNECTION ESTABLISHED" : "CALCULATING DESTINY...",
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textSecondary(context),
                      letterSpacing: 3,
                    ),
                  )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .shimmer(duration: 2.seconds, color: AppTheme.textSecondary(context).withValues(alpha: 0.1)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FadeInText extends StatefulWidget {
  final Widget child;
  const FadeInText({super.key, required this.child});

  @override
  State<FadeInText> createState() => _FadeInTextState();
}

class _FadeInTextState extends State<FadeInText> with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _anim, curve: const Interval(0.5, 1.0, curve: Curves.easeIn)),
    );
    _anim.forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _opacity, child: widget.child);
  }
}