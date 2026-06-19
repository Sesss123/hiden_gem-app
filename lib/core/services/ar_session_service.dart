import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/models/ar_session.dart';

class ARSessionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static final ARSessionService _instance = ARSessionService._internal();
  factory ARSessionService() => _instance;
  ARSessionService._internal();

  /// Collection reference for sessions
  CollectionReference get _sessions => _firestore.collection('ar_sessions');

  /// Create a new shared AR session
  Future<ARSession?> createSession({
    required String modelId,
    required String cloudAnchorId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final joinCode = _generateJoinCode();
    final session = ARSession(
      id: joinCode,
      hostUid: user.uid,
      cloudAnchorId: cloudAnchorId,
      modelId: modelId,
      createdAt: DateTime.now(),
      participantUids: [user.uid],
    );

    await _sessions.doc(joinCode).set(session.toMap());
    return session;
  }

  /// Join an existing AR session
  Future<ARSession?> joinSession(String joinCode) async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _sessions.doc(joinCode).get();
    if (!doc.exists) return null;

    final session = ARSession.fromFirestore(doc.id, doc.data() as Map<String, dynamic>);
    
    // Add user to participants if not already there
    if (!session.participantUids.contains(user.uid)) {
      await _sessions.doc(joinCode).update({
        'participantUids': FieldValue.arrayUnion([user.uid])
      });
    }

    return session;
  }

  /// Update the visual state (e.g., Historical View) for all participants
  Future<void> updateSessionState(String joinCode, {required bool isHistorical}) async {
    await _sessions.doc(joinCode).update({
      'isHistorical': isHistorical,
    });
  }

  /// Listen for real-time updates to the session
  Stream<ARSession?> listenToSession(String joinCode) {
    return _sessions.doc(joinCode).snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) return null;
      return ARSession.fromFirestore(snapshot.id, snapshot.data() as Map<String, dynamic>);
    });
  }

  /// End a session (only by host)
  Future<void> endSession(String joinCode) async {
    await _sessions.doc(joinCode).delete();
  }

  /// Generate a unique 6-digit join code
  String _generateJoinCode() {
    final random = Random();
    String code = "";
    for (int i = 0; i < 6; i++) {
      code += random.nextInt(10).toString();
    }
    return code;
  }
}
