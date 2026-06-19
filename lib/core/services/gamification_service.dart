import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/ar_artifact.dart';

/// Service to manage user points, badges, and AR treasure hunt progress.
class GamificationService {
  static final GamificationService _instance = GamificationService._internal();
  factory GamificationService() => _instance;
  GamificationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final ValueNotifier<int> totalPoints = ValueNotifier(0);
  final ValueNotifier<Set<String>> foundArtifactIds = ValueNotifier({});

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;
    
    final prefs = await SharedPreferences.getInstance();
    
    // Load local found artifacts (offline cache)
    final localFound = prefs.getStringList('found_artifacts') ?? [];
    foundArtifactIds.value = Set.from(localFound);
    
    // Load points and sync with Firestore if logged in
    await syncWithCloud();
    _isInitialized = true;
  }

  Future<void> syncWithCloud() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final doc = await _firestore.collection('user_gamification').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        totalPoints.value = data['points'] as int? ?? 0;
        
        // Merge cloud with local
        final cloudFound = List<String>.from(data['found_artifacts'] ?? []);
        final merged = foundArtifactIds.value.union(Set.from(cloudFound));
        foundArtifactIds.value = merged;
        
        // Save merged back to cloud if different
        if (merged.length > cloudFound.length) {
          await _saveToCloud();
        }
      } else {
        // First time user doc creation
        await _saveToCloud();
      }
    } catch (e) {
      debugPrint("Gamification Sync Error: $e");
    }
  }

  Future<void> markArtifactAsFound(ARArtifact artifact) async {
    if (foundArtifactIds.value.contains(artifact.id)) return;

    // Update Local State
    final updatedSet = Set<String>.from(foundArtifactIds.value)..add(artifact.id);
    foundArtifactIds.value = updatedSet;
    totalPoints.value += artifact.points;

    // Save to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('found_artifacts', updatedSet.toList());

    // Save to Cloud
    await _saveToCloud();
  }

  Future<void> _saveToCloud() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('user_gamification').doc(user.uid).set({
        'points': totalPoints.value,
        'found_artifacts': foundArtifactIds.value.toList(),
        'last_updated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Cloud Save Error: $e");
    }
  }

  /// Calculates the "Radar" intensity (0.0 to 1.0) based on distance to artifact.
  /// Used for audio ping frequency or visual radar.
  double getRadarIntensity(double distanceMeters) {
    if (distanceMeters > 10) return 0.0;
    if (distanceMeters < 1) return 1.0;
    return (10 - distanceMeters) / 9;
  }
}
