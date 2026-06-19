import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/guide_listing.dart';

final marketplaceRepositoryProvider = Provider((ref) => MarketplaceRepository());

/// [MarketplaceRepository] — Scalability-hardened data layer.
///
/// PERFORMANCE ARCHITECTURE:
/// - Search & Browse: get() + pagination (limit 20)  → No persistent listeners
/// - Featured Guides: get() with 5-min TTL cache     → Hot data, read once
/// - Admin oversight: snapshots() is OK here         → Low-volume admin tool
///
/// This design ensures that 10,000 concurrent users don't each hold open
/// a Firestore listener — a mistake that would cause exponential read costs.
class MarketplaceRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _listingRef =>
      _firestore.collection('guide_listings');

  static const int _pageSize = 20;

  // --- Featured Guides (Hot Data Cache) ---

  // In-memory cache for featured guides (TTL: 5 minutes)
  List<GuideListing>? _featuredCache;
  DateTime? _featuredCacheExpiry;

  /// Fetches featured guides with an in-memory cache.
  /// Re-fetches from Firestore only after 5 minutes.
  Future<List<GuideListing>> getFeaturedGuides() async {
    if (_featuredCache != null &&
        _featuredCacheExpiry != null &&
        DateTime.now().isBefore(_featuredCacheExpiry!)) {
      return _featuredCache!; // Serve from cache
    }

    final snapshot = await _listingRef
        .where('isFeatured', isEqualTo: true)
        .where('status', isEqualTo: 'published')
        .where('moderationStatus', isEqualTo: 'approved')
        .orderBy('ratingAverage', descending: true)
        .limit(10)
        .get(const GetOptions(source: Source.serverAndCache));

    _featuredCache = snapshot.docs
        .map((doc) => GuideListing.fromJson(doc.data()))
        .toList();
    _featuredCacheExpiry = DateTime.now().add(const Duration(minutes: 5));
    return _featuredCache!;
  }

  void invalidateFeaturedCache() {
    _featuredCache = null;
    _featuredCacheExpiry = null;
  }

  // --- Search (Paginated, On-Demand) ---

  /// First page of a marketplace search. Returns a [MarketplacePage].
  Future<MarketplacePage> searchMarketplace({
    String? region,
    String? category,
    String? language,
    bool? vehicleRequired,
  }) async {
    Query query = _buildSearchQuery(
      region: region,
      category: category,
      language: language,
      vehicleRequired: vehicleRequired,
    );

    final snapshot = await query
        .limit(_pageSize)
        .get(const GetOptions(source: Source.serverAndCache));

    return MarketplacePage._fromSnapshot(snapshot);
  }

  /// Loads the next page of results using a cursor from the previous page.
  Future<MarketplacePage> loadNextPage({
    required DocumentSnapshot lastDocument,
    String? region,
    String? category,
    String? language,
    bool? vehicleRequired,
  }) async {
    Query query = _buildSearchQuery(
      region: region,
      category: category,
      language: language,
      vehicleRequired: vehicleRequired,
    );

    final snapshot = await query
        .startAfterDocument(lastDocument)
        .limit(_pageSize)
        .get(const GetOptions(source: Source.serverAndCache));

    return MarketplacePage._fromSnapshot(snapshot);
  }

  Query _buildSearchQuery({
    String? region,
    String? category,
    String? language,
    bool? vehicleRequired,
  }) {
    Query query = _listingRef
        .where('status', isEqualTo: 'published')
        .where('moderationStatus', isEqualTo: 'approved');

    if (region != null) query = query.where('regions', arrayContains: region);
    if (category != null) {
      query = query.where('guideCategory', isEqualTo: category);
    }
    if (language != null) {
      query = query.where('languages', arrayContains: language);
    }
    if (vehicleRequired == true) {
      query = query.where('vehicleAvailable', isEqualTo: true);
    }

    return query.orderBy('ratingAverage', descending: true);
  }

  // --- Single Listing ---

  Future<GuideListing?> getListing(String listingId) async {
    final doc = await _listingRef.doc(listingId).get();
    if (!doc.exists) return null;
    return GuideListing.fromJson(doc.data()!);
  }

  Future<void> trackProfileView(String listingId) async {
    await _listingRef.doc(listingId).update({
      'profileViews': FieldValue.increment(1),
    });
  }

  // --- Guide Packages ---

  Future<List<Map<String, dynamic>>> getGuidePackages(String guideId) async {
    final snapshot = await _firestore
        .collection('tour_packages')
        .where('ownerId', isEqualTo: guideId)
        .where('isActive', isEqualTo: true)
        .get(const GetOptions(source: Source.serverAndCache));

    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  // --- Create / Update ---

  Future<void> upsertListing(GuideListing listing) async {
    await _listingRef
        .doc(listing.listingId)
        .set(listing.toJson(), SetOptions(merge: true));
  }

  // --- ADMIN METHODS (Stream OK — admin is low-volume) ---

  Stream<List<GuideListing>> getAllListingsAdmin() {
    return _listingRef
        .orderBy('createdAt', descending: true)
        .limit(100) // Safety cap even for admin
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => GuideListing.fromJson(doc.data()))
            .toList());
  }

  Future<void> updateModerationStatus(String listingId, String status) async {
    await _listingRef.doc(listingId).update({
      'moderationStatus': status,
      'lastModeratedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> toggleFeatured(String listingId, bool isFeatured) async {
    await _listingRef.doc(listingId).update({'isFeatured': isFeatured});
  }
}

/// A single page of marketplace results with cursor for pagination.
class MarketplacePage {
  final List<GuideListing> listings;
  final bool hasMore;
  final DocumentSnapshot? lastDocument;

  const MarketplacePage({
    required this.listings,
    required this.hasMore,
    this.lastDocument,
  });

  factory MarketplacePage._fromSnapshot(QuerySnapshot snapshot) {
    final listings = snapshot.docs
        .map((doc) => GuideListing.fromJson(doc.data() as Map<String, dynamic>))
        .toList();

    return MarketplacePage(
      listings: listings,
      hasMore: listings.length >= 20,
      lastDocument: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
    );
  }

  static const MarketplacePage empty = MarketplacePage(
    listings: [],
    hasMore: false,
  );
}
