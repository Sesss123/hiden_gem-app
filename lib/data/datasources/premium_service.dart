import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'user_preference_service.dart';
import '../../core/config/app_config.dart';
import 'package:hidden_gems_sl/core/utils/secure_logger.dart';
import '../../core/services/delta_sync_service.dart';
import '../../core/services/secure_entitlements.dart';
import '../../core/services/premium_unlock_service.dart';

part 'premium_service.g.dart';

@riverpod
class PremiumNotifier extends _$PremiumNotifier {
  static const String entitlementId = 'premium_access';
  static const String premiumId = 'hgems_premium_monthly';
  static const String explorerId = 'hgems_explorer_monthly';

  bool get _isFirebaseReady => Firebase.apps.isNotEmpty;

  @override
  bool build() {
    // 🎧 Listen to RevenueCat customer info changes (BUG-F005 & BUG-F006 fix)
    void listener(CustomerInfo customerInfo) {
      _updateStateFromCustomerInfo(customerInfo);
    }
    Purchases.addCustomerInfoUpdateListener(listener);

    ref.onDispose(() {
      Purchases.removeCustomerInfoUpdateListener(listener);
      _firestoreSubscription?.cancel();
    });

    _initRevenueCat();
    _setupFirestoreListener();
    
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

  StreamSubscription<DocumentSnapshot>? _firestoreSubscription;

  void _setupFirestoreListener() {
    if (!_isFirebaseReady) {
      _checkPremiumStatus();
      return;
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _firestoreSubscription?.cancel();
      _firestoreSubscription = null;
      return;
    }

    _firestoreSubscription?.cancel();
    _firestoreSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .listen((doc) async {
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final isPrem = data['isPremium'] == true;
        final expiry = data['premiumExpiresAt'] ?? data['subExpiresAt'];
        DateTime? expiryDate;
        if (expiry != null) {
          expiryDate = expiry is Timestamp ? expiry.toDate() : DateTime.tryParse(expiry.toString());
        }
        
        // BUG-5 Fix: Immediately invalidate client state if expired or revoked
        if (!isPrem || (expiryDate != null && expiryDate.isBefore(DateTime.now()))) {
          if (state == true) {
            state = false;
            SecureEntitlements().forceRefresh();
            PremiumUnlockService.invalidateAllUnlocks();
            await UserPreferenceService.updatePremiumStatus(false, source: 'expired');
            SecureLogger.info("Premium status revoked or expired via server sync.", tag: "RevenueCat");
          }
        } else if (isPrem && state == false) {
          state = true;
          SecureEntitlements().forceRefresh();
          await UserPreferenceService.updatePremiumStatus(
            true, 
            plan: data['premiumPlanId'] ?? data['premiumPlan'] ?? data['subscriptionPlan'], 
            source: 'firestore'
          );
        }
      }
    });

    _checkPremiumStatus();
  }

  void dispose() {
    _firestoreSubscription?.cancel();
    _firestoreSubscription = null;
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

      // 🛡️ SYNC TO FIRESTORE: Keep server record updated for other services (Analytics, Rules)
      if (_isFirebaseReady) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final expDateStr = activeEntitlement?.expirationDate;
          final expDate = expDateStr != null ? DateTime.tryParse(expDateStr) : null;

          await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
            'isPremium': isPremium,
            'premiumExpiresAt': expDate != null ? Timestamp.fromDate(expDate) : null,
            'premiumPlanId': activeEntitlement?.productIdentifier ?? 'unknown',
            'premiumPlan': activeEntitlement?.productIdentifier ?? 'unknown',
            'premiumSource': 'revenuecat',
            'updatedAt': FieldValue.serverTimestamp(),
          }).catchError((e) {
            DeltaSyncService().enqueueOutboxMutation(
              collection: 'users',
              documentId: user.uid,
              data: {
                'isPremium': isPremium,
                'premiumPlanId': activeEntitlement?.productIdentifier ?? 'unknown',
                'premiumSource': 'revenuecat',
              }
            );
            SecureLogger.error("Firestore Sync Support Failed, queued in outbox", e, null, "RevenueCat");
          });
        }
      }
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
    
    // Sync to Firestore mockly
    if (_isFirebaseReady) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'isPremium': true,
          'premiumPlanId': 'premium_mock_dev',
          'premiumPlan': 'premium_mock_dev',
          'premiumSource': 'mock_internal',
        });
      }
    }
  }
}
