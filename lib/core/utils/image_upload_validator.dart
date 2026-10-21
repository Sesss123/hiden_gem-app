import 'package:image_picker/image_picker.dart';

class ImageValidationException implements Exception {
  final String message;

  const ImageValidationException(this.message);

  @override
  String toString() => message;
}

class ImageUploadValidator {
  static const int defaultMaxBytes = 10 * 1024 * 1024;

  static Future<void> validate(
    XFile file, {
    int maxBytes = defaultMaxBytes,
  }) async {
    final length = await file.length();
    if (length <= 0) {
      throw const ImageValidationException('The selected image is empty.');
    }
    if (length > maxBytes) {
      final maxMegabytes = maxBytes ~/ (1024 * 1024);
      throw ImageValidationException(
        'The selected image is too large. Choose an image under $maxMegabytes MB.',
      );
    }

    final header = await file.openRead(0, length < 16 ? length : 16).first;
    if (!_hasSupportedSignature(header)) {
      throw const ImageValidationException(
        'Unsupported or invalid image. Choose a JPEG, PNG, WebP, or HEIC image.',
      );
    }
  }

  static bool _hasSupportedSignature(List<int> bytes) {
    final isJpeg = bytes.length >= 3 &&
        bytes[0] == 0xff &&
        bytes[1] == 0xd8 &&
        bytes[2] == 0xff;
    final isPng = bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4e &&
        bytes[3] == 0x47 &&
        bytes[4] == 0x0d &&
        bytes[5] == 0x0a &&
        bytes[6] == 0x1a &&
        bytes[7] == 0x0a;
    final isWebP = bytes.length >= 12 &&
        String.fromCharCodes(bytes.sublist(0, 4)) == 'RIFF' &&
        String.fromCharCodes(bytes.sublist(8, 12)) == 'WEBP';
    final isHeic = bytes.length >= 12 &&
        String.fromCharCodes(bytes.sublist(4, 8)) == 'ftyp' &&
        <String>{'heic', 'heix', 'hevc', 'hevx', 'mif1', 'msf1'}
            .contains(String.fromCharCodes(bytes.sublist(8, 12)));
    return isJpeg || isPng || isWebP || isHeic;
  }
}
