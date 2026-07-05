// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'marketplace_search_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
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

@ProviderFor(MarketplaceSearchController)
final marketplaceSearchControllerProvider =
    MarketplaceSearchControllerProvider._();

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
final class MarketplaceSearchControllerProvider extends $NotifierProvider<
    MarketplaceSearchController, MarketplaceSearchState> {
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
  MarketplaceSearchControllerProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'marketplaceSearchControllerProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$marketplaceSearchControllerHash();

  @$internal
  @override
  MarketplaceSearchController create() => MarketplaceSearchController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MarketplaceSearchState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MarketplaceSearchState>(value),
    );
  }
}

String _$marketplaceSearchControllerHash() =>
    r'017f81aa22e7c5838c0e4b2c9090e1e70f5d1a80';

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

abstract class _$MarketplaceSearchController
    extends $Notifier<MarketplaceSearchState> {
  MarketplaceSearchState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<MarketplaceSearchState, MarketplaceSearchState>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<MarketplaceSearchState, MarketplaceSearchState>,
        MarketplaceSearchState,
        Object?,
        Object?>;
    return element.handleCreate(ref, build);
  }
}
