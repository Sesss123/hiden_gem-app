import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/tour_package.dart';

final packageRepositoryProvider = Provider((ref) => PackageRepository());

class PackageRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _packageRef =>
      _firestore.collection('tour_packages');

  Future<String> createPackage(TourPackage package) async {
    final id = package.packageId.isEmpty ? const Uuid().v4() : package.packageId;
    final withId = TourPackage(
      packageId: id,
      ownerId: package.ownerId,
      ownerType: package.ownerType,
      title: package.title,
      description: package.description,
      detailedItinerary: package.detailedItinerary,
      photos: package.photos,
      regions: package.regions,
      durationHours: package.durationHours,
      maxGuests: package.maxGuests,
      price: package.price,
      currency: package.currency,
      includesVehicle: package.includesVehicle,
      inclusions: package.inclusions,
      exclusions: package.exclusions,
      isActive: package.isActive,
      isFeatured: package.isFeatured,
      bookingsCount: package.bookingsCount,
      createdAt: package.createdAt,
      updatedAt: package.updatedAt,
    );
    await _packageRef.doc(id).set(withId.toJson());
    return id;
  }

  Future<void> updatePackage(TourPackage package) async {
    await _packageRef.doc(package.packageId).set(package.toJson(), SetOptions(merge: true));
  }

  Future<void> deletePackage(String packageId) async {
    await _packageRef.doc(packageId).delete();
  }

  /// One-shot read — the guide's own package list changes only on an
  /// occasional create/edit/delete action, not while a screen happens to be
  /// open. Callers re-call this after their own writes rather than relying
  /// on a listener.
  Future<List<TourPackage>> getPackagesByOwner(String ownerId) async {
    final snapshot = await _packageRef.where('ownerId', isEqualTo: ownerId).get();
    final packages = snapshot.docs.map((doc) => TourPackage.fromJson(doc.data())).toList();
    packages.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return packages;
  }

  /// Active packages for a guide, shown to tourists as booking options.
  Future<List<TourPackage>> getActivePackagesByOwner(String ownerId) async {
    final packages = await getPackagesByOwner(ownerId);
    return packages.where((p) => p.isActive).toList();
  }

  Future<TourPackage?> getPackage(String packageId) async {
    final doc = await _packageRef.doc(packageId).get();
    if (!doc.exists) return null;
    return TourPackage.fromJson(doc.data()!);
  }
}
