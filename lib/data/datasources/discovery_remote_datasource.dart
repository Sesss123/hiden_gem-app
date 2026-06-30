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
    final securityHeaders = await VaultService.getSecurityHeaders('/discovery/places');
    final response = await _client.get(
      Uri.parse('${AppConfig.baseUrl}/discovery/places'),
      headers: {
        'X-TripMe-Key': AppConfig.tripMeApiKey,
        ...securityHeaders,
      },
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return response.body;
    } else {
      throw Exception("API returned status ${response.statusCode}");
    }
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
      onTimeout: () => [],
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
        if (idToken.isNotEmpty) 'Authorization': 'Bearer $idToken',
        ...securityHeaders,
      },
      body: body,
    );

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    } else {
      throw Exception("AI Recommendation API failed with status ${response.statusCode}");
    }
  }
}
