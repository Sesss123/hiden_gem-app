import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class DynamicLightWrapper extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const DynamicLightWrapper({
    super.key,
    required this.child,
    this.duration = const Duration(seconds: 4),
  });

  @override
  State<DynamicLightWrapper> createState() => _DynamicLightWrapperState();
}

class _DynamicLightWrapperState extends State<DynamicLightWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)..repeat();
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
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: [
                _controller.value - 0.2,
                _controller.value,
                _controller.value + 0.2,
              ],
              colors: [
                Colors.transparent,
                AppTheme.modernGreen(context).withValues(alpha: 0.1),
                Colors.transparent,
              ],
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcATop,
          child: widget.child,
        );
      },
    );
  }
}
