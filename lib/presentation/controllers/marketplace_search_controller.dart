import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/guide_listing.dart';
import '../../data/repositories/marketplace_repository.dart';
import '../../core/services/behavior_analytics_engine.dart';

// ── Providers ───────────────────────────────────────────────────────────────

final marketplaceSearchControllerProvider =
    StateNotifierProvider.autoDispose<MarketplaceSearchController, MarketplaceSearchState>(
  (ref) => MarketplaceSearchController(ref.watch(marketplaceRepositoryProvider)),
);

// ── State ────────────────────────────────────────────────────────────────────

/// The complete UI state for the marketplace search experience.
class MarketplaceSearchState {
  final List<GuideListing> results;
  final bool isLoading;
  final String? error;
  final String normalizedQuery;
  final bool hasMore;         // Has a next page to load
  final bool isCooldown;      // Rate limit UI cooldown active
  final int cooldownSeconds;  // Seconds remaining in cooldown
  final SearchMetrics metrics;

  const MarketplaceSearchState({
    this.results = const [],
    this.isLoading = false,
    this.error,
    this.normalizedQuery = '',
    this.hasMore = false,
    this.isCooldown = false,
    this.cooldownSeconds = 0,
    this.metrics = const SearchMetrics(),
  });

  bool get isEmpty => results.isEmpty && !isLoading && normalizedQuery.isNotEmpty;
  bool get isBlank => normalizedQuery.isEmpty;

  MarketplaceSearchState copyWith({
    List<GuideListing>? results,
    bool? isLoading,
    String? error,
    String? normalizedQuery,
    bool? hasMore,
    bool? isCooldown,
    int? cooldownSeconds,
    SearchMetrics? metrics,
  }) =>
      MarketplaceSearchState(
        results: results ?? this.results,
        isLoading: isLoading ?? this.isLoading,
        error: error ?? this.error,
        normalizedQuery: normalizedQuery ?? this.normalizedQuery,
        hasMore: hasMore ?? this.hasMore,
        isCooldown: isCooldown ?? this.isCooldown,
        cooldownSeconds: cooldownSeconds ?? this.cooldownSeconds,
        metrics: metrics ?? this.metrics,
      );
}

// ── Controller ───────────────────────────────────────────────────────────────

