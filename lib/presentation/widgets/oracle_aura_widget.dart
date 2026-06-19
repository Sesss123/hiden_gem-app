import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class OracleAuraWidget extends StatefulWidget {
  final bool isVisible;
  final Color? baseColor;

  const OracleAuraWidget({
    super.key,
    required this.isVisible,
    this.baseColor,
  });

  @override
  State<OracleAuraWidget> createState() => _OracleAuraWidgetState();
}

class _OracleAuraWidgetState extends State<OracleAuraWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.4).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutExpo),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) return const SizedBox.shrink();
    final effectiveColor = widget.baseColor ?? AppTheme.modernGreen(context);

    return Center(
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // Outer Glow
              Container(
                width: 200 * _pulseAnimation.value,
                height: 200 * _pulseAnimation.value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      effectiveColor.withValues(alpha: 0.3),
                      effectiveColor.withValues(alpha: 0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              // Inner Core
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: effectiveColor.withValues(alpha: 0.5),
                      blurRadius: 30,
                      spreadRadius: 10,
                    ),
                  ],
                  gradient: LinearGradient(
                    colors: [
                      effectiveColor,
                      effectiveColor.withValues(alpha: 0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              // Floating Particles (Simulated)
              ...List.generate(5, (index) {
                final angle = (index * 72) * pi / 180;
                final offsetMultiplier = 1.2;
                return Transform.translate(
                  offset: Offset(
                    cos(angle) * 70 * _pulseAnimation.value * offsetMultiplier,
                    sin(angle) * 70 * _pulseAnimation.value * offsetMultiplier,
                  ),
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: effectiveColor.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}
