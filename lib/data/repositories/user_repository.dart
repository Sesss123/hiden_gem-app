import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';
import '../../core/utils/secure_logger.dart';

class UserRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Fetch all users for administrative review.
  /// In a production app, this would use pagination.
  Stream<List<UserProfile>> getAllUsers() {
    return _firestore
        .collection('users')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        // Ensure UID is present if not in doc data
        data['uid'] = doc.id;
        return UserProfile.fromJson(data);
      }).toList();
    });
  }

  /// Update a user's role (admin, guide, user)
  Future<void> updateUserRole(String uid, String role) async {
    try {
      await _firestore.collection('users').doc(uid).update({'role': role});
    } catch (e) {
      SecureLogger.error("Failed to update user role", e);
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
      SecureLogger.error("Failed to toggle premium status", e);
      rethrow;
    }
  }

  /// Ban a user (Soft Delete / Role restricted)
  Future<void> banUser(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'role': 'banned',
      });
    } catch (e) {
      SecureLogger.error("Failed to ban user", e);
      rethrow;
    }
  }
}
