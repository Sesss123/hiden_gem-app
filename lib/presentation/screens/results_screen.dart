import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/oracle_ui_system.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/localization/locale_provider.dart';
import '../../data/datasources/user_preference_service.dart';
import '../../data/datasources/trip_cache_service.dart';
import '../../data/datasources/monetization_service.dart';
import '../../data/datasources/premium_service.dart';
import '../../data/datasources/pdf_service.dart';
import '../../data/models/trip_plan_model.dart';
import '../widgets/offline_highlights_widget.dart';
import '../widgets/custom_buttons.dart';
import '../widgets/skeleton_loaders.dart';
import '../widgets/kinetic_timeline_view.dart';
import 'map_route_screen.dart';
import 'budget_tracker_screen.dart';

import 'smart_match_screen.dart';
import 'package:hidden_gems_sl/l10n/app_localizations.dart';
import 'dart:ui';
import '../../core/analytics/analytics_service.dart';
import '../../core/rating/rating_service.dart';
import '../../data/datasources/voice_service.dart';
import '../../core/utils/screenshot_service.dart';
import 'package:screenshot/screenshot.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/services/geo_aware_guide_service.dart';
import '../../core/services/dynamic_itinerary_service.dart';
import '../../core/services/voice_assistant_service.dart';

class ResultsScreen extends ConsumerStatefulWidget {
  final TripPlan plan;
  final CacheReadResult cacheState;
  final String? cacheKey;

  const ResultsScreen({
    super.key,
    required this.plan,
    this.cacheState = CacheReadResult.miss,
    this.cacheKey,
  });

