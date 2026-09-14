import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/config/app_config.dart';
import '../../core/utils/secure_logger.dart';

enum PriceDisplayMode { unavailable, contact, free, fixed, from, range }

class CatalogPrice {
  final String key;
  final PriceDisplayMode mode;
  final num? amount;
  final num? maxAmount;
  final String? currency;
  final String? billingPeriod;
  final DateTime? expiresAt;
  const CatalogPrice({required this.key, required this.mode, this.amount, this.maxAmount,
    this.currency, this.billingPeriod, this.expiresAt});

  factory CatalogPrice.fromJson(String key, Map<String, dynamic> json) {
    final mode = PriceDisplayMode.values.where((e) => e.name == json['display_mode'])
        .firstOrNull ?? PriceDisplayMode.unavailable;
    return CatalogPrice(key: key, mode: mode, amount: json['amount'] as num?,
      maxAmount: json['max_amount'] as num?, currency: json['currency'] as String?,
      billingPeriod: json['billing_period'] as String?,
      expiresAt: DateTime.tryParse('${json['expires_at'] ?? ''}'));
  }
  bool get isUsable => expiresAt == null || expiresAt!.isAfter(DateTime.now());
}

/// Laravel is the sole source for centrally-managed prices. The cache contains
/// only the last server response; there are no embedded numeric defaults.
class PriceCatalogService {
  PriceCatalogService._();
  static final PriceCatalogService instance = PriceCatalogService._();
  static const _cacheKey = 'server_price_catalog_v1';
  final ValueNotifier<int> revision = ValueNotifier(0);
  Map<String, CatalogPrice> _prices = const {};

  CatalogPrice? price(String key) {
    final value = _prices[key];
    return value != null && value.isUsable ? value : null;
  }

  Future<void> sync({http.Client? client}) async {
    final prefs = await SharedPreferences.getInstance();
    _loadJson(prefs.getString(_cacheKey));
    try {
      final uri = Uri.parse('${AppConfig.laravelUrl}/config/prices');
      final response = await (client?.get(uri) ?? http.get(uri)).timeout(const Duration(seconds: 5));
      if (response.statusCode != 200) return;
      final decoded = jsonDecode(response.body);
      if (decoded is! Map || decoded['prices'] is! Map) return;
      final raw = jsonEncode(decoded['prices']);
      _loadJson(raw);
      await prefs.setString(_cacheKey, raw);
    } catch (error) {
      SecureLogger.info('[PriceCatalog] Using last server cache: $error');
    }
  }

  void _loadJson(String? raw) {
    if (raw == null || raw.isEmpty) return;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      _prices = decoded.map((key, value) => MapEntry(key,
          CatalogPrice.fromJson(key, Map<String, dynamic>.from(value as Map))));
      revision.value++;
    } catch (error) {
      SecureLogger.warning('[PriceCatalog] Rejected invalid cache: $error');
    }
  }

  @visibleForTesting
  void clearForTesting() { _prices = const {}; revision.value++; }
}
