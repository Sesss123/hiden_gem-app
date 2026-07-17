import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/guide_application.dart';
import '../models/guide_status.dart';
import '../../core/config/app_config.dart';
import '../../core/network/secure_http_client.dart';
import '../../core/utils/secure_logger.dart';

class GuideApplicationRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Uploads a guide enrollment document (license/NIC/selfie) to the Laravel
  /// backend's local disk storage — the self-hosted replacement for Firebase
  /// Storage, so it moves to a VPS unchanged when one is provisioned.
  /// Returns the absolute URL to the stored file, or null on failure.
  Future<String?> uploadDocument({required XFile file, required String docType}) async {
    try {
      final client = SecureHttpClient(http.Client());
      final uri = Uri.parse('${AppConfig.laravelUrl}/guide-applications/documents');
      final request = http.MultipartRequest('POST', uri)
        ..headers['Accept'] = 'application/json'
        ..headers['X-API-KEY'] = AppConfig.hiddenGemsApiKey
        ..headers['X-HiddenGems-Key'] = AppConfig.hiddenGemsApiKey
        ..fields['doc_type'] = docType
        ..files.add(await http.MultipartFile.fromPath('file', file.path));

      final streamedResponse = await client.send(request).timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data']['full_url'] as String?;
      }
      SecureLogger.error("Document upload returned status ${response.statusCode}: ${response.body}");
    } catch (e) {
      SecureLogger.error("Failed to upload guide document to Laravel Backend: $e");
    }
    return null;
  }

  Future<void> submitApplication(GuideApplication application) async {
    // 1. Submit to Laravel Backend API
    try {
      final client = SecureHttpClient(http.Client());
      final uri = Uri.parse('${AppConfig.laravelUrl}/guide-applications');
      final response = await client.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-API-KEY': AppConfig.hiddenGemsApiKey,
          'X-HiddenGems-Key': AppConfig.hiddenGemsApiKey,
        },
        body: json.encode({
          ...application.toJson(),
          'email': _auth.currentUser?.email,
          'name': _auth.currentUser?.displayName ?? 'Guide Applicant',
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        SecureLogger.info("Guide application successfully submitted to Laravel Backend.");
      } else {
        SecureLogger.error("Laravel Backend returned status ${response.statusCode} during guide submission.");
      }
    } catch (e) {
      SecureLogger.error("Failed to submit guide application to Laravel Backend (falling back to Firestore): $e");
    }

    // 2. Fallback / Sync to Firestore
    await _firestore.collection('guide_applications').doc(application.userId).set(application.toJson());
  }

  Future<GuideApplication?> getMyApplication() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    // 1. Check Laravel Backend API first
    try {
      final client = SecureHttpClient(http.Client());
      final uri = Uri.parse('${AppConfig.laravelUrl}/guide-applications/status/${user.uid}');
      final response = await client.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'X-API-KEY': AppConfig.hiddenGemsApiKey,
          'X-HiddenGems-Key': AppConfig.hiddenGemsApiKey,
        },
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['data'] != null) {
          final app = GuideApplication.fromJson(data['data']);
          // Sync approved/rejected status back to Firestore/user profile.
          // Note: 'role' is NOT set here — firestore.rules blocks clients
          // from writing that field on their own account (anti-fraud), and
          // Laravel's admin approval flow already sets it server-side
          // (laravel-backend/app/Http/Controllers/Admin/GuideController.php).
          if (app.status == GuideStatus.approved) {
            await _firestore.collection('users').doc(user.uid).update({
              'guideStatus': GuideStatus.approved.name,
              'isGuideApproved': true,
            }).catchError((_) {});
          } else if (app.status == GuideStatus.rejected) {
            await _firestore.collection('users').doc(user.uid).update({
              'guideStatus': GuideStatus.rejected.name,
              'guideRejectionReason': app.adminComment ?? "Documents incomplete or unclear. Please reapply.",
            }).catchError((_) {});
          }
          return app;
        }
      }
    } catch (e) {
      SecureLogger.error("Failed to fetch guide status from Laravel Backend: $e");
    }

    // 2. Fallback to Firestore
    final doc = await _firestore.collection('guide_applications').doc(user.uid).get();
    if (doc.exists) {
      return GuideApplication.fromJson(doc.data()!);
    }
    return null;
  }

  // Admin-only dashboard (low traffic), capped as defense-in-depth against
  // an unbounded pending-applications backlog re-delivering on every change.
  Stream<List<GuideApplication>> getPendingApplications() => getApplicationsByStatus(GuideStatus.pending.name);

  Stream<List<GuideApplication>> getApplicationsByStatus(String status) {
    return _firestore
        .collection('guide_applications')
        .where('status', isEqualTo: status)
        .limit(200)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => GuideApplication.fromJson(doc.data())).toList());
  }

  Future<void> reviewApplication({
    required String userId,
    required GuideStatus status,
    String? adminComment,
  }) async {
    // 1. Review on Laravel Backend
    try {
      final client = SecureHttpClient(http.Client());
      final endpoint = status == GuideStatus.approved ? 'approve' : 'reject';
      final uri = Uri.parse('${AppConfig.laravelUrl}/admin/guide-applications/$userId/$endpoint');
      await client.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-API-KEY': AppConfig.hiddenGemsApiKey,
          'X-HiddenGems-Key': AppConfig.hiddenGemsApiKey,
        },
        body: json.encode({
          'admin_comment': adminComment,
        }),
      ).timeout(const Duration(seconds: 10));
    } catch (e) {
      SecureLogger.error("Failed to review application on Laravel Backend: $e");
    }

    // 2. Update Firestore as well. Unlike the Laravel call above (best-effort
    // logged-only), failures here are NOT swallowed — they propagate to the
    // caller so admin_guide_verification_detail_screen.dart's error handling
    // can actually fire instead of showing a false "approved"/"rejected"
    // success message while the applicant's records are unchanged.
    await _firestore.collection('guide_applications').doc(userId).update({
      'status': status.name,
      'adminComment': adminComment,
      'reviewedAt': DateTime.now().toIso8601String(),
    });

    if (status == GuideStatus.approved) {
      await _firestore.collection('users').doc(userId).update({
        'role': 'guide_approved',
        'guideStatus': GuideStatus.approved.name,
        'isGuideApproved': true,
      });
    } else if (status == GuideStatus.rejected) {
      await _firestore.collection('users').doc(userId).update({
        'role': 'user',
        'guideStatus': GuideStatus.rejected.name,
        'isGuideApproved': false,
        'guideRejectionReason': adminComment ?? "Documents incomplete or unclear. Please reapply.",
      });
    }
  }
}
