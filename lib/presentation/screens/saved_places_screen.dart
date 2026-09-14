import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/oracle_ui_system.dart';
import '../../core/services/opening_hours_service.dart';
import '../../data/models/discovery_place.dart';
import '../../data/datasources/user_preference_service.dart';
import '../../data/repositories/discovery_repository.dart';
import '../widgets/cached_image.dart';
import 'place_details_screen.dart';
import '../../l10n/app_localizations.dart';

class SavedPlacesScreen extends ConsumerStatefulWidget {
  final int initialTabIndex;

  const SavedPlacesScreen({
    super.key,
    this.initialTabIndex = 0,
  });

  @override
  ConsumerState<SavedPlacesScreen> createState() => _SavedPlacesScreenState();
}

class _SavedPlacesScreenState extends ConsumerState<SavedPlacesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<DiscoveryPlace> _allPlaces = [];
  bool _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 2),
    );
    _loadAllPlaces();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllPlaces() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final res = await ref.read(discoveryRepositoryProvider).getDiscoveryPlaces();
      res.fold(
        (error) {
          if (mounted) {
            setState(() {
              _isLoading = false;
              _loadError = error.message;
            });
          }
        },
        (places) {
          if (mounted) {
            setState(() {
              _allPlaces = places;
              _isLoading = false;
            });
          }
        },
      );
    } catch (error) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadError = error.toString();
        });
      }
    }
  }

  List<DiscoveryPlace> _filterPlaces(List<String> ids) {
    if (ids.isEmpty) return [];
    final idMap = {for (final p in _allPlaces) p.id: p};
    final List<DiscoveryPlace> result = [];
    for (final id in ids) {
      final p = idMap[id];
      if (p != null) result.add(p);
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final profile = UserPreferenceService.getProfile();
    final bookmarked = _filterPlaces(profile.bookmarkedPlaces);
    final wantToVisit = _filterPlaces(profile.itineraryPlaceIds);
    final recentlyViewed = _filterPlaces(profile.recentlyViewedPlaces);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: isDark ? AppPaletteDark.surface : AppTheme.colors.white,
        elevation: 0,
        title: Text(
          l10n.savedJourneyHubTitle,
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary(context),
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: AppTheme.textPrimary(context), size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppPalette.sigiriyaOchre,
          indicatorWeight: 3,
          labelColor: AppPalette.sigiriyaOchre,
          unselectedLabelColor: AppTheme.textSecondary(context),
          labelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
          unselectedLabelStyle: GoogleFonts.inter(fontSize: 12),
          tabs: [
            Tab(
              icon: const Icon(Icons.bookmark_rounded, size: 20),
              text: l10n.bookmarkedCount(bookmarked.length),
            ),
            Tab(
              icon: const Icon(Icons.explore_rounded, size: 20),
              text: l10n.wantToVisitCount(wantToVisit.length),
            ),
            Tab(
              icon: const Icon(Icons.history_rounded, size: 20),
              text: l10n.recentCount(recentlyViewed.length),
            ),
          ],
        ),
      ),
      body: OracleUI.auraBackground(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppPalette.sigiriyaOchre),
              )
            : _loadError != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.cloud_off_rounded, size: 44),
                          const SizedBox(height: 12),
                          Text(l10n.savedPlacesLoadError),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: _loadAllPlaces,
                            icon: const Icon(Icons.refresh_rounded),
                            label: Text(l10n.retryAction),
                          ),
                        ],
                      ),
                    ),
                  )
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildPlaceList(
                    context,
                    places: bookmarked,
                    emptyTitle: l10n.noBookmarkedPlaces,
                    emptySubtitle: l10n.noBookmarkedPlacesHint,
                    emptyIcon: Icons.bookmark_border_rounded,
                    isBookmarkTab: true,
                  ),
                  _buildPlaceList(
                    context,
                    places: wantToVisit,
                    emptyTitle: l10n.wantToVisitEmpty,
                    emptySubtitle: l10n.wantToVisitEmptyHint,
                    emptyIcon: Icons.explore_off_outlined,
                    isItineraryTab: true,
                  ),
                  _buildRecentlyViewedTab(context, recentlyViewed),
                ],
              ),
      ),
    );
  }

  Widget _buildRecentlyViewedTab(BuildContext context, List<DiscoveryPlace> places) {
    if (places.isEmpty) {
      return _buildEmptyState(
        context,
        title: AppLocalizations.of(context)!.noRecentlyViewedPlaces,
        subtitle: AppLocalizations.of(context)!.noRecentlyViewedPlacesHint,
        icon: Icons.history_rounded,
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.browsingHistoryCount(places.length),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary(context),
                ),
              ),
              TextButton.icon(
                onPressed: () async {
                  HapticFeedback.lightImpact();
                  await UserPreferenceService.clearRecentlyViewedPlaces();
                  setState(() {});
                },
                icon: Icon(Icons.delete_sweep_rounded, size: 16, color: AppPalette.error),
                label: Text(
                  'Clear History',
                  style: GoogleFonts.inter(fontSize: 12, color: AppPalette.error),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _buildPlaceListView(context, places),
        ),
      ],
    );
  }

  Widget _buildPlaceList(
    BuildContext context, {
    required List<DiscoveryPlace> places,
    required String emptyTitle,
    required String emptySubtitle,
    required IconData emptyIcon,
    bool isBookmarkTab = false,
    bool isItineraryTab = false,
  }) {
    if (places.isEmpty) {
      return _buildEmptyState(
        context,
        title: emptyTitle,
        subtitle: emptySubtitle,
        icon: emptyIcon,
      );
    }

    return _buildPlaceListView(
      context,
      places,
      isBookmarkTab: isBookmarkTab,
      isItineraryTab: isItineraryTab,
    );
  }

  Widget _buildPlaceListView(
    BuildContext context,
    List<DiscoveryPlace> places, {
    bool isBookmarkTab = false,
    bool isItineraryTab = false,
  }) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      physics: const BouncingScrollPhysics(),
      itemCount: places.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final place = places[index];
        final opening = OpeningHoursService.evaluate(
          place.openingHours,
          weeklyHours: place.weeklyHours,
          temporarilyClosed: place.temporarilyClosed,
          closureNote: place.closureNote,
          closureUntil: place.closureUntil,
          holidayHoursNote: place.holidayHoursNote,
          monsoonNote: place.monsoonNote,
          riskTags: place.riskTags,
          description: place.description,
        );

        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => PlaceDetailsScreen(place: place)),
            ).then((_) => setState(() {}));
          },
          child: OracleUI.glassContainer(
            padding: const EdgeInsets.all(12),
            radius: BorderRadius.circular(20),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: CachedImage(
                    url: place.imageUrl,
                    width: 86,
                    height: 86,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: opening.badgeColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: opening.badgeColor.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              opening.badgeText,
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: opening.badgeColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            place.district,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AppTheme.textSecondary(context),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        place.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary(context),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            place.rating > 0 ? Icons.star_rounded : Icons.star_border_rounded,
                            size: 14,
                            color: place.rating > 0
                                ? AppPalette.heroOchre
                                : AppTheme.textSecondary(context),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            place.rating > 0 ? place.rating.toStringAsFixed(1) : 'No reviews',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary(context),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '•  ${place.category}',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AppTheme.textSecondary(context),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (isBookmarkTab)
                  IconButton(
                    icon: const Icon(Icons.bookmark_remove_rounded, color: AppPalette.error, size: 20),
                    tooltip: 'Remove bookmark',
                    onPressed: () async {
                      HapticFeedback.mediumImpact();
                      await UserPreferenceService.toggleBookmark(place.id);
                      setState(() {});
                    },
                  ),
                if (isItineraryTab)
                  IconButton(
                    icon: const Icon(Icons.playlist_remove_rounded, color: AppPalette.error, size: 22),
                    tooltip: 'Remove from list',
                    onPressed: () async {
                      HapticFeedback.mediumImpact();
                      await UserPreferenceService.toggleItinerary(place.id);
                      setState(() {});
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppPalette.sigiriyaOchre.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: AppPalette.sigiriyaOchre),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary(context),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppTheme.textSecondary(context),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.compass_calibration_rounded, size: 18),
              label: const Text('Explore Hidden Gems'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppPalette.sigiriyaOchre,
                foregroundColor: AppTheme.colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
