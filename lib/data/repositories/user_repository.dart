import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/utils/secure_logger.dart';
import '../models/guide_status.dart';

class UserRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Update a user's role (admin, guide, user)
  Future<void> updateUserRole(String uid, String role) async {
    try {
      await _firestore.collection('users').doc(uid).update({'role': role});
    } catch (e) {
      SecureLogger.error("Failed to update user role: $e");
      rethrow;
    }
  }

  /// Toggle premium status for a user
  Future<void> togglePremium(String uid, bool isPremium) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'isPremium': isPremium,
        'premiumPlan': isPremium ? 'admin_granted' : null,
      });
    } catch (e) {
      SecureLogger.error("Failed to toggle premium status: $e");
      rethrow;
    }
  }

  /// Ban a user (Soft Delete / Role restricted)
  Future<void> banUser(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'role': 'banned',
        'guideStatus': GuideStatus.suspended.name,
      });
    } catch (e) {
      SecureLogger.error("Failed to ban user: $e");
      rethrow;
    }
  }
}
