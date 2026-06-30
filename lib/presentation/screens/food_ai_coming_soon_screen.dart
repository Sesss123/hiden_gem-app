import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// 🍽️ FoodAiComingSoonScreen
///
/// A premium "Coming Soon" page for the AI Food Scanner feature.
/// Features animated particles, a glowing scanner ring, and a
/// notify-me CTA button.
class FoodAiComingSoonScreen extends StatefulWidget {
  const FoodAiComingSoonScreen({super.key});

  @override
  State<FoodAiComingSoonScreen> createState() => _FoodAiComingSoonScreenState();
}

class _FoodAiComingSoonScreenState extends State<FoodAiComingSoonScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late AnimationController _particleController;

  bool _notified = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Animated gradient background
          _buildAnimatedBackground(),
          // Floating food particles
          _buildFoodParticles(),
          // Main content
          _buildMainContent(context),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.0 + (_pulseController.value * 0.3),
              colors: [
                const Color(0xFF1A0A00).withValues(alpha: 0.9),
                const Color(0xFF0D1A0A).withValues(alpha: 0.8),
                const Color(0xFF0A0A0F),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFoodParticles() {
    final emojis = ['🍛', '🥗', '🍜', '🍱', '🥘', '🍚', '🌶️', '🫚'];
    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) {
        return Stack(
          children: List.generate(8, (i) {
            final progress = (_particleController.value + i / 8) % 1.0;
            final size = MediaQuery.of(context).size;
            final angle = (i / 8) * 2 * pi;
            final radius = 160.0 + sin(progress * pi * 2) * 30;
            final x = size.width / 2 + cos(angle + progress * 2 * pi) * radius;
            final y = size.height / 2 + sin(angle + progress * 2 * pi) * radius * 0.4;
            final opacity = 0.15 + sin(progress * pi) * 0.25;

            return Positioned(
              left: x - 16,
              top: y - 16,
              child: Opacity(
                opacity: opacity.clamp(0.0, 1.0),
                child: Text(
                  emojis[i % emojis.length],
                  style: TextStyle(fontSize: 28 + sin(progress * pi) * 8),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildMainContent(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),

              // ── Animated Scanner Ring ───────────────────────────────
              _buildScannerRing()
                  .animate()
                  .fadeIn(duration: 800.ms)
                  .scale(begin: const Offset(0.7, 0.7)),

              const SizedBox(height: 48),

              // ── "COMING SOON" Badge ─────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(100),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF6B00), Color(0xFFFF9500)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF6B00).withValues(alpha: 0.5),
                      blurRadius: 20,
                      spreadRadius: 2,
                    )
                  ],
                ),
                child: Text(
                  '🔥  COMING SOON',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 3,
                  ),
                ),
              )
                  .animate(delay: 200.ms)
                  .fadeIn(duration: 600.ms)
                  .slideY(begin: 0.3),

              const SizedBox(height: 24),

              // ── Title ───────────────────────────────────────────────
              Text(
                'AI FOOD\nSCANNER',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 1.1,
                  letterSpacing: -1,
                  shadows: [
                    Shadow(
                      color: const Color(0xFFFF6B00).withValues(alpha: 0.6),
                      blurRadius: 30,
                    )
                  ],
                ),
              )
                  .animate(delay: 300.ms)
                  .fadeIn(duration: 700.ms)
                  .slideY(begin: 0.2),

              const SizedBox(height: 20),

              // ── Subtitle ────────────────────────────────────────────
              Text(
                'Point your camera at any Sri Lankan dish and get instant nutrition facts, calories, and authentic recipe details — powered by our custom AI model.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.55),
                  height: 1.6,
                ),
              )
                  .animate(delay: 400.ms)
                  .fadeIn(duration: 600.ms)
                  .slideY(begin: 0.2),

              const SizedBox(height: 40),

              // ── Feature Cards ───────────────────────────────────────
              _buildFeatureGrid()
                  .animate(delay: 500.ms)
                  .fadeIn(duration: 600.ms)
                  .slideY(begin: 0.3),

              const SizedBox(height: 40),

              // ── Notify Me Button ────────────────────────────────────
              GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  setState(() => _notified = !_notified);
                  if (!_notified) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: const Color(0xFF1A2A1A),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        content: Row(
                          children: [
                            const Text('✅', style: TextStyle(fontSize: 18)),
                            const SizedBox(width: 12),
                            Text(
                              'Notification set! We\'ll alert you on launch.',
                              style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                },
                child: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: _notified
                            ? const LinearGradient(
                                colors: [Color(0xFF1A3A1A), Color(0xFF0A2A0A)])
                            : LinearGradient(
                                colors: [
                                  const Color(0xFFFF6B00),
                                  Color.lerp(
                                        const Color(0xFFFF9500),
                                        const Color(0xFFFF6B00),
                                        _pulseController.value,
                                      ) ??
                                      const Color(0xFFFF9500),
                                ],
                              ),
                        boxShadow: _notified
                            ? []
                            : [
                                BoxShadow(
                                  color: const Color(0xFFFF6B00).withValues(
                                    alpha: 0.4 + _pulseController.value * 0.2,
                                  ),
                                  blurRadius: 25,
                                  spreadRadius: 2,
                                )
                              ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _notified
                                ? Icons.notifications_active_rounded
                                : Icons.notifications_outlined,
                            color: Colors.white,
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _notified ? 'NOTIFICATION SET ✓' : 'NOTIFY ME ON LAUNCH',
                            style: GoogleFonts.outfit(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              )
                  .animate(delay: 700.ms)
                  .fadeIn(duration: 600.ms)
                  .slideY(begin: 0.3),

              const SizedBox(height: 16),

              // ── Go Back ─────────────────────────────────────────────
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Back to App',
                  style: GoogleFonts.inter(
                    color: Colors.white.withValues(alpha: 0.35),
                    fontSize: 13,
                  ),
                ),
              ).animate(delay: 800.ms).fadeIn(duration: 400.ms),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScannerRing() {
    return SizedBox(
      width: 200,
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer glow rings
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Container(
                width: 180 + _pulseController.value * 20,
                height: 180 + _pulseController.value * 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFFF6B00).withValues(
                      alpha: 0.15 + _pulseController.value * 0.15,
                    ),
                    width: 1,
                  ),
                ),
              );
            },
          ),
          // Rotating scanner arc
          AnimatedBuilder(
            animation: _rotateController,
            builder: (context, child) {
              return Transform.rotate(
                angle: _rotateController.value * 2 * pi,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: SweepGradient(
                      colors: [
                        Colors.transparent,
                        Colors.transparent,
                        const Color(0xFFFF6B00).withValues(alpha: 0.3),
                        const Color(0xFFFF6B00).withValues(alpha: 0.9),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.6, 0.75, 0.85, 1.0],
                    ),
                  ),
                ),
              );
            },
          ),
          // Inner solid ring
          Container(
            width: 130,
            height: 130,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF1A0E05),
              border: Border.all(
                color: const Color(0xFFFF6B00).withValues(alpha: 0.4),
                width: 1.5,
              ),
            ),
            child: Center(
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Text(
                    '🍽️',
                    style: TextStyle(
                      fontSize: 52 + _pulseController.value * 6,
                    ),
                  );
                },
              ),
            ),
          ),
          // Corner scan brackets (top-left, top-right, bottom-left, bottom-right)
          ..._buildScanBrackets(),
        ],
      ),
    );
  }

  List<Widget> _buildScanBrackets() {
    const color = Color(0xFFFF6B00);
    const size = 18.0;
    const thickness = 2.5;
    const offset = 6.0;

    Widget bracket(double? top, double? right, double? bottom, double? left,
        bool flipH, bool flipV) {
      return Positioned(
        top: top,
        right: right,
        bottom: bottom,
        left: left,
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..scale(flipH ? -1.0 : 1.0, flipV ? -1.0 : 1.0),
          child: SizedBox(
            width: size,
            height: size,
            child: CustomPaint(
              painter: _BracketPainter(color: color, thickness: thickness),
            ),
          ),
        ),
      );
    }

    return [
      bracket(offset, null, null, offset, false, false), // top-left
      bracket(offset, offset, null, null, true, false),  // top-right
      bracket(null, null, offset, offset, false, true),  // bottom-left
      bracket(null, offset, offset, null, true, true),   // bottom-right
    ];
  }

  Widget _buildFeatureGrid() {
    final features = [
      {'icon': '🔬', 'title': 'AI Analysis', 'desc': 'Deep learning food recognition'},
      {'icon': '📊', 'title': 'Nutrition Facts', 'desc': 'Calories, protein, carbs & fat'},
      {'icon': '🇱🇰', 'title': 'Sri Lankan Focus', 'desc': 'Trained on local cuisine data'},
      {'icon': '⚡', 'title': 'Real-Time', 'desc': 'Instant scan results'},
    ];

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.4,
      children: features
          .map((f) => Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: const Color(0xFF141414),
                  border: Border.all(
                    color: const Color(0xFFFF6B00).withValues(alpha: 0.15),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(f['icon']!, style: const TextStyle(fontSize: 26)),
                    const SizedBox(height: 8),
                    Text(
                      f['title']!,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      f['desc']!,
                      style: GoogleFonts.inter(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 10,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }
}

/// Paints a single corner bracket (L-shape)
class _BracketPainter extends CustomPainter {
  final Color color;
  final double thickness;

  const _BracketPainter({required this.color, required this.thickness});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.square
      ..style = PaintingStyle.stroke;

    // Vertical line
    canvas.drawLine(Offset(0, 0), Offset(0, size.height), paint);
    // Horizontal line
    canvas.drawLine(Offset(0, 0), Offset(size.width, 0), paint);
  }

  @override
  bool shouldRepaint(_BracketPainter old) => false;
}
