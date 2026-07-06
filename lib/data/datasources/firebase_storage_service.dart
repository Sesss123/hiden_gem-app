import 'dart:io' as io;
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

class FirebaseStorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String?> uploadGuideDocument({
    required XFile file,
    required String docType, // 'license', 'nic', 'selfie'
  }) async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_$docType.jpg';
      final ref = _storage.ref().child('guide_documents/${user.uid}/$fileName');
      
      late TaskSnapshot uploadTask;
      if (kIsWeb) {
        final bytes = await file.readAsBytes();
        
        // Compress for web
        final compressedBytes = await FlutterImageCompress.compressWithList(
          bytes,
          minWidth: 1080,
          minHeight: 1080,
          quality: 80,
          format: CompressFormat.webp,
        );

        uploadTask = await ref.putData(
          compressedBytes,
          SettableMetadata(contentType: 'image/webp'),
        );
      } else {
        // Compress for mobile
        final tempPath = '${io.Directory.systemTemp.path}/$fileName.webp';
        final compressedFile = await FlutterImageCompress.compressAndGetFile(
          file.path,
          tempPath,
          minWidth: 1080,
          minHeight: 1080,
          quality: 80,
          format: CompressFormat.webp,
        );

        if (compressedFile != null) {
          uploadTask = await ref.putFile(
            io.File(compressedFile.path),
            SettableMetadata(contentType: 'image/webp'),
          );
        } else {
          // Fallback if compression fails
          uploadTask = await ref.putFile(
            io.File(file.path),
            SettableMetadata(contentType: 'image/jpeg'),
          );
        }
      }

      if (uploadTask.state == TaskState.success) {
        return await ref.getDownloadURL();
      }
    } catch (e) {
      debugPrint('Firebase Storage upload error: $e');
    }
    return null;
  }

  Future<void> deleteFile(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (e) {
      debugPrint('Firebase Storage deletion error: $e');
    }
  }
}
