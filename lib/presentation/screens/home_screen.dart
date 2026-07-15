import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hidden_gems_sl/l10n/app_localizations.dart';
import 'package:hidden_gems_sl/presentation/screens/real_time_food_scanner_screen.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/oracle_ui_system.dart';
import '../../core/utils/secure_logger.dart';
import '../../data/datasources/trip_cache_service.dart';
import '../../data/datasources/auth_service.dart';
import '../widgets/batik_background.dart';
import '../widgets/oracle_orb.dart';
import 'saved_plans_screen.dart';
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
import '../widgets/banner_ad_widget.dart';
import '../widgets/native_ad_widget.dart';
import '../../data/models/discovery_place.dart';
import '../../data/repositories/discovery_repository.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../widgets/cached_image.dart';
import 'marketplace_results_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final bool isOffline;
  const HomeScreen({super.key, this.isOffline = false});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0; // For bottom navigation
  String? _discoveryCategoryFilter; // Pending category tapped from "Explore by Category"

  List<EventModel> _todayEvents = [];
  bool _showEventBanner = true;
  List<DiscoveryPlace> _localGems = [];

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  List<DiscoveryPlace> get _searchResults {
    if (_searchQuery.trim().isEmpty) return [];
    final q = _searchQuery.trim().toLowerCase();
    return _localGems.where((p) => p.name.toLowerCase().contains(q)).take(5).toList();
  }

  void _openPlace(DiscoveryPlace place) {
    Haptics.medium();
    FocusScope.of(context).unfocus();
    setState(() {
      _searchController.clear();
      _searchQuery = "";
    });
    Navigator.push(context, MaterialPageRoute(builder: (_) => PlaceDetailsScreen(place: place)));
  }

  void _onSearchSubmitted(String query) {
    if (_searchResults.isNotEmpty) {
      _openPlace(_searchResults.first);
    } else if (query.trim().isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.noPlaceFoundMatching(query))),
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
      final result = await repo.getDiscoveryPlaces();
      if (mounted) {
        setState(() {
          _localGems = result.valueOrNull ?? [];
        });
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _checkTodayEvents() async {
    final dynamicEvents = await DynamicContentService.fetchEvents();
    final events = LiveEventsService.getTodayEvents(dynamicEvents: dynamicEvents);
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
    final String name = hasGem ? _localGems.first.name : "Sigiriya Ancient Fortress";
    final String district = hasGem ? _localGems.first.district : "Matale";
    final String imageUrl = hasGem ? _localGems.first.imageUrl : "https://images.unsplash.com/photo-1588598130782-690a298573ec?q=80&w=600&auto=format&fit=crop";
    final double rating = hasGem ? _localGems.first.rating : 4.9;

    return SizedBox(
      height: 220,
      width: double.infinity,
      child: OracleUI.kineticCard(
        context: context,
        isEvening: false,
        opacity: 0.0,
        child: ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(24)),
          child: Stack(
            children: [
              Positioned.fill(
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  memCacheWidth: 600,
                  memCacheHeight: 400,
                  errorWidget: (c, u, e) => Image.asset("assets/images/sigiriya_sunset_bg.jpg", fit: BoxFit.cover),
                  placeholder: (c, u) => Container(color: AppTheme.colors.black26),
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
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.8),
                            borderRadius: const BorderRadius.all(Radius.circular(12)),
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
                        Row(
                          children: [
                            Icon(Icons.star_rounded, color: AppTheme.colors.orangeAccent, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              rating.toString(),
                              style: GoogleFonts.inter(
                                color: AppTheme.colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      name,
                      style: GoogleFonts.outfit(
                        color: AppTheme.colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on_rounded, color: AppTheme.colors.white70, size: 14),
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
                                  builder: (context) => PlaceDetailsScreen(place: _localGems.first),
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
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(100))),
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

  Widget _buildQuickActionsRow(AppLocalizations l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildQuickActionItem(
          l10n.planTripAction,
          Icons.edit_calendar_outlined,
          AppTheme.colors.teal,
          () {
            Haptics.medium();
            Navigator.push(context, MaterialPageRoute(builder: (context) => const TripFormScreen()));
          },
        ),
        _buildQuickActionItem(
          l10n.findGuideAction,
          Icons.person_search_outlined,
          AppTheme.colors.amber,
          () {
            Haptics.medium();
            Navigator.push(context, MaterialPageRoute(builder: (context) => const MarketplaceResultsScreen()));
          },
        ),
        _buildQuickActionItem(
          l10n.foodAiAction,
          Icons.restaurant_menu_outlined,
          AppTheme.colors.orangeAccent,
          () {
            Haptics.medium();
            Navigator.push(context, MaterialPageRoute(builder: (context) => const SavorLankaScreen()));
          },
        ),
        _buildQuickActionItem(
          l10n.arPortalsAction,
          Icons.view_in_ar_rounded,
          AppTheme.colors.indigoAccent,
          () {
            Haptics.medium();
            Navigator.push(context, MaterialPageRoute(builder: (context) => const ARVideoLibraryScreen()));
          },
        ),
      ],
    );
  }

  Widget _buildQuickActionItem(String label, IconData icon, Color color, VoidCallback onTap) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.16 : 0.1),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary(context),
          ),
        ),
      ],
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
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              slivers: [
                _buildAppBar(context),
                SliverToBoxAdapter(
                  child: AnimationLimiter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
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
                            _journalUnfold(child: _buildWelcomeCard(l10n)),
                            const SizedBox(height: 20),
                            _buildFeaturedDestinationCard(l10n),
                            const SizedBox(height: 24),
                            _buildQuickActionsRow(l10n),
                            const SizedBox(height: 32),
                            if (_todayEvents.isNotEmpty && _showEventBanner) ...[
                               _buildTodayEventBanner(l10n),
                               const SizedBox(height: 24),
                            ],
                            if (isOffline || _localGems.isNotEmpty) ...[
                              _buildSectionHeader(isOffline ? l10n.localGemsOffline : l10n.localGemsNearby),
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
          DiscoveryScreen(key: ValueKey('discovery_$_discoveryCategoryFilter'), initialFilter: _discoveryCategoryFilter),
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
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.celebration, color: Theme.of(context).colorScheme.primary, size: 24),
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
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
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
              icon: Icon(Icons.close, color: AppTheme.textSecondary(context).withValues(alpha: 0.5), size: 16),
              onPressed: () {
                setState(() => _showEventBanner = false);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _journalUnfold({required Widget child}) {
    return AnimationConfiguration.synchronized(
      duration: const Duration(milliseconds: 1000),
      child: SlideAnimation(
        verticalOffset: 50.0,
        child: FadeInAnimation(
          child: child,
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = widget.isOffline ? null : (ref.watch(authStateProvider).value ?? FirebaseAuth.instance.currentUser);
    return SliverAppBar(
      expandedHeight: 360,
      pinned: true,
      stretch: true,
      backgroundColor: AppTheme.colors.transparent,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground, StretchMode.blurBackground],
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
                    const SizedBox(height: 48),
                    Text(
                      l10n.discoverSriLanka,
                      style: GoogleFonts.outfit(
                        fontSize: 28,
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
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                      children: [
                        OracleUI.premiumGlassCard(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                          radius: const BorderRadius.all(Radius.circular(40)),
                          child: Row(
                            children: [
                              Icon(Icons.search_rounded, color: Theme.of(context).colorScheme.primary, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  textInputAction: TextInputAction.search,
                                  onChanged: (v) => setState(() => _searchQuery = v),
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
                                      color: AppTheme.textSecondary(context).withValues(alpha: 0.6),
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
                                  child: Icon(Icons.close_rounded, color: AppTheme.textSecondary(context), size: 18),
                                ),
                            ],
                          ),
                        ),
                        if (_searchQuery.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: OracleUI.premiumGlassCard(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              radius: const BorderRadius.all(Radius.circular(20)),
                              child: _searchResults.isEmpty
                                  ? Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      child: Text(
                                        l10n.noPlaceFoundMatching(_searchQuery),
                                        style: GoogleFonts.inter(color: AppTheme.textSecondary(context), fontSize: 12),
                                      ),
                                    )
                                  : Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: _searchResults.map((place) => InkWell(
                                        onTap: () => _openPlace(place),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                          child: Row(
                                            children: [
                                              Icon(Icons.place_rounded, size: 16, color: Theme.of(context).colorScheme.primary),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Text(
                                                  place.name,
                                                  style: GoogleFonts.inter(
                                                    color: AppTheme.textPrimary(context),
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      )).toList(),
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
                        ? Image.network(
                            user.photoURL!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Icon(Icons.person_rounded, color: AppTheme.textPrimary(context), size: 20),
                          )
                        : Icon(Icons.person_rounded, color: AppTheme.textPrimary(context), size: 20),
                  ),
                ),
              ),
            ),
          )
        else
          _glassActionIcon(Icons.person_outline, () {
            setState(() => _selectedIndex = 3);
          }),
        
        _glassActionIcon(Icons.bookmark_border_rounded, () {
           Navigator.push(context, MaterialPageRoute(builder: (_) => const SavedPlansScreen()));
        }),
        _glassActionIcon(Icons.camera_enhance_outlined, () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const RealTimeFoodScannerScreen()));
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
            Icon(Icons.cloud_off_rounded, color: AppTheme.colors.redAccent, size: 14),
            const SizedBox(width: 6),
            Text(
              AppLocalizations.of(context)!.offlineModeLabel,
              style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.colors.redAccent),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(AppLocalizations l10n) {
    final user = widget.isOffline ? null : (ref.watch(authStateProvider).value ?? FirebaseAuth.instance.currentUser);
    final name = user?.displayName?.split(" ").first ?? l10n.travelerFallback;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.all(Radius.circular(20)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_awesome, color: Theme.of(context).colorScheme.primary, size: 12),
                  const SizedBox(width: 6),
                  Text(
                    l10n.ayubowanGreeting(name),
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          l10n.letOracleGuide,
          style: GoogleFonts.outfit(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary(context),
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: AppTheme.textPrimary(context),
        ),
      ),
    );
  }

  Widget _buildCategoriesGrid(AppLocalizations l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Label -> the matching DiscoveryScreen filter key (see discovery_screen.dart's _filters/_applyFilter).
    final List<(String, IconData, List<Color>, String)> categories = [
      (l10n.categoryNatureLabel, Icons.forest_outlined, isDark ? [const Color(0xFF241D15), const Color(0xFF241D15)] : [const Color(0xFF557A4A), const Color(0xFF2C3D24)], "nature"),
      (l10n.categoryBeachesLabel, Icons.waves_rounded, [const Color(0xFF3A7A8A), const Color(0xFF1C3D44)], "coastal"),
      (l10n.categoryCultureLabel, Icons.temple_hindu_outlined, [Theme.of(context).colorScheme.primary, isDark ? AppPaletteDark.gemDim : AppPalette.rustDim], "culture"),
      (l10n.categoryAdventureLabel, Icons.explore_outlined, [AppPalette.heroOchre, const Color(0xFFA97A1E)], "hiking"),
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
            return GestureDetector(
              onTap: () {
                Haptics.light();
                setState(() {
                  _discoveryCategoryFilter = cat.$4;
                  _selectedIndex = 1;
                });
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    colors: cat.$3,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Theme.of(context).brightness == Brightness.dark
                      ? Border.all(color: AppTheme.colors.white.withValues(alpha: 0.06))
                      : null,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: AppTheme.colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Icon(cat.$2, color: AppTheme.colors.white, size: 18),
                    ),
                    Text(
                      cat.$1,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.colors.white,
                      ),
                    ),
                  ],
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

  Widget _buildPlanCard(BuildContext context, String title, String desc, String duration) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      height: 160,
      child: OracleUI.kineticCard(
        context: context,
        isEvening: false,
        opacity: 0.0, // Kinetic card adds its own container, we just use it for the press animation
        child: OracleUI.premiumGlassCard(
          padding: EdgeInsets.zero,
          radius: BorderRadius.circular(24),
          child: Stack(
            children: [
              Positioned.fill(
                child: Opacity(
                  opacity: 0.4,
                  child: CachedImage(
                    url: "https://images.unsplash.com/photo-1546708973-b339540b5162?q=80&w=2670&auto=format&fit=crop",
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
                            Text(
                              title.toUpperCase(), 
                              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.colors.white, letterSpacing: 1)
                            ),
                            const SizedBox(height: 4),
                            Text(desc, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.colors.white70), maxLines: 1, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                      OracleUI.glassContainer(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        radius: BorderRadius.circular(12),
                        child: Text(duration, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppTheme.colors.white, fontSize: 10)),
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

  Widget _glassActionIcon(IconData icon, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: OracleUI.glassContainer(
        padding: EdgeInsets.zero,
        radius: BorderRadius.circular(12),
        child: IconButton(
          icon: Icon(icon, color: AppTheme.textPrimary(context), size: 20),
          onPressed: onTap,
        ),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context, AppLocalizations l10n) {
    final textScaleFactor = MediaQuery.textScalerOf(context).scale(1.0);
    final double dynamicHeight = (70 * textScaleFactor).clamp(70.0, 110.0);

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
            color: Theme.of(context).brightness == Brightness.dark ? AppPaletteDark.card : AppTheme.colors.white,
            borderRadius: BorderRadius.circular(100),
            border: Theme.of(context).brightness == Brightness.dark
                ? Border.all(color: AppTheme.colors.white.withValues(alpha: 0.07))
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
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(l10n.home, Icons.home_rounded, 0),
              _navItem(l10n.exploreNavLabel, Icons.travel_explore_rounded, 1),
              const SizedBox(width: 60),
              _navItem(l10n.eventsNavLabel, Icons.calendar_month_rounded, 2),
              _navItem(l10n.profile, Icons.person_rounded, 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(String label, IconData icon, int index) {
    final bool active = _selectedIndex == index;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _selectedIndex = index);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
          Icon(
            icon,
            color: active ? Theme.of(context).colorScheme.primary : AppTheme.textSecondary(context).withValues(alpha: 0.5),
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              color: active ? Theme.of(context).colorScheme.primary : AppTheme.textSecondary(context).withValues(alpha: 0.4),
              fontSize: 10,
              fontWeight: active ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
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
      height: 140,
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
              width: 160,
              margin: const EdgeInsets.only(right: 16),
              child: OracleUI.glassContainer(
                padding: const EdgeInsets.all(16),
                radius: BorderRadius.circular(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Icon(Icons.location_on_rounded, size: 14, color: Theme.of(context).colorScheme.primary),
                        Text(gem.rating.toString(), style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.colors.orangeAccent)),
                      ],
                    ),
                    const Spacer(),
                    Text(gem.name.toUpperCase(), style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textPrimary(context)), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(gem.district, style: GoogleFonts.inter(fontSize: 9, color: AppTheme.textSecondary(context))),
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
