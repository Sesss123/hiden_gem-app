import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/oracle_ui_system.dart';
import '../../core/utils/image_utils.dart';
import '../../core/analytics/analytics_service.dart';
import '../../core/services/ar_service.dart';
import '../../data/models/ar_place_data.dart';
import '../../core/services/ar_support_service.dart';
import '../../core/services/asset_cache_service.dart';
import 'package:hidden_gems_sl/data/repositories/discovery_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/cached_image.dart';
import '../../data/models/discovery_place.dart';
import '../../data/datasources/user_preference_service.dart';
import '../../data/datasources/portal_service.dart';
import '../../core/services/usage_limiter_service.dart';
import '../../core/services/translation_service.dart';
import '../../core/localization/l10n_utils.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/limit_reached_dialog.dart';
import 'ar_viewer_screen.dart';
import 'ar_upgrade_dialog.dart';
import 'ar_fallback_screen.dart';
import 'premium_hub_screen.dart';
import '../../core/services/premium_unlock_service.dart';
import '../../data/datasources/monetization_service.dart';
import '../widgets/native_ad_widget.dart';
import '../widgets/banner_ad_widget.dart';
import 'heritage_passport_screen.dart';
import 'audio_guide_screen.dart';
import 'ancestral_portal_screen.dart';

class PlaceDetailsScreen extends ConsumerStatefulWidget {
  final DiscoveryPlace place;

  const PlaceDetailsScreen({super.key, required this.place});

  @override
  ConsumerState<PlaceDetailsScreen> createState() => _PlaceDetailsScreenState();
}

class _PlaceDetailsScreenState extends ConsumerState<PlaceDetailsScreen> {
  String? _translatedAiReason;
  bool _isTranslating = false;
  bool _isBookmarked = false;

