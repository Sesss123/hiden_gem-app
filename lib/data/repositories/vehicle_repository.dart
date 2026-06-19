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

  Stream<List<Vehicle>> getGuideVehicles(String guideId) {
    return _firestore
        .collection('vehicles')
        .where('guideId', isEqualTo: guideId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Vehicle.fromJson(doc.data())).toList());
  }

  Future<Vehicle?> getVehicle(String vehicleId) async {
    final doc = await _firestore.collection('vehicles').doc(vehicleId).get();
    if (doc.exists) {
      return Vehicle.fromJson(doc.data()!);
    }
    return null;
  }
}
