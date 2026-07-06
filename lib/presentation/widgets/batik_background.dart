import 'package:flutter/material.dart';

class BatikBackground extends StatelessWidget {
  final Widget child;
  final double opacity;
  const BatikBackground({super.key, required this.child, this.opacity = 0.015});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // The background color is naturally inherited from the Scaffold (Cream/Dark).
    // We removed the solid orange (primary) gradient that was painting over everything.
    return Stack(
      children: [
          Positioned.fill(
            child: RepaintBoundary(
              child: CustomPaint(
                painter: BatikPainter(
                  color: theme.colorScheme.primary.withValues(alpha: opacity),
                ),
              ),
            ),
          ),
          child,
        ],
    );
  }
}

class BatikPainter extends CustomPainter {
  final Color color;

  BatikPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    const double spacing = 40.0;
    const double crossSize = 4.0;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        // Draw horizontal line of the '+'
        canvas.drawLine(
          Offset(x - crossSize / 2, y),
          Offset(x + crossSize / 2, y),
          paint,
        );
        // Draw vertical line of the '+'
        canvas.drawLine(
          Offset(x, y - crossSize / 2),
          Offset(x, y + crossSize / 2),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant BatikPainter oldDelegate) => oldDelegate.color != color;
}

