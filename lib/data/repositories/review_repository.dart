import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/tour_review.dart';
import '../../core/config/app_config.dart';
import '../../core/network/secure_http_client.dart';
import '../../core/utils/secure_logger.dart';

final reviewRepositoryProvider = Provider((ref) => ReviewRepository());

/// [ReviewRepository] — Scalability-hardened review data layer.
///
/// PERFORMANCE ARCHITECTURE:
/// - Reads (getGuideReviews) go through a shared, write-through Laravel
///   cache (GET /v1/reviews/guide/{guideId}) instead of a direct per-device
///   Firestore query — a Firestore read only happens when a review is
///   actually submitted/moderated, never on profile views.
/// - On top of that, a short-lived in-memory cache here avoids even the
///   Laravel network round-trip if the SAME user re-opens the SAME guide's
///   reviews more than once within one app session (e.g. navigating back
///   and forth). This repository instance lives for the app's lifetime
///   (plain Provider, not autoDispose), so the cache persists per session.
/// - Rating aggregation uses server-side atomic updates, NOT client scans
/// - Guide reviewCount/ratingAverage are updated by the Laravel backend
///   (POST /v1/reviews/{id}/recalculate) — firestore.rules blocks clients
///   from writing those fields on another user's (the guide's) document.
/// - No open Streams on review collections (prevents read cost explosion)
class ReviewRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _reviewRef =>
      _firestore.collection('tour_reviews');

  // In-session cache: guideId -> (reviews, cached-at). Short TTL — the
  // server-side data can change (write-through), this is purely about not
  // re-hitting the network for the same guide within the same short window.
  final Map<String, _CachedReviewPage> _sessionCache = {};
  static const Duration _sessionCacheTtl = Duration(minutes: 2);

  // --- Submit Review ---

  /// Creates a verified tour review.
  /// Enforces: session completion, eligibility (participant list), and review window.
  Future<void> submitReview(TourReview review) async {
    // 1. Verify Session Eligibility & Window
    final sessionDoc = await _firestore
        .collection('tour_sessions')
        .doc(review.sessionId)
        .get();
    if (!sessionDoc.exists) throw Exception("SESSION_NOT_FOUND");

    final status = sessionDoc.get('status');
    if (status != 'completed') throw Exception("SESSION_NOT_COMPLETED");

    final endsAtStr = sessionDoc.get('reviewWindowEndsAt');
    if (endsAtStr != null) {
      final endsAt = DateTime.parse(endsAtStr);
      if (DateTime.now().isAfter(endsAt)) throw Exception("REVIEW_WINDOW_EXPIRED");
    }

    final eligibleIds =
        List<String>.from(sessionDoc.get('reviewEligibleTouristIds') ?? []);
    if (!eligibleIds.contains(review.touristId)) {
      throw Exception("NOT_ELIGIBLE: Participant was not linked to this session.");
    }

    // 2. Prevent Duplicate Reviews (efficient: single compound query)
    final existing = await _reviewRef
        .where('sessionId', isEqualTo: review.sessionId)
        .where('touristId', isEqualTo: review.touristId)
        .limit(1) // Only need to know if 1 exists
        .get();
    if (existing.docs.isNotEmpty) throw Exception("ALREADY_REVIEWED");

    // 3. Create Review
    final doc = _reviewRef.doc();
    final verifiedReview = TourReview(
      reviewId: doc.id,
      sessionId: review.sessionId,
      guideId: review.guideId,
      touristId: review.touristId,
      overallRating: review.overallRating,
      knowledgeRating: review.knowledgeRating,
      communicationRating: review.communicationRating,
      punctualityRating: review.punctualityRating,
      safetyRating: review.safetyRating,
      friendlinessRating: review.friendlinessRating,
      comment: review.comment,
      createdAt: DateTime.now(),
      isVerifiedSession: true,
      reviewWindowValidated: true,
      submittedFromDeviceHash: review.submittedFromDeviceHash,
      moderationStatus: 'active',
    );

    await doc.set(verifiedReview.toJson());

    // Ask the backend to bump the guide's reviewCount and recalculate
    // ratingAverage — firestore.rules blocks a client from writing those
    // fields on another user's document, so this can't be done from here.
    // The review itself is already saved above regardless of this call's
    // outcome; a transient failure here just delays the guide's stats update.
    await _notifyBackendReviewChanged(doc.id, review.guideId);
  }

  Future<void> _notifyBackendReviewChanged(String reviewId, String guideId) async {
    // Drop this guide's session cache immediately so a subsequent
    // getGuideReviews() call on this device re-fetches instead of serving a
    // stale pre-change snapshot for up to _sessionCacheTtl.
    _sessionCache.remove(guideId);
    try {
      final client = SecureHttpClient(http.Client());
      final uri = Uri.parse('${AppConfig.laravelUrl}/reviews/$reviewId/recalculate');
      await client.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'X-API-KEY': AppConfig.hiddenGemsApiKey,
        },
        body: json.encode({'guideId': guideId}),
      ).timeout(const Duration(seconds: 8));
    } catch (e) {
      SecureLogger.warning("Failed to notify backend of new review (guide stats will be stale until retried): $e", tag: "Reviews");
    }
  }

  // --- Read Reviews (Server-Cached + Session-Cached) ---

  /// Reviews for a guide. Two cache layers:
  /// 1. In-memory, per-session (this repository instance) — avoids a network
  ///    round-trip if the same guide is re-viewed within [_sessionCacheTtl].
  /// 2. Laravel's write-through cache (GET /v1/reviews/guide/{guideId}) —
  ///    avoids a Firestore read on every profile view; only refreshed when a
  ///    review is actually submitted/moderated.
  /// Capped at 50 reviews (no caller paginates past this today).
  Future<ReviewPage> getGuideReviews(String guideId) async {
    final cached = _sessionCache[guideId];
    if (cached != null && DateTime.now().isBefore(cached.expiresAt)) {
      return cached.page;
    }

    try {
      final client = SecureHttpClient(http.Client());
      final uri = Uri.parse('${AppConfig.laravelUrl}/reviews/guide/$guideId');
      final response = await client.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'X-API-KEY': AppConfig.hiddenGemsApiKey,
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final list = (data['reviews'] as List<dynamic>? ?? [])
            .map((r) => TourReview.fromJson(r as Map<String, dynamic>))
            .toList();
        final page = ReviewPage(reviews: list, hasMore: false);
        _sessionCache[guideId] = _CachedReviewPage(page, DateTime.now().add(_sessionCacheTtl));
        return page;
      }
      SecureLogger.warning("Guide reviews fetch returned ${response.statusCode}", tag: "Reviews");
    } catch (e) {
      SecureLogger.warning("Failed to fetch guide reviews from backend: $e", tag: "Reviews");
    }
    return cached?.page ?? ReviewPage.empty;
  }

  // --- Moderation ---

  Future<void> flagReview(String reviewId, String reason) async {
    final doc = await _reviewRef.doc(reviewId).get();
    final guideId = doc.data()?['guideId'] as String?;

    await _reviewRef.doc(reviewId).update({
      'moderationStatus': 'under_review',
      'isFlagged': true,
      'flagReason': reason,
    });

    // A flagged review drops out of the guide's "active" review set — refresh
    // reviewCount/ratingAverage and the guideReviews() cache (write-through).
    if (guideId != null) {
      await _notifyBackendReviewChanged(reviewId, guideId);
    }
  }

  Future<void> hideReview(
      String reviewId, String adminId, String reason) async {
    final doc = await _reviewRef.doc(reviewId).get();
    final guideId = doc.data()?['guideId'] as String?;

    await _reviewRef.doc(reviewId).update({
      'moderationStatus': 'hidden',
      'hiddenByAdmin': adminId,
      'hiddenReason': reason,
    });

    // reviewCount/ratingAverage on users/{guideId} are backend-owned fields
    // (firestore.rules blocks a client write here) — ask Laravel to
    // recompute them, which also refreshes the guideReviews() cache.
    if (guideId != null) {
      await _notifyBackendReviewChanged(reviewId, guideId);
    }
  }

  // --- Admin: Stream is OK (low-volume dashboard) ---

  Stream<List<TourReview>> getFlaggedReviewsAdmin() {
    return _reviewRef
        .where('moderationStatus', isEqualTo: 'under_review')
        .orderBy('createdAt', descending: true)
        .limit(50) // Safety cap
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => TourReview.fromJson(doc.data())).toList());
  }
}

/// A single page of reviews (server-cached, capped at 50 — see getGuideReviews).
class ReviewPage {
  final List<TourReview> reviews;
  final bool hasMore;

  const ReviewPage({
    required this.reviews,
    required this.hasMore,
  });

  static const ReviewPage empty = ReviewPage(reviews: [], hasMore: false);
}

/// In-session (per-device) cache entry for [ReviewRepository._sessionCache].
class _CachedReviewPage {
  final ReviewPage page;
  final DateTime expiresAt;

  const _CachedReviewPage(this.page, this.expiresAt);
}


