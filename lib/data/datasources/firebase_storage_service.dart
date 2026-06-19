import 'dart:io' as io;
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:firebase_storage/firebase_storage.dart';
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
        uploadTask = await ref.putData(
          bytes,
          SettableMetadata(contentType: 'image/jpeg'),
        );
      } else {
        uploadTask = await ref.putFile(
          io.File(file.path),
          SettableMetadata(contentType: 'image/jpeg'),
        );
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
