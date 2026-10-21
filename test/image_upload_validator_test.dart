import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hidden_gems_sl/core/utils/image_upload_validator.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  late Directory tempDirectory;

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp('image-validator-');
  });

  tearDown(() async {
    await tempDirectory.delete(recursive: true);
  });

  test('accepts a valid JPEG signature', () async {
    final file = File('${tempDirectory.path}/photo.jpg');
    await file.writeAsBytes(<int>[0xff, 0xd8, 0xff, 0xe0, 0x00]);

    await expectLater(
      ImageUploadValidator.validate(XFile(file.path)),
      completes,
    );
  });

  test('rejects non-image content', () async {
    final file = File('${tempDirectory.path}/fake.jpg');
    await file.writeAsString('not an image');

    await expectLater(
      ImageUploadValidator.validate(XFile(file.path)),
      throwsA(isA<ImageValidationException>()),
    );
  });

  test('rejects an oversized image before upload', () async {
    final file = File('${tempDirectory.path}/large.jpg');
    await file.writeAsBytes(<int>[0xff, 0xd8, 0xff, 0xe0, 0x00]);

    await expectLater(
      ImageUploadValidator.validate(XFile(file.path), maxBytes: 4),
      throwsA(isA<ImageValidationException>()),
    );
  });
}