  @override
  void initState() {
    super.initState();
    final profile = UserPreferenceService.getProfile();
    _isBookmarked = profile.bookmarkedPlaces.contains(widget.place.id);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return FutureBuilder<bool>(
      future: PremiumUnlockService.hasAccess(widget.place.id, arTier: widget.place.arTier),
      builder: (context, snapshot) {
        final hasAccess = snapshot.data ?? true;

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: OracleUI.auraBackground(
            child: Stack(
              children: [
                CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    _buildHeroImage(context),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeaderInfo(context, l10n).animate().fadeIn(duration: 600.ms).slideX(begin: -0.1),
                            const SizedBox(height: 24),
                            _buildAIReason(context, l10n).animate().fadeIn(delay: 200.ms, duration: 600.ms).slideY(begin: 0.1),
                            const SizedBox(height: 24),
                            _buildSponsoredExperience().animate().fadeIn(delay: 300.ms, duration: 600.ms),
                            const SizedBox(height: 24),
                            _buildQuickStats(context, l10n).animate().fadeIn(delay: 400.ms, duration: 600.ms).scale(begin: const Offset(0.95, 0.95)),
                            const SizedBox(height: 24),
                            _buildDetailsSection(context, Icons.info_outline, l10n.theKnowledge, _buildDetailsChips(context, l10n)).animate().fadeIn(delay: 500.ms, duration: 600.ms),
                            const SizedBox(height: 24),
                            _buildDetailsSection(context, Icons.warning_amber_rounded, l10n.safetyProtocols, _buildRiskTags(context)).animate().fadeIn(delay: 600.ms, duration: 600.ms),
                            const SizedBox(height: 24),
                            _buildDetailsSection(context, Icons.local_cafe_outlined, l10n.provisions, _buildFacilities(context)).animate().fadeIn(delay: 700.ms, duration: 600.ms),
                            const SizedBox(height: 24),
                            _buildEtiquetteSection(context, l10n).animate().fadeIn(delay: 800.ms, duration: 600.ms),
                            const SizedBox(height: 24),
                            _buildAncestralPortalCard(context).animate().fadeIn(delay: 900.ms, duration: 600.ms).shimmer(delay: 2.seconds, duration: 1500.ms),
                            const SizedBox(height: 100),
                          ],
                        ),
                      ),
                    )
                  ],
                ),
                if (!hasAccess) _buildLockOverlay(context, l10n),
              ],
            ),
          ),
          bottomNavigationBar: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const BannerAdWidget(),
              _buildBottomActions(context, ref, l10n),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLockOverlay(BuildContext context, AppLocalizations l10n) {
    return Container(
      color: Colors.black.withValues(alpha: 0.9),
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: OracleUI.glassContainer(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline_rounded, color: AppPalette.sigiriyaOchre, size: 64),
              const SizedBox(height: 24),
              OracleUI.neonText(
                "Heritage Site Locked",
                style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: AppPalette.sigiriyaOchre),
              ),
              const SizedBox(height: 16),
              Text(
                "This Oracle Vision is reserved for Premium Explorers. Watch a short Ad to unlock this place for today.",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: Colors.white70, height: 1.5),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    MonetizationService().showRewardedAd(
                      onRewardEarned: (reward) {
                        PremiumUnlockService.unlockPlace(widget.place.id);
                        setState(() {}); // Refresh UI
                      },
                    );
                  },
                  icon: const Icon(Icons.play_circle_outline, color: Colors.black),
                  label: Text("WATCH AD TO UNLOCK", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.black)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppPalette.sigiriyaOchre,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Go Back", style: TextStyle(color: Colors.white38)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEtiquetteSection(BuildContext context, AppLocalizations l10n) {
    final cat = widget.place.category.toLowerCase();
    
    String title = l10n.sustainableEthos;
    IconData icon = Icons.eco_outlined;
    List<String> tips = [
      "Carry a reusable water bottle",
      "Avoid plastic single-use bags",
      "Respect local wildlife and plants"
    ];

    if (cat.contains("temple") || cat.contains("culture") || cat.contains("historical")) {
      title = l10n.culturalEtiquette;
      icon = Icons.temple_buddhist_outlined;
      tips = [
        "Remove shoes and hats before entering",
        "Dress modestly (cover shoulders and knees)",
        "Ask permission before taking photos of people",
        "Do not pose for photos with your back to statues"
      ];
    } else if (cat.contains("nature") || cat.contains("waterfall") || cat.contains("hiking")) {
      title = l10n.ecoResponsibleTravel;
      icon = Icons.nature_people_outlined;
      tips = [
        "Stay on marked trails to protect flora",
        "Pack out all your trash (Leave no trace)",
        "Do not feed or disturb wild animals",
        "Avoid using soap/shampoo in natural pools"
      ];
    }

    return OracleUI.glassContainer(
      showGlow: true,
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary, size: 22),
              SizedBox(width: 10),
              OracleUI.neonText(
                title, 
                style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary, letterSpacing: 2),
              ),
            ],
          ),
          SizedBox(height: 16),
          ...tips.map((tip) => Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.check_circle_outline, color: Theme.of(context).colorScheme.primary, size: 16),
                SizedBox(width: 12),
                Expanded(child: Text(tip, style: GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 13))),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildHeroImage(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 320,
      pinned: true,
      stretch: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      elevation: 0,
      leading: Padding(
        padding: EdgeInsets.all(8.0),
        child: CircleAvatar(
          backgroundColor: Colors.black.withValues(alpha: 0.3),
          child: IconButton(
            icon: Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.audiotrack_outlined, color: Theme.of(context).colorScheme.secondary),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AudioGuideScreen(place: widget.place)),
          ),
        ),
        IconButton(
          icon: Icon(Icons.wallet_membership_outlined, color: Theme.of(context).colorScheme.secondary),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const HeritagePassportScreen()),
          ),
        ),
        SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground, StretchMode.blurBackground],
        background: Stack(
          fit: StackFit.expand,
          children: [
            CachedImage(
              url: widget.place.imageUrl.isNotEmpty
                  ? widget.place.imageUrl
                  : ImageUtils.getPlaceholderImage(widget.place.category, widget.place.name),
              fit: BoxFit.cover,
            ),
            // Subdued top overlay for back button visibility
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.4), 
                    Colors.transparent, 
                  ],
                  stops: [0, 0.3],
                ),
              ),
            ),
            // Bottom glow/fade to content
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent, 
                    Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.5),
                    Theme.of(context).scaffoldBackgroundColor
                  ],
                  stops: [0.6, 0.85, 1],
                ),
              ),
            ),
            if (widget.place.arSupported)
              Positioned(
                top: 80,
                right: 20,
                child: _buildARTierBadge(context, widget.place.arTier),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildARTierBadge(BuildContext context, int tier) {
    String icon = 'ðŸ›';
    String label = 'HERITAGE AR';
    Color color = Theme.of(context).colorScheme.secondary;

    if (tier == 2) {
      icon = 'ðŸ”­';
      label = 'EXPLORE AR';
      color = const Color(0xFF29B6F6);
    } else if (tier == 3) {
      icon = 'ðŸ“–';
      label = 'STORY VIEW';
      color = Theme.of(context).colorScheme.primary;
    }

    return OracleUI.glassContainer(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: TextStyle(fontSize: 14)),
          SizedBox(width: 8),
          OracleUI.neonText(
            label,
            style: GoogleFonts.outfit(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 11,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    ).animate(onPlay: (c) => c.repeat()).shimmer(
      duration: 3.seconds, 
      color: (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black).withValues(alpha: 0.1)
    );
  }

  Widget _buildHeaderInfo(BuildContext context, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.place.name,
                    style: GoogleFonts.outfit(
                      fontSize: 32, 
                      fontWeight: FontWeight.w900, 
                      color: Theme.of(context).colorScheme.onSurface, 
                      height: 1.1,
                      letterSpacing: -0.5
                    ),
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 16, color: Theme.of(context).colorScheme.primary),
                      SizedBox(width: 8),
                      Text(
                        widget.place.district.toUpperCase(), 
                        style: GoogleFonts.inter(
                          fontSize: 12, 
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          letterSpacing: 2,
                          fontWeight: FontWeight.bold,
                        )
                      ),
                      if (widget.place.distanceKm > 0) ...[
                        SizedBox(width: 12),
                        Container(width: 4, height: 4, decoration: BoxDecoration(color: Theme.of(context).dividerColor.withValues(alpha: 0.2), shape: BoxShape.circle)),
                        SizedBox(width: 12),
                        Text(
                          "${widget.place.distanceKm.toStringAsFixed(1)} KM", 
                          style: GoogleFonts.outfit(
                            fontSize: 12, 
                            color: Theme.of(context).colorScheme.primary, 
                            fontWeight: FontWeight.bold
                          )
                        ),
                      ]
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.star_rounded, color: Theme.of(context).colorScheme.secondary, size: 20),
                  SizedBox(width: 6),
                  Text(
                    widget.place.rating.toString(), 
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w900, 
                      color: Theme.of(context).colorScheme.secondary, 
                      fontSize: 16
                    )
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAIReason(BuildContext context, AppLocalizations l10n) {
    if (widget.place.aiReason.isEmpty) return const SizedBox.shrink();
    final currentLocale = Localizations.localeOf(context).languageCode;
    final canTranslate = currentLocale == 'si' && _translatedAiReason == null;

    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.auto_awesome, color: Theme.of(context).colorScheme.primary, size: 18),
                  SizedBox(width: 10),
                  Text(
                    l10n.oracleVision.toUpperCase(), 
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w900, 
                      color: Theme.of(context).colorScheme.primary, 
                      fontSize: 11, 
                      letterSpacing: 2
                    )
                  ),
                ],
              ),
              if (canTranslate)
                GestureDetector(
                  onTap: _isTranslating ? null : _translateDescription,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)),
                    ),
                    child: _isTranslating 
                      ? SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 1.5, color: Theme.of(context).colorScheme.primary))
                      : Text(
                          l10n.tapToTranslate,
                          style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                        ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            _translatedAiReason ?? widget.place.aiReason, 
            style: GoogleFonts.inter(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.9), 
              height: 1.7, 
              fontSize: 15,
              fontWeight: FontWeight.w400,
            )
          ),
          if (widget.place.arSupported) ...[
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_awesome, color: Theme.of(context).colorScheme.secondary, size: 14),
                        SizedBox(width: 10),
                        Text(
                          l10n.aerDimensionReady,
                          style: GoogleFonts.outfit(
                            color: Theme.of(context).colorScheme.secondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildDownloadButton(context),
                ],
              ),
            ],
          ],
        ),
      );
    }

  Widget _buildSponsoredExperience() {
    return const NativeAdWidget();
  }

  Future<void> _translateDescription() async {
    setState(() => _isTranslating = true);
    try {
      final translated = await TranslationService.translate(widget.place.aiReason, 'si');
      if (mounted) {
        setState(() {
          _translatedAiReason = translated;
          _isTranslating = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isTranslating = false);
    }
  }
  
  Widget _buildDownloadButton(BuildContext context) {
    return _DownloadButton(place: widget.place);
  }

  Widget _buildQuickStats(BuildContext context, AppLocalizations l10n) {
    return Row(
      children: [
        _statBox(context, Icons.access_time_outlined, l10n.moment, widget.place.bestTime),
        SizedBox(width: 16),
        _statBox(context, Icons.confirmation_number_outlined, l10n.offering, widget.place.ticketRange),
        if (widget.place.arSupported) ...[
          SizedBox(width: 16),
          _statBox(
            context,
            Icons.view_in_ar,
            l10n.reality,
            widget.place.arTier == 1 ? "Heritage" : (widget.place.arTier == 2 ? "Explore" : "Story"),
            color: widget.place.arTier == 1 ? Theme.of(context).colorScheme.secondary : (widget.place.arTier == 2 ? const Color(0xFF29B6F6) : Theme.of(context).colorScheme.primary),
          ),
        ],
      ],
    );
  }

  Widget _statBox(BuildContext context, IconData icon, String title, String value, {Color? color}) {
    final accentColor = color ?? Theme.of(context).colorScheme.primary;
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.05)),
        ),
        child: Column(
          children: [
            Icon(icon, color: accentColor.withValues(alpha: 0.8), size: 22),
            SizedBox(height: 10),
            Text(
              title.toUpperCase(), 
              style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3), letterSpacing: 1.2)
            ),
            SizedBox(height: 4),
            Text(
              value.isEmpty ? "N/A" : value, 
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.9)), 
              textAlign: TextAlign.center, 
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsSection(BuildContext context, IconData icon, String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
            ),
            SizedBox(width: 14),
            Text(
              title.toUpperCase(), 
              style: GoogleFonts.outfit(
                fontSize: 12, 
                fontWeight: FontWeight.w900, 
                color: Theme.of(context).colorScheme.primary, 
                letterSpacing: 2
              )
            ),
          ],
        ),
        SizedBox(height: 16),
        content,
      ],
    );
  }

  Widget _buildDetailsChips(BuildContext context, AppLocalizations l10n) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        if (widget.place.category.isNotEmpty) _chip(context, L10nUtils.getLocalizedCategory(context, widget.place.category), Theme.of(context).colorScheme.primary),
        if (widget.place.roadType.isNotEmpty) _chip(context, "${l10n.road}: ${widget.place.roadType}", Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)),
        if (widget.place.vehicleAccess.isNotEmpty) _chip(context, "${l10n.access}: ${widget.place.vehicleAccess}", Theme.of(context).colorScheme.secondary),
        if (widget.place.parkingRange.isNotEmpty) _chip(context, "${l10n.parking}: ${widget.place.parkingRange}", Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2)),
      ],
    );
  }

  Widget _buildRiskTags(BuildContext context) {
    if (widget.place.riskTags.isEmpty) return Text("No manifestations detected.", style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 13));
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: widget.place.riskTags.map((t) => _chip(context, t, AppTheme.errorRed)).toList(),
    );
  }

  Widget _buildFacilities(BuildContext context) {
    if (widget.place.facilities.isEmpty) return Text("Minimal provisions found.", style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 13));
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: widget.place.facilities.map((t) => _chip(context, t, const Color(0xFF29B6F6))).toList(),
    );
  }

  Widget _chip(BuildContext context, String label, Color color) {
    return OracleUI.glassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Text(
        label.toUpperCase(), 
        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: color, letterSpacing: 1)
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: OracleUI.glassContainer(
        padding: EdgeInsets.all(12),
        showGlow: true,
        child: Row(
          children: [
            Container(
              height: 60,
              width: 60,
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.primaryBorder(context)),
                borderRadius: BorderRadius.circular(18),
                color: AppTheme.glassBackground(context),
              ),
              child: IconButton(
                icon: Icon(
                  _isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                  color: _isBookmarked
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurface,
                ),
                onPressed: () async {
                  HapticFeedback.mediumImpact();
                  final nowBookmarked = await UserPreferenceService.toggleBookmark(widget.place.id);
                  if (!context.mounted) return;
                  setState(() => _isBookmarked = nowBookmarked);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(nowBookmarked
                        ? "✨ Marked in your journey!"
                        : "Removed from bookmarks."),
                    backgroundColor: AppTheme.accentOchre(context),
                  ));
                },
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Container(
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.secondary],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 5),
                    )
                  ],
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Theme.of(context).scaffoldBackgroundColor,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                  onPressed: () async {
                    HapticFeedback.mediumImpact();
                    if (widget.place.arSupported) {
                      _handleARLaunch(context, ref, l10n);
                    } else {
                      final nowAdded = await UserPreferenceService.toggleItinerary(widget.place.id);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(nowAdded
                              ? "🗺️ ${widget.place.name} added to your destiny!"
                              : "Removed from itinerary."),
                      ));
                    }
                  },
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(widget.place.arSupported ? Icons.view_in_ar : Icons.auto_fix_high, size: 20),
                        SizedBox(width: 12),
                        Text(
                          widget.place.arSupported ? l10n.invokeAr : l10n.addToDestiny,
                          style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleARLaunch(BuildContext context, WidgetRef ref, AppLocalizations l10n) async {
    HapticFeedback.heavyImpact();
    
    bool isSupported = false;
    try {
      isSupported = await ARService.isSupported();
    } catch (_) {
      isSupported = false; 
    }

    if (!isSupported) {
      if (context.mounted) _showCinematicARError(context, l10n);
      return;
    }

    final profile = UserPreferenceService.getProfile();
    final isPremium = profile.isPremium;
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
              SizedBox(width: 16),
              Text(l10n.syncingResonance),
            ],
          ),
          duration: Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    Position? userPos;
    try {
      final repository = ref.read(discoveryRepositoryProvider);
      userPos = await repository.getCurrentLocation().timeout(const Duration(seconds: 10));
    } catch (e) {
      userPos = null;
    }

    if (context.mounted) ScaffoldMessenger.of(context).hideCurrentSnackBar();

    if (userPos == null) {
      if (context.mounted) {
        _showErrorDialog(context, l10n.resonanceLost, l10n.gpsRequired);
      }
      return;
    }

    final distanceMeters = Geolocator.distanceBetween(
      userPos.latitude, userPos.longitude, widget.place.lat, widget.place.lng
    );

    const double proximityThreshold = 500; 
    final bool isNear = distanceMeters <= proximityThreshold;

    if (!isNear && !isPremium) {
      if (context.mounted) _showProximityLockDialog(context, distanceMeters, l10n);
      return;
    }

    if (isPremium) {
      final canAccess = await UsageLimiterService.canAccessArSession();
      if (!context.mounted) return;

      if (!canAccess) {
        showDialog(
          context: context,
          builder: (_) => LimitReachedDialog(
            featureName: 'Heritage Sessions',
            onWatchAd: () {
              MonetizationService().showRewardedAd(
                onRewardEarned: (reward) async {
                  await UsageLimiterService.provideBonusArSession();
                  if (!mounted || !context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Bonus Session Unlocked! Try launching again.")),
                  );
                },
              );
            },
          ),
        );
        return;
      }

      await UsageLimiterService.incrementArSession();
      if (context.mounted) _navigateToAR(context);
    } else {
      if (context.mounted) {
        ARUpgradeDialog.show(
          context,
          onUpgrade: () {
            AnalyticsService().logARUpgradeClicked(placeName: widget.place.name, source: 'oracle_v2_proximity');
            Navigator.push(context, MaterialPageRoute(builder: (context) => const PremiumHubScreen()));
          },
          onPreview: () => _navigateToAR(context, isDemo: true),
          onWatchAd: () {
            MonetizationService().showRewardedAd(
              context: context,
              onRewardEarned: (reward) async {
                await UsageLimiterService.provideBonusArSession();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✨ Oracle reward active! AR session unlocked.'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  _navigateToAR(context);
                }
              },
            );
          },
        );
      }
    }
  }


  void _showProximityLockDialog(BuildContext context, double distanceMeters, AppLocalizations l10n) {
    final km = (distanceMeters / 1000).toStringAsFixed(1);
    showDialog(
      context: context,
      builder: (context) => OracleUI.glassContainer(
        margin: EdgeInsets.symmetric(horizontal: 40, vertical: 200),
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_off, color: Theme.of(context).colorScheme.secondary, size: 48),
            SizedBox(height: 20),
            OracleUI.neonText(l10n.distanceLockTitle, style: GoogleFonts.outfit(color: Theme.of(context).colorScheme.secondary, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2)),
            SizedBox(height: 16),
            Text(
              l10n.distanceLockMessage(km),
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), height: 1.5),
            ),
            SizedBox(height: 24),
            SizedBox(height: 50, width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const PremiumHubScreen()));
                },
                style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.secondary, foregroundColor: Theme.of(context).scaffoldBackgroundColor),
                child: Text(l10n.unlockTeleport, style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
              ),
            ),
            TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.close, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)))),
          ],
        ),
      ),
    );
  }



  void _showCinematicARError(BuildContext context, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.transparent,
        contentPadding: EdgeInsets.all(0),
        content: Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: (Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white).withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.errorRed.withValues(alpha: 0.3), width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded, color: AppTheme.errorRed, size: 48),
              SizedBox(height: 16),
              Text(
                l10n.arCoreNotDetected,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                  letterSpacing: 2,
                ),
              ),
              SizedBox(height: 12),
              Text(
                l10n.arCoreMessage,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.glassBackground(context),
                  foregroundColor: Theme.of(context).colorScheme.onSurface,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(l10n.understood),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showErrorDialog(BuildContext context, String title, String msg) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(title, style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
        content: Text(msg, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7))),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text("OK"))],
      ),
    );
  }
  void _navigateToAR(BuildContext context, {bool isDemo = false}) async {
    // Stage 5: ARCore Availability Guard
    final bool isSupported = await ARSupportService.isARCoreSupported();
    
    if (!isSupported) {
      if (context.mounted) _showCinematicARError(context, AppLocalizations.of(context)!);
      return;
    }

    if (!context.mounted) return;
    final arData = _getARPlaceData(context);

    // ðŸŽ¬ Cinematic "AR Portal" bottom sheet before launch
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      isScrollControlled: true,
      builder: (ctx) => _ARPortalSheet(
        place: widget.place,
        isDemo: isDemo,
        onLaunch: () {
          Navigator.pop(ctx);
          Navigator.push(
            context,
            PageRouteBuilder(
              transitionDuration: const Duration(milliseconds: 800),
              pageBuilder: (_, __, ___) => ARViewerScreen(
                arData: arData,
                placeName: widget.place.name,
                isDemo: isDemo,
              ),
              transitionsBuilder: (_, anim, __, child) {
                return FadeTransition(
                  opacity: anim,
                  child: ScaleTransition(scale: Tween(begin: 1.1, end: 1.0).animate(anim), child: child),
                );
              },
            ),
          ).catchError((e) {
            if (context.mounted) _navigateToFallback(context, reason: "failed");
          });
        },
      ),
    );
  }

  void _navigateToFallback(BuildContext context, {String reason = "unsupported"}) {
    final arData = _getARPlaceData(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ARFallbackScreen(
          arData: arData,
          placeName: widget.place.name,
          reason: reason,
        ),
      ),
    );
  }

  ARPlaceData _getARPlaceData(BuildContext context) {
    return ARPlaceData(
      arSupported: widget.place.arSupported,
      arTier: widget.place.arTier,
      arBrandName: widget.place.arTier == 1 ? "Heritage AR" : "Explore AR",
      arModelUrl: widget.place.arModelUrl.isNotEmpty 
          ? widget.place.arModelUrl 
          : "https://github.com/KhronosGroup/glTF-Sample-Models/raw/master/2.0/Duck/glTF-Binary/Duck.glb",
      arHistoricalModelUrl: widget.place.arHistoricalModelUrl.isNotEmpty 
          ? widget.place.arHistoricalModelUrl 
          : "https://raw.githubusercontent.com/KhronosGroup/glTF-Sample-Models/master/2.0/AntiqueCamera/glTF-Binary/AntiqueCamera.glb",
      arModelScale: widget.place.arModelScale > 0 ? widget.place.arModelScale : 0.01,
      historicalPeriod: widget.place.historicalPeriod.isNotEmpty ? widget.place.historicalPeriod : "Ancient Era",
      modelFileSizeMb: widget.place.arFileSizeMb,
      authorName: widget.place.arAuthor,
      audioUrlSi: widget.place.audioUrlSi,
      audioUrlEn: widget.place.audioUrlEn,
      fallbackVideoUrl: widget.place.fallbackVideoUrl,
      arContentVersion: 1,
      hotspots: widget.place.arHotspots.map((h) => 
        ARHotspot.fromMap(h as Map<String, dynamic>)
      ).toList(),
      artifacts: widget.place.arArtifacts,
      targetLat: widget.place.lat,
      targetLng: widget.place.lng,
    );
  }



  Widget _buildAncestralPortalCard(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final portal = PortalService.getPortalForPlace(widget.place.name);
    if (portal == null) return const SizedBox.shrink();
    return GestureDetector(
      onTap: () { HapticFeedback.mediumImpact(); Navigator.push(context, MaterialPageRoute(builder: (_) => AncestralPortalScreen(portal: portal))); },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.sigiriyaOchre(context).withValues(alpha: 0.05),
          border: Border.all(color: AppTheme.sigiriyaOchre(context).withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(children: [
          Container(padding: EdgeInsets.all(12), decoration: BoxDecoration(color: AppTheme.sigiriyaOchre(context).withValues(alpha: 0.1), shape: BoxShape.circle), child: Icon(Icons.auto_awesome, color: AppTheme.sigiriyaOchre(context), size: 28)),
          SizedBox(width: 20),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l10n.ancestralPortalOpen, style: GoogleFonts.outfit(color: AppTheme.sigiriyaOchre(context), fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 2)),
            SizedBox(height: 4),
            Text(l10n.stepIntoHistory, style: GoogleFonts.outfit(color: Theme.of(context).colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.bold)),
            Text(l10n.viewEraIn360(portal.era), style: GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 12)),
          ])),
          Icon(Icons.arrow_forward_ios, color: AppTheme.primaryBorder(context), size: 16),
        ]),
      ),
    );
  }
}

