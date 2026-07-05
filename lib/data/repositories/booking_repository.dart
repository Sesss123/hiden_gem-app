import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/booking_request.dart';
import '../../core/utils/secure_logger.dart';

final bookingRepositoryProvider = Provider((ref) => BookingRepository());

class BookingRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _bookingRef => 
      _firestore.collection('booking_requests');

  /// Submits a new booking request from a tourist.
  Future<String> submitRequest(BookingRequest request) async {
    final doc = _bookingRef.doc();
    final quoted = request.quotedPrice;
    final commission = request.commissionAmount ?? (quoted != null ? quoted * 0.10 : null);
    final netAmount = request.guideNetAmount ?? (quoted != null ? quoted * 0.90 : null);

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
      quotedPrice: quoted,
      currency: request.currency ?? 'LKR',
      packageSnapshot: request.packageSnapshot,
      includedItemsSnapshot: request.includedItemsSnapshot,
      commissionAmount: commission,
      guideNetAmount: netAmount,
      payoutStatus: request.payoutStatus,
      
      status: 'pending',
      createdAt: DateTime.now(),
    );

    await doc.set(newRequest.toJson());
    
    // Increment booking request counts for analytics and trigger push notification
    if (request.guideId != null) {
      try {
        await _firestore.collection('guide_listings').doc(request.guideId).update({
          'bookingRequestsCount': FieldValue.increment(1),
        });
      } catch (e) {
        SecureLogger.warning("Failed to increment booking count: $e", tag: "Booking");
      }

      try {
        await _firestore.collection('user_notifications').add({
          'recipientId': request.guideId,
          'title': '📅 New Booking Request!',
          'body': 'You have received a tour request for ${request.guestCount} guests on ${request.requestedDate.toString().split(' ')[0]}.',
          'type': 'new_booking',
          'bookingId': doc.id,
          'createdAt': FieldValue.serverTimestamp(),
          'isRead': false,
        });
        SecureLogger.info("Dispatched new_booking notification to guide: ${request.guideId}", tag: "Booking");
      } catch (e) {
        SecureLogger.warning("Failed to dispatch booking notification: $e", tag: "Booking");
      }
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

  /// Links a created tour session to a booking request.
  Future<void> updateLinkedSessionId(String bookingId, String sessionId) async {
    await _bookingRef.doc(bookingId).update({
      'linkedSessionId': sessionId,
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

    return query.snapshots().map((snapshot) {
      final docs = snapshot.docs.map((doc) => BookingRequest.fromJson(doc.data())).toList();
      docs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return docs;
    });
  }

  /// Retrieves a tourist's own booking history.
  Stream<List<BookingRequest>> getTouristBookings(String touristId) {
    return _bookingRef
        .where('touristId', isEqualTo: touristId)
        .snapshots()
        .map((snapshot) {
          final docs = snapshot.docs.map((doc) => BookingRequest.fromJson(doc.data())).toList();
          docs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return docs;
        });
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
