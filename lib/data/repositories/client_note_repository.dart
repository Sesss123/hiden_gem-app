import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/guide_client_note.dart';

final clientNoteRepositoryProvider = Provider((ref) => ClientNoteRepository());

/// One note document per (guide, client) pair — a guide keeps a single
/// running note per client, not a growing list, so the doc ID itself
/// encodes the pair and avoids needing a query for lookup/upsert.
class ClientNoteRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _noteRef =>
      _firestore.collection('guide_client_notes');

  String _docId(String guideId, String touristId) => '${guideId}_$touristId';

  Future<GuideClientNote?> getNote(String guideId, String touristId) async {
    final doc = await _noteRef.doc(_docId(guideId, touristId)).get();
    if (!doc.exists) return null;
    return GuideClientNote.fromJson(doc.data()!);
  }

  Future<void> upsertNote({
    required String guideId,
    required String touristId,
    required String note,
  }) async {
    final now = DateTime.now();
    final existing = await getNote(guideId, touristId);
    final record = GuideClientNote(
      noteId: _docId(guideId, touristId),
      guideId: guideId,
      touristId: touristId,
      note: note,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );
    await _noteRef.doc(record.noteId).set(record.toJson());
  }
}