/// [MarketplaceSearchController] — Production-grade search state manager.
///
/// Features:
///   ✅ Cancelable requests (stale result rejection via requestId)
///   ✅ Rate-limit UI (5 searches/min → cooldown snackbar)
///   ✅ Query normalization (trim, lowercase, collapse spaces)
///   ✅ 60-second result cache (same query = no Firestore hit)
///   ✅ Empty state guard (< 2 chars = no query fired)
///   ✅ Global fetch timeout (8 seconds)
///   ✅ Metrics telemetry (reads, cache hits, cancels, rate limits)
///   ✅ Pagination (loadMore via cursor)
class MarketplaceSearchController
    extends StateNotifier<MarketplaceSearchState> {
  final MarketplaceRepository _repository;
  final _analytics = BehaviorAnalyticsEngine();

  // ── Configuration ──────────────────────────────────────────────────────
  static const int _minChars = 2;
  static const int _maxSearchesPerMinute = 5;
  static const Duration _fetchTimeout = Duration(seconds: 8);
  static const Duration _cacheTtl = Duration(seconds: 60);
  static const Duration _cooldownDuration = Duration(seconds: 10);

  // ── Cancelable Request State ────────────────────────────────────────────
  /// Monotonically increasing ID. A result is only applied if its ID matches
  /// the CURRENT _activeRequestId at the time of arrival.
  int _activeRequestId = 0;

  // ── Rate Limiting ───────────────────────────────────────────────────────
  final List<DateTime> _searchTimestamps = [];
  Timer? _cooldownTimer;
  int _cooldownRemaining = 0;

  // ── Result Cache (Query String → Timed Result) ──────────────────────────
  final Map<String, _CachedResult> _queryCache = {};

  // ── Pagination Cursor ───────────────────────────────────────────────────
  MarketplacePage? _lastPage;

  // ── Active Filters ──────────────────────────────────────────────────────
  String? _region;
  String? _category;
  String? _language;
  bool? _vehicleRequired;

  MarketplaceSearchController(this._repository)
      : super(const MarketplaceSearchState());

  // ── Public API ─────────────────────────────────────────────────────────

  /// Main search entry point. Called from UI after debouncer fires.
  Future<void> search(
    String rawQuery, {
    String? region,
    String? category,
    String? language,
    bool? vehicleRequired,
  }) async {
    // A. Normalize query
    final query = _normalize(rawQuery);

    // B. Empty state guard
    if (query.length < _minChars) {
      state = state.copyWith(
        results: const [],
        normalizedQuery: query,
        isLoading: false,
        hasMore: false,
        error: null,
      );
      return;
    }

    // C. Rate limit check
    if (_isRateLimited()) {
      _startCooldownUI();
      _analytics.reportCustomAnomaly('search_rate_exceeded', weight: 5);
      return;
    }

    // D. Cache check
    final cacheKey = _buildCacheKey(query, region, category, language, vehicleRequired);
    final cached = _queryCache[cacheKey];
    if (cached != null && DateTime.now().isBefore(cached.expiresAt)) {
      state = state.copyWith(
        results: cached.listings,
        normalizedQuery: query,
        isLoading: false,
        hasMore: cached.hasMore,
        error: null,
        metrics: state.metrics.copyWith(cacheHits: state.metrics.cacheHits + 1),
      );
      debugPrint('[Search] Cache hit for "$query"');
      return;
    }

    // E. Record this search in rate-limit tracker
    _recordSearch();
    _analytics.reportSearchFired();

    // F. Assign a new request ID to cancel any in-flight response
    final requestId = ++_activeRequestId;

    // Store active filters for pagination
    _region = region;
    _category = category;
    _language = language;
    _vehicleRequired = vehicleRequired;
    _lastPage = null;

    state = state.copyWith(
      isLoading: true,
      normalizedQuery: query,
      error: null,
      results: const [],
      hasMore: false,
    );

    try {
      final page = await _repository
          .searchMarketplace(
            region: region,
            category: category,
            language: language,
            vehicleRequired: vehicleRequired,
          )
          .timeout(_fetchTimeout);

      // G. Stale result guard — discard if a newer request is active
      if (requestId != _activeRequestId) {
        debugPrint('[Search] Discarding stale result for "$query" (id=$requestId)');
        state = state.copyWith(
          metrics: state.metrics.copyWith(canceledRequests: state.metrics.canceledRequests + 1),
        );
        return;
      }

      _lastPage = page;

      // H. Cache the result
      _queryCache[cacheKey] = _CachedResult(
        listings: page.listings,
        hasMore: page.hasMore,
        expiresAt: DateTime.now().add(_cacheTtl),
      );

      state = state.copyWith(
        results: page.listings,
        isLoading: false,
        hasMore: page.hasMore,
        error: null,
        metrics: state.metrics.copyWith(
          totalSearches: state.metrics.totalSearches + 1,
          totalDocsRead: state.metrics.totalDocsRead + page.listings.length,
        ),
      );

      debugPrint('[Search] "$query" → ${page.listings.length} results (id=$requestId)');
    } on TimeoutException {
      if (requestId != _activeRequestId) return;
      state = state.copyWith(
        isLoading: false,
        error: 'Search timed out. Please try again.',
      );
    } catch (e) {
      if (requestId != _activeRequestId) return;
      state = state.copyWith(
        isLoading: false,
        error: 'Search failed. Please check your connection.',
      );
      debugPrint('[Search] Error: $e');
    }
  }

  /// Load the next page of results (infinite scroll).
  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;
    final lastDoc = _lastPage?.lastDocument;
    if (lastDoc == null) return;

    final requestId = ++_activeRequestId;
    state = state.copyWith(isLoading: true);

    try {
      final page = await _repository
          .loadNextPage(
            lastDocument: lastDoc,
            region: _region,
            category: _category,
            language: _language,
            vehicleRequired: _vehicleRequired,
          )
          .timeout(_fetchTimeout);

      if (requestId != _activeRequestId) return;

      _lastPage = page;
      state = state.copyWith(
        results: [...state.results, ...page.listings],
        isLoading: false,
        hasMore: page.hasMore,
        metrics: state.metrics.copyWith(
          totalDocsRead: state.metrics.totalDocsRead + page.listings.length,
          paginationDepth: state.metrics.paginationDepth + 1,
        ),
      );
    } on TimeoutException {
      if (requestId != _activeRequestId) return;
      state = state.copyWith(isLoading: false, error: 'Load more timed out.');
    } catch (e) {
      if (requestId != _activeRequestId) return;
      state = state.copyWith(isLoading: false);
    }
  }

  /// Clear search and return to idle state.
  void clear() {
    _activeRequestId++; // Cancel any in-flight request
    state = const MarketplaceSearchState();
  }

  // ── Query Normalization ─────────────────────────────────────────────────

  String _normalize(String raw) {
    return raw
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), ' '); // Collapse multiple spaces
  }

  // ── Cache ───────────────────────────────────────────────────────────────

  String _buildCacheKey(String query, String? region, String? category,
      String? language, bool? vehicleRequired) {
    return '$query|${region ?? ""}|${category ?? ""}|${language ?? ""}|${vehicleRequired ?? ""}';
  }

  // ── Rate Limiter ────────────────────────────────────────────────────────

  bool _isRateLimited() {
    _pruneOldTimestamps();
    return _searchTimestamps.length >= _maxSearchesPerMinute ||
        state.isCooldown;
  }

  void _recordSearch() {
    _searchTimestamps.add(DateTime.now());
    _pruneOldTimestamps();
  }

  void _pruneOldTimestamps() {
    final cutoff = DateTime.now().subtract(const Duration(minutes: 1));
    _searchTimestamps.removeWhere((t) => t.isBefore(cutoff));
  }

  void _startCooldownUI() {
    _cooldownRemaining = _cooldownDuration.inSeconds;
    state = state.copyWith(
      isCooldown: true,
      cooldownSeconds: _cooldownRemaining,
      metrics: state.metrics.copyWith(rateLimitHits: state.metrics.rateLimitHits + 1),
    );

    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _cooldownRemaining--;
      if (_cooldownRemaining <= 0) {
        timer.cancel();
        if (mounted) state = state.copyWith(isCooldown: false, cooldownSeconds: 0);
      } else {
        if (mounted) state = state.copyWith(cooldownSeconds: _cooldownRemaining);
      }
    });
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }
}

