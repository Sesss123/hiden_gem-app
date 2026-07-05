import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/media_cache_manager.dart';
import '../../core/utils/secure_logger.dart';

class CachedImage extends StatelessWidget {
  final String url;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;
  final CachePoolType poolType;
  final int? maxWidthDiskCache;

  const CachedImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
    this.poolType = CachePoolType.thumbnail,
    this.maxWidthDiskCache,
  });

  @override
  Widget build(BuildContext context) {
    final uri = Uri.tryParse(url);
    if (url.isEmpty || uri == null || !uri.hasAbsolutePath) {
      return errorWidget ?? _buildError(context);
    }

    // BUG-P04 & BUG-P05 Fix: Route to appropriate cache pool with LRU eviction and TTL
    final cacheManager = poolType == CachePoolType.full
        ? FullCacheManager()
        : ThumbCacheManager();

    // BUG-P01, P02, P03 Fix: Use CachedNetworkImage which deduplicates in-flight requests
    // and eliminates the 3x isolate compute() overhead per image.
    final image = CachedNetworkImage(
      imageUrl: url,
      cacheManager: cacheManager,
      fit: fit,
      width: width,
      height: height,
      maxWidthDiskCache: maxWidthDiskCache,
      memCacheWidth: 600,
      memCacheHeight: 400,
      placeholder: (context, url) => placeholder ?? _buildShimmer(context),
      errorWidget: (context, url, error) {
        // BUG-P06 Fix: Explicit error logging instead of silent catch
        SecureLogger.warning("Failed to load image from cache: $url | Error: $error", tag: "ImageCache", isBackground: true);
        return errorWidget ?? _buildError(context);
      },
    );

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
          ? const AppTheme.colors.primary
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
                      const AppTheme.colors.primary,
                      const AppTheme.colors.primary,
                      const AppTheme.colors.primary,
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