  @override
  ConsumerState<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends ConsumerState<ResultsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isSaved = false;
  String? _savedId;
  bool _isInit = false;
  bool _isBannerLoaded = false;
  bool _isListening = false;
  bool _planBUnlocked = false;
  BannerAd? _bannerAd;
  final ScreenshotService _screenshotService = ScreenshotService();
  late TripPlan _activePlan;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        HapticFeedback.lightImpact();
      }
    });
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _isInit = true);
    });

    _initBanner();
    _triggerPostGenerationEvents();
    
    _activePlan = widget.plan;
    DynamicItineraryService.setPlan(_activePlan);

    // Check if this plan is already saved in Oracle cache
    final savedPlans = TripCacheService.getSavedPlans();
    for (final entry in savedPlans) {
      if (entry.plan.tripSummary.destinationCity == _activePlan.tripSummary.destinationCity &&
          entry.plan.tripSummary.startDate == _activePlan.tripSummary.startDate &&
          entry.plan.tripSummary.days == _activePlan.tripSummary.days &&
          entry.plan.tripSummary.userBudgetLkr == _activePlan.tripSummary.userBudgetLkr) {
        _isSaved = true;
        _savedId = entry.id;
        break;
      }
    }

    // Listen for mutations from the Oracle
    DynamicItineraryService.currentPlan.addListener(_onPlanMutated);
    
    // Stage 5: Cinematic Feedback Listener
    VoiceAssistantService.state.addListener(_onOracleStateChanged);

    // Start autonomous Geo-Aware guiding
    GeoAwareGuideService.startMonitoring(
      _activePlan.itinerary.expand((day) => day.items).toList(),
    );
  }

  void _onPlanMutated() {
    if (DynamicItineraryService.currentPlan.value != null && mounted) {
      setState(() {
        _activePlan = DynamicItineraryService.currentPlan.value!;
      });
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_activePlan.humanText),
          backgroundColor: AppTheme.accentOchre(context),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _triggerPostGenerationEvents() async {
    // 1. Log Analytics
    await AnalyticsService().logPlanGenerated(
      destination: _activePlan.destination,
      style: _activePlan.tripSummary.style,
      days: _activePlan.itinerary.length,
      verifiedScore: _activePlan.verifiedScore,
    );

    // 2. Increment Trip Count for User DNA
    await UserPreferenceService.addTrip();

    // 3. Check for Rating Prompt (Milestone trigger)
    await RatingService().checkAndRequestReview();
  }

  void _initBanner() async {
    final isPremium = ref.read(premiumNotifierProvider);
    if (!isPremium) {
      _bannerAd = await MonetizationService().createBannerAd();
      setState(() => _isBannerLoaded = true);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _bannerAd?.dispose();
    DynamicItineraryService.currentPlan.removeListener(_onPlanMutated);
    VoiceAssistantService.state.removeListener(_onOracleStateChanged);
    GeoAwareGuideService.stopMonitoring();
    super.dispose();
  }

  void _onOracleStateChanged() {
    if (mounted) {
      // Logic for haptics remains, but we remove setState
      
      // Haptic Patterns for Stage 5
      switch (VoiceAssistantService.state.value) {
        case OracleState.listening:
          HapticFeedback.lightImpact();
          break;
        case OracleState.thinking:
          HapticFeedback.mediumImpact();
          break;
        case OracleState.speaking:
          HapticFeedback.selectionClick();
          break;
        case OracleState.idle:
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPremium = ref.watch(premiumNotifierProvider);
    final l10n = AppLocalizations.of(context)!;
    final plan = _activePlan;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Screenshot(
        controller: _screenshotService.controller,
        child: Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: Stack(
            children: [
              NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverAppBar(
                  expandedHeight: 280,
                  pinned: true,
                  stretch: true,
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  elevation: 0,
                  scrolledUnderElevation: 0,
                  leading: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: CircleAvatar(
                      backgroundColor: Colors.white.withValues(alpha: 0.8),
                      child: IconButton(
                        icon: Icon(Icons.arrow_back_ios_new, color: AppTheme.textPrimary(context), size: 18),
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          Navigator.pop(context);
                        },
                      ),
                    ),
                  ),
                  actions: [
                    _buildSaveButton(context, plan),
                    SizedBox(width: 8),
                    IconButton(
                      icon: Icon(Icons.public, color: Theme.of(context).colorScheme.primary),
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MapRouteScreen(plan: plan))),
                    ),
                    IconButton(
                      icon: Icon(Icons.picture_as_pdf_outlined, color: Theme.of(context).colorScheme.secondary),
                      onPressed: () {
                        if (isPremium) {
                          PdfService.generateAndShareTripPdf(plan);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text("PDF Export is a Premium feature."),
                              backgroundColor: AppTheme.accentOchre(context),
                            ),
                          );
                          _tabController.animateTo(3);
                        }
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.person_search, color: Colors.amberAccent),
                      onPressed: () => Navigator.push(
                        context, 
                        MaterialPageRoute(builder: (context) => const SmartMatchScreen())
                      ),
                    ),
                    SizedBox(width: 8),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    stretchModes: const [StretchMode.zoomBackground, StretchMode.blurBackground],
                    titlePadding: EdgeInsets.only(left: 20, bottom: 60),
                    title: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        OracleUI.neonText(
                          _activePlan.tripSummary.destinationCity.toUpperCase(),
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w900,
                            fontSize: 32,
                            color: Colors.white,
                            letterSpacing: 4,
                            shadows: [Shadow(color: Colors.black.withValues(alpha: 0.8), blurRadius: 20)],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "AUTHENTICATED BY THE ORACLE",
                          style: GoogleFonts.inter(
                            fontSize: 10, 
                            fontWeight: FontWeight.w900,
                            color: Colors.white70,
                            letterSpacing: 3,
                            shadows: [Shadow(color: Colors.black.withValues(alpha: 0.8), blurRadius: 10)],
                          ),
                        ),
                      ],
                    ),
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        CachedNetworkImage(
                          imageUrl: _getDestinationImage(_activePlan.tripSummary.destinationCity),
                          fit: BoxFit.cover,
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.2),
                                Colors.transparent,
                                Theme.of(context).scaffoldBackgroundColor,
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              stops: const [0.0, 0.4, 1.0],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(60),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(32),
                          topRight: Radius.circular(32),
                        ),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        isScrollable: true,
                        dividerColor: Colors.transparent,
                        indicator: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                          border: Border.all(color: Theme.of(context).colorScheme.primary),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        indicatorPadding: const EdgeInsets.symmetric(horizontal: -16, vertical: 8),
                        labelColor: Theme.of(context).colorScheme.primary,
                        unselectedLabelColor: AppTheme.textSecondary(context),
                        labelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.5),
                        tabs: [
                          Tab(text: l10n.itinerary.toUpperCase()),
                          const Tab(text: "BUDGET"),
                          const Tab(text: "MAP"),
                          Tab(text: l10n.planB.toUpperCase()),
                          Tab(text: l10n.tips.toUpperCase()),
                        ],
                      ),
                    ),
                  ),
                ),
              ];
            },
            body: _isInit 
                ? TabBarView(
                    controller: _tabController,
                    children: [
                      _buildItineraryTab(plan, l10n),
                      _buildBudgetTab(context, plan),
                      _buildMapTab(plan),
                      _buildPlanBTab(plan, isPremium),
                      _buildTipsTab(plan),
                    ],
                  ).animate().fadeIn(duration: 800.ms)
                : const ResultsTabSkeleton(),
          ),

          // Oracle Aura Overlay (Granular Rebuild Pattern)
          ValueListenableBuilder<OracleState>(
            valueListenable: VoiceAssistantService.state,
            builder: (context, state, _) {
              if (state == OracleState.idle) return const SizedBox.shrink();
              return Positioned.fill(
                child: Container(
                  color: Colors.black45,
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: OracleUI.auraBackground(
                      isVisible: true,
                      baseColor: _getOracleColor(context, state),
                    ),
                  ),
                ),
              );
            },
          ),
          
          // Ad Banner at bottom (Optimized & Polished)
          if (!isPremium && _isBannerLoaded && _bannerAd != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  border: Border(top: BorderSide(color: AppTheme.primaryBorder(context))),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -2))
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: SizedBox(
                    width: _bannerAd!.size.width.toDouble(),
                    height: _bannerAd!.size.height.toDouble(),
                    child: AdWidget(ad: _bannerAd!),
                  ),
                ),
              ),
            ),

          // Time-Aware Dynamic Overlay
          IgnorePointer(
            child: Container(
              color: AppTheme.getDynamicOverlay(),
            ),
          ),
        ],
      ),
    ),
  ),
);
}


  Widget _buildVoiceButton(BuildContext context, TripPlan plan, bool isPremium) {
    final localeCode = ref.read(localeNotifierProvider)?.languageCode ?? 'en';
    
    return IconButton(
      icon: Icon(
        _isListening ? Icons.stop_circle_outlined : Icons.play_circle_fill,
        color: AppTheme.accentOchre(context),
        size: 28,
      ),
      onPressed: () async {
        if (!isPremium) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("Voice Guide is a Premium feature."),
              backgroundColor: AppTheme.accentOchre(context),
            ),
          );
          _tabController.animateTo(3);
          return;
        }

        if (_isListening) {
          await VoiceService().stop();
          if (mounted) setState(() => _isListening = false);
        } else {
          setState(() => _isListening = true);
          await VoiceService().speak(plan.humanText, languageCode: localeCode);
          if (mounted) setState(() => _isListening = false);
        }
      },
    );
  }

  Widget _buildSaveButton(BuildContext context, TripPlan plan) {
    return IconButton(
      icon: Icon(
        _isSaved ? Icons.bookmark : Icons.bookmark_border_rounded,
        color: _isSaved ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface,
      ),
      onPressed: () async {
        if (!_isSaved) {
          final id = await TripCacheService.savePlan(plan);
          if (mounted) {
            setState(() {
              _isSaved = true;
              _savedId = id;
            });
          }
        } else {
          String? idToDelete = _savedId;
          if (idToDelete == null) {
            final savedPlans = TripCacheService.getSavedPlans();
            for (final entry in savedPlans) {
              if (entry.plan.tripSummary.destinationCity == plan.tripSummary.destinationCity &&
                  entry.plan.tripSummary.startDate == plan.tripSummary.startDate &&
                  entry.plan.tripSummary.days == plan.tripSummary.days &&
                  entry.plan.tripSummary.userBudgetLkr == plan.tripSummary.userBudgetLkr) {
                idToDelete = entry.id;
                break;
              }
            }
          }
          if (idToDelete != null) {
            await TripCacheService.deleteSavedPlan(idToDelete);
          }
          if (mounted) {
            setState(() {
              _isSaved = false;
              _savedId = null;
            });
          }
        }
      },
    );
  }



  String _getDestinationImage(String city) {
    // High-quality placeholders for key cities
    final images = {
      'Kandy': 'https://images.unsplash.com/photo-1588598116346-6019f6f67f67?auto=format&fit=crop&q=80&w=800',
      'Ella': 'https://images.unsplash.com/photo-1546708973-b339540b51bd?auto=format&fit=crop&q=80&w=800',
      'Galle': 'https://images.unsplash.com/photo-1625484478269-95333f8e6c4a?auto=format&fit=crop&q=80&w=800',
      'Colombo': 'https://images.unsplash.com/photo-1582298538104-fe2e74c27f59?auto=format&fit=crop&q=80&w=800',
    };
    return images[city] ?? 'https://images.unsplash.com/photo-1549880338-65ddcdfd017b?auto=format&fit=crop&q=80&w=800';
  }

  // ═══════════════════════════════════════════════════════════════════
  // TAB 1 – ITINERARY
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildItineraryTab(TripPlan plan, AppLocalizations l10n) {
    final isPremium = ref.read(premiumNotifierProvider);

    return Column(
      children: [
        if (widget.cacheState != CacheReadResult.fresh)
          OfflineHighlightsWidget(destination: plan.destination),
        
        // Oracle's Summary & Voice Guide
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppTheme.secondaryBorder(context)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_awesome, color: Theme.of(context).colorScheme.primary, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      "ORACLE'S VISION",
                      style: GoogleFonts.inter(
                        color: Theme.of(context).colorScheme.primary, 
                        fontWeight: FontWeight.w900, 
                        letterSpacing: 4, 
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    _buildVoiceButton(context, plan, isPremium),
                  ],
                ),
                SizedBox(height: 12),
                Text(
                  plan.humanText,
                  style: GoogleFonts.inter(
                    color: AppTheme.textSecondary(context), 
                    height: 1.6, 
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
            child: KineticTimelineView(days: plan.itinerary),
          ),
        ),
      ],
    );
  }
  // ═══════════════════════════════════════════════════════════════════
  // TAB 2 – ORACLE STYLE
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildBudgetTab(BuildContext context, TripPlan plan) {
    int totalCost = 0;
    Map<String, int> categories = {
      'Transport': 0,
      'Food': 0,
      'Attractions': 0,
      'Hotel': 0,
      'Other': 0,
    };

    for (var day in plan.itinerary) {
      for (var item in day.items) {
        totalCost += item.costLkr;
        if (item.isTransport) {
          categories['Transport'] = categories['Transport']! + item.costLkr;
        } else if (item.isFood) {
          categories['Food'] = categories['Food']! + item.costLkr;
        } else if (item.isHotel) {
          categories['Hotel'] = categories['Hotel']! + item.costLkr;
        } else if (item.type == 'attraction') {
          categories['Attractions'] = categories['Attractions']! + item.costLkr;
        } else {
          categories['Other'] = categories['Other']! + item.costLkr;
        }
      }
    }
    
    final userBudget = plan.tripSummary.userBudgetLkr;
    final progress = userBudget > 0 ? (totalCost / userBudget).clamp(0.0, 1.0) : 0.0;
    final isOverBudget = totalCost > userBudget && userBudget > 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeroBudgetCard(context, totalCost, userBudget, progress, isOverBudget),
          SizedBox(height: 24),
          _buildSectionHeader(context, "Expense Breakdown"),
          SizedBox(height: 16),
          ...categories.entries.where((e) => e.value > 0).map((e) => _buildBudgetRow(context, e.key, e.value, totalCost)),
          const SizedBox(height: 32),
          ModernGradientButton(
            label: "Open Expense Tracker",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BudgetTrackerScreen(
                    plan: plan,
                    planId: _savedId,
                    cacheKey: widget.cacheKey,
                  ),
                ),
              ).then((_) {
                if (mounted) setState(() {});
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeroBudgetCard(BuildContext context, int total, int userBudget, double progress, bool isOver) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.secondaryBorder(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "ESTIMATED TOTAL", 
                style: GoogleFonts.inter(
                  color: AppTheme.modernGreen(context), 
                  fontWeight: FontWeight.bold, 
                  fontSize: 12, 
                  letterSpacing: 1.5,
                ),
              ),
              if (isOver) 
                Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent, size: 20),
            ],
          ),
          SizedBox(height: 8),
          Text(
            _fmtLkr(total), 
            style: GoogleFonts.outfit(
              color: AppTheme.darkText(context), 
              fontSize: 32, 
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 12,
              backgroundColor: Theme.of(context).dividerColor.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(
                isOver ? Colors.orangeAccent : Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "User Budget: ${_fmtLkr(userBudget)}", 
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), 
                  fontSize: 12,
                ),
              ),
              Text(
                "${(progress * 100).toInt()}% Used", 
                style: TextStyle(
                  color: isOver ? Colors.orangeAccent : Theme.of(context).colorScheme.primary, 
                  fontSize: 12, 
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetRow(BuildContext context, String label, int amount, int total) {
    final percent = (amount / total * 100).toInt();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.secondaryBorder(context)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, shape: BoxShape.circle),
            child: Icon(_getCategoryIcon(label), color: Colors.white, size: 20),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label, 
                  style: GoogleFonts.outfit(
                    color: Theme.of(context).colorScheme.onSurface, 
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "$percent% of total", 
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5), 
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Text(
            _fmtLkr(amount), 
            style: GoogleFonts.outfit(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8), 
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String label) {
    switch (label) {
      case 'Transport': return Icons.directions_bus_outlined;
      case 'Food': return Icons.restaurant_outlined;
      case 'Hotel': return Icons.hotel_outlined;
      case 'Attractions': return Icons.map_outlined;
      default: return Icons.more_horiz;
    }
  }

  Widget _buildMapTab(TripPlan plan) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.map_rounded, size: 64, color: Theme.of(context).colorScheme.primary),
          ),
          SizedBox(height: 32),
          Text(
            "Visual Tour Route",
            style: GoogleFonts.outfit(
              fontSize: 24, 
              fontWeight: FontWeight.bold, 
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 12),
          Text(
            "Plot your entire journey across the teardrop isle. View detailed route segments and travel times.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), 
              height: 1.5,
            ),
          ),
          SizedBox(height: 48),
          ModernGradientButton(
            label: "Open Route Map",
            onPressed: () {
               HapticFeedback.heavyImpact();
               Navigator.push(context, MaterialPageRoute(builder: (_) => MapRouteScreen(plan: plan)));
            },
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // TAB 3 – PLAN B (RAIN)
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildPlanBTab(TripPlan plan, bool isPremium) {
    if (!isPremium && !_planBUnlocked) {
      return _buildRewardedGate();
    }

    final item = plan.planB;
    return SingleChildScrollView(
      padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(Icons.umbrella, color: AppTheme.accentOchre(context), size: 28),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Oracle's Rain Plan", 
                        style: GoogleFonts.outfit(
                          color: Theme.of(context).colorScheme.primary, 
                          fontWeight: FontWeight.bold, 
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        "Caught in a sudden shower? Switch to this.", 
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), 
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20),
          _buildPlanBCard(item),
          SizedBox(height: 40),
          _buildPremiumCTA(),
        ],
      ),
    );
  }

  Widget _buildRewardedGate() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.secondaryBorder(context)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 15,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.accentOchre(context).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.lock_outline, color: AppTheme.accentOchre(context), size: 48),
              ),
              SizedBox(height: 24),
              Text(
                "Oracle's Vault",
                style: GoogleFonts.outfit(
                  fontSize: 24, 
                  fontWeight: FontWeight.bold, 
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              SizedBox(height: 12),
              Text(
                "The rainy-day alternative is locked for free travelers.\nWatch a short video to unlock it for this trip.",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
              ),
              SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                MonetizationService().showRewardedAd(onRewardEarned: (reward) {
                  setState(() => _planBUnlocked = true);
                });
              },
              icon: Icon(Icons.play_circle_fill),
              label: Text("UNLOCK WITH AD"),
              style: AppTheme.primaryButtonStyle(context),
            ),
            TextButton(
              onPressed: () => ref.read(premiumNotifierProvider.notifier).buyPremium(),
              child: Text(
                "Go Premium for Ad-Free Experience", 
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
              ),
            ),
          ],
        ),
      ),
    ),
   );
  }

  Widget _buildPremiumCTA() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5), width: 2),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Icon(Icons.stars, color: AppTheme.accentOchre(context).withValues(alpha: 0.2), size: 80),
              Icon(Icons.rocket_launch_rounded, color: AppTheme.primaryBlue(context), size: 40),
            ],
          ),
          SizedBox(height: 20),
          Text(
            "TRIPME LUXURY",
            style: GoogleFonts.outfit(
              color: Theme.of(context).colorScheme.onSurface, 
              fontWeight: FontWeight.bold, 
              letterSpacing: 4,
              fontSize: 18,
            ),
          ),
          SizedBox(height: 12),
          Text(
            "Go beyond the ordinary. Unlock the Oracle's full wisdom.",
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 13),
          ),
          SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _premiumFeature(Icons.mic_none, "Voice"),
              _premiumFeature(Icons.picture_as_pdf, "PDF"),
              _premiumFeature(Icons.block, "No Ads"),
            ],
          ),
          SizedBox(height: 32),
          Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.accentOchre(context).withValues(alpha: 0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                )
              ],
            ),
            child: ElevatedButton(
              onPressed: () => ref.read(premiumNotifierProvider.notifier).buyPremium(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentOchre(context),
                foregroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.white, // Keep white for branding contrast if background is dark ochre
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                "UNLEASH THE ORACLE", 
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, letterSpacing: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _premiumFeature(IconData icon, String label) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), size: 20),
          SizedBox(height: 4),
          Text(label, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5))),
        ],
      ),
    );
  }

  Widget _buildPlanBCard(PlanBItem item) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.secondaryBorder(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            Text(
              item.title, 
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold, 
                fontSize: 18, 
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 12),
            Text(
              item.reason, 
              style: GoogleFonts.inter(
                fontSize: 14, 
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), 
                height: 1.5,
              ),
            ),
            SizedBox(height: 20),
            Row(
              children: [
                Icon(Icons.location_on, color: AppTheme.errorRed, size: 16),
                SizedBox(width: 4),
                Text("${item.lat.toStringAsFixed(4)}, ${item.lng.toStringAsFixed(4)}", 
                  style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary(context))),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {},
                  icon: Icon(Icons.map_outlined, size: 18),
                  label: Text("View on Map"),
                ),
              ],
            ),
          ],
        ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // TAB 4 – COMFORT UPGRADES
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildTipsTab(TripPlan plan) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
      children: [
        _buildSafetyHero(plan.safetyTip),
        SizedBox(height: 24),
        Text("Verification Sources", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).colorScheme.onSurface)),
        SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: plan.kbCitations.map((c) => _sourceChip(c)).toList(),
        ),
        SizedBox(height: 32),
        Text("💡 Pro Tips for Sri Lanka", style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7))),
        SizedBox(height: 12),
        ...plan.tips.map((t) => _tipItem(t)),
      ],
    );
  }

  Widget _buildSafetyHero(String tip) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.warningAmber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.warningAmber.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shield_outlined, color: AppTheme.warningAmber, size: 24),
              SizedBox(width: 10),
              Text("Oracle's Local Tip", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppTheme.warningAmber)),
            ],
          ),
          SizedBox(height: 12),
          Text(tip, style: GoogleFonts.inter(fontSize: 15, color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _sourceChip(String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.glassBackground(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.primaryBorder(context)),
      ),
      child: Text(label, style: GoogleFonts.inter(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontWeight: FontWeight.bold)),
    );
  }

  Widget _tipItem(String tip) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 4),
            child: Icon(Icons.check_circle, size: 16, color: AppTheme.accentOchre(context)),
          ),
          SizedBox(width: 12),
          Expanded(child: Text(tip, style: GoogleFonts.inter(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)))),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════

  Color _getOracleColor(BuildContext context, OracleState state) {
    switch (state) {
      case OracleState.listening:
        return Colors.blueAccent;
      case OracleState.thinking:
        return Colors.amberAccent;
      case OracleState.speaking:
        return AppTheme.accentOchre(context);
      case OracleState.idle:
        return Colors.transparent;
    }
  }


  String _fmtLkr(int n) {
    if (n >= 100000) {
      return "LKR ${(n / 1000).toStringAsFixed(0)}K";
    }
    // Add comma formatting manually
    final s = n.toString();
    if (s.length <= 3) return "LKR $s";
    final chars = s.split('').reversed.toList();
    final result = <String>[];
    for (int i = 0; i < chars.length; i++) {
      if (i > 0 && i % 3 == 0) result.add(',');
      result.add(chars[i]);
    }
    return "LKR ${result.reversed.join()}";
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }

}
