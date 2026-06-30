import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/booking_request.dart';

final bookingRepositoryProvider = Provider((ref) => BookingRepository());

class BookingRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _bookingRef => 
      _firestore.collection('booking_requests');

  /// Submits a new booking request from a tourist.
  Future<String> submitRequest(BookingRequest request) async {
    final doc = _bookingRef.doc();
    final newRequest = BookingRequest(
      bookingId: doc.id,
      touristId: request.touristId,
      guideId: request.guideId,
      operatorId: request.operatorId,
      packageId: request.packageId,
      requestedDate: request.requestedDate,
      guestCount: request.guestCount,
      notes: request.notes,
      
      // Capture Snapshots
      quotedPrice: request.quotedPrice,
      currency: request.currency,
      packageSnapshot: request.packageSnapshot,
      includedItemsSnapshot: request.includedItemsSnapshot,
      
      status: 'pending',
      createdAt: DateTime.now(),
    );

    await doc.set(newRequest.toJson());
    
    // Increment booking request counts for analytics
    if (request.guideId != null) {
      await _firestore.collection('guide_listings').doc(request.guideId).update({
        'bookingRequestsCount': FieldValue.increment(1),
      });
    }

    return doc.id;
  }

  /// Responds to a booking request (Accept/Decline).
  Future<void> respondToRequest({
    required String bookingId,
    required String status,
    String? note,
  }) async {
    await _bookingRef.doc(bookingId).update({
      'status': status,
      'respondedAt': DateTime.now().toIso8601String(),
      'responseNote': note,
    });
  }

  /// Retrieves booking requests for a specific guide or operator inbox.
  Stream<List<BookingRequest>> getInbox(String ownerId, {bool isOperator = false}) {
    Query query = _bookingRef;
    if (isOperator) {
      query = query.where('operatorId', isEqualTo: ownerId);
    } else {
      query = query.where('guideId', isEqualTo: ownerId);
    }

    return query.orderBy('createdAt', descending: true).snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => BookingRequest.fromJson(doc.data() as Map<String, dynamic>)).toList());
  }

  /// Retrieves a tourist's own booking history.
  Stream<List<BookingRequest>> getTouristBookings(String touristId) {
    return _bookingRef
        .where('touristId', isEqualTo: touristId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => BookingRequest.fromJson(doc.data())).toList());
  }

  /// Gets the number of booking requests received by a guide in the current month.
  Future<int> getMonthlyBookingCount(String guideId) async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    
    final query = await _bookingRef
        .where('guideId', isEqualTo: guideId)
        .where('createdAt', isGreaterThanOrEqualTo: startOfMonth)
        .count()
        .get();
        
    return query.count ?? 0;
  }
}
