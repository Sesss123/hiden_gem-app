import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final userSafetyRepositoryProvider = Provider<UserSafetyRepository>(
  (ref) => UserSafetyRepository(),
);

class UserSafetyRepository {
  UserSafetyRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _reports =>
      _firestore.collection('abuse_reports');

  CollectionReference<Map<String, dynamic>> get _blocks =>
      _firestore.collection('user_blocks');

  CollectionReference<Map<String, dynamic>> get _aiOutputReports =>
      _firestore.collection('ai_output_reports');

  String _requireUserId() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw StateError('You must be signed in to use safety controls.');
    }
    return userId;
  }

  static String blockDocumentId(String blockerId, String blockedUserId) =>
      '${blockerId}_$blockedUserId';

  Future<void> report({
    required String targetType,
    required String targetId,
    required String reportedUserId,
    required String reason,
    String details = '',
  }) async {
    final reporterId = _requireUserId();
    if (targetId.trim().isEmpty || reportedUserId.trim().isEmpty) {
      throw ArgumentError('A report must identify its content and user.');
    }
    if (reporterId == reportedUserId && targetType == 'user') {
      throw StateError('You cannot report your own account.');
    }

    await _reports.add({
      'reportedBy': reporterId,
      'reportedUserId': reportedUserId,
      'targetType': targetType,
      'targetId': targetId,
      'reason': reason,
      'details': details.trim(),
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> blockUser(String blockedUserId) async {
    final blockerId = _requireUserId();
    if (blockedUserId.isEmpty || blockerId == blockedUserId) {
      throw StateError('You cannot block this account.');
    }

    await _blocks.doc(blockDocumentId(blockerId, blockedUserId)).set({
      'blockerId': blockerId,
      'blockedUserId': blockedUserId,
      'status': 'active',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> reportAiOutput({
    required String feature,
    required String outputId,
    required String reason,
    required String outputPreview,
    String details = '',
  }) async {
    final reporterId = _requireUserId();
    if (feature.trim().isEmpty || outputId.trim().isEmpty) {
      throw ArgumentError('An AI report must identify its feature and output.');
    }

    final normalizedPreview = outputPreview.trim();
    await _aiOutputReports.add({
      'reportedBy': reporterId,
      'feature': feature.trim(),
      'outputId': outputId.trim(),
      'reason': reason,
      'details': details.trim(),
      'outputPreview': normalizedPreview.length > 1000
          ? normalizedPreview.substring(0, 1000)
          : normalizedPreview,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> unblockUser(String blockedUserId) async {
    final blockerId = _requireUserId();
    await _blocks.doc(blockDocumentId(blockerId, blockedUserId)).delete();
  }

  Future<bool> isUserBlocked(String blockedUserId) async {
    final blockerId = _auth.currentUser?.uid;
    if (blockerId == null || blockedUserId.isEmpty) return false;
    final snapshot =
        await _blocks.doc(blockDocumentId(blockerId, blockedUserId)).get();
    return snapshot.data()?['status'] == 'active';
  }

  Future<Set<String>> getBlockedUserIds() async {
    final blockerId = _auth.currentUser?.uid;
    if (blockerId == null) return const <String>{};

    final snapshot = await _blocks
        .where('blockerId', isEqualTo: blockerId)
        .where('status', isEqualTo: 'active')
        .limit(500)
        .get();
    return snapshot.docs
        .map((doc) => doc.data()['blockedUserId'])
        .whereType<String>()
        .toSet();
  }
}
