import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/subscription_record.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/services.dart';
import '../../core/config/app_config.dart';

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
    final record = SubscriptionRecord.fromJson(snapshot.docs.first.data());
    // SAFETY NET CHECK: Immediately fall back to free-tier if local date is past expiresAt
    if (record.expiresAt.isBefore(DateTime.now())) {
      return null;
    }
    return record;
  }

  // Capabilities each paid plan unlocks. 'pro' capabilities are a subset of
  // 'elite' so an elite guide gets everything pro does, plus elite-only ones.
  static const Map<String, Set<String>> _planCapabilities = {
    'pro': {'featuredListings', 'prioritySos', 'advancedAnalytics', 'priorityLeads', 'verifiedInsured', 'customPackages'},
    'elite': {
      'featuredListings', 'prioritySos', 'advancedAnalytics', 'priorityLeads', 'verifiedInsured', 'customPackages',
      'teamManagement', 'operatorDashboard', 'whiteLabelBranding',
    },
  };

  /// Checks if an account's active plan includes a given capability key.
  /// Free tier / no active subscription never has any entitlement.
  Future<bool> hasEntitlement(String accountId, String key) async {
    final sub = await getActiveSubscription(accountId);
    if (sub == null) return false;
    return _planCapabilities[sub.planId]?.contains(key) ?? false;
  }

  /// Returns the limit for a specific metric (e.g., maxTeamSize) based on plan.
  Future<int> getLimit(String accountId, String key) async {
    final sub = await getActiveSubscription(accountId);
    final planId = sub?.planId ?? 'free';
    
    return _getPlanLimit(planId, key);
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

  bool get _revenueCatUnconfigured {
    final key = AppConfig.revenueCatApiKeyAndroid;
    return key.isEmpty || key == 'goog_example_key' || key == 'appl_example_key' || key.contains('example_key') || key == 'dev-key-local';
  }

  /// Initiates a real payment via RevenueCat.
  Future<void> purchasePlan(String planId, String accountId, String accountType) async {
    // Dev-mode bypass: RevenueCat's SDK is never configured when only dummy
    // API keys are present (see premium_service.dart's identical check), so
    // any real Purchases.* call throws "no singleton instance" before it can
    // even try. Rather than leaving the Fleet Plan screen entirely untestable
    // through its own UI, skip straight to writing the subscription record —
    // gated by kDebugMode so this can never fire against a real deployment.
    if (kDebugMode && _revenueCatUnconfigured) {
      final record = SubscriptionRecord(
        subscriptionId: const Uuid().v4(),
        accountId: accountId,
        accountType: accountType,
        planId: planId,
        status: 'active',
        startedAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 30)),
        entitlements: {},
      );
      await startSubscription(record);
      return;
    }

    // Map internal plan IDs to RevenueCat product identifiers
    final revenueCatProductId = planId == 'pro' ? 'guide_pro_monthly' : 'guide_elite_monthly';

    try {
      // 1. Fetch available products from RevenueCat
      final offerings = await Purchases.getOfferings();
      if (offerings.current == null || offerings.current!.availablePackages.isEmpty) {
        throw Exception("No products available or configured in RevenueCat.");
      }

      // 2. Find the specific package to purchase
      Package? packageToBuy;
      for (var package in offerings.current!.availablePackages) {
        if (package.storeProduct.identifier == revenueCatProductId) {
          packageToBuy = package;
          break;
        }
      }

      if (packageToBuy == null) {
        throw Exception("Product $revenueCatProductId not found in current offering.");
      }

      // 3. Initiate the native purchase flow
      final purchaseResult = await Purchases.purchase(PurchaseParams.package(packageToBuy));

      // 4. If successful, sync the active subscription with our Firestore database
      if (purchaseResult.customerInfo.entitlements.all.isNotEmpty) {
        final record = SubscriptionRecord(
          subscriptionId: const Uuid().v4(),
          accountId: accountId,
          accountType: accountType,
          planId: planId,
          status: 'active',
          startedAt: DateTime.now(),
          expiresAt: DateTime.now().add(const Duration(days: 30)), // Basic estimation, real expiry is in RevenueCat
          entitlements: {},
        );
        await startSubscription(record);
      } else {
         throw Exception("Purchase completed but no entitlements were unlocked.");
      }
    } on PlatformException catch (e) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      if (errorCode == PurchasesErrorCode.purchaseCancelledError) {
        throw Exception("Purchase was cancelled.");
      } else {
        throw Exception("Failed to process payment: $e");
      }
    }
  }

  /// Records a purchase attempt. Note: this does NOT grant premium — 'isPremium'
  /// and related privileged fields on the user's account can only be set by the
  /// RevenueCat webhook (Laravel backend), since firestore.rules blocks clients
  /// from writing those fields to their own account document. This record exists
  /// so the UI has something to show immediately; the webhook is the source of truth.
  Future<void> startSubscription(SubscriptionRecord record) async {
    await _subscriptionRef.doc(record.subscriptionId).set(record.toJson());
  }

  /// Retrieves billing history for an account. One-shot read (not a live
  /// listener) — a billing history screen is a historical record the user
  /// checks occasionally, not something that needs sub-second live updates
  /// while open.
  Future<List<SubscriptionRecord>> getBillingHistory(String accountId) async {
    final snapshot = await _subscriptionRef
        .where('accountId', isEqualTo: accountId)
        .orderBy('startedAt', descending: true)
        .get();
    return snapshot.docs.map((doc) => SubscriptionRecord.fromJson(doc.data())).toList();
  }

  /// Cancels an active subscription.
  Future<void> cancelSubscription(String subscriptionId) async {
    final docSnap = await _subscriptionRef.doc(subscriptionId).get();
    await _subscriptionRef.doc(subscriptionId).update({
      'status': 'cancelled',
      'autoRenew': false,
      'cancelledAt': DateTime.now().toIso8601String(),
    });
    
    if (docSnap.exists && docSnap.data() != null) {
      final data = docSnap.data()!;
      final accountId = data['accountId'] as String?;
      final accountType = data['accountType'] as String?;
      if (accountId != null && accountType != null) {
        final collection = accountType == 'guide' ? 'users' : 'operator_accounts';
        await _firestore.collection(collection).doc(accountId).update({
          'autoRenew': false,
        });
      }
    }
  }
}
