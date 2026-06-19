import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/tour_review.dart';

final reviewRepositoryProvider = Provider((ref) => ReviewRepository());

/// [ReviewRepository] — Scalability-hardened review data layer.
///
/// PERFORMANCE ARCHITECTURE:
/// - Reviews are fetched on-demand with pagination (limit 10)
/// - Rating aggregation uses server-side atomic updates, NOT client scans
/// - A "recalc_needed" signal triggers Cloud Functions for accurate averages
/// - No open Streams on review collections (prevents read cost explosion)
class ReviewRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _reviewRef =>
      _firestore.collection('tour_reviews');

  static const int _pageSize = 10;

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

    // Use batch to atomically write review + signal for async recalculation
    final batch = _firestore.batch();
    batch.set(doc, verifiedReview.toJson());

    // Signal Cloud Function to recalculate — avoids expensive client-side scan
    // Cloud Function watches for this field change and does the aggregation.
    batch.update(
      _firestore.collection('users').doc(review.guideId),
      {
        'reviewCount': FieldValue.increment(1),
        // Cloud Function trigger: recalculates ratingAverage accurately
        'ratingRecalcNeededAt': FieldValue.serverTimestamp(),
      },
    );

    await batch.commit();
  }

  // --- Read Reviews (Paginated) ---

  /// First page of reviews for a guide.
  Future<ReviewPage> getGuideReviews(String guideId) async {
    final snapshot = await _reviewRef
        .where('guideId', isEqualTo: guideId)
        .where('moderationStatus', isEqualTo: 'active')
        .orderBy('createdAt', descending: true)
        .limit(_pageSize)
        .get(const GetOptions(source: Source.serverAndCache));

    return ReviewPage._fromSnapshot(snapshot);
  }

  /// Loads the next page of reviews using a cursor.
  Future<ReviewPage> loadMoreReviews({
    required String guideId,
    required DocumentSnapshot lastDocument,
  }) async {
    final snapshot = await _reviewRef
        .where('guideId', isEqualTo: guideId)
        .where('moderationStatus', isEqualTo: 'active')
        .orderBy('createdAt', descending: true)
        .startAfterDocument(lastDocument)
        .limit(_pageSize)
        .get(const GetOptions(source: Source.serverAndCache));

    return ReviewPage._fromSnapshot(snapshot);
  }

  // --- Moderation ---

  Future<void> flagReview(String reviewId, String reason) async {
    await _reviewRef.doc(reviewId).update({
      'moderationStatus': 'under_review',
      'isFlagged': true,
      'flagReason': reason,
    });
  }

  Future<void> hideReview(
      String reviewId, String adminId, String reason) async {
    final batch = _firestore.batch();

    batch.update(_reviewRef.doc(reviewId), {
      'moderationStatus': 'hidden',
      'hiddenByAdmin': adminId,
      'hiddenReason': reason,
    });

    // Decrement count + signal recalculation
    final doc = await _reviewRef.doc(reviewId).get();
    if (doc.exists) {
      final guideId = doc.get('guideId') as String?;
      if (guideId != null) {
        batch.update(_firestore.collection('users').doc(guideId), {
          'reviewCount': FieldValue.increment(-1),
          'ratingRecalcNeededAt': FieldValue.serverTimestamp(),
        });
      }
    }

    await batch.commit();
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

/// A single page of reviews with a cursor for pagination.
class ReviewPage {
  final List<TourReview> reviews;
  final bool hasMore;
  final DocumentSnapshot? lastDocument;

  const ReviewPage({
    required this.reviews,
    required this.hasMore,
    this.lastDocument,
  });

  factory ReviewPage._fromSnapshot(QuerySnapshot snapshot) {
    final reviews = snapshot.docs
        .map((doc) => TourReview.fromJson(doc.data() as Map<String, dynamic>))
        .toList();

    return ReviewPage(
      reviews: reviews,
      hasMore: reviews.length >= 10,
      lastDocument: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
    );
  }

  static const ReviewPage empty = ReviewPage(reviews: [], hasMore: false);
}


