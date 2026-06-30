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
import '../../data/datasources/trip_cache_service.dart';
import '../widgets/batik_background.dart';
import '../widgets/dynamic_light_wrapper.dart';
import '../widgets/oracle_orb.dart';
import 'saved_plans_screen.dart';
import 'trip_form_screen.dart';
import 'discovery_screen.dart';
import 'profile_screen.dart';
import 'event_calendar_screen.dart';
import '../../data/datasources/live_events_service.dart';
import '../../data/models/event_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'guide_marketplace_screen.dart';
import 'smart_match_screen.dart';
import 'savor_lanka_screen.dart';
import '../widgets/pulse_hub_widget.dart';
import '../widgets/banner_ad_widget.dart';
import '../widgets/native_ad_widget.dart';
import '../../data/datasources/monetization_service.dart';
import '../../data/models/discovery_place.dart';
import '../../data/repositories/discovery_repository.dart';
import 'place_details_screen.dart';
import '../widgets/usage_meter_widget.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final bool isOffline;
  const HomeScreen({super.key, this.isOffline = false});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0; // For bottom navigation
  
  List<EventModel> _todayEvents = [];
  bool _showEventBanner = true;
  List<DiscoveryPlace> _localGems = [];
  
  late Timer _bgTimer;
  int _bgImageIndex = 0;
  final List<String> _bgImages = [
    "assets/images/sigiriya_sunset_bg.jpg",
    "assets/images/ella_nine_arch_bg.jpg",
    "assets/images/kandy_lake_bg.jpg",
    "assets/images/galle_fort_bg.jpg",
    "assets/images/nuwara_eliya_tea_bg.jpg",
  ];

  @override
  void initState() {
    super.initState();
    _checkTodayEvents();
    _startBgTimer();
    _loadLocalGems();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    for (final imagePath in _bgImages) {
      precacheImage(AssetImage(imagePath), context);
    }
  }

  Future<void> _loadLocalGems() async {
    try {
      final repo = ref.read(discoveryRepositoryProvider);
      final places = await repo.getDiscoveryPlaces();
      if (mounted) {
        setState(() {
          _localGems = places;
        });
      }
    } catch (e) {
      debugPrint("Error loading gems: $e");
    }
  }

  void _startBgTimer() {
    _bgTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted) {
        setState(() {
          _bgImageIndex = (_bgImageIndex + 1) % _bgImages.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _bgTimer.cancel();
    super.dispose();
  }

  void _checkTodayEvents() {
    final events = LiveEventsService.getTodayEvents();
    if (events.isNotEmpty && mounted) {
      setState(() {
        _todayEvents = events;
      });
    }
  }

  Future<void> _handleRefresh() async {
    HapticFeedback.mediumImpact();
    if (mounted) {
      _checkTodayEvents();
    }
    await Future.delayed(const Duration(milliseconds: 800));
  }

  Widget _buildMarketplaceShortcuts() {
    return Row(
      children: [
        Expanded(
          child: OracleUI.kineticCard(
            context: context,
            isEvening: false,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const GuideMarketplaceScreen())),
            child: Column(
              children: [
                Icon(Icons.storefront_outlined, color: Theme.of(context).colorScheme.primary, size: 24),
                const SizedBox(height: 8),
                Text("MARKETPLACE", style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OracleUI.kineticCard(
            context: context,
            isEvening: false,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SmartMatchScreen())),
            child: Column(
              children: [
                const Icon(Icons.auto_awesome_outlined, color: Colors.purpleAccent, size: 24),
                const SizedBox(height: 8),
                Text("SMART MATCH", style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OracleUI.kineticCard(
            context: context,
            isEvening: false,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SavorLankaScreen())),
            child: Column(
              children: [
                const Icon(Icons.restaurant_menu_outlined, color: Colors.orangeAccent, size: 24),
                const SizedBox(height: 8),
                Text("FOOD AI", style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
              ],
            ),
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
                            _journalUnfold(child: _buildWelcomeCard()),
                            const SizedBox(height: 24),
                            const UsageMeterWidget(),
                            const SizedBox(height: 24),
                            // Phase 8: Kinetic Pulse Hub (Bridge to Travel)
                            const PulseHubWidget(),
                            const SizedBox(height: 24),
                            // Plan Journey Button (Premium)
                            _buildCTAButton(l10n),
                            const SizedBox(height: 16),
                            _buildMarketplaceShortcuts(),
                            const SizedBox(height: 32),
                            if (_todayEvents.isNotEmpty && _showEventBanner) ...[
                               _buildTodayEventBanner(),
                               const SizedBox(height: 24),
                            ],
                            if (isOffline) ...[
                              _buildSectionHeader(l10n.localGemsOffline),
                              const SizedBox(height: 16),
                              _buildLocalGemsScroller(context),
                              const SizedBox(height: 16),
                            ],
                            _buildCategoriesGrid(),
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

  Widget _buildCTAButton(AppLocalizations l10n) {
    return GestureDetector(
      onTap: () {
        Haptics.medium();
        MonetizationService().showInterstitialAd();
        Navigator.push(context, MaterialPageRoute(builder: (context) => const TripFormScreen()));
      },
      child: OracleUI.premiumGlassCard(
        padding: const EdgeInsets.symmetric(vertical: 20),
        showGlow: true,
        radius: BorderRadius.circular(24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_awesome, color: Theme.of(context).colorScheme.primary, size: 24),
            const SizedBox(width: 16),
            Flexible(
              child: Text(
                l10n.planNewTrip.toUpperCase(),
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  letterSpacing: 2,
                  color: AppTheme.textPrimary(context),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
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
          const DiscoveryScreen(),
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

  Widget _buildTodayEventBanner() {
    final event = _todayEvents.first;
    return OracleUI.glassContainer(
      padding: const EdgeInsets.all(20),
      radius: BorderRadius.circular(24),
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
                      "TODAY IN SRI LANKA 🇱🇰",
                      style: GoogleFonts.outfit(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      (event.name).toUpperCase(),
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
    final user = widget.isOffline ? null : FirebaseAuth.instance.currentUser;
    return SliverAppBar(
      expandedHeight: 360,
      pinned: true,
      stretch: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground, StretchMode.blurBackground],
        background: Stack(
          fit: StackFit.expand,
          children: [
            OracleUI.heroCrossfade(
              child: Image.asset(
                _bgImages[_bgImageIndex],
                key: ValueKey<int>(_bgImageIndex),
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (context, error, stackTrace) => Container(color: Theme.of(context).colorScheme.primary),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.5),
                    Colors.transparent,
                    Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.8),
                    Theme.of(context).scaffoldBackgroundColor,
                  ],
                  stops: const [0.0, 0.4, 0.8, 1.0],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                    const SizedBox(height: 48),
                    OracleUI.neonText(
                      "DISCOVER SRI LANKA",
                      style: GoogleFonts.outfit(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "LET THE ORACLE GUIDE YOUR PATH",
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: Colors.white.withValues(alpha: 0.6),
                        letterSpacing: 3,
                      ),
                    ),
                  const SizedBox(height: 24),
                   Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: OracleUI.premiumGlassCard(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      radius: BorderRadius.circular(40),
                      child: Row(
                        children: [
                          Icon(Icons.search_rounded, color: Theme.of(context).colorScheme.primary, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "Search secret locations...",
                              style: GoogleFonts.inter(
                                color: AppTheme.textSecondary(context).withValues(alpha: 0.6),
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
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
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                radius: 18,
                backgroundImage: NetworkImage(user.photoURL ?? "https://ui-avatars.com/api/?name=${user.displayName}"),
              ),
            ),
          )
        else
          _glassActionIcon(Icons.person_outline, () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
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
        radius: BorderRadius.circular(20),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, color: Colors.redAccent, size: 14),
            const SizedBox(width: 6),
            Text(
              "OFFLINE MODE",
              style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.redAccent),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    final user = widget.isOffline ? null : FirebaseAuth.instance.currentUser;
    final name = user?.displayName?.split(" ").first ?? "Traveler";

    return DynamicLightWrapper(
      child: OracleUI.premiumGlassCard(
        padding: const EdgeInsets.all(28),
        radius: BorderRadius.circular(32),
        showGlow: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            OracleUI.neonText(
              "AYUBOWAN, $name!",
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w900,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "WHERE SHALL THE\nORACLE GUIDE YOU?",
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: AppTheme.textPrimary(context),
                height: 1.1,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: OracleUI.neonText(
        title.toUpperCase(),
        style: GoogleFonts.outfit(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: 3,
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
        ),
      ),
    );
  }

  Widget _buildCategoriesGrid() {
    final List<(String, IconData, Color)> categories = [
      ("Nature", Icons.forest_outlined, AppTheme.modernGreen(context)),
      ("Beaches", Icons.waves_rounded, Colors.blue),
      ("Culture", Icons.temple_hindu_outlined, Theme.of(context).colorScheme.primary),
      ("Adventure", Icons.explore_outlined, AppTheme.modernGreen(context)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("Explore by Category"),
        const SizedBox(height: 16),
        GridView.builder(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.1,
          ),
          itemCount: categories.length,
          itemBuilder: (context, i) {
            final cat = categories[i];
            return OracleUI.glassContainer(
              padding: const EdgeInsets.all(20),
              radius: BorderRadius.circular(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cat.$3.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(cat.$2, color: cat.$3, size: 28),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    cat.$1.toUpperCase(),
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                      color: AppTheme.textPrimary(context),
                    ),
                  ),
                ],
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
          "${trip.itinerary.length} Days"
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
                  child: Image.network(
                    "https://images.unsplash.com/photo-1546708973-b339540b5162?q=80&w=2670&auto=format&fit=crop",
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withValues(alpha: 0.8)],
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
                              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white, letterSpacing: 1)
                            ),
                            const SizedBox(height: 4),
                            Text(desc, style: GoogleFonts.inter(fontSize: 12, color: Colors.white70), maxLines: 1, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                      OracleUI.glassContainer(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        radius: BorderRadius.circular(12),
                        child: Text(duration, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 10)),
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
      color: Colors.transparent,
      elevation: 0,
      padding: EdgeInsets.zero,
      notchMargin: 10,
      child: Container(
        height: dynamicHeight,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.95),
          border: Border(top: BorderSide(color: AppTheme.secondaryBorder(context), width: 1.0)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(l10n.home, Icons.home_rounded, 0),
            _navItem("Explore", Icons.travel_explore_rounded, 1),
            const SizedBox(width: 60), 
            _navItem("Events", Icons.calendar_month_rounded, 2),
            _navItem(l10n.profile, Icons.person_rounded, 3),
          ],
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
            color: active ? AppPalette.rust : AppPalette.ink.withValues(alpha: 0.4),
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
                        Text(gem.rating.toString(), style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.orangeAccent)),
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
