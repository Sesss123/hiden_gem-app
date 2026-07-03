import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import '../../core/theme/app_theme.dart';
import '../../core/services/media_cache_manager.dart';

class IsolateCacheHelper {
  static Future<File> getCachedFile(String url) async {
    final tempDir = await getTemporaryDirectory();
    final hash = sha1.convert(utf8.encode(url)).toString();
    final filePath = '${tempDir.path}/$hash';
    
    // Check file existence in background isolate to keep UI thread free
    final fileExists = await compute(_checkFileExists, filePath);
    if (fileExists) {
      return File(filePath);
    }
    
    // Download and write bytes to disk in background isolates
    final bytes = await compute(_downloadBytes, url);
    if (bytes != null && bytes.isNotEmpty) {
      await compute(_writeFile, {'path': filePath, 'bytes': bytes});
    }
    return File(filePath);
  }

  static bool _checkFileExists(String path) {
    return File(path).existsSync();
  }

  static Future<List<int>?> _downloadBytes(String url) async {
    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
    } catch (_) {}
    return null;
  }

  static void _writeFile(Map<String, dynamic> args) {
    try {
      final file = File(args['path'] as String);
      file.writeAsBytesSync(args['bytes'] as List<int>);
    } catch (_) {}
  }
}

class CachedImage extends StatefulWidget {
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
  State<CachedImage> createState() => _CachedImageState();
}

class _CachedImageState extends State<CachedImage> {
  Future<File>? _imageFuture;

  @override
  void initState() {
    super.initState();
    if (widget.url.isNotEmpty) {
      _imageFuture = IsolateCacheHelper.getCachedFile(widget.url);
    }
  }

  @override
  void didUpdateWidget(CachedImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      if (widget.url.isNotEmpty) {
        _imageFuture = IsolateCacheHelper.getCachedFile(widget.url);
      } else {
        _imageFuture = null;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Empty URL guard
    if (widget.url.isEmpty || _imageFuture == null) return _buildError(context);

    final image = FutureBuilder<File>(
      future: _imageFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return widget.placeholder ?? _buildShimmer(context);
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          return widget.errorWidget ?? _buildError(context);
        }
        
        // Ensure the file is not empty/corrupted
        final file = snapshot.data!;
        if (!file.existsSync() || file.lengthSync() == 0) {
          return widget.errorWidget ?? _buildError(context);
        }

        return Image.file(
          file,
          fit: widget.fit,
          width: widget.width,
          height: widget.height,
          cacheWidth: widget.maxWidthDiskCache,
        );
      },
    );

    // Optional rounded corners
    if (widget.borderRadius != null) {
      return ClipRRect(
        borderRadius: widget.borderRadius!,
        child: image,
      );
    }

    return image;
  }

  Widget _buildShimmer(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: widget.width,
      height: widget.height,
      color: isDark
          ? const Color(0xFF1A2332)
          : AppPalette.sand2,
      child: _ShimmerBox(width: widget.width, height: widget.height),
    );
  }

  Widget _buildError(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      color: AppPalette.heroCream,
      child: Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          color: AppPalette.earth.withValues(alpha: 0.4),
          size: (widget.height != null && widget.height! < 80) ? 20 : 32,
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