/// ðŸŽ¬ Cinematic AR Portal Sheet â€“ shows before AR launches
class _ARPortalSheet extends StatefulWidget {
  final DiscoveryPlace place;
  final bool isDemo;
  final VoidCallback onLaunch;
  const _ARPortalSheet({required this.place, required this.isDemo, required this.onLaunch});

  @override
  State<_ARPortalSheet> createState() => _ARPortalSheetState();
}

class _ARPortalSheetState extends State<_ARPortalSheet> with SingleTickerProviderStateMixin {
  late AnimationController _pulse;

  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _scale = Tween<double>(begin: 1.0, end: 1.06).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final Color accentColor = widget.isDemo ? const Color(0xFF29B6F6) : const Color(0xFFFFB300);
    final String tierLabel = widget.isDemo ? l10n.arDemoLabel : l10n.fullHeritageAr;
    final String tierIcon = widget.isDemo ? "â³" : "ðŸ›ï¸";

    return Container(
      margin: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: accentColor.withValues(alpha: 0.4), width: 1.5),
        boxShadow: [BoxShadow(color: accentColor.withValues(alpha: 0.2), blurRadius: 40, spreadRadius: 4)],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Portal ring animation
            ScaleTransition(
              scale: _scale,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: accentColor, width: 3),
                  boxShadow: [BoxShadow(color: accentColor.withValues(alpha: 0.5), blurRadius: 20, spreadRadius: 2)],
                ),
                child: Icon(Icons.view_in_ar, color: accentColor, size: 36),
              ),
            ),
            SizedBox(height: 20),
            Text(
              "$tierIcon  $tierLabel",
              style: GoogleFonts.inter(color: accentColor, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5),
            ),
            SizedBox(height: 8),
            Text(
              widget.place.name,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(color: Theme.of(context).colorScheme.onSurface, fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4),
            Text(
              widget.place.historicalPeriod.isNotEmpty ? widget.place.historicalPeriod : l10n.ancientHeritageSite,
              style: GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4), fontSize: 13),
            ),
            SizedBox(height: 28),
            // What to expect
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: accentColor.withValues(alpha: 0.2)),
              ),
              child: Column(
                children: [
                  _portalTip(Icons.tap_and_play_rounded, l10n.arTipPlace),
                  SizedBox(height: 8),
                  _portalTip(Icons.history_toggle_off_rounded, l10n.arTipTime),
                  if (!widget.isDemo) ...[
                    SizedBox(height: 8),
                    _portalTip(Icons.headphones_rounded, l10n.arTipAudio),
                    SizedBox(height: 8),
                    _portalTip(Icons.group_rounded, l10n.arTipGroup),
                  ],
                ],
              ),
            ),
            SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: Icon(Icons.rocket_launch_rounded),
                label: Text(widget.isDemo ? l10n.enterDemo : l10n.openArPortal, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15)),
                onPressed: widget.onLaunch,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.black,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 8,
                  shadowColor: accentColor.withValues(alpha: 0.6),
                ),
              ),
            ),
            SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel, style: GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4), fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _portalTip(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55), size: 18),
        SizedBox(width: 10),
        Expanded(child: Text(label, style: GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 12))),
      ],
    );
  }

}


