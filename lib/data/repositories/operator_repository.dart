import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/operator_account.dart';

final operatorRepositoryProvider = Provider((ref) => OperatorRepository());

class OperatorRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _operatorRef => 
      _firestore.collection('operator_accounts');

  /// Fetches an operator account for an owner user.
  Future<OperatorAccount?> getOperatorByOwner(String ownerId) async {
    final snapshot = await _operatorRef
        .where('ownerUserId', isEqualTo: ownerId)
        .limit(1)
        .get();
    
    if (snapshot.docs.isEmpty) return null;
    return OperatorAccount.fromJson(snapshot.docs.first.data());
  }

  /// Invites a guide to join an operator's team.
  Future<void> inviteGuideToTeam(String operatorId, String guideId) async {
    await _operatorRef.doc(operatorId).update({
      'teamGuideIds': FieldValue.arrayUnion([guideId]),
    });
  }

  /// Removes a guide from an operator's team.
  Future<void> removeGuideFromTeam(String operatorId, String guideId) async {
    await _operatorRef.doc(operatorId).update({
      'teamGuideIds': FieldValue.arrayRemove([guideId]),
    });
  }

  /// Assigns a vehicle to an operator account.
  Future<void> assignVehicle(String operatorId, String vehicleId) async {
    await _operatorRef.doc(operatorId).update({
      'vehicleIds': FieldValue.arrayUnion([vehicleId]),
    });
  }

  /// Stream of an operator's team profile.
  Stream<OperatorAccount?> streamOperator(String operatorId) {
    return _operatorRef.doc(operatorId).snapshots().map((doc) =>
        doc.exists ? OperatorAccount.fromJson(doc.data()!) : null);
  }

  /// Updates an operator's company branding info.
  Future<void> updateBranding(String operatorId, Map<String, String> branding) async {
    await _operatorRef.doc(operatorId).update({
      'brandingAssets': branding,
    });
  }
}
