import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hidden_gems_sl/l10n/app_localizations.dart';
import '../../core/config/app_config.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/oracle_ui_system.dart';
import '../../core/utils/secure_logger.dart';
import '../../data/datasources/trip_cache_service.dart';
import '../../data/datasources/auth_service.dart';
import '../../data/datasources/weather_service.dart';
import '../widgets/batik_background.dart';
import '../widgets/oracle_orb.dart';
import 'saved_places_screen.dart';
import 'trip_form_screen.dart';
import 'discovery_screen.dart';
import 'profile_screen.dart';
import 'event_calendar_screen.dart';
import 'place_details_screen.dart';
import '../../data/datasources/live_events_service.dart';
import '../../data/datasources/dynamic_content_service.dart';
import '../../data/models/event_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'savor_lanka_screen.dart';
import '../../features/ar_video/screens/ar_video_library_screen.dart';
import 'ar_coming_soon_screen.dart';
import '../widgets/banner_ad_widget.dart';
import '../widgets/native_ad_widget.dart';
import '../../data/models/discovery_place.dart';
import '../../data/repositories/discovery_repository.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../widgets/cached_image.dart';
import 'marketplace_results_screen.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'map_explorer_screen.dart';
import 'emergency_kit_screen.dart';
import '../../core/services/disaster_alert_service.dart';
import 'heritage_passport_screen.dart';
import 'family_share_screen.dart';
import 'budget_tracker_screen.dart';
import 'budget_concierge_screen.dart';
import '../../core/services/weather_localization_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final bool isOffline;
  const HomeScreen({super.key, this.isOffline = false});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0; // For bottom navigation
  String?
      _discoveryCategoryFilter; // Pending category tapped from "Explore by Category"

  List<EventModel> _todayEvents = [];
  bool _showEventBanner = true;
  List<DiscoveryPlace> _localGems = [];
  WeatherSnapshot? _weather;
  bool _showNearbyNowBanner = true;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  List<DiscoveryPlace> get _searchResults {
    if (_searchQuery.trim().isEmpty) return [];
    final q = _searchQuery.trim().toLowerCase();
    return _localGems
        .where((p) => p.name.toLowerCase().contains(q))
        .take(5)
        .toList();
  }

  void _openPlace(DiscoveryPlace place) {
    Haptics.medium();
    FocusScope.of(context).unfocus();
    setState(() {
      _searchController.clear();
      _searchQuery = "";
    });
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => PlaceDetailsScreen(place: place)));
  }

  void _onSearchSubmitted(String query) {
    if (_searchResults.isNotEmpty) {
      _openPlace(_searchResults.first);
    } else if (query.trim().isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                AppLocalizations.of(context)!.noPlaceFoundMatching(query))),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _checkTodayEvents();
    _loadLocalGems();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  Future<void> _loadLocalGems() async {
    try {
      final repo = ref.read(discoveryRepositoryProvider);
      // Without a user position, getDiscoveryPlaces() skips its
      // distance-sort step entirely and returns places in raw backend
      // order — so "Local Gems Nearby" and the Featured card (which uses
      // _localGems.first) were effectively showing a random place instead
      // of the closest one.
      Position? position;
      try {
        position =
            await repo.getCurrentLocation().timeout(const Duration(seconds: 8));
      } catch (_) {
        // Location unavailable/denied — fall through with unsorted places
        // rather than blocking the home screen on a permission prompt.
      }
      final result = await repo.getDiscoveryPlaces(
          userLat: position?.latitude, userLng: position?.longitude);
      if (mounted) {
        setState(() {
          _localGems = result.valueOrNull ?? [];
        });
      }
      if (position != null) {
        _loadWeather(position.latitude, position.longitude);
      }
    } catch (e) {
      SecureLogger.error("Failed to load local gems in HomeScreen: $e");
      if (mounted) {
        setState(() {
          _localGems = [];
        });
      }
    }
  }

  Future<void> _loadWeather(double lat, double lng) async {
    final snapshot = await WeatherService.getCurrentWeather(lat: lat, lng: lng);
    if (mounted && snapshot != null) {
      setState(() => _weather = snapshot);
    }
  }

  // Maps OpenWeatherMap's icon codes (https://openweathermap.org/weather-conditions)
  // to a Material icon — the numeric prefix identifies the condition group,
  // "d"/"n" suffix (day/night) is ignored since we only need the general look.
  IconData _weatherIcon(String owmCode) {
    final group =
        owmCode.isNotEmpty ? owmCode.substring(0, owmCode.length - 1) : '';
    switch (group) {
      case '01':
        return Icons.wb_sunny_rounded;
      case '02':
      case '03':
      case '04':
        return Icons.cloud_rounded;
      case '09':
      case '10':
        return Icons.water_drop_rounded;
      case '11':
        return Icons.thunderstorm_rounded;
      case '13':
        return Icons.ac_unit_rounded;
      case '50':
        return Icons.foggy;
      default:
        return Icons.wb_cloudy_rounded;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _checkTodayEvents() async {
    final dynamicEvents = await DynamicContentService.fetchEvents();
    final events =
        LiveEventsService.getTodayEvents(dynamicEvents: dynamicEvents);
    if (events.isNotEmpty && mounted) {
      setState(() {
        _todayEvents = events;
      });
    }
  }

  Future<void> _handleRefresh() async {
    HapticFeedback.mediumImpact();
    if (mounted) {
      // BUG-6 FIX: Also reload place cards on pull-to-refresh.
      // Previously only events were refreshed — the Featured Destination
      // card and local gems list remained stale after a pull-to-refresh.
      _checkTodayEvents();
      await _loadLocalGems();
    }
  }

  Widget _buildFeaturedDestinationCard(AppLocalizations l10n) {
    final hasGem = _localGems.isNotEmpty;
    final String name =
        hasGem ? _localGems.first.name : "Sigiriya Ancient Fortress";
    final String district = hasGem ? _localGems.first.district : "Matale";
    final String imageUrl = hasGem
        ? _localGems.first.imageUrl
        : "https://images.unsplash.com/photo-1588598130782-690a298573ec?q=80&w=600&auto=format&fit=crop";

    return SizedBox(
      height: 286,
      width: double.infinity,
      child: OracleUI.kineticCard(
        context: context,
        isEvening: false,
        opacity: 0.0,
        child: ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(28)),
          child: Stack(
            children: [
              Positioned.fill(
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  memCacheWidth: 600,
                  memCacheHeight: 400,
                  errorWidget: (c, u, e) => Container(
                    color: AppPalette.earth,
                    child: Icon(Icons.terrain_rounded,
                        color: AppTheme.colors.white24, size: 48),
                  ),
                  placeholder: (c, u) =>
                      Container(color: AppTheme.colors.black26),
                ),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppTheme.colors.black.withValues(alpha: 0.2),
                        AppTheme.colors.black.withValues(alpha: 0.75),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .secondary
                            .withValues(alpha: 0.8),
                        borderRadius:
                            const BorderRadius.all(Radius.circular(100)),
                      ),
                      child: Text(
                        l10n.featuredLabel,
                        style: GoogleFonts.inter(
                          color: AppTheme.colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      name,
                      style: GoogleFonts.outfit(
                        color: AppTheme.colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.location_on_rounded,
                            color: AppTheme.colors.white70, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          district,
                          style: GoogleFonts.inter(
                            color: AppTheme.colors.white70,
                            fontSize: 11,
                          ),
                        ),
                        const Spacer(),
                        ElevatedButton(
                          onPressed: () {
                            Haptics.medium();
                            if (hasGem) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PlaceDetailsScreen(
                                      place: _localGems.first),
                                ),
                              );
                            } else {
                              setState(() => _selectedIndex = 1);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.colors.white,
                            foregroundColor: AppTheme.colors.black,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            shape: const RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(100))),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                l10n.exploreLabel,
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.arrow_forward_rounded, size: 12),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDisasterHazardAlertBanner(AppLocalizations l10n) {
    final place = _localGems.isNotEmpty ? _localGems.first : null;
    // Do not infer a live disaster alert from a place's static rain-sensitivity
    // text.  Alerts require an actual weather observation or an admin alert.
    final liveCondition = _weather?.condition;
    if (liveCondition == null || liveCondition.trim().isEmpty) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.surfaceMuted(context),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(Icons.cloud_off_rounded, size: 17, color: AppTheme.textSecondary(context)),
            const SizedBox(width: 8),
            Expanded(child: Text('Live hazard data unavailable', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary(context)))),
          ],
        ),
      );
    }
    final hazard = DisasterAlertService.instance.evaluateLocationHazard(
      district: place?.district,
      locationTitle: place?.name ?? '',
      weatherCondition: liveCondition,
    );

    if (hazard == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: hazard.badgeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: hazard.badgeColor.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: hazard.badgeColor.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.warning_amber_rounded,
                color: hazard.badgeColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hazard.title,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: hazard.badgeColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  hazard.subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppTheme.textSecondary(context),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  '${hazard.source} · ${hazard.updatedAt == null ? 'Live check' : 'Updated ${hazard.updatedAt}'}${hazard.expiresAt == null ? '' : ' · Expires ${hazard.expiresAt}'}',
                  style: GoogleFonts.inter(fontSize: 9, color: AppTheme.textSecondary(context)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EmergencyKitScreen()),
              );
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              backgroundColor: hazard.badgeColor.withValues(alpha: 0.15),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              l10n.safetyActionLabel,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: hazard.badgeColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsRow(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Explore
            Expanded(
              child: _buildQuickActionItem(
                l10n.exploreNavLabel,
                Icons.travel_explore_rounded,
                AppTheme.colors.teal,
                () {
                  Haptics.medium();
                  setState(() => _selectedIndex = 1);
                },
              ),
            ),
            // 2. Plan Trip
            Expanded(
              child: _buildQuickActionItem(
                l10n.planTripAction,
                Icons.route_rounded,
                AppPalette.sigiriyaOchre,
                () {
                  Haptics.medium();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TripFormScreen(),
                    ),
                  );
                },
              ),
            ),
            // 3. Map
            Expanded(
              child: _buildQuickActionItem(
                l10n.mapActionLabel,
                Icons.map_rounded,
                const Color(0xFF29B6F6),
                () {
                  Haptics.medium();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MapExplorerScreen(
                        initialPosition: LatLng(6.9271, 79.8612),
                      ),
                    ),
                  );
                },
              ),
            ),
            // 4. Safety
            Expanded(
              child: _buildQuickActionItem(
                l10n.safetyActionLabel,
                Icons.health_and_safety_rounded,
                AppPalette.error,
                () {
                  Haptics.medium();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EmergencyKitScreen(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        _buildMoreToolsBanner(l10n),
      ],
    );
  }

  Widget _buildMoreToolsBanner(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Material(
        color: AppTheme.surfaceMuted(context),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            Haptics.medium();
            _showMoreToolsSheet(context, l10n);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.moreToolsTitle,
                        style: GoogleFonts.outfit(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary(context),
                        ),
                      ),
                      Text(
                        l10n.moreToolsSubtitle,
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          color: AppTheme.textSecondary(context),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 13,
                  color: AppTheme.textSecondary(context).withValues(alpha: 0.6),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openBudgetTool() {
    final trips = TripCacheService.getAllTrips();
    if (trips.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BudgetTrackerScreen(plan: trips.first),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const BudgetConciergeScreen(),
        ),
      );
    }
  }

  void _showMoreToolsSheet(BuildContext context, AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(
              color: AppTheme.primaryBorder(context),
              width: 1.5,
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color:
                        AppTheme.textSecondary(context).withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.moreToolsTitle,
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary(context),
                          ),
                        ),
                        Text(
                          l10n.moreToolsSubtitle,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppTheme.textSecondary(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 2.1,
                children: [
                  _moreToolItem(
                    title: l10n.foodAiAction,
                    subtitle: "Savor Lanka AI",
                    icon: Icons.ramen_dining_rounded,
                    color: AppTheme.colors.orangeAccent,
                    onTap: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SavorLankaScreen()),
                      );
                    },
                  ),
                  _moreToolItem(
                    title: l10n.arPortalsAction,
                    subtitle: "Immersive 3D/Video",
                    icon: Icons.view_in_ar_rounded,
                    color: AppTheme.colors.indigoAccent,
                    onTap: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AppConfig.arFeatureEnabled
                              ? const ARVideoLibraryScreen()
                              : ARComingSoonScreen(
                                  placeName: l10n.arPortalsAction),
                        ),
                      );
                    },
                  ),
                  _moreToolItem(
                    title: l10n.heritagePassport,
                    subtitle: "Digital Collectibles",
                    icon: Icons.workspace_premium_outlined,
                    color: AppPalette.heroOchre,
                    onTap: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const HeritagePassportScreen()),
                      );
                    },
                  ),
                  _moreToolItem(
                    title: l10n.familyShareTitle,
                    subtitle: "Live Explorer Tracking",
                    icon: Icons.family_restroom_rounded,
                    color: const Color(0xFF4CAF50),
                    onTap: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const FamilyShareScreen()),
                      );
                    },
                  ),
                  _moreToolItem(
                    title: l10n.aiBudgetConcierge,
                    subtitle: "Expense Management",
                    icon: Icons.account_balance_wallet_outlined,
                    color: AppPalette.rust,
                    onTap: () {
                      Navigator.pop(ctx);
                      _openBudgetTool();
                    },
                  ),
                  _moreToolItem(
                    title: l10n.findGuideAction,
                    subtitle: "Licensed Experts",
                    icon: Icons.person_pin_circle_rounded,
                    color: AppTheme.colors.amber,
                    onTap: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const MarketplaceResultsScreen()),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _moreToolItem({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppTheme.surfaceMuted(context),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.primaryBorder(context)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.outfit(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary(context),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 9.5,
                        color: AppTheme.textSecondary(context),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionItem(
      String label, IconData icon, Color color, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      button: true,
      label: label,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Material(
          color: color.withValues(alpha: isDark ? 0.18 : 0.11),
          borderRadius: BorderRadius.circular(22),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(22),
            child: SizedBox(
              height: 104,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 14, 8, 10),
                child: Column(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            color.withValues(alpha: isDark ? 0.34 : 0.24),
                            color.withValues(alpha: isDark ? 0.14 : 0.08),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: color.withValues(alpha: isDark ? 0.38 : 0.24),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:
                                color.withValues(alpha: isDark ? 0.22 : 0.14),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(icon, color: color, size: 25),
                          Positioned(
                            top: 7,
                            right: 7,
                            child: Container(
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.75),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 9),
                    Expanded(
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          height: 1.15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHomeContent(AppLocalizations l10n, bool isOffline) {
    return Stack(
      children: [
        BatikBackground(
          child: RefreshIndicator(
            onRefresh: _handleRefresh,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            color: Theme.of(context).colorScheme.primary,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics()),
              slivers: [
                _buildAppBar(context),
                SliverToBoxAdapter(
                  child: AnimationLimiter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 18, 16, 112),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: AnimationConfiguration.toStaggeredList(
                          duration: const Duration(milliseconds: 800),
                          childAnimationBuilder: (widget) => FadeInAnimation(
                            child: SlideAnimation(
                              verticalOffset: 30.0,
                              child: widget,
                            ),
                          ),
                          children: [
                            _buildFeaturedDestinationCard(l10n),
                            const SizedBox(height: 16),
                            _buildDisasterHazardAlertBanner(l10n),
                            if (_localGems.isNotEmpty &&
                                _showNearbyNowBanner &&
                                _localGems.first.distanceKm > 0 &&
                                _localGems.first.distanceKm < 100) ...[
                              _buildNearbyNowBanner(l10n),
                              const SizedBox(height: 24),
                            ],
                            _buildQuickActionsRow(l10n),
                            const SizedBox(height: 28),
                            if (_todayEvents.isNotEmpty &&
                                _showEventBanner) ...[
                              _buildTodayEventBanner(l10n),
                              const SizedBox(height: 24),
                            ],
                            if (isOffline || _localGems.isNotEmpty) ...[
                              _buildSectionHeader(isOffline
                                  ? l10n.localGemsOffline
                                  : l10n.localGemsNearby),
                              const SizedBox(height: 16),
                              _buildLocalGemsScroller(context),
                              const SizedBox(height: 24),
                            ],
                            _buildCategoriesGrid(l10n),
                            const SizedBox(height: 32),
                            const NativeAdWidget(),
                            const SizedBox(height: 32),
                            _buildSectionHeader(l10n.oraclesChoice),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildRecentPlansList(context, l10n),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (isOffline) _buildOfflineBadge(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isOffline = widget.isOffline;
    return Scaffold(
      extendBody: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildHomeContent(l10n, isOffline),
          DiscoveryScreen(
              key: ValueKey('discovery_$_discoveryCategoryFilter'),
              initialFilter: _discoveryCategoryFilter),
          const EventCalendarScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const BannerAdWidget(),
          _buildBottomNav(context, l10n),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: const OracleOrb(),
    );
  }

  Widget _buildNearbyNowBanner(AppLocalizations l10n) {
    final place = _localGems.first;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => PlaceDetailsScreen(place: place)));
      },
      child: OracleUI.glassContainer(
        padding: const EdgeInsets.all(16),
        radius: const BorderRadius.all(Radius.circular(24)),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .secondary
                    .withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.near_me_rounded,
                  color: Theme.of(context).colorScheme.secondary, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.nearbyNowLabel(place.distanceKm.toStringAsFixed(1)),
                    style: GoogleFonts.inter(
                      color: AppTheme.textSecondary(context),
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    place.name,
                    style: GoogleFonts.outfit(
                      color: AppTheme.textPrimary(context),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _showNearbyNowBanner = false);
              },
              child: Icon(Icons.close_rounded,
                  color: AppTheme.textSecondary(context), size: 18),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayEventBanner(AppLocalizations l10n) {
    final event = _todayEvents.first;
    return OracleUI.glassContainer(
      padding: const EdgeInsets.all(20),
      radius: const BorderRadius.all(Radius.circular(24)),
      showGlow: true,
      child: Stack(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.celebration,
                    color: Theme.of(context).colorScheme.primary, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.todayInSriLanka,
                      style: GoogleFonts.inter(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      event.name,
                      style: GoogleFonts.outfit(
                        color: AppTheme.textPrimary(context),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (event.description.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          event.description,
                          style: GoogleFonts.inter(
                            color: AppTheme.textSecondary(context),
                            fontSize: 12,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    if (event.location != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          (event.location ?? "SRI LANKA").toUpperCase(),
                          style: GoogleFonts.inter(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.7),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            top: -10,
            right: -10,
            child: IconButton(
              icon: Icon(Icons.close,
                  color: AppTheme.textSecondary(context).withValues(alpha: 0.5),
                  size: 16),
              onPressed: () {
                setState(() => _showEventBanner = false);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = widget.isOffline
        ? null
        : (ref.watch(authStateProvider).value ??
            FirebaseAuth.instance.currentUser);
    final name = user?.displayName?.split(' ').first ?? l10n.travelerFallback;
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      stretch: true,
      backgroundColor: AppTheme.colors.transparent,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [
          StretchMode.zoomBackground,
          StretchMode.blurBackground
        ],
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.secondary,
                    Theme.of(context).scaffoldBackgroundColor,
                  ],
                  stops: const [0.0, 0.4, 1.0],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            Positioned.fill(
              child: const RepaintBoundary(
                child: BatikBackground(
                  opacity: 0.03,
                  child: SizedBox.expand(),
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 42),
                  Text(
                    l10n.ayubowanGreeting(name),
                    style: GoogleFonts.outfit(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.letOracleGuide,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.colors.white.withValues(alpha: 0.75),
                    ),
                  ),
                  if (_weather != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_weatherIcon(_weather!.iconCode),
                              color: AppTheme.colors.white, size: 15),
                          const SizedBox(width: 6),
                          Text(
                            "${_weather!.tempC.round()}\u00B0C \u00B7 ${WeatherLocalizationService.getLocalizedCondition(context, _weather!.condition)}",
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (WeatherLocalizationService.isSevereWeather(
                        _weather!.condition)) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 7),
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          color: AppTheme.colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color:
                                  AppTheme.colors.white.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.thunderstorm_rounded,
                                size: 15, color: Colors.amberAccent),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                WeatherLocalizationService
                                        .getSevereWeatherAdvisory(
                                            context, _weather!.condition) ??
                                    '',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        OracleUI.premiumGlassCard(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 7),
                          radius: const BorderRadius.all(Radius.circular(40)),
                          child: Row(
                            children: [
                              Icon(Icons.search_rounded,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  textInputAction: TextInputAction.search,
                                  onChanged: (v) =>
                                      setState(() => _searchQuery = v),
                                  onSubmitted: _onSearchSubmitted,
                                  style: GoogleFonts.inter(
                                    color: AppTheme.textPrimary(context),
                                    fontSize: 13,
                                  ),
                                  decoration: InputDecoration(
                                    isDense: true,
                                    border: InputBorder.none,
                                    hintText: l10n.searchSecretLocations,
                                    hintStyle: GoogleFonts.inter(
                                      color: AppTheme.textSecondary(context)
                                          .withValues(alpha: 0.6),
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                              if (_searchQuery.isNotEmpty)
                                GestureDetector(
                                  onTap: () => setState(() {
                                    _searchController.clear();
                                    _searchQuery = "";
                                  }),
                                  child: Icon(Icons.close_rounded,
                                      color: AppTheme.textSecondary(context),
                                      size: 18),
                                ),
                            ],
                          ),
                        ),
                        if (_searchQuery.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: OracleUI.premiumGlassCard(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              radius:
                                  const BorderRadius.all(Radius.circular(20)),
                              child: _searchResults.isEmpty
                                  ? Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 12),
                                      child: Text(
                                        l10n.noPlaceFoundMatching(_searchQuery),
                                        style: GoogleFonts.inter(
                                            color:
                                                AppTheme.textSecondary(context),
                                            fontSize: 12),
                                      ),
                                    )
                                  : Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: _searchResults
                                          .map((place) => InkWell(
                                                onTap: () => _openPlace(place),
                                                child: Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 16,
                                                      vertical: 10),
                                                  child: Row(
                                                    children: [
                                                      Icon(Icons.place_rounded,
                                                          size: 16,
                                                          color:
                                                              Theme.of(context)
                                                                  .colorScheme
                                                                  .primary),
                                                      const SizedBox(width: 10),
                                                      Expanded(
                                                        child: Text(
                                                          place.name,
                                                          style:
                                                              GoogleFonts.inter(
                                                            color: AppTheme
                                                                .textPrimary(
                                                                    context),
                                                            fontSize: 13,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ))
                                          .toList(),
                                    ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        if (user != null)
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: OracleUI.glassContainer(
              padding: EdgeInsets.zero,
              radius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => setState(() => _selectedIndex = 3),
                child: SizedBox(
                  width: 36,
                  height: 36,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: (user.photoURL != null && user.photoURL!.isNotEmpty)
                        ? CachedImage(
                            url: user.photoURL!,
                            fit: BoxFit.cover,
                            width: 36,
                            height: 36,
                            errorWidget: Icon(Icons.person_rounded,
                                color: AppTheme.textPrimary(context), size: 20),
                          )
                        : Icon(Icons.person_rounded,
                            color: AppTheme.textPrimary(context), size: 20),
                  ),
                ),
              ),
            ),
          )
        else
          _glassActionIcon(Icons.person_outline, l10n.profile, () {
            setState(() => _selectedIndex = 3);
          }),
        _glassActionIcon(
            Icons.bookmark_border_rounded, l10n.savedPlacesHubTitle, () {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const SavedPlacesScreen()));
        }),
        _glassActionIcon(Icons.camera_enhance_outlined, l10n.foodScannerTooltip,
            () {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const SavorLankaScreen()));
        }),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildOfflineBadge() {
    return Positioned(
      top: 60,
      right: 20,
      child: OracleUI.glassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        radius: const BorderRadius.all(Radius.circular(20)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded,
                color: AppTheme.colors.redAccent, size: 14),
            const SizedBox(width: 6),
            Text(
              AppLocalizations.of(context)!.offlineModeLabel,
              style: GoogleFonts.outfit(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.colors.redAccent),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: AppTheme.textPrimary(context),
          letterSpacing: -0.3,
        ),
      ),
    );
  }

  Widget _buildCategoriesGrid(AppLocalizations l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Label -> the matching DiscoveryScreen filter key (see discovery_screen.dart's _filters/_applyFilter).
    final List<(String, IconData, List<Color>, String)> categories = [
      (
        l10n.categoryNatureLabel,
        Icons.forest_rounded,
        isDark
            ? [const Color(0xFF17382F), const Color(0xFF10241F)]
            : [const Color(0xFFE9F5EC), const Color(0xFFD7ECDE)],
        "nature"
      ),
      (
        l10n.categoryBeachesLabel,
        Icons.waves_rounded,
        isDark
            ? [const Color(0xFF174552), const Color(0xFF102D37)]
            : [const Color(0xFFE4F4F7), const Color(0xFFCFEAF0)],
        "coastal"
      ),
      (
        l10n.categoryCultureLabel,
        Icons.account_balance_rounded,
        isDark
            ? [const Color(0xFF522A20), const Color(0xFF321C17)]
            : [const Color(0xFFFFEEE7), const Color(0xFFF8D9CC)],
        "culture"
      ),
      (
        l10n.categoryAdventureLabel,
        Icons.hiking_rounded,
        isDark
            ? [const Color(0xFF534019), const Color(0xFF332811)]
            : [const Color(0xFFFFF4D7), const Color(0xFFF6E1A9)],
        "hiking"
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(l10n.exploreByCategory),
        const SizedBox(height: 16),
        GridView.builder(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.3,
          ),
          itemCount: categories.length,
          itemBuilder: (context, i) {
            final cat = categories[i];
            final accent = switch (i) {
              0 => const Color(0xFF4E9A72),
              1 => const Color(0xFF3D96AA),
              2 => const Color(0xFFD46A43),
              _ => const Color(0xFFD6A52B),
            };
            return Semantics(
              button: true,
              label: cat.$1,
              child: Material(
                color: AppTheme.colors.transparent,
                child: InkWell(
                  onTap: () {
                    Haptics.light();
                    setState(() {
                      _discoveryCategoryFilter = cat.$4;
                      _selectedIndex = 1;
                    });
                  },
                  borderRadius: BorderRadius.circular(24),
                  child: Ink(
                    padding: const EdgeInsets.fromLTRB(16, 15, 14, 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: LinearGradient(
                        colors: cat.$3,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(
                        color: accent.withValues(alpha: isDark ? 0.28 : 0.20),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: accent.withValues(alpha: isDark ? 0.10 : 0.12),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          right: -12,
                          bottom: -18,
                          child: Icon(
                            cat.$2,
                            size: 92,
                            color:
                                accent.withValues(alpha: isDark ? 0.09 : 0.10),
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: accent.withValues(
                                        alpha: isDark ? 0.20 : 0.16),
                                    borderRadius: BorderRadius.circular(13),
                                    border: Border.all(
                                        color: accent.withValues(alpha: 0.22)),
                                  ),
                                  alignment: Alignment.center,
                                  child: Icon(cat.$2, color: accent, size: 21),
                                ),
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: (isDark
                                            ? AppTheme.colors.white
                                            : AppTheme.colors.black)
                                        .withValues(alpha: 0.06),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.arrow_outward_rounded,
                                      size: 15,
                                      color: AppTheme.textSecondary(context)),
                                ),
                              ],
                            ),
                            Text(
                              cat.$1,
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.1,
                                color: AppTheme.textPrimary(context),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRecentPlansList(BuildContext context, AppLocalizations l10n) {
    final cachedTrips = TripCacheService.getAllTrips();
    if (cachedTrips.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(l10n.recentPlans),
        const SizedBox(height: 16),
        ...cachedTrips.take(3).map((trip) => _buildPlanCard(
              context,
              trip.destination,
              trip.humanText,
              l10n.daysLabel(trip.itinerary.length),
            )),
      ],
    );
  }

  Widget _buildPlanCard(
      BuildContext context, String title, String desc, String duration) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      height: 160,
      child: OracleUI.kineticCard(
        context: context,
        isEvening: false,
        opacity:
            0.0, // Kinetic card adds its own container, we just use it for the press animation
        child: OracleUI.premiumGlassCard(
          padding: EdgeInsets.zero,
          radius: BorderRadius.circular(24),
          child: Stack(
            children: [
              Positioned.fill(
                child: Opacity(
                  opacity: 0.4,
                  child: CachedImage(
                    url:
                        "https://images.unsplash.com/photo-1546708973-b339540b5162?q=80&w=2670&auto=format&fit=crop",
                    fit: BoxFit.cover,
                    maxWidthDiskCache: 300,
                  ),
                ),
              ),
              RepaintBoundary(
                child: BatikBackground(
                  opacity: 0.04,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppTheme.colors.orange.withValues(alpha: 0.05),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(title.toUpperCase(),
                                  style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: AppTheme.colors.white,
                                      letterSpacing: 1)),
                              const SizedBox(height: 4),
                              Text(desc,
                                  style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: AppTheme.colors.white70),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                        OracleUI.glassContainer(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          radius: BorderRadius.circular(12),
                          child: Text(duration,
                              style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.colors.white,
                                  fontSize: 10)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _glassActionIcon(
      IconData icon, String semanticLabel, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: OracleUI.glassContainer(
        padding: EdgeInsets.zero,
        radius: BorderRadius.circular(12),
        child: IconButton(
          tooltip: semanticLabel,
          icon: Icon(icon, color: AppTheme.textPrimary(context), size: 20),
          onPressed: onTap,
        ),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context, AppLocalizations l10n) {
    final textScaleFactor = MediaQuery.textScalerOf(context).scale(1.0);
    final double dynamicHeight = (70 * textScaleFactor).clamp(70.0, 120.0);
    final double centerGap =
        (MediaQuery.sizeOf(context).width * 0.16).clamp(44.0, 60.0).toDouble();

    return BottomAppBar(
      color: AppTheme.colors.transparent,
      elevation: 0,
      padding: EdgeInsets.zero,
      notchMargin: 10,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        child: Container(
          height: dynamicHeight,
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppPaletteDark.card
                : AppTheme.colors.white,
            borderRadius: BorderRadius.circular(100),
            border: Theme.of(context).brightness == Brightness.dark
                ? Border.all(
                    color: AppTheme.colors.white.withValues(alpha: 0.07))
                : null,
            boxShadow: [
              BoxShadow(
                color: AppTheme.colors.black.withValues(alpha: 0.14),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(child: _navItem(l10n.home, Icons.home_rounded, 0)),
              Expanded(
                  child: _navItem(
                      l10n.exploreNavLabel, Icons.travel_explore_rounded, 1)),
              SizedBox(width: centerGap),
              Expanded(
                  child: _navItem(
                      l10n.eventsNavLabel, Icons.calendar_month_rounded, 2)),
              Expanded(child: _navItem(l10n.profile, Icons.person_rounded, 3)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(String label, IconData icon, int index) {
    final bool active = _selectedIndex == index;
    return Semantics(
      button: true,
      selected: active,
      label: label,
      child: Tooltip(
        message: label,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            HapticFeedback.lightImpact();
            setState(() => _selectedIndex = index);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: active
                      ? Theme.of(context).colorScheme.primary
                      : AppTheme.textSecondary(context).withValues(alpha: 0.5),
                  size: 24,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: active
                        ? Theme.of(context).colorScheme.primary
                        : AppTheme.textSecondary(context)
                            .withValues(alpha: 0.4),
                    fontSize: 10,
                    fontWeight: active ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLocalGemsScroller(BuildContext context) {
    if (_localGems.isEmpty) {
      return SizedBox(
        height: 140,
        child: Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      );
    }

    return SizedBox(
      height: 218,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _localGems.length,
        itemBuilder: (context, i) {
          final gem = _localGems[i];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PlaceDetailsScreen(place: gem),
                ),
              );
            },
            child: Container(
              width: 184,
              margin: const EdgeInsets.only(right: 16),
              child: OracleUI.glassContainer(
                padding: EdgeInsets.zero,
                radius: BorderRadius.circular(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(24)),
                      child: CachedImage(
                        url: gem.imageUrl,
                        width: double.infinity,
                        height: 126,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(gem.name.toUpperCase(),
                              style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary(context)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(Icons.location_on_rounded,
                                  size: 11,
                                  color: Theme.of(context).colorScheme.primary),
                              const SizedBox(width: 3),
                              Expanded(
                                child: Text(gem.district,
                                    style: GoogleFonts.inter(
                                        fontSize: 9,
                                        color: AppTheme.textSecondary(context)),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
