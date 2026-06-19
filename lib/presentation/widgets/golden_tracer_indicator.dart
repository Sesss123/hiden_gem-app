import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class ModernTracerIndicator extends StatefulWidget {
  const ModernTracerIndicator({super.key});

  @override
  State<ModernTracerIndicator> createState() => _ModernTracerIndicatorState();
}

class _ModernTracerIndicatorState extends State<ModernTracerIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: AppTheme.glassDecoration(context, opacity: 0.1, radius: BorderRadius.circular(20)),
      // Fixed size to house 3 dots horizontally
      child: SizedBox(
        width: 40,
        height: 12,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return CustomPaint(
              painter: _ModernTracerPainter(
                progress: _controller.value,
                color: AppTheme.modernGreen(context),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ModernTracerPainter extends CustomPainter {
  final double progress;
  final Color color;

  _ModernTracerPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    // We have 3 dots. Width is 40. 
    // Dot centers: x=4, x=20, x=36
    final List<double> centers = [6, 20, 34];
    final List<double> delays = [0, 0.2, 0.4];

    for (int i = 0; i < 3; i++) {
      final p = (progress + delays[i]) % 1.0;
      final scale = 0.8 + (0.4 * (1.0 - (p - 0.5).abs() * 2));
      final opacity = 0.4 + (0.6 * (1.0 - (p - 0.5).abs() * 2));
      
      final paint = Paint()
        ..color = color.withValues(alpha: opacity)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, p * 3); // hardware accelerated blur

      // base radius 4. scaled by scale.
      canvas.drawCircle(Offset(centers[i], size.height / 2), 4 * scale, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ModernTracerPainter old) => old.progress != progress;
}
