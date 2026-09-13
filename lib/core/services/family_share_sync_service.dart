import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/encryption_util.dart';
import '../utils/secure_logger.dart';
import '../../data/models/family_share_link.dart';

/// Keeps each active family-share link's `encryptedStatus` blob (see
/// FamilyShareScreen) fresh as the linked tour_sessions doc changes.
///
/// Only the tourist's own device holds a family-share link's decryption
/// key (embedded in the URL fragment given to the recipient, persisted
/// locally in secure storage keyed by shareId) -- the key is never written
/// to Firestore, so nothing server-side (Laravel, Firestore rules, a DB
/// leak) can ever decrypt the status. Because the guide's device is what
/// actually mutates tour_sessions (phase changes, SOS toggles) but never
/// holds any family-share key, the *tourist's* device must be the one that
/// watches tour_sessions and re-encrypts/re-writes encryptedStatus on every
/// relevant change -- this service is that listener, running independent of
/// whether FamilyShareScreen is currently open.
class FamilyShareSyncService {
  static final FamilyShareSyncService instance = FamilyShareSyncService._();
  FamilyShareSyncService._();

  final _storage = const FlutterSecureStorage();
  final _firestore = FirebaseFirestore.instance;

  StreamSubscription<User?>? _authSub;
  StreamSubscription<QuerySnapshot>? _linksSub;
  final Map<String, StreamSubscription<DocumentSnapshot>> _sessionSubsByLink =
      {};

  bool _started = false;

  /// Call once at app startup. Follows auth state internally, so callers
  /// don't need to re-invoke this on sign-in/sign-out.
  void init() {
    if (_started) return;
    _started = true;
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      _stopWatchingAllLinks();
      if (user != null) {
        _watchTouristLinks(user.uid);
      }
    });
  }

  void _watchTouristLinks(String touristUid) {
    _linksSub = _firestore
        .collection('family_share_links')
        .where('touristId', isEqualTo: touristUid)
        .where('isActive', isEqualTo: true)
        .limit(50)
        .snapshots()
        .listen((snapshot) {
      final activeIds = <String>{};
      for (final doc in snapshot.docs) {
        try {
          final link = FamilyShareLink.fromJson(doc.data());
          activeIds.add(link.shareId);
          watchLink(link);
        } catch (e) {
          SecureLogger.error(
              "FamilyShareSyncService: malformed link doc ${doc.id}: $e");
        }
      }
      // Drop session listeners for links that are no longer active/owned.
      for (final shareId in _sessionSubsByLink.keys.toList()) {
        if (!activeIds.contains(shareId)) unwatchLink(shareId);
      }
    }, onError: (e, st) {
      SecureLogger.error("FamilyShareSyncService: links listener error", e, st);
    });
  }

  /// Starts (or restarts) watching [link]'s tour_sessions doc so
  /// encryptedStatus stays current. Safe to call repeatedly for the same
  /// link -- replaces any existing subscription.
  void watchLink(FamilyShareLink link) {
    if (link.sessionId.isEmpty) return;
    _sessionSubsByLink[link.shareId]?.cancel();
    _sessionSubsByLink[link.shareId] = _firestore
        .collection('tour_sessions')
        .doc(link.sessionId)
        .snapshots()
        .listen((sessionDoc) => _onSessionUpdate(link, sessionDoc),
            onError: (e, st) {
      SecureLogger.error(
          "FamilyShareSyncService: session listener error for ${link.shareId}",
          e,
          st);
    });
  }

  void unwatchLink(String shareId) {
    _sessionSubsByLink.remove(shareId)?.cancel();
  }

  void _stopWatchingAllLinks() {
    _linksSub?.cancel();
    _linksSub = null;
    for (final sub in _sessionSubsByLink.values) {
      sub.cancel();
    }
    _sessionSubsByLink.clear();
  }

  Future<void> _onSessionUpdate(
      FamilyShareLink link, DocumentSnapshot sessionDoc) async {
    if (!sessionDoc.exists) return;
    final session = sessionDoc.data() as Map<String, dynamic>? ?? {};

    final linkKey =
        await _storage.read(key: 'family_share_key_${link.shareId}');
    if (linkKey == null) {
      return; // Key not on this device -- nothing we can encrypt for the recipient.
    }

    final blob = await buildEncryptedStatus(
      sessionId: link.sessionId,
      permissions: link.permissions,
      linkKey: linkKey,
      sessionData: session,
    );
    if (blob == null) return;

    try {
      await _firestore
          .collection('family_share_links')
          .doc(link.shareId)
          .update({
        'encryptedStatus': blob,
        'lastSyncedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      SecureLogger.error(
          "FamilyShareSyncService: failed to write encryptedStatus for ${link.shareId}: $e");
    }
  }

  /// Builds the E2EE status blob for a link. If [sessionData] isn't
  /// supplied, reads tour_sessions/{sessionId} once. Only includes fields
  /// permitted by [permissions] (mirrors what show.blade.php used to gate
  /// server-side). Returns null if there's no session data to report yet.
  Future<String?> buildEncryptedStatus({
    required String sessionId,
    required Map<String, bool> permissions,
    required String linkKey,
    Map<String, dynamic>? sessionData,
  }) async {
    Map<String, dynamic>? session = sessionData;
    if (session == null && sessionId.isNotEmpty) {
      final doc =
          await _firestore.collection('tour_sessions').doc(sessionId).get();
      session = doc.data();
    }
    if (session == null) return null;

    final payload = <String, dynamic>{};

    if (permissions['show_status'] == true) {
      payload['phase'] = session['currentPhase'] ?? 'assembling';
    }
    if (permissions['show_emergency'] == true) {
      payload['sosActive'] = session['sosActive'] ?? false;
    }
    if (permissions['show_identity'] == true) {
      // The participant-readable session contains a safe display-name
      // snapshot. Reading another user's private users/{uid} document is
      // deliberately forbidden by firestore.rules.
      payload['guideName'] = session['guideName'] as String?;
    }
    if (permissions['show_meeting_point'] == true) {
      final meetingPointName = session['meetingPointName'] as String?;
      if (meetingPointName != null && meetingPointName.isNotEmpty) {
        payload['meetingPointName'] = meetingPointName;
      }
    }

    return EncryptionUtil.encryptWithKey(jsonEncode(payload), linkKey);
  }

  void dispose() {
    _authSub?.cancel();
    _authSub = null;
    _stopWatchingAllLinks();
    _started = false;
  }
}
