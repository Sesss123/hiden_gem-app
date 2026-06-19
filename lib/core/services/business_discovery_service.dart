import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import '../../data/models/business_partner.dart';
import '../../core/utils/secure_logger.dart';

/// Service to discover local business partners (Hotels, Guides) near heritage sites.
class BusinessDiscoveryService {
  static final BusinessDiscoveryService _instance = BusinessDiscoveryService._internal();
  factory BusinessDiscoveryService() => _instance;
  BusinessDiscoveryService._internal();

  /// Fetches business partners near a specific coordinate.
  Future<List<BusinessPartner>> getNearbyPartners({
    required double lat,
    required double lng,
    double radiusKm = 5.0,
  }) async {
    try {
      // In a real app, this would be an API call to /business/nearby
      // For the Phase 4 demo, we load from a static mock and filter by distance.
      final String response = await rootBundle.loadString('assets/business_partners.json');
      final List<dynamic> data = json.decode(response);
      
      List<BusinessPartner> partners = data.map((j) => BusinessPartner.fromJson(j)).toList();
      
      // Calculate distance and filter
      for (var partner in partners) {
        partner.distanceKm = Geolocator.distanceBetween(
          lat, lng, partner.lat, partner.lng
        ) / 1000.0;
      }
      
      return partners.where((p) => p.distanceKm <= radiusKm).toList()
        ..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
        
    } catch (e) {
      SecureLogger.error("Error fetching nearby business partners", e);
      return [];
    }
  }
}
