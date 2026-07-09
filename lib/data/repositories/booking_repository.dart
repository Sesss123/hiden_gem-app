import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/booking_request.dart';
import '../../core/utils/secure_logger.dart';
import '../../core/config/app_config.dart';
import '../../core/network/secure_http_client.dart';

final bookingRepositoryProvider = Provider((ref) => BookingRepository());

class BookingRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _bookingRef =>
      _firestore.collection('booking_requests');

  /// Submits a new booking request from a tourist.
  ///
  /// Note: quotedPrice/commissionAmount/guideNetAmount/payoutStatus are NOT
  /// set here — firestore.rules blocks clients from writing those fields
  /// (money math must never be trusted from the client), and quoting isn't
  /// wired into the booking flow yet. The guide sets a real quote via a
  /// future backend-mediated quoting step; this just records the request.
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
      currency: request.currency ?? 'LKR',
      packageSnapshot: request.packageSnapshot,
      includedItemsSnapshot: request.includedItemsSnapshot,
      status: 'pending',
      createdAt: DateTime.now(),
    );

    await doc.set(newRequest.toJson());

    // Increment booking request counts for analytics and trigger push notification
    if (request.guideId != null) {
      await _notifyBackendOfNewBooking(doc.id, request.guideId!);

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

  Future<void> _notifyBackendOfNewBooking(String bookingId, String guideId) async {
    // Increments guide_listings.bookingRequestsCount server-side —
    // firestore.rules only allows the listing owner (the guide) to write
    // that field, and the tourist submitting the booking isn't the owner.
    try {
      final client = SecureHttpClient(http.Client());
      final uri = Uri.parse('${AppConfig.laravelUrl}/bookings/$bookingId/notify-guide');
      await client.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'X-API-KEY': AppConfig.hiddenGemsApiKey,
        },
        body: json.encode({'guideId': guideId}),
      ).timeout(const Duration(seconds: 8));
    } catch (e) {
      SecureLogger.warning("Failed to increment booking count: $e", tag: "Booking");
    }
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
      final docs = snapshot.docs.map((doc) => BookingRequest.fromJson(doc.data() as Map<String, dynamic>)).toList();
      docs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return docs;
    });
  }

  /// Retrieves a tourist's own booking history. One-shot read (not a live
  /// listener) — a personal booking history list doesn't need live sync
  /// while the screen happens to be open; re-fetch on screen open or
  /// pull-to-refresh is enough.
  Future<List<BookingRequest>> getTouristBookings(String touristId) async {
    final snapshot = await _bookingRef.where('touristId', isEqualTo: touristId).get();
    final docs = snapshot.docs.map((doc) => BookingRequest.fromJson(doc.data())).toList();
    docs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return docs;
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
