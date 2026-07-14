import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'user_preference_service.dart';
import '../../core/config/app_config.dart';
import 'package:hidden_gems_sl/core/utils/secure_logger.dart';
import '../../core/services/secure_entitlements.dart';
import '../../core/services/premium_unlock_service.dart';
import '../../core/services/integrity_shield.dart';
import '../../core/services/usage_limiter_service.dart';

part 'premium_service.g.dart';

@riverpod
class PremiumNotifier extends _$PremiumNotifier {
  static const String entitlementId = 'premium_access';
  static const String premiumId = 'hgems_premium_monthly';
  static const String explorerId = 'hgems_explorer_monthly';
  // Annual Heritage Premium — same entitlement, cheaper effective monthly
  // rate (Rs. 9,999/yr ≈ Rs. 833/mo vs Rs. 999/mo billed monthly) to convert
  // more of the trial/monthly cohort into upfront annual cash + lower churn.
  // Configure this product ID (with the same 'premium_access' entitlement
  // attached) in the RevenueCat dashboard — offer a free trial there via the
  // store's introductory-offer mechanism (App Store Connect / Play Console),
  // not in app code.
  static const String premiumAnnualId = 'hgems_premium_annual';

  bool get _isFirebaseReady => Firebase.apps.isNotEmpty;

  @override
  bool build() {
    // 🎧 Listen to RevenueCat customer info changes (BUG-F005 & BUG-F006 fix)
    // This is RevenueCat's own push mechanism — free, real-time, and the
    // correct source of truth for purchase-driven changes. No Firestore
    // listener is needed for this path.
    void listener(CustomerInfo customerInfo) {
      _updateStateFromCustomerInfo(customerInfo);
    }
    Purchases.addCustomerInfoUpdateListener(listener);

    ref.onDispose(() {
      Purchases.removeCustomerInfoUpdateListener(listener);
    });

    _initRevenueCat();
    _checkServerOverride();

    return false; // Default initial state
  }

  Future<void> _initRevenueCat() async {
    try {
      if (kIsWeb) return;

      await Purchases.setLogLevel(LogLevel.debug);

      String apiKey = defaultTargetPlatform == TargetPlatform.iOS
          ? AppConfig.revenueCatApiKeyIos
          : AppConfig.revenueCatApiKeyAndroid;

      if (apiKey.isEmpty || apiKey == 'goog_example_key' || apiKey == 'appl_example_key' || apiKey.contains('example_key') || apiKey == 'dev-key-local') {
        SecureLogger.info("Skipping RevenueCat initialization: Dummy/example API key detected in dev mode.", tag: "RevenueCat");
        return;
      }

      await Purchases.configure(PurchasesConfiguration(apiKey));

      // Identify user if logged in
      if (_isFirebaseReady) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await Purchases.logIn(user.uid);
        }
      }

