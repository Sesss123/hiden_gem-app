import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import '../../data/models/business_partner.dart';
import '../../core/utils/secure_logger.dart';

/// Service to discover local business partners (Hotels, Guides) near heritage
/// sites, and premium-only Curator Deals at partner boutique stays/cafes.
class BusinessDiscoveryService {
  static final BusinessDiscoveryService _instance = BusinessDiscoveryService._internal();
  factory BusinessDiscoveryService() => _instance;
  BusinessDiscoveryService._internal();

  final _partnersRef = FirebaseFirestore.instance.collection('partners');

  /// Loads the full partner list from Firestore, falling back to the bundled
  /// demo dataset (assets/business_partners.json) when Firestore has no
  /// partners yet or is unreachable — keeps the AR/nearby-partner feature
  /// working out of the box before any admin has added a real partner.
  Future<List<BusinessPartner>> _loadAllPartners() async {
    try {
      final snapshot = await _partnersRef.get();
      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs
            .map((doc) => BusinessPartner.fromJson({...doc.data(), 'id': doc.id}))
            .toList();
      }
    } catch (e) {
      SecureLogger.warning("Firestore partners fetch failed, falling back to bundled dataset: $e", tag: "BusinessDiscovery");
    }

    try {
      final String response = await rootBundle.loadString('assets/business_partners.json');
      final List<dynamic> data = json.decode(response);
      return data.map((j) => BusinessPartner.fromJson(j)).toList();
    } catch (e) {
      SecureLogger.error("Error loading bundled business partners: $e");
      return [];
    }
  }

  /// Fetches business partners near a specific coordinate.
  Future<List<BusinessPartner>> getNearbyPartners({
    required double lat,
    required double lng,
    double radiusKm = 5.0,
  }) async {
    final partners = await _loadAllPartners();

    for (var partner in partners) {
      partner.distanceKm = Geolocator.distanceBetween(lat, lng, partner.lat, partner.lng) / 1000.0;
    }

    return partners.where((p) => p.distanceKm <= radiusKm).toList()
      ..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
  }

  /// Fetches every partner currently offering an active premium-only deal —
  /// backs the "Exclusive Curator Deals" premium benefit.
  Future<List<BusinessPartner>> getPremiumDeals() async {
    final partners = await _loadAllPartners();
    return partners.where((p) => p.hasActiveDeal).toList();
  }
}
