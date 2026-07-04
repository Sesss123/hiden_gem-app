import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';
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
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }

    if (permission == LocationPermission.deniedForever) return null;

    return await Geolocator.getCurrentPosition();
  }

  Future<String> fetchPlacesRest() async {
    final List<dynamic> allPlaces = [];
    String? cursor;
    bool hasMore = true;
    int pageCount = 0;
    const int maxPages = 20; // Bounded pagination to prevent memory exhaustion / infinite loop

    while (hasMore && pageCount < maxPages) {
      pageCount++;
      final queryParam = cursor != null ? '?cursor=$cursor' : '';
      final securityHeaders = await VaultService.getSecurityHeaders('/places$queryParam');
      
      final response = await _client.get(
        Uri.parse('${AppConfig.laravelUrl}/places$queryParam'),
        headers: {
          'Accept': 'application/json',
          'Accept-Encoding': 'gzip',
          'X-API-KEY': AppConfig.hiddenGemsApiKey,
          'X-HiddenGems-Key': AppConfig.hiddenGemsApiKey,
          ...securityHeaders,
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        Map<String, dynamic> data;
        try {
          data = json.decode(response.body);
        } on FormatException catch (e) {
          throw FormatException("Invalid JSON payload from REST API (/places): $e");
        }
        final List<dynamic> places = data['places'] ?? [];
        allPlaces.addAll(places);
        cursor = data['next_cursor']?.toString();
        hasMore = data['has_more'] as bool? ?? false;
      } else {
        throw Exception("API returned status ${response.statusCode}");
      }
    }

    return json.encode(allPlaces);
  }

  Future<List<DiscoveryPlace>> fetchNearbyPlacesFirestore({
    required Position center,
    double radiusKm = 50.0,
  }) async {
    final CollectionReference<Map<String, dynamic>> collectionReference = 
        FirebaseFirestore.instance.collection('locations');
    final centerPoint = GeoFirePoint(GeoPoint(center.latitude, center.longitude));
    
    final Stream<List<DocumentSnapshot<Map<String, dynamic>>>> stream = 
        GeoCollectionReference<Map<String, dynamic>>(collectionReference)
        .subscribeWithin(
          center: centerPoint,
          radiusInKm: radiusKm,
          field: 'geo',
          geopointFrom: (data) => (data['geo'] as Map<String, dynamic>)['geopoint'] as GeoPoint,
        );

    final List<DocumentSnapshot> snapshots = await stream.first.timeout(
      const Duration(seconds: 5),
      onTimeout: () => throw TimeoutException("GeoHash Firestore stream timed out after 5 seconds."),
    );

    return snapshots.map((doc) => DiscoveryPlace.fromFirestore(doc)).toList();
  }

  Future<List<DiscoveryPlace>> fetchAllPlacesFirestore() async {
    final querySnapshot = await FirebaseFirestore.instance.collection('places').get();
    return querySnapshot.docs.map((doc) => DiscoveryPlace.fromFirestore(doc)).toList();
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
    );

    if (response.statusCode == 200) {
      try {
        final decoded = json.decode(response.body);
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
