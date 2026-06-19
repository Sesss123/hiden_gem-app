import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/subscription_record.dart';

final subscriptionServiceProvider = Provider((ref) => SubscriptionService());

class SubscriptionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _subscriptionRef => 
      _firestore.collection('subscriptions');

  /// Fetches the active subscription for an account.
  Future<SubscriptionRecord?> getActiveSubscription(String accountId) async {
    final snapshot = await _subscriptionRef
        .where('accountId', isEqualTo: accountId)
        .where('status', isEqualTo: 'active')
        .limit(1)
        .get();
    
    if (snapshot.docs.isEmpty) return null;
    return SubscriptionRecord.fromJson(snapshot.docs.first.data());
  }

  /// Checks if an account has a specific entitlement or remains within limits.
  Future<bool> hasEntitlement(String accountId, String key) async {
    final sub = await getActiveSubscription(accountId);
    if (sub == null) return _getDefaultEntitlement(key);
    
    final entitlement = sub.entitlements[key];
    if (entitlement is bool) return entitlement;
    if (entitlement is num) return entitlement > 0;
    
    return _getDefaultEntitlement(key);
  }

  /// Returns the limit for a specific metric (e.g., maxTeamSize) based on plan.
  Future<int> getLimit(String accountId, String key) async {
    final sub = await getActiveSubscription(accountId);
    final planId = sub?.planId ?? 'free';
    
    return _getPlanLimit(planId, key);
  }

  bool _getDefaultEntitlement(String key) {
    // Default values for Free/No subscription
    final defaults = {
      'featuredAllowed': false,
      'analyticsAccess': false,
      'teamManagement': false,
    };
    return defaults[key] ?? false;
  }

  int _getPlanLimit(String planId, String key) {
    final limits = {
      'free': {'maxTeamSize': 1, 'maxPackages': 3, 'monthlyBookingQuota': 5},
      'pro': {'maxTeamSize': 5, 'maxPackages': 10, 'monthlyBookingQuota': 50},
      'elite': {'maxTeamSize': 20, 'maxPackages': 50, 'monthlyBookingQuota': 500},
      'starter': {'maxTeamSize': 3, 'maxPackages': 10, 'monthlyBookingQuota': 30},
      'growth': {'maxTeamSize': 15, 'maxPackages': 50, 'monthlyBookingQuota': 200},
      'enterprise': {'maxTeamSize': 100, 'maxPackages': 1000, 'monthlyBookingQuota': 9999},
    };
    
    return limits[planId]?[key] ?? 0;
  }

  /// Upgrades or starts a new subscription.
  Future<void> startSubscription(SubscriptionRecord record) async {
    await _subscriptionRef.doc(record.subscriptionId).set(record.toJson());
    
    // Update the account's subscription info for quick access
    final collection = record.accountType == 'guide' ? 'users' : 'operator_accounts';
    await _firestore.collection(collection).doc(record.accountId).update({
      'subscriptionPlan': record.planId,
      'subExpiresAt': record.expiresAt.toIso8601String(),
    });
  }

  /// Retrieves billing history for an account.
  Stream<List<SubscriptionRecord>> getBillingHistory(String accountId) {
    return _subscriptionRef
        .where('accountId', isEqualTo: accountId)
        .orderBy('startedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => SubscriptionRecord.fromJson(doc.data())).toList());
  }

  /// Cancels an active subscription.
  Future<void> cancelSubscription(String subscriptionId) async {
    await _subscriptionRef.doc(subscriptionId).update({
      'status': 'cancelled',
      'cancelledAt': DateTime.now().toIso8601String(),
    });
  }
}
