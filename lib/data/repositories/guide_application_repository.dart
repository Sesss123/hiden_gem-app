import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/guide_application.dart';
import '../models/guide_status.dart';

class GuideApplicationRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> submitApplication(GuideApplication application) async {
    await _firestore.collection('guide_applications').doc(application.userId).set(application.toJson());
  }

  Future<GuideApplication?> getMyApplication() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _firestore.collection('guide_applications').doc(user.uid).get();
    if (doc.exists) {
      return GuideApplication.fromJson(doc.data()!);
    }
    return null;
  }

  Stream<List<GuideApplication>> getPendingApplications() {
    return _firestore
        .collection('guide_applications')
        .where('status', isEqualTo: GuideStatus.pending.name)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => GuideApplication.fromJson(doc.data())).toList());
  }

  Future<void> reviewApplication({
    required String userId,
    required GuideStatus status,
    String? adminComment,
  }) async {
    await _firestore.collection('guide_applications').doc(userId).update({
      'status': status.name,
      'adminComment': adminComment,
      'reviewedAt': DateTime.now().toIso8601String(),
    });

    // If approved, update user role
    if (status == GuideStatus.approved) {
      await _firestore.collection('users').doc(userId).update({
        'role': 'guide_approved',
        'guideStatus': GuideStatus.approved.name,
        'isGuideApproved': true, // Legacy support
      });
    }
  }
}