// ── Supporting Types ─────────────────────────────────────────────────────────

class _CachedResult {
  final List<GuideListing> listings;
  final bool hasMore;
  final DateTime expiresAt;
  const _CachedResult({
    required this.listings,
    required this.hasMore,
    required this.expiresAt,
  });
}

/// Telemetry counters — logged to BehaviorAnalytics or dev dashboard.
class SearchMetrics {
  final int totalSearches;
  final int cacheHits;
  final int canceledRequests;
  final int rateLimitHits;
  final int totalDocsRead;
  final int paginationDepth;

  const SearchMetrics({
    this.totalSearches = 0,
    this.cacheHits = 0,
    this.canceledRequests = 0,
    this.rateLimitHits = 0,
    this.totalDocsRead = 0,
    this.paginationDepth = 0,
  });

  double get cacheHitRate => totalSearches == 0
      ? 0
      : (cacheHits / (totalSearches + cacheHits) * 100);

  double get avgDocsPerSearch =>
      totalSearches == 0 ? 0 : totalDocsRead / totalSearches;

  SearchMetrics copyWith({
    int? totalSearches,
    int? cacheHits,
    int? canceledRequests,
    int? rateLimitHits,
    int? totalDocsRead,
    int? paginationDepth,
  }) =>
      SearchMetrics(
        totalSearches: totalSearches ?? this.totalSearches,
        cacheHits: cacheHits ?? this.cacheHits,
        canceledRequests: canceledRequests ?? this.canceledRequests,
        rateLimitHits: rateLimitHits ?? this.rateLimitHits,
        totalDocsRead: totalDocsRead ?? this.totalDocsRead,
        paginationDepth: paginationDepth ?? this.paginationDepth,
      );

  @override
  String toString() =>
      'SearchMetrics(searches: $totalSearches, cache: $cacheHitRate%, '
      'canceled: $canceledRequests, docs: $totalDocsRead, depth: $paginationDepth)';
}
