import 'dart:io';
import 'dart:async';
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
        final TrackingStatus status =
            await AppTrackingTransparency.trackingAuthorizationStatus;
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
            await _initializeAdsIfAllowed();
          }
        },
        (FormError error) {
          SecureLogger.warning(
              "UMP Consent Info Update Failed: ${error.message}");
          // Fail closed: an unavailable consent service is not consent.
        },
      );
    } catch (e) {
      SecureLogger.error("Error in ConsentService init: $e");
      // Fail closed; core app functionality does not depend on ads.
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
                SecureLogger.warning(
                    "Consent Form Show Error: ${formError.message}");
              }
              _initializeAdsIfAllowed();
            },
          );
        } else {
          // Already consented or not required
          _initializeAdsIfAllowed();
        }
      },
      (FormError formError) {
        SecureLogger.warning("Consent Form Load Error: ${formError.message}");
        // Fail closed when the consent form cannot be loaded.
      },
    );
  }

  Future<void> _initializeAdsIfAllowed() async {
    if (!await ConsentInformation.instance.canRequestAds()) {
      SecureLogger.info('Ads remain disabled because consent is unresolved.');
      return;
    }
    try {
      MobileAds.instance.initialize();
      SecureLogger.info("MobileAds initialized after consent check.");
    } catch (e) {
      SecureLogger.error("MobileAds Init Error: $e");
    }
  }

  /// Lets the user revisit/withdraw ad consent from Profile settings.
  Future<void> showPrivacyOptions() async {
    final completer = Completer<void>();
    ConsentForm.showPrivacyOptionsForm((error) {
      if (error != null) {
        completer.completeError(StateError(error.message));
      } else {
        completer.complete();
      }
    });
    return completer.future;
  }
}
