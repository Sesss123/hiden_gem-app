import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// [CachedImage] — Optimized network image widget with disk + memory caching.
///
/// Replaces all `Image.network()` calls across the app.
/// Features:
///   - Disk cache (survives app restarts)
///   - Memory LRU cache
///   - Shimmer placeholder
///   - Graceful error fallback with icon
///   - BoxFit control
///
/// USAGE:
/// ```dart
/// CachedImage(
///   url: place.imageUrl,
///   fit: BoxFit.cover,
///   height: 200,
/// )
/// ```
class CachedImage extends StatelessWidget {
  final String url;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;

  const CachedImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    // Empty URL guard
    if (url.isEmpty) return _buildError(context);

    final image = CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      width: width,
      height: height,

      // Shimmer-style loading placeholder
      placeholder: (context, url) =>
          placeholder ?? _buildShimmer(context),

      // Error fallback
      errorWidget: (context, url, error) =>
          errorWidget ?? _buildError(context),

      // Cache config: keep 200 images, max 30 days
      memCacheWidth: width != null ? (width! * 2).toInt() : null,
    );

    // Optional rounded corners
    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: image,
      );
    }

    return image;
  }

  Widget _buildShimmer(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: width,
      height: height,
      color: isDark
          ? const Color(0xFF1A2332)
          : AppPalette.sand2,
      child: _ShimmerBox(width: width, height: height),
    );
  }

  Widget _buildError(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: AppPalette.heroCream,
      child: Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          color: AppPalette.earth.withValues(alpha: 0.4),
          size: (height != null && height! < 80) ? 20 : 32,
        ),
      ),
    );
  }
}

/// Animated shimmer loading box
class _ShimmerBox extends StatefulWidget {
  final double? width;
  final double? height;

  const _ShimmerBox({this.width, this.height});

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _animation = Tween<double>(begin: -1.5, end: 1.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(_animation.value - 1, 0),
              end: Alignment(_animation.value, 0),
              colors: isDark
                  ? [
                      const Color(0xFF1A2332),
                      const Color(0xFF243044),
                      const Color(0xFF1A2332),
                    ]
                  : [
                      AppPalette.sand2,
                      AppPalette.sand2.withValues(alpha: 0.5),
                      AppPalette.sand2,
                    ],
            ),
          ),
        );
      },
    );
  }
}
