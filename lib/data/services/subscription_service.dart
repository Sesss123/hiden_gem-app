import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/subscription_record.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:flutter/services.dart';
import '../../core/config/app_config.dart';
import 'package:firebase_auth/firebase_auth.dart';

final subscriptionServiceProvider = Provider((ref) => SubscriptionService());

class SubscriptionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _subscriptionRef =>
      _firestore.collection('subscriptions');

  /// Fetches the active subscription for an account.
  Future<SubscriptionRecord?> getActiveSubscription(String accountId) async {
    final snapshot = await _subscriptionRef
        .where('accountId', isEqualTo: accountId)
        .where('status', whereIn: ['active', 'grace_period'])
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    final document = snapshot.docs.first;
    final data = document.data();
    data.putIfAbsent('subscriptionId', () => document.id);
    final record = SubscriptionRecord.fromJson(data);
    // SAFETY NET CHECK: Immediately fall back to free-tier if local date is past expiresAt
    if (record.expiresAt.isBefore(DateTime.now())) {
      return null;
    }
    return record;
  }

  // Capabilities each paid plan unlocks. 'pro' capabilities are a subset of
  // 'elite' so an elite guide gets everything pro does, plus elite-only ones.
  static const Map<String, Set<String>> _planCapabilities = {
    'pro': {
      'featuredListings',
      'prioritySos',
      'advancedAnalytics',
      'priorityLeads',
      'verifiedInsured',
      'customPackages'
    },
    'elite': {
      'featuredListings',
      'prioritySos',
      'advancedAnalytics',
      'priorityLeads',
      'verifiedInsured',
      'customPackages',
      'teamManagement',
      'operatorDashboard',
      'whiteLabelBranding',
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
      'free': {'maxTeamSize': 1, 'maxPackages': 0, 'monthlyBookingQuota': 5},
      'pro': {'maxTeamSize': 5, 'maxPackages': 10, 'monthlyBookingQuota': 50},
      'elite': {
        'maxTeamSize': 20,
        'maxPackages': 50,
        'monthlyBookingQuota': 500
      },
      'starter': {
        'maxTeamSize': 3,
        'maxPackages': 10,
        'monthlyBookingQuota': 30
      },
      'growth': {
        'maxTeamSize': 15,
        'maxPackages': 50,
        'monthlyBookingQuota': 200
      },
      'enterprise': {
        'maxTeamSize': 100,
        'maxPackages': 1000,
        'monthlyBookingQuota': 9999
      },
    };

    return limits[planId]?[key] ?? 0;
  }

  bool get _revenueCatUnconfigured {
    final key = AppConfig.revenueCatApiKeyAndroid;
    return key.isEmpty ||
        key == 'goog_example_key' ||
        key == 'appl_example_key' ||
        key.contains('example_key') ||
        key == 'dev-key-local';
  }

  /// Initiates a real payment via RevenueCat.
  Future<SubscriptionRecord> purchasePlan(
      String planId, String accountId, String accountType) async {
    // Dev-mode bypass: RevenueCat's SDK is never configured when only dummy
    // API keys are present (see premium_service.dart's identical check), so
    // any real Purchases.* call throws "no singleton instance" before it can
    // even try. This project has a single firebase_options.dart (no separate
    // test/dev Firebase project), so a direct client write here would hit
    // the same tripme-89742 project as production and is correctly blocked
    // by firestore.rules (subscriptions/{subId} is Admin-SDK-only — see the
    // rules comment). So this now intentionally does NOT write a Firestore
    // record; it only lets the Fleet Plan screen's UI flow run to completion
    // in a debug build without a "no singleton instance" crash. To actually
    // test a paid plan locally, grant it server-side (Firebase console /
    // Admin SDK script) rather than through this client path.
    if (kDebugMode && _revenueCatUnconfigured) {
      throw StateError(
          'RevenueCat is not configured. Add a real Android public SDK key before testing subscriptions.');
    }

    // Map internal plan IDs to RevenueCat product identifiers
    final revenueCatProductId =
        planId == 'pro' ? 'guide_pro_monthly' : 'guide_elite_monthly';

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.uid != accountId) {
        throw StateError(
            'The billing account does not match the signed-in user.');
      }
      if (await Purchases.appUserID != accountId) {
        await Purchases.logIn(accountId);
      }
      // 1. Fetch available products from RevenueCat
      final offerings = await Purchases.getOfferings();
      if (offerings.current == null ||
          offerings.current!.availablePackages.isEmpty) {
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
        throw Exception(
            "Product $revenueCatProductId not found in current offering.");
      }

      // 3. Initiate the native purchase flow
      final purchaseResult =
          await Purchases.purchase(PurchaseParams.package(packageToBuy));

      // 4. If successful, sync the active subscription with our Firestore database
      final purchasedProductIsActive = purchaseResult
          .customerInfo.entitlements.active.values
          .any((entitlement) =>
              entitlement.productIdentifier == revenueCatProductId);
      if (!purchasedProductIsActive) {
        throw Exception(
            "Purchase completed but the selected plan entitlement is not active.");
      }

      for (var attempt = 0; attempt < 6; attempt++) {
        final subscription = await getActiveSubscription(accountId);
        if (subscription?.planId == planId) return subscription!;
        if (attempt < 5) await Future.delayed(const Duration(seconds: 2));
      }
      throw StateError(
          'Purchase was received, but account activation is still syncing. Use Restore Purchases in a moment.');
    } on PlatformException catch (e) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      if (errorCode == PurchasesErrorCode.purchaseCancelledError) {
        throw Exception("Purchase was cancelled.");
      } else {
        throw Exception("Failed to process payment: $e");
      }
    }
  }

  /// Restores store purchases only after binding RevenueCat to the current
  /// Firebase UID, then waits for the server webhook projection. This keeps a
  /// purchase restored under one Google account from silently unlocking a
  /// different in-app account.
  Future<SubscriptionRecord> restorePurchases(String accountId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.uid != accountId) {
      throw StateError(
          'The billing account does not match the signed-in user.');
    }
    if (await Purchases.appUserID != accountId) {
      await Purchases.logIn(accountId);
    }
    await Purchases.restorePurchases();
    for (var attempt = 0; attempt < 4; attempt++) {
      final subscription = await getActiveSubscription(accountId);
      if (subscription != null) return subscription;
      if (attempt < 3) await Future.delayed(const Duration(seconds: 2));
    }
    throw StateError('No server-verified active subscription was found.');
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
    return snapshot.docs
        .map((doc) => SubscriptionRecord.fromJson(doc.data()))
        .toList();
  }
}
