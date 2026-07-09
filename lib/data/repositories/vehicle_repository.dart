import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/vehicle.dart';

final vehicleRepositoryProvider = Provider((ref) => VehicleRepository());

class VehicleRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addVehicle(Vehicle vehicle) async {
    await _firestore.collection('vehicles').doc(vehicle.id).set(vehicle.toJson());
  }

  Future<void> updateVehicle(Vehicle vehicle) async {
    await _firestore.collection('vehicles').doc(vehicle.id).update(vehicle.toJson());
  }

  Future<void> deleteVehicle(String vehicleId) async {
    await _firestore.collection('vehicles').doc(vehicleId).delete();
  }

  /// One-shot read (not a live listener) — a guide's vehicle list changes
  /// only on an occasional add/edit/delete action, not while this screen
  /// happens to be open. Callers should re-call this after their own
  /// add/update/delete rather than relying on a listener to reflect it.
  Future<List<Vehicle>> getGuideVehicles(String guideId) async {
    final snapshot = await _firestore
        .collection('vehicles')
        .where('guideId', isEqualTo: guideId)
        .get();
    return snapshot.docs.map((doc) => Vehicle.fromJson(doc.data())).toList();
  }

  Future<Vehicle?> getVehicle(String vehicleId) async {
    final doc = await _firestore.collection('vehicles').doc(vehicleId).get();
    if (doc.exists) {
      return Vehicle.fromJson(doc.data()!);
    }
    return null;
  }
}
