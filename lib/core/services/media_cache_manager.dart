import 'package:flutter_cache_manager/flutter_cache_manager.dart';

enum CachePoolType { thumbnail, full }

/// ThumbCacheManager — For List & Grid view thumbnails (Lightweight, Long TTL)
/// Prevents high-resolution gallery downloads from evicting UI list thumbnails.
class ThumbCacheManager extends CacheManager with ImageCacheManager {
  static const key = 'heritage_thumbs';
  static final ThumbCacheManager _instance = ThumbCacheManager._();
  factory ThumbCacheManager() => _instance;
  ThumbCacheManager._()
      : super(Config(
          key,
          stalePeriod: const Duration(days: 60),
          maxNrOfCacheObjects: 500,
          repo: JsonCacheInfoRepository(databaseName: key),
          fileService: HttpFileService(),
        ));
}

/// FullCacheManager — For PlaceDetailsScreen Galleries & Hero photos (High resolution, Fast LRU Eviction)
class FullCacheManager extends CacheManager with ImageCacheManager {
  static const key = 'heritage_full';
  static final FullCacheManager _instance = FullCacheManager._();
  factory FullCacheManager() => _instance;
  FullCacheManager._()
      : super(Config(
          key,
          stalePeriod: const Duration(days: 14),
          maxNrOfCacheObjects: 150,
          repo: JsonCacheInfoRepository(databaseName: key),
          fileService: HttpFileService(),
        ));
}
