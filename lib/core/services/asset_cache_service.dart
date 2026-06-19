import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import '../config/app_config.dart';

class AssetCacheService {
  static final HeritageCacheManager _manager = HeritageCacheManager();

  /// Gets a file from the cache or downloads it if not present.
  /// Supports R2 CDN resolution and progress tracking.
  static Future<File?> getAssetFile(String url, {Function(double)? onProgress}) async {
    // Resolve CDN URL if it's a relative path or uses old storage
    final finalUrl = _resolveCdnUrl(url);
    
    try {
      final fileStream = _manager.getFileStream(
        finalUrl,
        withProgress: true,
      );

      File? resultFile;
      
      await for (final response in fileStream) {
        if (response is DownloadProgress && onProgress != null) {
          onProgress(response.progress ?? 0.0);
        } else if (response is FileInfo) {
          resultFile = response.file;
        }
      }
      return resultFile;
    } catch (e) {
      debugPrint("AssetCacheService: Cache fetch failed: $e");
      return null;
    }
  }

  /// Downloads an asset to the cache explicitly.
  static Future<void> downloadAsset(String url, {Function(double)? onProgress}) async {
    if (url.isEmpty) return;
    final finalUrl = _resolveCdnUrl(url);
    try {
      final fileStream = _manager.getFileStream(
        finalUrl,
        withProgress: true,
      );
      
      await for (final response in fileStream) {
        if (response is DownloadProgress && onProgress != null) {
          onProgress(response.progress ?? 0.0);
        }
      }
    } catch (e) {
      debugPrint("AssetCacheService: Download failed: $e");
    }
  }

  static String _resolveCdnUrl(String url) {
    if (url.startsWith('http')) return url;
    // If it's just a filename or relative path, prepend CDN base
    return "${AppConfig.cdnBaseUrl}/$url";
  }

  static Future<String?> getLocalPath(String url) async {
    final finalUrl = _resolveCdnUrl(url);
    final fileInfo = await _manager.getFileFromCache(finalUrl);
    return fileInfo?.file.path;
  }

  static Future<void> clearCache() async {
    await _manager.emptyCache();
  }
}

/// Custom Cache Manager for Hidden Gems SL Heritage Assets
class HeritageCacheManager extends CacheManager with ImageCacheManager {
  static const key = 'heritage_assets';

  static final HeritageCacheManager _instance = HeritageCacheManager._();

  factory HeritageCacheManager() => _instance;

  HeritageCacheManager._()
      : super(Config(
          key,
          stalePeriod: const Duration(days: 30),
          maxNrOfCacheObjects: 100,
          repo: JsonCacheInfoRepository(databaseName: key),
          fileService: HttpFileService(),
        ));
}