      final customerInfo = await Purchases.getCustomerInfo();
      _updateStateFromCustomerInfo(customerInfo);
    } catch (e) {
      final errStr = e.toString();
      if (errStr.contains('InvalidCredentialsError') || errStr.contains('Invalid API Key') || errStr.contains('credentials issue')) {
        SecureLogger.warning(
          "RevenueCat API Key is invalid or not configured properly. "
          "Please check your RevenueCat Dashboard for the correct public Android/iOS API Key and set REVENUECAT_API_KEY_ANDROID / REVENUECAT_API_KEY_IOS. "
          "Falling back to local/free tier.",
          tag: "RevenueCat",
          isBackground: true,
        );
      } else {
        SecureLogger.warning("RevenueCat Init error: $e", tag: "RevenueCat", isBackground: true);
      }
    }
  }

  static const String _lastCheckPrefsKey = 'premium_last_server_check_at';

  /// Risk-tiered re-check window: trusted devices (low IntegrityShield risk
  /// score — the vast majority of users) don't need a fresh Firestore read
  /// on every app open, since server-side overrides (admin revocation,
  /// webhook-driven changes) are rare. Devices showing tamper/fraud signals
  /// get checked far more often, since that population is exactly where
  /// entitlement abuse is most likely to be attempted.
  Duration _checkWindowForRiskScore(int riskScore) {
    if (riskScore >= 60) return Duration.zero; // High/Critical: always re-check
    if (riskScore >= 30) return const Duration(minutes: 15); // Medium
    return const Duration(hours: 6); // Low risk (default/typical user)
  }

  /// One-shot check (NOT a live listener) for server-side overrides — e.g. an
  /// admin manually revoking premium, or a RevenueCat webhook event that
  /// landed while the app was closed. RevenueCat's own CustomerInfo listener
  /// (registered in build()) already handles all purchase-driven changes in
  /// real time at no Firestore cost, so this only needs to run once per app
  /// session (not stay open) to catch the rarer out-of-band case — and even
  /// then, only after the risk-tiered window above has elapsed.
  Future<void> _checkServerOverride() async {
    if (!_isFirebaseReady) {
      _checkPremiumStatus();
      return;
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final lastCheckMs = prefs.getInt(_lastCheckPrefsKey);
      final riskScore = IntegrityShield().riskScore;
      final window = _checkWindowForRiskScore(riskScore);

      if (lastCheckMs != null && window > Duration.zero) {
        final elapsed = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(lastCheckMs));
        if (elapsed < window) {
          _checkPremiumStatus();
          return;
        }
      }

      await prefs.setInt(_lastCheckPrefsKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      SecureLogger.warning("Premium check-window lookup failed, checking anyway: $e", tag: "RevenueCat", isBackground: true);
    }

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final isPrem = data['isPremium'] == true;
        final expiry = data['premiumExpiresAt'] ?? data['subExpiresAt'];
        DateTime? expiryDate;
        if (expiry != null) {
          expiryDate = expiry is Timestamp ? expiry.toDate() : DateTime.tryParse(expiry.toString());
        }

        if (!isPrem || (expiryDate != null && expiryDate.isBefore(DateTime.now()))) {
          if (state == true) {
            state = false;
            SecureEntitlements().forceRefresh();
            PremiumUnlockService.invalidateAllUnlocks();
            UsageLimiterService.invalidatePlanLimitsCache();
            await UserPreferenceService.updatePremiumStatus(false, source: 'expired');
            SecureLogger.info("Premium status revoked or expired via server sync.", tag: "RevenueCat");
          }
        } else if (isPrem && state == false) {
          state = true;
          SecureEntitlements().forceRefresh();
          UsageLimiterService.invalidatePlanLimitsCache();
          await UserPreferenceService.updatePremiumStatus(
            true,
            plan: data['premiumPlanId'] ?? data['premiumPlan'] ?? data['subscriptionPlan'],
            source: 'firestore'
          );
        }
      }
    } catch (e) {
      SecureLogger.warning("Server override check failed: $e", tag: "RevenueCat", isBackground: true);
    }

    _checkPremiumStatus();
  }

  Future<void> _checkPremiumStatus() async {
    if (kIsWeb) return;
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      _updateStateFromCustomerInfo(customerInfo);
    } catch (e) {
      SecureLogger.warning("Status Check failed: $e", tag: "RevenueCat", isBackground: true);
    }
  }

  Future<void> _updateStateFromCustomerInfo(CustomerInfo customerInfo) async {
    try {
      final bool isPremium = customerInfo.entitlements.active.containsKey(entitlementId);
    
    if (state != isPremium) {
      state = isPremium;
      // A mid-session plan change (e.g. a purchase completing) must not
      // keep serving usage limits cached under the old plan for up to
      // the 1-hour cache window in UsageLimiterService.
      UsageLimiterService.invalidatePlanLimitsCache();

      final activeEntitlement = customerInfo.entitlements.active[entitlementId];
      
      // Sync locally for offline access
      await UserPreferenceService.updatePremiumStatus(
        isPremium,
        plan: activeEntitlement?.productIdentifier,
        expiry: activeEntitlement?.expirationDate != null
            ? DateTime.tryParse(activeEntitlement!.expirationDate!)
            : null,
        source: 'revenuecat',
      );

      // NOTE: users/{uid}.isPremium is a backend-owned field — firestore.rules
      // blocks the client from writing it on its own document (anti-fraud).
      // The real sync path is the RevenueCat webhook -> Laravel ->
      // FirestoreService.updateUserSubscription(), which fires server-side
      // the moment RevenueCat confirms the purchase. No client write needed
      // or possible here.
    }
    } catch (e, st) {
      SecureLogger.error("Failed to sync premium state", e, st, "RevenueCat");
    }
  }

  Future<void> buyPremium({String? productId}) async {
    try {
      Offerings offerings = await Purchases.getOfferings();
      if (offerings.current != null && offerings.current!.availablePackages.isNotEmpty) {
        // Purchase the first available package (usually monthly/yearly)
        Package package = offerings.current!.availablePackages.first;
        if (productId != null) {
          package = offerings.current!.availablePackages.firstWhere(
            (p) => p.storeProduct.identifier == productId,
            orElse: () => offerings.current!.availablePackages.first,
          );
        }
        
        PurchaseResult purchaseResult = await Purchases.purchase(PurchaseParams.package(package));
        _updateStateFromCustomerInfo(purchaseResult.customerInfo);
      }
    } on PlatformException catch (e) {
      var errorCode = PurchasesErrorHelper.getErrorCode(e);
      if (errorCode != PurchasesErrorCode.purchaseCancelledError) {
        SecureLogger.error("Purchase Error", e, null, "RevenueCat");
      }
    }
  }

  Future<void> restorePurchases() async {
    try {
      CustomerInfo customerInfo = await Purchases.restorePurchases();
      _updateStateFromCustomerInfo(customerInfo);
    } catch (e) {
      SecureLogger.error("Restore failed", e, null, "RevenueCat");
    }
  }

  // Legacy sync methods maintained for compatibility or specific server checks
  Future<void> checkPremiumStatusOnLaunch() async {
    await _checkPremiumStatus();
  }

  // 🛠️ MOCK UTILITY: Only for Dev/Internal testing to bypass RevenueCat
  Future<void> simulateMockPurchase() async {
    state = true;
    await UserPreferenceService.updatePremiumStatus(
      true,
      plan: 'premium_mock_dev',
      source: 'mock_internal'
    );
    // NOTE: no Firestore write here — users/{uid}.isPremium is blocked for
    // client writes by firestore.rules (see _updateStateFromCustomerInfo).
    // The mock only needs to flip local/in-memory state for dev testing.
  }

  // 🛠️ MOCK UTILITY: Only for Dev/Internal testing — undoes
  // simulateMockPurchase() so the pricing tiers (and the mock-buy button
  // itself) are reachable again without reinstalling the app.
  Future<void> simulateMockCancel() async {
    state = false;
    await UserPreferenceService.updatePremiumStatus(false, source: 'mock_internal');
  }
}
