import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DataSeeder {
  static const List<String> _files = [
    'assets/tripme_database_complete_Adventure Park.json',
    'assets/tripme_database_complete_Religious Places.json',
    'assets/tripme_database_complete_beach.json',
    'assets/tripme_database_complete_tea estate.json',
    'assets/tripme_database_complete_viwe-point.json',
    'assets/tripme_database_complete_water-falls.json',
  ];

  static Future<void> seedPlaces() async {
    try {
      debugPrint('Starting LLM data seeding...');
      final firestore = FirebaseFirestore.instance;
      int totalCount = 0;
      
      for (final file in _files) {
        debugPrint('Loading $file...');
        final String response = await rootBundle.loadString(file);
        final List<dynamic> data = json.decode(response);
        
        final batch = firestore.batch();
        int batchCount = 0;
        
        for (var rawPlace in data) {
          // Mapping the LLM JSON format to our DiscoveryPlace format
          final Map<String, dynamic> mappedData = {
            'id': rawPlace['id']?.toString() ?? firestore.collection('places').doc().id,
            'name': rawPlace['name'] ?? 'Unknown Place',
            'description': rawPlace['description'] ?? '',
            'district': rawPlace['district_id'] ?? 'Unknown',
            'province': rawPlace['province_id'] ?? '',
            'category': rawPlace['category_id'] ?? 'General',
            'lat': rawPlace['lat']?.toString() ?? '0.0',
            'lng': rawPlace['lng']?.toString() ?? '0.0',
            'openingHours': rawPlace['opening_hours'] ?? '',
            'roadType': rawPlace['road_condition'] ?? 'Unknown',
            'ticketRange': rawPlace['ticket_price'] ?? 'Free',
            'budgetCategory': rawPlace['budget_category'] ?? 'Budget',
            'bestTime': rawPlace['best_time_to_visit'] ?? 'Anytime',
            'safetyLevel': rawPlace['safety_level'] ?? 'Safe',
            
            // Build facilities list based on raw boolean/yes/no fields
            'facilities': _buildFacilities(rawPlace),
            
            // Default fields that are missing in the raw JSON
            'rating': 4.5, // Default rating
            'imageUrl': 'https://images.unsplash.com/photo-1552465011-b4e21bf6e79a?q=80&w=2078&auto=format&fit=crop',
            'riskTags': rawPlace['wildlife_hazard'] != 'None' ? [rawPlace['wildlife_hazard']] : [],
            'vehicleAccess': rawPlace['road_condition'] ?? 'All',
            'parkingRange': rawPlace['parking_avail'] == 'yes' ? 'Available' : 'None',
            'isEncrypted': false,
          };
          
          final docRef = firestore.collection('places').doc(mappedData['id']);
          batch.set(docRef, mappedData);
          batchCount++;
          totalCount++;
          
          // Firestore batches support up to 500 operations
          if (batchCount == 400) {
            await batch.commit();
            batchCount = 0;
          }
        }
        if (batchCount > 0) {
          await batch.commit();
        }
        debugPrint('Finished uploading $file');
      }
      
      debugPrint('Successfully seeded $totalCount TOTAL places to Firestore!');
    } catch (e) {
      debugPrint('Error seeding data: $e');
    }
  }

  static List<String> _buildFacilities(Map<String, dynamic> raw) {
    List<String> f = [];
    if (raw['parking_avail']?.toString().toLowerCase() == 'yes') f.add('Parking');
    if (raw['toilets']?.toString().toLowerCase() == 'yes') f.add('Restrooms');
    if (raw['food_nearby']?.toString().toLowerCase() == 'yes') f.add('Food');
    if (raw['camping_allowed']?.toString().toLowerCase() == 'yes') f.add('Camping');
    return f;
  }
}
