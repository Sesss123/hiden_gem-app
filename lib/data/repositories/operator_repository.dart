import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
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

  /// Lazily creates an operator account for an Elite-tier guide the first
  /// time they open the operator dashboard. Seeded with sensible defaults
  /// for the model's required fields — editable afterwards via the
  /// dashboard's Branding tab (updateBranding) or future settings UI.
  Future<OperatorAccount> createOperatorAccount({
    required String ownerId,
    required String displayName,
    required String supportEmail,
  }) async {
    final account = OperatorAccount(
      operatorId: const Uuid().v4(),
      companyName: displayName,
      ownerUserId: ownerId,
      teamGuideIds: [ownerId],
      teamRoles: {ownerId: 'owner'},
      brNumber: '',
      supportEmail: supportEmail,
      subscriptionPlan: 'Enterprise',
    );
    await _operatorRef.doc(account.operatorId).set(account.toJson());
    return account;
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

  /// Updates an operator's company branding info.
  Future<void> updateBranding(String operatorId, Map<String, String> branding) async {
    await _operatorRef.doc(operatorId).update({
      'brandingAssets': branding,
    });
  }

  /// Updates an operator's logo URL.
  Future<void> updateLogoUrl(String operatorId, String logoUrl) async {
    await _operatorRef.doc(operatorId).update({
      'logoUrl': logoUrl,
    });
  }
}
