import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'user_preference_service.dart';
import '../../core/config/app_config.dart';

part 'premium_service.g.dart';

@riverpod
class PremiumNotifier extends _$PremiumNotifier {
  static const String entitlementId = 'premium_access';
  static const String premiumId = 'hgems_premium_monthly';
  static const String explorerId = 'hgems_explorer_monthly';

  @override
  bool build() {
    // 🎧 Listen to RevenueCat customer info changes
    Purchases.addCustomerInfoUpdateListener((customerInfo) {
      _updateStateFromCustomerInfo(customerInfo);
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

      await Purchases.configure(PurchasesConfiguration(apiKey));

      // Identify user if logged in
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await Purchases.logIn(user.uid);
      }

      final customerInfo = await Purchases.getCustomerInfo();
      _updateStateFromCustomerInfo(customerInfo);
    } catch (e) {
      debugPrint('[RevenueCat] Init error: $e');
    }
  }

  StreamSubscription<DocumentSnapshot>? _firestoreSubscription;

  void _setupFirestoreListener() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _firestoreSubscription?.cancel();
    _firestoreSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .listen((doc) async {
      if (doc.exists && doc.data() != null) {
        // We still keep the Firestore listener for auxiliary server-side flags
        // but RevenueCat is the primary source of truth for "active" status.
      }
    });

    _checkPremiumStatus();
  }

  Future<void> _checkPremiumStatus() async {
    if (kIsWeb) return;
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      _updateStateFromCustomerInfo(customerInfo);
    } catch (e) {
      debugPrint("[RevenueCat] Status Check failed: $e");
    }
  }

  void _updateStateFromCustomerInfo(CustomerInfo customerInfo) async {
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
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'isPremium': isPremium,
          'premiumExpiresAt': activeEntitlement?.expirationDate != null 
              ? Timestamp.fromDate(DateTime.parse(activeEntitlement!.expirationDate!)) 
              : null,
          'premiumPlan': activeEntitlement?.productIdentifier ?? 'unknown',
          'premiumSource': 'revenuecat',
          'updatedAt': FieldValue.serverTimestamp(),
        }).catchError((e) => debugPrint("Firestore Sync Support Failed: $e"));
      }
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
        debugPrint('[RevenueCat] Purchase Error: $e');
      }
    }
  }

  Future<void> restorePurchases() async {
    try {
      CustomerInfo customerInfo = await Purchases.restorePurchases();
      _updateStateFromCustomerInfo(customerInfo);
    } catch (e) {
      debugPrint("[RevenueCat] Restore failed: $e");
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
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'isPremium': true,
        'premiumPlan': 'premium_mock_dev',
        'premiumSource': 'mock_internal',
      });
    }
  }
}
