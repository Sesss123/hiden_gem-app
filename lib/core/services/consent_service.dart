import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:hidden_gems_sl/core/utils/secure_logger.dart';

class ConsentService {
  static final ConsentService _instance = ConsentService._internal();
  factory ConsentService() => _instance;
  ConsentService._internal();

  /// Initialize Consent flows (ATT for iOS, UMP for EU/GDPR)
  /// Only starts Google Mobile Ads after consent is resolved.
  Future<void> init() async {
    if (kIsWeb) return;

    try {
      // 1. Request iOS App Tracking Transparency (ATT)
      if (Platform.isIOS) {
        final TrackingStatus status = await AppTrackingTransparency.trackingAuthorizationStatus;
        if (status == TrackingStatus.notDetermined) {
          // Show ATT dialog
          await AppTrackingTransparency.requestTrackingAuthorization();
        }
      }

      // 2. Request GDPR Consent via Google UMP SDK
      final params = ConsentRequestParameters();
      ConsentInformation.instance.requestConsentInfoUpdate(
        params,
        () async {
          if (await ConsentInformation.instance.isConsentFormAvailable()) {
            _loadAndShowConsentForm();
          } else {
            // No form available, likely outside EU or already resolved. Initialize ads.
            _initializeAds();
          }
        },
        (FormError error) {
          SecureLogger.warning("UMP Consent Info Update Failed: ${error.message}");
          // Fallback to initializing ads anyway if form update fails
          _initializeAds();
        },
      );
    } catch (e) {
      SecureLogger.error("Error in ConsentService init: $e");
      _initializeAds();
    }
  }

  void _loadAndShowConsentForm() {
    ConsentForm.loadConsentForm(
      (ConsentForm consentForm) async {
        final status = await ConsentInformation.instance.getConsentStatus();
        if (status == ConsentStatus.required) {
          consentForm.show(
            (FormError? formError) {
              if (formError != null) {
                SecureLogger.warning("Consent Form Show Error: ${formError.message}");
              }
              // After form is dismissed, initialize ads
              _initializeAds();
            },
          );
        } else {
          // Already consented or not required
          _initializeAds();
        }
      },
      (FormError formError) {
        SecureLogger.warning("Consent Form Load Error: ${formError.message}");
        _initializeAds();
      },
    );
  }

  void _initializeAds() {
    try {
      MobileAds.instance.initialize();
      SecureLogger.info("MobileAds initialized after consent check.");
    } catch (e) {
      SecureLogger.error("MobileAds Init Error: $e");
    }
  }
}
