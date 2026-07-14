import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../../core/config/app_config.dart';
import '../../core/network/secure_http_client.dart';
import '../../core/utils/secure_logger.dart';

/// [PaymentService] — starts a PayHere checkout for a tour booking.
///
/// The tourist taps "Pay Now" on an accepted booking; we ask Laravel for the
/// signed PayHere parameters (the server reads the real quotedPrice from
/// Firestore, so the amount can't be tampered client-side), then open PayHere's
/// hosted checkout. The booking is only marked paid by PayHere's server-to-
/// server `notify` callback into Laravel — never by this client — so a user
/// can't fake a payment to skip the platform commission.
///
/// Opening the checkout: PayHere requires an HTML form POST, so we launch a
/// tiny Laravel-hosted redirect page (`/payments/redirect/{bookingId}`) that
/// re-derives the signed params and auto-submits the form. That avoids adding
/// a webview dependency (the app already ships `url_launcher`).
class PaymentService {
  static String get _baseUrl => AppConfig.baseUrl;
  static String get _apiKey => AppConfig.hiddenGemsApiKey;
  static final _client = SecureHttpClient(http.Client());

  /// Confirms the booking is payable and returns the amount to show in the UI
  /// before launching checkout. Returns null if the server rejects (not the
  /// owner, not accepted, already paid, no price).
  static Future<PaymentQuote?> fetchQuote(String bookingId) async {
    try {
      final res = await _client.post(
        Uri.parse('$_baseUrl/payments/checkout'),
        headers: {
          'Content-Type': 'application/json',
          'X-HiddenGems-Key': _apiKey,
        },
        body: jsonEncode({'booking_id': bookingId}),
      );
      if (res.statusCode != 200) {
        SecureLogger.warning('Payment checkout rejected (${res.statusCode}): ${res.body}', tag: 'Payment');
        return null;
      }
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final params = data['params'] as Map<String, dynamic>?;
      if (params == null) return null;
      return PaymentQuote(
        amount: double.tryParse('${params['amount']}') ?? 0,
        currency: '${params['currency'] ?? 'LKR'}',
      );
    } catch (e) {
      SecureLogger.error('Payment checkout failed', e, null, 'Payment');
      return null;
    }
  }

  /// Opens PayHere's hosted checkout for the booking in an external browser.
  /// Returns true if the checkout page was launched (NOT that payment
  /// succeeded — that is confirmed asynchronously via the server webhook).
  static Future<bool> launchCheckout(String bookingId) async {
    final uri = Uri.parse('$_baseUrl/payments/redirect/$bookingId');
    if (await canLaunchUrl(uri)) {
      return launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return false;
  }
}

/// Amount preview shown before launching checkout.
class PaymentQuote {
  final double amount;
  final String currency;
  const PaymentQuote({required this.amount, required this.currency});
}
