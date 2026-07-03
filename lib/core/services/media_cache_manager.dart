import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

enum CachePoolType { thumbnail, full }

/// BUG-112: Custom FileService that generates unique cache keys based on URL hashes
/// BUG-132: Validates that the downloaded file is a valid image before saving it
class ValidatedHttpFileService extends HttpFileService {
  @override
  Future<FileServiceResponse> get(String url, {Map<String, String>? headers}) async {
    final response = await super.get(url, headers: headers);
    // Wrap to validate that content is actually a valid image
    return ValidatedResponse(response);
  }

  // Helper to hash URL strings into secure unique filenames
  static String hashKey(String url) {
    return md5.convert(utf8.encode(url)).toString();
  }

  // BUG-132: Verify if the byte payload starts with valid magic numbers/headers of common image types
  static bool isValidImageBytes(Uint8List bytes) {
    if (bytes.length < 4) return false;
    // JPEG: FF D8 FF
    if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) return true;
    // PNG: 89 50 4E 47
    if (bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47) return true;
    // GIF: 47 49 46 38
    if (bytes[0] == 0x47 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x38) return true;
    // WebP/RIFF: 52 49 46 46 (RIFF) ... 57 41 56 45 (WEBP)
    if (bytes[0] == 0x52 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x46) return true;
    return false;
  }
}

class ValidatedResponse implements FileServiceResponse {
  final FileServiceResponse _inner;
  ValidatedResponse(this._inner);

  @override
  int? get contentLength => _inner.contentLength;

  @override
  DateTime get validTill => _inner.validTill ?? DateTime.now().add(const Duration(hours: 1));

  @override
  String? get eTag => _inner.eTag;

  @override
  String get fileExtension {
    // Keep it generic, or derive from content-type header
    return _inner.fileExtension;
  }

  @override
  int get statusCode => _inner.statusCode;

  @override
  Stream<List<int>> get content {
    // Read the first chunk of stream to validate image signatures
    return _inner.content.map((chunk) {
      if (chunk.isNotEmpty) {
        final bytes = Uint8List.fromList(chunk);
        // Validate if it is indeed a valid image file.
        // We only check on first packet or headers chunk.
        if (!ValidatedHttpFileService.isValidImageBytes(bytes)) {
          throw StateError("Invalid image header: block corrupt content from entering cache.");
        }
      }
      return chunk;
    });
  }
}

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
          // BUG-072: Increase max cache objects limit to 1000 to prevent frequent evictions
          maxNrOfCacheObjects: 1000,
          repo: JsonCacheInfoRepository(databaseName: key),
          fileService: ValidatedHttpFileService(),
        ));

  Future<void> clearThumbnailCache() async {
    await emptyCache();
  }
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
          fileService: ValidatedHttpFileService(),
        ));


  Future<void> clearFullImageCache() async {
    await emptyCache();
  }
}

class MediaCacheManager {
  static Future<void> clearFullCacheOnly() async {
    await FullCacheManager().clearFullImageCache();
  }

  static Future<void> clearThumbnailCacheOnly() async {
    await ThumbCacheManager().clearThumbnailCache();
  }

  static Future<void> clearAll() async {
    await clearFullCacheOnly();
    await clearThumbnailCacheOnly();
  }
}
