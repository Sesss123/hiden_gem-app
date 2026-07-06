import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../models/discovery_place.dart';
import '../../core/config/app_config.dart';
import '../../core/services/vault_service.dart';
import '../../core/network/secure_http_client.dart';

class DiscoveryRemoteDataSource {
  final http.Client _client;

  DiscoveryRemoteDataSource({http.Client? client}) 
      : _client = SecureHttpClient(client ?? http.Client());

  Future<Position?> getCurrentLocation() async {
    LocationPermission permission;
    bool serviceEnabled;

    // Exec #8 / Audit #1: Check location permission BEFORE querying service status
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }

    if (permission == LocationPermission.deniedForever) return null;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    // Add explicit timeout to prevent hanging when GPS signal is poor
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      ).timeout(const Duration(seconds: 12));
    } catch (e) {
      return null;
    }
  }


  Future<List<DiscoveryPlace>> fetchAllPlacesFirestore() async {
    final querySnapshot = await FirebaseFirestore.instance.collection('places').get();
    return querySnapshot.docs.map((doc) => DiscoveryPlace.fromFirestore(doc)).toList();
  }

  static dynamic _decodeAiPayload(String body) {
    return json.decode(body);
  }

  Future<List<Map<String, dynamic>>> getAiRecommendationsRaw({
    required List<DiscoveryPlace> nearbyPlaces,
    required String vibeText,
  }) async {
    final body = json.encode({
      'nearbyPlaces': nearbyPlaces.map((p) => {
        'id': p.id,
        'name': p.name,
        'category': p.category,
        'distanceKm': p.distanceKm
      }).toList(),
      'vibeText': vibeText
    });
    
    final securityHeaders = await VaultService.getSecurityHeaders('/ai/recommendations', body: body);
    final idToken = await FirebaseAuth.instance.currentUser?.getIdToken() ?? '';

    final response = await _client.post(
      Uri.parse('${AppConfig.nodeProxyUrl}/ai/recommendations'),
      headers: {
        'Content-Type': 'application/json',
        'Accept-Encoding': 'gzip',
        if (idToken.isNotEmpty) 'Authorization': 'Bearer $idToken',
        ...securityHeaders,
      },
      body: body,
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      try {
        final decoded = await compute(_decodeAiPayload, response.body);
        if (decoded is List) {
          return List<Map<String, dynamic>>.from(decoded);
        } else if (decoded is Map && decoded.containsKey('recommendations')) {
          return List<Map<String, dynamic>>.from(decoded['recommendations']);
        }
        return [];
      } on FormatException catch (e) {
        throw FormatException("Invalid JSON payload from AI recommendations API: $e");
      }
    } else {
      throw Exception("AI Recommendation API failed with status ${response.statusCode}");
    }
  }
}
