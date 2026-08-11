import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/config/app_config.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/oracle_ui_system.dart';
import '../../core/analytics/analytics_service.dart';
import '../../core/services/ar_service.dart';
import '../../data/models/ar_place_data.dart';
import '../../core/services/ar_support_service.dart';
import '../../core/services/asset_cache_service.dart';
import 'package:hidden_gems_sl/data/repositories/discovery_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/cached_image.dart';
import '../../core/services/media_cache_manager.dart';
import '../../data/models/discovery_place.dart';
import '../../data/datasources/user_preference_service.dart';
import '../../data/datasources/portal_service.dart';
import '../../core/services/usage_limiter_service.dart';
import '../../core/services/secure_entitlements.dart';
import '../../core/services/integrity_shield.dart';
import '../../core/services/translation_service.dart';
import '../../core/localization/l10n_utils.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/limit_reached_dialog.dart';
import 'ar_viewer_screen.dart';
import 'ar_upgrade_dialog.dart';
import 'ar_fallback_screen.dart';
import 'ar_coming_soon_screen.dart';
import 'premium_hub_screen.dart';
import '../../core/services/premium_unlock_service.dart';
import '../../data/datasources/monetization_service.dart';
import '../widgets/native_ad_widget.dart';
import '../widgets/banner_ad_widget.dart';
import 'heritage_passport_screen.dart';
import 'audio_guide_screen.dart';
import 'ancestral_portal_screen.dart';
import '../../core/services/explorer_progress_service.dart';

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

  // AR content isn't live yet (no trained/production 3D assets) — gate every
  // AR entry point on AppConfig.arFeatureEnabled as well as the place's own
  // arSupported flag, so flipping that one config value is enough to bring
  // AR back for a future release without touching this screen again.
  bool get _arAvailableForPlace => widget.place.arSupported && AppConfig.arFeatureEnabled;

  @override
  void initState() {
    super.initState();
    final profile = UserPreferenceService.getProfile();
    _isBookmarked = profile.bookmarkedPlaces.contains(widget.place.id);

    // Record the visit only once GPS confirms real-world proximity — fixes
    // "Places" stat and Level progress without letting casual in-app browsing
    // (opening lots of detail pages from the couch) inflate them.
    _recordVisitIfNearby();
  }

  static const double _visitProximityMeters = 500;

  Future<void> _recordVisitIfNearby() async {
    final placeId = widget.place.id;
    try {
      // Security: a GPS proximity check alone is spoofable by any
      // mock-location app — this can't be made server-verified without new
      // attestation infrastructure, but IntegrityShield's existing
      // device-tamper/mock-location signal set (already used to gate
      // premium features) is a reasonable proportionate check to reuse
      // here, rather than trusting an unconditioned on-device GPS reading
      // to award heritage-passport stamps / explorer badges / level
      // progress.
      if (IntegrityShield().riskScore >= 60) return;

      final repository = ref.read(discoveryRepositoryProvider);
      final userPos = await repository.getCurrentLocation().timeout(const Duration(seconds: 8));
      if (userPos == null) return;

      final distanceMeters = Geolocator.distanceBetween(
        userPos.latitude, userPos.longitude, widget.place.lat, widget.place.lng,
      );
      if (distanceMeters > _visitProximityMeters) return;

      // Adds to visitedPlaces list (fixes Places: 0 bug)
      await UserPreferenceService.addVisitedPlace(placeId);
      // Triggers explorer level calculation (fixes Level stuck at 1 bug)
      await ExplorerProgressService().recordSiteVisit(placeId);
    } catch (_) {
      // No location permission / GPS unavailable — just don't record.
      // Viewing a place's details shouldn't be blocked or show an error
      // over this, unlike the AR unlock flow which requires location.
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return FutureBuilder<bool>(
      future: PremiumUnlockService.hasAccess(widget.place.id, arTier: widget.place.arTier),
      builder: (context, snapshot) {
        // Fail closed: while hasAccess() is still resolving or errors out,
        // treat the place as locked rather than granting free premium
        // access for the duration of every screen open.
        final hasAccess = snapshot.data ?? false;

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: OracleUI.auraBackground(
            child: Stack(
              children: [
                CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
    _buildHeroImage(context, l10n),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildStatPillStrip(context, l10n).animate().fadeIn(duration: 600.ms),
                            const SizedBox(height: 26),
                            _buildDescription(context, l10n).animate().fadeIn(duration: 600.ms),
                            const SizedBox(height: 24),
                            _buildPhotoGallery(context, l10n).animate().fadeIn(duration: 600.ms),
                            const SizedBox(height: 24),
                            _buildAIReason(context, l10n).animate().fadeIn(delay: 200.ms, duration: 600.ms).slideY(begin: 0.1),
                            const SizedBox(height: 24),
                            _buildSponsoredExperience().animate().fadeIn(delay: 300.ms, duration: 600.ms),
                            const SizedBox(height: 28),
                            _buildGoodToKnowCard(context, l10n).animate().fadeIn(delay: 400.ms, duration: 600.ms),
                            const SizedBox(height: 28),
                            if (_hasFieldNotes())
                              _buildFieldNotesCard(context, l10n).animate().fadeIn(delay: 500.ms, duration: 600.ms),
                            if (_hasFieldNotes()) const SizedBox(height: 24),
                            _buildEtiquetteSection(context, l10n).animate().fadeIn(delay: 600.ms, duration: 600.ms),
                            const SizedBox(height: 20),
                            _buildAncestralPortalCard(context).animate().fadeIn(delay: 700.ms, duration: 600.ms).shimmer(delay: 2.seconds, duration: 1500.ms),
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
    // Scrim uses the screen's own background color (not a hardcoded black)
    // so it sits behind the glass card consistently in both themes instead
    // of a stark black backdrop clashing with the app's warm light theme.
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.92),
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
                l10n.heritageSiteLocked,
                style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: AppPalette.sigiriyaOchre),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.lockOverlayDescription,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: AppTheme.textSecondary(context), height: 1.5),
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
                  icon: Icon(Icons.play_circle_outline, color: AppTheme.colors.black),
                  label: Text(l10n.watchAdToUnlock, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppTheme.colors.black)),
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
                child: Text(l10n.goBack, style: TextStyle(color: AppTheme.textSecondary(context).withValues(alpha: 0.7))),
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
      l10n.etiquetteTipReusableBottle,
      l10n.etiquetteTipAvoidPlastic,
      l10n.etiquetteTipRespectWildlife,
    ];

    if (cat.contains("temple") || cat.contains("culture") || cat.contains("historical")) {
      title = l10n.culturalEtiquette;
      icon = Icons.temple_buddhist_outlined;
      tips = [
        l10n.etiquetteTipRemoveShoes,
        l10n.etiquetteTipDressModestly,
        l10n.etiquetteTipAskPhotoPermission,
        l10n.etiquetteTipNoBackToStatues,
      ];
    } else if (cat.contains("nature") || cat.contains("waterfall") || cat.contains("hiking")) {
      title = l10n.ecoResponsibleTravel;
      icon = Icons.nature_people_outlined;
      tips = [
        l10n.etiquetteTipStayOnTrails,
        l10n.etiquetteTipPackOutTrash,
        l10n.etiquetteTipNoFeedingAnimals,
        l10n.etiquetteTipNoSoapInPools,
      ];
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceMuted(context),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary, size: 18),
              const SizedBox(width: 10),
              Text(
                title,
                style: GoogleFonts.outfit(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppTheme.textPrimary(context), letterSpacing: 0.3),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...tips.map((tip) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              "·  $tip",
              style: GoogleFonts.inter(color: AppTheme.textPrimary(context).withValues(alpha: 0.75), fontSize: 12.5),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildHeroImage(BuildContext context, AppLocalizations l10n) {
    return SliverAppBar(
      expandedHeight: 380,
      pinned: true,
      stretch: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      elevation: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground, StretchMode.blurBackground],
        background: Stack(
          fit: StackFit.expand,
          children: [
            CachedImage(
              url: widget.place.heroImageUrl,
              fit: BoxFit.cover,
              poolType: CachePoolType.full,
            ),
            // Top overlay for back/action button visibility
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppTheme.colors.black.withValues(alpha: 0.45),
                    AppTheme.colors.transparent,
                  ],
                  stops: const [0, 0.22],
                ),
              ),
            ),
            // Bottom fade so the overlapping title block stays legible
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppTheme.colors.transparent,
                    Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.85),
                    Theme.of(context).scaffoldBackgroundColor,
                  ],
                  stops: const [0.42, 0.92, 1],
                ),
              ),
            ),
            // Back button
            Positioned(
              top: 56,
              left: 16,
              child: _heroIconButton(
                context,
                icon: Icons.arrow_back_ios_new_rounded,
                onTap: () => Navigator.pop(context),
              ),
            ),
            // Audio guide + heritage passport actions
            Positioned(
              top: 56,
              right: 16,
              child: Row(
                children: [
                  _heroIconButton(
                    context,
                    icon: Icons.audiotrack_outlined,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AudioGuideScreen(place: widget.place)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _heroIconButton(
                    context,
                    icon: Icons.wallet_membership_outlined,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const HeritagePassportScreen()),
                    ),
                  ),
                ],
              ),
            ),
            if (_arAvailableForPlace)
              Positioned(
                top: 104,
                right: 16,
                child: _buildARTierBadge(context, widget.place.arTier),
              )
            else if (widget.place.category.isNotEmpty)
              Positioned(
                top: 104,
                right: 16,
                child: _buildCategoryBadge(context, l10n),
              ),
            // Title block overlapping the hero bottom
            Positioned(
              left: 20,
              right: 20,
              bottom: 26,
              child: _buildHeaderInfo(context, l10n),
            ),
          ],
        ),
      ),
    );
  }

  Widget _heroIconButton(BuildContext context, {required IconData icon, required VoidCallback onTap}) {
    return ClipOval(
      child: Material(
        color: AppTheme.colors.black.withValues(alpha: 0.28),
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: 36,
            height: 36,
            child: Icon(icon, color: AppTheme.colors.white, size: 16),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryBadge(BuildContext context, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
      decoration: BoxDecoration(
        color: AppTheme.colors.black.withValues(alpha: 0.32),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.account_balance_outlined, color: Colors.white, size: 13),
          const SizedBox(width: 7),
          Text(
            L10nUtils.getLocalizedCategory(context, widget.place.category).toUpperCase(),
            style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.colors.white, letterSpacing: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildARTierBadge(BuildContext context, int tier) {
    final l10n = AppLocalizations.of(context)!;
    String label = l10n.arBadgeHeritage;

    if (tier == 2) {
      label = l10n.arBadgeExplore;
    } else if (tier == 3) {
      label = l10n.arBadgeStory;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
      decoration: BoxDecoration(
        color: AppTheme.colors.black.withValues(alpha: 0.32),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.account_balance_outlined, color: AppTheme.colors.white, size: 13),
          const SizedBox(width: 7),
          Text(
            label.toUpperCase(),
            style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.colors.white, letterSpacing: 1.5),
          ),
        ],
      ),
    ).animate(onPlay: (c) => c.repeat()).shimmer(
      duration: 3.seconds,
      color: AppTheme.colors.white.withValues(alpha: 0.15),
    );
  }
  Widget _buildHeaderInfo(BuildContext context, AppLocalizations l10n) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.place.name,
                style: GoogleFonts.outfit(
                  fontSize: 27,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.onSurface,
                  height: 1.08,
                  letterSpacing: -0.4
                ).copyWith(
                  fontFamilyFallback: [GoogleFonts.abhayaLibre().fontFamily!, GoogleFonts.hindGuntur().fontFamily!],
                ),
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.location_on_rounded, color: Theme.of(context).colorScheme.primary, size: 13),
                  SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      widget.place.distanceKm > 0
                          ? "${widget.place.district} · ${widget.place.distanceKm.toStringAsFixed(1)} km"
                          : widget.place.district,
                      style: GoogleFonts.inter(fontSize: 11.5, color: AppTheme.textSecondary(context), fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(width: 12),
        _buildBookmarkSquare(context, l10n),
      ],
    );
  }

  Widget _buildBookmarkSquare(BuildContext context, AppLocalizations l10n) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.primaryBorder(context)),
        boxShadow: AppTheme.softShadow,
      ),
      child: Material(
        color: AppTheme.colors.transparent,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () async {
            HapticFeedback.mediumImpact();
            final nowBookmarked = await UserPreferenceService.toggleBookmark(widget.place.id);
            if (!context.mounted) return;
            setState(() => _isBookmarked = nowBookmarked);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(nowBookmarked ? l10n.bookmarkAddedSnackbar : l10n.bookmarkRemovedSnackbar),
              backgroundColor: AppTheme.accentOchre(context),
            ));
          },
          child: Icon(
            _isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
            color: Theme.of(context).colorScheme.primary,
            size: 18,
          ),
        ),
      ),
    );
  }

  // Admin can upload multiple gallery photos per place (Media tab), and the
  // full images[] list is parsed onto the model, but this screen's hero
  // only ever showed the single cover image — every other uploaded photo
  // was wasted admin effort, invisible to any user. Only shown when there's
  // more than one photo, since the hero already covers the single-photo case.
  Widget _buildPhotoGallery(BuildContext context, AppLocalizations l10n) {
    final images = widget.place.images;
    if (images.length <= 1) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.photosLabel,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.primary,
            fontSize: 11,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 88,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: images.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => _openGalleryViewer(context, images, index),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: CachedImage(
                    url: images[index].thumbPath,
                    width: 88,
                    height: 88,
                    fit: BoxFit.cover,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _openGalleryViewer(BuildContext context, List<PlaceImageModel> images, int initialIndex) {
    HapticFeedback.selectionClick();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _FullscreenGalleryViewer(images: images, initialIndex: initialIndex),
        fullscreenDialog: true,
      ),
    );
  }

  // The admin panel's plain-text "description" field was written to the
  // model (see PlaceResource.php) but had no widget reading it anywhere —
  // this screen only ever displayed aiReason (a separate AI-generated
  // blurb), so an admin's own description text never reached the app.
  Widget _buildDescription(BuildContext context, AppLocalizations l10n) {
    if (widget.place.description.trim().isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.aboutSectionTitle,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.primary,
            fontSize: 11,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          widget.place.description,
          style: GoogleFonts.inter(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.9),
            height: 1.7,
            fontSize: 15,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildAIReason(BuildContext context, AppLocalizations l10n) {
    if (widget.place.aiReason.isEmpty) return const SizedBox.shrink();
    final currentLocale = Localizations.localeOf(context).languageCode;
    final canTranslate = currentLocale == 'si' && _translatedAiReason == null;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 3,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.oracleVision,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 11,
                  letterSpacing: 0.5
                )
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
            ).copyWith(
              fontFamilyFallback: [GoogleFonts.abhayaLibre().fontFamily!, GoogleFonts.hindGuntur().fontFamily!],
            )
          ),
          if (_arAvailableForPlace) ...[
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
            ),
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

  Widget _buildStatPillStrip(BuildContext context, AppLocalizations l10n) {
    final pills = <Widget>[
      // Always available — every place has coordinates, and the admin panel
      // captures GPS lat/lng but this screen had no way to actually surface
      // them (no embedded map, no external-maps link). Opens the device's
      // own maps app via a plain geo: URI — no Maps SDK/API key/billing
      // involved, unlike the embedded map used elsewhere in the app.
      _statPill(
        context,
        Icons.directions_outlined,
        l10n.getDirections,
        onTap: () => _openDirections(context, l10n),
      ),
      if (widget.place.bestTime.isNotEmpty)
        _statPill(context, Icons.schedule_rounded, l10n.bestAtLabel(widget.place.bestTime)),
      if (widget.place.ticketRange.isNotEmpty)
        _statPill(context, Icons.confirmation_number_outlined, widget.place.ticketRange),
      // openingHours is captured by the admin form (Travel Insights tab) and
      // parsed by DiscoveryPlace, but had no widget displaying it anywhere
      // on this screen — a visitor could never see when a place is open.
      if (widget.place.openingHours.isNotEmpty)
        _statPill(context, Icons.access_time_rounded, widget.place.openingHours),
      if (_arAvailableForPlace)
        _statPill(
          context,
          Icons.view_in_ar_outlined,
          l10n.arHeritageReady,
          accent: AppTheme.sigiriyaOchre(context),
        ),
    ];

    if (pills.isEmpty) return const SizedBox.shrink();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < pills.length; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            pills[i],
          ],
        ],
      ),
    );
  }

  Future<void> _openDirections(BuildContext context, AppLocalizations l10n) async {
    HapticFeedback.selectionClick();
    final lat = widget.place.lat;
    final lng = widget.place.lng;
    final label = Uri.encodeComponent(widget.place.name);
    // geo: is handled by whatever maps app is installed (Google Maps,
    // or any other) — falls back to a Google Maps web URL if no app
    // claims the geo: scheme (e.g. some emulators, or GPS disabled).
    final geoUri = Uri.parse('geo:$lat,$lng?q=$lat,$lng($label)');
    final webUri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');

    final launched = await canLaunchUrl(geoUri) && await launchUrl(geoUri);
    if (!launched && await canLaunchUrl(webUri)) {
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
      return;
    }
    if (!launched) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.couldNotOpenMaps)));
    }
  }

  Widget _statPill(BuildContext context, IconData icon, String label, {Color? accent, VoidCallback? onTap}) {
    final color = accent ?? AppTheme.textPrimary(context);
    final pill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: accent != null ? accent.withValues(alpha: 0.15) : AppTheme.surfaceMuted(context),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
    if (onTap == null) return pill;
    return Material(
      color: AppTheme.colors.transparent,
      borderRadius: BorderRadius.circular(100),
      child: InkWell(borderRadius: BorderRadius.circular(100), onTap: onTap, child: pill),
    );
  }

  Widget _buildGoodToKnowCard(BuildContext context, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.goodToKnow,
          style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary(context)),
        ),
        const SizedBox(height: 14),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.primaryBorder(context)),
          ),
          child: Column(
            children: [
              _goodToKnowRow(context, Icons.info_outline, l10n.theKnowledge, Theme.of(context).colorScheme.primary, _buildDetailsChips(context, l10n), showDivider: true),
              _goodToKnowRow(context, Icons.warning_amber_rounded, l10n.safetyProtocols, AppTheme.errorRed, _buildRiskTags(context), showDivider: true),
              _goodToKnowRow(context, Icons.local_cafe_outlined, l10n.provisions, AppTheme.colors.teal.shade700, _buildFacilities(context), showDivider: false),
            ],
          ),
        ),
      ],
    );
  }

  Widget _goodToKnowRow(BuildContext context, IconData icon, String title, Color iconColor, Widget content, {required bool showDivider}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: showDivider
          ? BoxDecoration(border: Border(bottom: BorderSide(color: AppTheme.primaryBorder(context))))
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 14),
              Text(
                title,
                style: GoogleFonts.outfit(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppTheme.textPrimary(context)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(left: 32),
            child: content,
          ),
        ],
      ),
    );
  }

  Widget _buildFieldNotesCard(BuildContext context, AppLocalizations l10n) {
    final entries = _fieldNoteEntries(context, l10n);
    if (entries.isEmpty) return const SizedBox.shrink();

    // Prose-style fields (activities, condition notes) can run to a full
    // sentence and don't fit a fixed-aspect-ratio grid tile without
    // overflowing — they render as their own full-width rows instead of
    // being forced into the 2-column compact grid.
    final compact = entries.where((e) => !e.$4).toList();
    final prose = entries.where((e) => e.$4).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              l10n.fieldNotesTitle,
              style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary(context)),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.sigiriyaOchre(context).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                "${entries.length}",
                style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppTheme.sigiriyaOchre(context)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (compact.isNotEmpty)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: compact.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.15,
            ),
            itemBuilder: (context, i) => _fieldNoteTile(context, compact[i].$1, compact[i].$2, compact[i].$3),
          ),
        if (compact.isNotEmpty && prose.isNotEmpty) const SizedBox(height: 12),
        for (var i = 0; i < prose.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          _fieldNoteProseRow(context, prose[i].$1, prose[i].$2, prose[i].$3),
        ],
      ],
    );
  }

  List<(IconData, String, String, bool)> _fieldNoteEntries(BuildContext context, AppLocalizations l10n) {
    final p = widget.place;
    return <(IconData, String, String, bool)>[
      (Icons.signal_cellular_alt_rounded, l10n.fieldNoteMobileSignal, p.mobileSignal, false),
      (Icons.route_outlined, l10n.fieldNoteRoadCondition, p.roadCondition, false),
      (Icons.hiking_rounded, l10n.fieldNoteActivities, p.activities, true),
      (Icons.trending_up_rounded, l10n.fieldNotePopularity, p.touristPopularity, false),
      (Icons.family_restroom_rounded, l10n.fieldNoteFamilyFriendly, p.familyFriendly, false),
      (Icons.savings_outlined, l10n.fieldNoteBudget, p.budgetCategory, false),
      (Icons.wc_rounded, l10n.fieldNoteToilets, p.toilets, false),
      (Icons.restaurant_outlined, l10n.fieldNoteFoodNearby, p.foodNearby, false),
      (Icons.accessible_rounded, l10n.fieldNoteWheelchairAccess, p.wheelchairAccess, false),
      (Icons.forest_outlined, l10n.fieldNoteCamping, p.campingAllowed, false),
      (Icons.shield_outlined, l10n.fieldNoteSafetyLevel, p.safetyLevel, false),
      (Icons.pets_outlined, l10n.fieldNoteWildlifeHazard, p.wildlifeHazard, true),
      (Icons.person_pin_circle_outlined, l10n.fieldNoteGuideRequired, p.guideRequired, false),
      (Icons.water_drop_outlined, l10n.fieldNoteRainSensitivity, p.rainSensitivity, false),
      (Icons.cloud_outlined, l10n.fieldNoteMonsoonNote, p.monsoonNote, true),
      (Icons.surfing_outlined, l10n.fieldNoteSurfing, p.surfing, false),
      if ((double.tryParse(p.heightM) ?? 0) > 0) (Icons.height_rounded, l10n.fieldNoteHeight, "${p.heightM} m", false),
      if ((double.tryParse(p.lengthKm) ?? 0) > 0) (Icons.straighten_rounded, l10n.fieldNoteLength, "${p.lengthKm} km", false),
    ].where((e) => e.$3.trim().isNotEmpty).toList();
  }

  Widget _fieldNoteProseRow(BuildContext context, IconData icon, String label, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceMuted(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textSecondary(context), letterSpacing: 0.3),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textPrimary(context), height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _fieldNoteTile(BuildContext context, IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceMuted(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 22, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 10),
          Text(
            label.toUpperCase(),
            style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppTheme.textSecondary(context), letterSpacing: 0.2),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary(context)),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
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
    if (widget.place.riskTags.isEmpty) return Text(AppLocalizations.of(context)!.noRiskTagsFound, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 13));
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: widget.place.riskTags.map((t) => _chip(context, t, AppTheme.errorRed)).toList(),
    );
  }

  Widget _buildFacilities(BuildContext context) {
    if (widget.place.facilities.isEmpty) return Text(AppLocalizations.of(context)!.noFacilitiesFound, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 13));
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: widget.place.facilities.map((t) => _chip(context, t, AppTheme.colors.primary)).toList(),
    );
  }

  bool _hasFieldNotes() {
    final p = widget.place;
    return [
      p.mobileSignal, p.roadCondition, p.activities, p.touristPopularity,
      p.familyFriendly, p.budgetCategory, p.toilets, p.foodNearby,
      p.wheelchairAccess, p.campingAllowed, p.safetyLevel, p.wildlifeHazard,
      p.guideRequired, p.rainSensitivity, p.monsoonNote, p.surfing,
    ].any((v) => v.trim().isNotEmpty) ||
        (double.tryParse(p.heightM) ?? 0) > 0 ||
        (double.tryParse(p.lengthKm) ?? 0) > 0;
  }

  Widget _chip(BuildContext context, String label, Color color) {
    final isNeutral = color == Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4) ||
        color == Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isNeutral ? AppTheme.surfaceMuted(context) : color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isNeutral ? AppTheme.textSecondary(context) : color,
        ),
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    return Container(
      color: AppTheme.colors.transparent,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      child: Row(
        children: [
          Container(
            height: 56,
            width: 56,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.primaryBorder(context)),
              boxShadow: AppTheme.softShadow,
            ),
            child: Material(
              color: AppTheme.colors.transparent,
              borderRadius: BorderRadius.circular(18),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () async {
                  HapticFeedback.mediumImpact();
                  final nowBookmarked = await UserPreferenceService.toggleBookmark(widget.place.id);
                  if (!context.mounted) return;
                  setState(() => _isBookmarked = nowBookmarked);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(nowBookmarked
                        ? l10n.bookmarkAddedSnackbar
                        : l10n.bookmarkRemovedSnackbar),
                    backgroundColor: AppTheme.accentOchre(context),
                  ));
                },
                child: Icon(
                  _isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                  color: _isBookmarked
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(100),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.32),
                    blurRadius: 26,
                    offset: const Offset(0, 12),
                  )
                ],
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.colors.transparent,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  shadowColor: AppTheme.colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                ),
                onPressed: () async {
                  HapticFeedback.mediumImpact();
                  if (_arAvailableForPlace) {
                    _handleARLaunch(context, ref, l10n);
                  } else if (widget.place.arSupported && !AppConfig.arFeatureEnabled) {
                    // This place genuinely has AR content tagged — the
                    // feature itself is just switched off app-wide, so say
                    // that rather than silently falling back to the
                    // unrelated "Add to Destiny" action.
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ARComingSoonScreen(placeName: widget.place.name)),
                    );
                  } else {
                    final nowAdded = await UserPreferenceService.toggleItinerary(widget.place.id);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(nowAdded
                            ? l10n.itineraryAddedSnackbar(widget.place.name)
                            : l10n.itineraryRemovedSnackbar),
                    ));
                  }
                },
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _arAvailableForPlace
                            ? Icons.view_in_ar
                            : (widget.place.arSupported ? Icons.view_in_ar_outlined : Icons.auto_fix_high),
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _arAvailableForPlace
                            ? l10n.invokeAr
                            : (widget.place.arSupported ? l10n.comingSoonButton : l10n.addToDestiny),
                        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
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

    // Security: server-verified, not the local cached profile flag — a
    // tampered local profile must not be able to bypass the AR proximity
    // lock (see SecureEntitlements docs; same class of bug already fixed in
    // UsageLimiterService).
    final isPremium = await SecureEntitlements().verifyPremium();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.colors.white)),
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

    // BUG FIX: canAccessArSession()/incrementArSession() were previously
    // only ever called on the `isPremium` branch (whose monthly quota is
    // 9999, i.e. effectively unlimited) — free users always fell into the
    // ARUpgradeDialog branch below regardless of whether they still had
    // their free monthly AR session available, so the free tier's
    // `ar_sessions_per_month` entitlement was never actually reachable.
    // Both tiers must go through the same check-then-consume flow; only
    // once a tier's quota is exhausted should the paywall/ad-unlock UI show.
    final canAccess = await UsageLimiterService.canAccessArSession();
    if (!context.mounted) return;

    if (canAccess) {
      // incrementArSession() is the real, atomic enforcement point (a
      // Firestore transaction) — canAccess above is just a cheap UI
      // pre-check and can't be trusted alone against concurrent/rapid
      // launches. If a concurrent call already consumed the last slot,
      // this returns false and we fall through to the limit-reached UI
      // instead of navigating to AR content the user didn't actually earn.
      final claimed = await UsageLimiterService.incrementArSession();
      if (!context.mounted) return;
      if (claimed) {
        _navigateToAR(context);
        return;
      }
    }

    if (isPremium) {
      showDialog(
        context: context,
        builder: (_) => LimitReachedDialog(
          featureName: AppLocalizations.of(context)!.featureNameHeritageSessions,
          onWatchAd: () {
            MonetizationService().showRewardedAd(
              onRewardEarned: (reward) async {
                await UsageLimiterService.provideBonusArSession();
                if (!mounted || !context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(AppLocalizations.of(context)!.bonusSessionUnlockedSnackbar)),
                );
              },
            );
          },
        ),
      );
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
                    SnackBar(
                      content: Text(AppLocalizations.of(context)!.oracleRewardActiveSnackbar),
                      backgroundColor: AppTheme.colors.green,
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
        backgroundColor: AppTheme.colors.transparent,
        contentPadding: EdgeInsets.all(0),
        content: Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: (Theme.of(context).brightness == Brightness.dark ? AppTheme.colors.black : AppTheme.colors.white).withValues(alpha: 0.9),
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
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(AppLocalizations.of(context)!.okButton))],
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
      backgroundColor: AppTheme.colors.transparent,
      barrierColor: AppTheme.colors.black.withValues(alpha: 0.85),
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
    final l10n = AppLocalizations.of(context)!;
    return ARPlaceData(
      arSupported: widget.place.arSupported,
      arTier: widget.place.arTier,
      // Admin sets ar_brand_name in the AR & Audio tab, and it reaches this
      // model correctly (PlaceResource -> DiscoveryPlace.arBrandName), but
      // this line used to always override it with a hardcoded tier-based
      // localized string, silently discarding whatever the admin entered.
      arBrandName: widget.place.arBrandName.isNotEmpty
          ? widget.place.arBrandName
          : (widget.place.arTier == 1 ? l10n.arBrandNameHeritage : l10n.arBrandNameExplore),
      arModelUrl: widget.place.arModelUrl.isNotEmpty
          ? widget.place.arModelUrl
          : "https://github.com/KhronosGroup/glTF-Sample-Models/raw/master/2.0/Duck/glTF-Binary/Duck.glb",
      arHistoricalModelUrl: widget.place.arHistoricalModelUrl.isNotEmpty
          ? widget.place.arHistoricalModelUrl
          : "https://raw.githubusercontent.com/KhronosGroup/glTF-Sample-Models/master/2.0/AntiqueCamera/glTF-Binary/AntiqueCamera.glb",
      arModelScale: widget.place.arModelScale > 0 ? widget.place.arModelScale : 0.01,
      historicalPeriod: widget.place.historicalPeriod.isNotEmpty ? widget.place.historicalPeriod : l10n.ancientHeritageSite,
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
    final Color accentColor = widget.isDemo ? AppTheme.colors.primary : AppTheme.colors.primary;
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
                  foregroundColor: AppTheme.colors.black,
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
        Icon(icon, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65), size: 18),
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
          Icon(Icons.check_circle, color: AppTheme.colors.green, size: 14),
          SizedBox(width: 4),
          Text(l10n.offlineReady, style: GoogleFonts.inter(color: AppTheme.colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
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
              featureName: l10n.featureNameOfflineDownloads,
              onWatchAd: () {
                MonetizationService().showRewardedAd(
                  onRewardEarned: (reward) async {
                    await UsageLimiterService.provideBonusOfflineDownload();
                    if (!mounted || !context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(AppLocalizations.of(context)!.bonusDownloadUnlockedSnackbar)),
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

/// Minimal fullscreen swipeable photo viewer for a place's gallery — kept
/// self-contained (no new package dependency) rather than pulling in a
/// pinch-zoom library for what is currently a simple swipe-through-photos need.
class _FullscreenGalleryViewer extends StatefulWidget {
  final List<PlaceImageModel> images;
  final int initialIndex;

  const _FullscreenGalleryViewer({required this.images, required this.initialIndex});

  @override
  State<_FullscreenGalleryViewer> createState() => _FullscreenGalleryViewerState();
}

class _FullscreenGalleryViewerState extends State<_FullscreenGalleryViewer> {
  late final PageController _controller;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: widget.images.length,
            onPageChanged: (i) => setState(() => _currentIndex = i),
            itemBuilder: (context, index) {
              final img = widget.images[index];
              return InteractiveViewer(
                minScale: 1.0,
                maxScale: 4.0,
                child: Center(
                  child: CachedImage(
                    url: img.fullPath.isNotEmpty ? img.fullPath : img.thumbPath,
                    fit: BoxFit.contain,
                  ),
                ),
              );
            },
          ),
          Positioned(
            top: 48,
            left: 12,
            child: IconButton(
              icon: Icon(Icons.close_rounded, color: AppTheme.colors.white, size: 28),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.colors.black54,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  '${_currentIndex + 1} / ${widget.images.length}',
                  style: GoogleFonts.inter(color: AppTheme.colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
