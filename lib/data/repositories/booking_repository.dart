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

  // Firestore cost fix: getInbox() used to open a brand-new .snapshots()
  // listener on every call. BookingInboxScreen, GuideEarningsScreen, and
  // GuideClientsScreen all call it independently, so simply navigating
  // between those 3 screens in one session opened 3 concurrent, unbounded,
  // duplicate live listeners against the exact same guide's full booking
  // history — every field change on any booking re-billed all 3. This
  // repository is a Riverpod singleton (bookingRepositoryProvider is a
  // plain Provider, one instance app-wide), so a per-ownerId broadcast
  // stream cache here means all 3 screens now share ONE real Firestore
  // listener; StreamBuilder's shape in all 3 callers is unchanged.
  final Map<String, Stream<List<BookingRequest>>> _inboxStreamCache = {};

  /// Submits a new booking request from a tourist.
  ///
  /// Note: quotedPrice/commissionAmount/guideNetAmount/payoutStatus are NOT
  /// set here — firestore.rules blocks clients from writing those fields
  /// (money math must never be trusted from the client), and quoting isn't
  /// wired into the booking flow yet. The guide sets a real quote via a
  /// future backend-mediated quoting step; this just records the request.
  Future<String> submitRequest(BookingRequest request) async {
    final doc = _bookingRef.doc();

    // Priority Leads: a Pro/Elite guide's incoming bookings are flagged so
    // their own inbox can surface them first — see SubscriptionService.
    //
    // This can't be checked via the GUIDE's own subscriptions doc from the
    // TOURIST's client — firestore.rules only allows an account to read its
    // own subscription (accountId == request.auth.uid) — so it's resolved
    // server-side via Laravel, which has elevated Firestore access. Never
    // let a failure here abort the booking itself; the priority flag is a
    // nice-to-have, not a precondition for the booking existing.
    bool isPriority = false;
    if (request.guideId != null) {
      isPriority = await _checkPriorityLeads(request.guideId!);
    }

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
      isPriority: isPriority,
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
          'isPriority': isPriority,
        });
        SecureLogger.info("Dispatched new_booking notification to guide: ${request.guideId}", tag: "Booking");
      } catch (e) {
        SecureLogger.warning("Failed to dispatch booking notification: $e", tag: "Booking");
      }
    }

    return doc.id;
  }

  Future<bool> _checkPriorityLeads(String guideId) async {
    try {
      final client = SecureHttpClient(http.Client());
      final uri = Uri.parse('${AppConfig.laravelUrl}/bookings/priority-check?guideId=$guideId');
      final response = await client.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'X-API-KEY': AppConfig.hiddenGemsApiKey,
        },
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return data['isPriority'] == true;
      }
    } catch (e) {
      SecureLogger.warning("Priority-lead check failed: $e", tag: "Booking");
    }
    return false;
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

  /// Responds to a booking request (Accept/Decline). Also notifies the
  /// tourist — previously this only updated Firestore silently, so a
  /// tourist had no way to learn their request was accepted/declined short
  /// of manually reopening the app and re-checking (there wasn't even a
  /// screen for that until MyBookingsScreen).
  Future<void> respondToRequest({
    required String bookingId,
    required String status,
    String? note,
    String? touristId,
  }) async {
    await _bookingRef.doc(bookingId).update({
      'status': status,
      'respondedAt': DateTime.now().toIso8601String(),
      'responseNote': note,
    });

    if (touristId != null) {
      try {
        final isAccepted = status == 'accepted' || status == 'session_ready';
        await _firestore.collection('user_notifications').add({
          'recipientId': touristId,
          'title': isAccepted ? '✅ Booking accepted!' : '📋 Booking update',
          'body': isAccepted
              ? 'Your guide accepted your booking request.'
              : (note ?? 'Your booking request was declined.'),
          'type': 'booking_response',
          'bookingId': bookingId,
          'createdAt': FieldValue.serverTimestamp(),
          'isRead': false,
        });
      } catch (e) {
        SecureLogger.warning("Failed to notify tourist of booking response: $e", tag: "Booking");
      }
    }
  }

  /// Links a created tour session to a booking request.
  Future<void> updateLinkedSessionId(String bookingId, String sessionId) async {
    await _bookingRef.doc(bookingId).update({
      'linkedSessionId': sessionId,
    });
  }

  /// Retrieves booking requests for a specific guide or operator inbox.
  /// Returns a SHARED broadcast stream per (ownerId, isOperator) pair — see
  /// _inboxStreamCache above. Capped at the 300 most recent bookings
  /// (createdAt desc); a guide's actionable inbox/earnings/clients views
  /// only ever need recent history, not an unbounded years-long feed.
  Stream<List<BookingRequest>> getInbox(String ownerId, {bool isOperator = false}) {
    final cacheKey = '${isOperator ? 'op' : 'guide'}_$ownerId';
    final cached = _inboxStreamCache[cacheKey];
    if (cached != null) return cached;

    Query query = _bookingRef;
    if (isOperator) {
      query = query.where('operatorId', isEqualTo: ownerId);
    } else {
      query = query.where('guideId', isEqualTo: ownerId);
    }
    query = query.orderBy('createdAt', descending: true).limit(300);

    final stream = query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => BookingRequest.fromJson(doc.data() as Map<String, dynamic>)).toList();
    }).asBroadcastStream();

    _inboxStreamCache[cacheKey] = stream;
    return stream;
  }

  /// Drops the cached shared inbox stream for an owner, forcing the next
  /// getInbox() call to open a fresh listener. Not normally needed (the
  /// live listener already reflects writes in real time) — provided for
  /// completeness/testing and in case a caller ever needs to force a full
  /// resubscribe (e.g. after a long background period).
  void invalidateInboxCache(String ownerId, {bool isOperator = false}) {
    _inboxStreamCache.remove('${isOperator ? 'op' : 'guide'}_$ownerId');
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
  ///
  /// Note: this is only ever safe to call as the guide themselves — a
  /// tourist's client can't run this query (firestore.rules can't prove a
  /// query filtered only by guideId is safe for a non-owner, non-guide
  /// caller). Tourists checking a guide's quota before booking must use
  /// [checkMonthlyQuota] instead, which goes through the Laravel backend.
  Future<int> getMonthlyBookingCount(String guideId) async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);

    // createdAt is stored as an ISO8601 string (BookingRequest.toJson()),
    // not a Firestore Timestamp — a DateTime range filter here would never
    // match, since Firestore inequality filters require matching types.
    // ISO8601 strings sort correctly lexicographically, so a string bound
    // works the same as a Timestamp bound would.
    final query = await _bookingRef
        .where('guideId', isEqualTo: guideId)
        .where('createdAt', isGreaterThanOrEqualTo: startOfMonth.toIso8601String())
        .count()
        .get();

    return query.count ?? 0;
  }

  /// Checks whether [guideId] has hit their monthly booking quota, via the
  /// Laravel backend (server-side, admin Firestore access) rather than a
  /// direct client query — a tourist can never legitimately read another
  /// guide's full booking_requests list under firestore.rules, so this must
  /// be resolved server-side before a tourist can submit a booking.
  Future<bool> checkMonthlyQuota(String guideId) async {
    try {
      final client = SecureHttpClient(http.Client());
      final uri = Uri.parse('${AppConfig.laravelUrl}/bookings/quota-check?guideId=$guideId');
      final response = await client.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'X-API-KEY': AppConfig.hiddenGemsApiKey,
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        SecureLogger.warning("Quota check failed (${response.statusCode}), allowing booking to proceed", tag: "Booking");
        return false;
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      return data['quotaExceeded'] as bool? ?? false;
    } catch (e) {
      SecureLogger.warning("Quota check failed: $e, allowing booking to proceed", tag: "Booking");
      return false;
    }
  }
}