class _DownloadButton extends StatefulWidget {
  final DiscoveryPlace place;
  const _DownloadButton({required this.place});

  @override
  State<_DownloadButton> createState() => _DownloadButtonState();
}

class _DownloadButtonState extends State<_DownloadButton> {
  bool isDownloading = false;
  double progress = 0;
  bool isDownloaded = false;

  @override
  void initState() {
    super.initState();
    _checkInitialStatus();
  }

  void _checkInitialStatus() async {
    final path = await AssetCacheService.getLocalPath(widget.place.arModelUrl);
    if (path != null && mounted) {
      if (mounted) setState(() => isDownloaded = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (isDownloaded) {
      return Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 14),
          SizedBox(width: 4),
          Text(l10n.offlineReady, style: GoogleFonts.inter(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      );
    }

    return GestureDetector(
      onTap: isDownloading ? null : () async {
        // Check Limits
        final canDownload = await UsageLimiterService.canDownloadOffline();
        if (!context.mounted) return;
        if (!canDownload) {
          showDialog(
            context: context,
            builder: (_) => LimitReachedDialog(
              featureName: 'Offline Downloads',
              onWatchAd: () {
                MonetizationService().showRewardedAd(
                  onRewardEarned: (reward) async {
                    await UsageLimiterService.provideBonusOfflineDownload();
                    if (!mounted || !context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Bonus Download Unlocked! Try downloading again.")),
                    );
                  },
                );
              },
            ),
          );
          return;
        }

        setState(() => isDownloading = true);
        
        try {
          // Download Model
          await AssetCacheService.downloadAsset(
            widget.place.arModelUrl, 
            onProgress: (p) {
              if (mounted) setState(() => progress = p * 0.7);
            }
          );
          
          // Download Audio (if exists)
          if (widget.place.audioUrlSi.isNotEmpty) {
            await AssetCacheService.downloadAsset(widget.place.audioUrlSi);
          }
          if (widget.place.audioUrlEn.isNotEmpty) {
            await AssetCacheService.downloadAsset(widget.place.audioUrlEn);
          }

          // Increment usage
          await UsageLimiterService.incrementOfflineDownload();

          if (context.mounted) {
            setState(() {
              isDownloading = false;
              isDownloaded = true;
            });
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.assetsCached)));
          }
        } catch (e) {
          if (context.mounted) {
            setState(() => isDownloading = false);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.downloadFailed)));
          }
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.glassBackground(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.primaryBorder(context)),
        ),
        child: isDownloading 
          ? SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, value: progress, color: AppPalette.sigiriyaOchre))
          : Row(
              children: [
                Icon(Icons.download_for_offline, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), size: 14),
                SizedBox(width: 6),
                Text(l10n.downloadForOffline, style: GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            ),
      ),
    );
  }

}


class PlaceDetailsScreenStats extends StatelessWidget {
  final DiscoveryPlace place;
  const PlaceDetailsScreenStats({super.key, required this.place});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink(); // Placeholder if needed
  }
}
