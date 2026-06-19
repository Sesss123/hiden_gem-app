import 'dart:io';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter/foundation.dart';

/// Caches AR videos locally so they load instantly after the first download.
/// Uses [flutter_cache_manager] with a 7-day TTL inside a dedicated cache store.
class VideoCacheService {
  static const _cacheKey = 'ar_video_cache';

  static final CacheManager _manager = CacheManager(
    Config(
      _cacheKey,
      stalePeriod: const Duration(days: 7),
      maxNrOfCacheObjects: 20,
      repo: JsonCacheInfoRepository(databaseName: _cacheKey),
      fileService: HttpFileService(),
    ),
  );

  /// Returns the local file if cached, or downloads and caches it.
  /// Throws [VideoCacheException] on failure.
  static Future<File> getVideo(String url) async {
    try {
      debugPrint('[VideoCacheService] Fetching: $url');
      final file = await _manager.getSingleFile(url);
      debugPrint('[VideoCacheService] Loaded from cache/network: ${file.path}');
      return file;
    } catch (e) {
      throw VideoCacheException('Failed to cache video: $e');
    }
  }

  /// Pre-warms the cache (call this on Place Details open, before AR starts).
  static Future<void> preload(String url) async {
    try {
      await _manager.downloadFile(url);
      debugPrint('[VideoCacheService] Preloaded: $url');
    } catch (e) {
      debugPrint('[VideoCacheService] Preload failed (non-critical): $e');
    }
  }

  /// Removes a specific video from cache.
  static Future<void> evict(String url) async {
    await _manager.removeFile(url);
  }

  /// Clears the entire AR video cache.
  static Future<void> clearAll() async {
    await _manager.emptyCache();
  }
}

class VideoCacheException implements Exception {
  final String message;
  const VideoCacheException(this.message);
  @override
  String toString() => 'VideoCacheException: $message';
}
