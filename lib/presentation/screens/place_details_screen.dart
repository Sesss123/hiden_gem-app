import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/oracle_ui_system.dart';
import '../../core/services/opening_hours_service.dart';
import '../../core/services/travel_time_service.dart';
import '../../core/services/health_safety_service.dart';
import '../../core/localization/health_safety_localization.dart';
import '../../core/services/food_safety_guidance.dart';
import '../../core/services/disaster_alert_service.dart';
import '../../core/utils/result.dart';
import 'package:hidden_gems_sl/data/repositories/discovery_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/cached_image.dart';
import '../../core/services/media_cache_manager.dart';
import '../../data/models/discovery_place.dart';
import '../../data/datasources/user_preference_service.dart';
import '../../core/services/integrity_shield.dart';
import '../../core/services/translation_service.dart';
import '../../core/localization/l10n_utils.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/native_ad_widget.dart';
import '../widgets/banner_ad_widget.dart';
import 'heritage_passport_screen.dart';
import 'audio_guide_screen.dart';
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

  @override
  void initState() {
    super.initState();
    final profile = UserPreferenceService.getProfile();
    _isBookmarked = profile.bookmarkedPlaces.contains(widget.place.id);

    // Track recently viewed place for traveler hub
    UserPreferenceService.addRecentlyViewedPlace(widget.place.id);

    // Record the visit only once GPS confirms real-world proximity — fixes
    // "Places" stat and Level progress without letting casual in-app browsing
    // (opening lots of detail pages from the couch) inflate them.
    _recordVisitIfNearby();
  }

  static const double _visitProximityMeters = 500;

  Future<void> _recordVisitIfNearby() async {
    final placeId = widget.place.id;
    try {
      if (IntegrityShield().riskScore >= 60) return;

      final repository = ref.read(discoveryRepositoryProvider);
      final userPos = await repository
          .getCurrentLocation()
          .timeout(const Duration(seconds: 8));
      if (userPos == null) return;

      final distanceMeters = Geolocator.distanceBetween(
        userPos.latitude,
        userPos.longitude,
        widget.place.lat,
        widget.place.lng,
      );
      if (distanceMeters > _visitProximityMeters) return;

      // Adds to visitedPlaces list (fixes Places: 0 bug)
      await UserPreferenceService.addVisitedPlace(placeId);
      // Triggers explorer level calculation (fixes Level stuck at 1 bug)
      await ExplorerProgressService().recordSiteVisit(placeId);
    } catch (_) {
      // No location permission / GPS unavailable — just don't record.
      // Viewing a place's details shouldn't be blocked or show an error.
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

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
                        // 1. Open / Closed & Structured Opening Hours
                        _buildOpeningHoursBanner(context, l10n)
                            .animate()
                            .fadeIn(duration: 500.ms),
                        const SizedBox(height: 18),

                        // 2. Distance & Route-Based Travel Time (Terrain-Weighted)
                        _buildRouteTravelTimeSection(context, l10n)
                            .animate()
                            .fadeIn(duration: 550.ms),
                        const SizedBox(height: 18),

                        // 3. Ticket Price & Admission
                        if (_hasTicketAndBudgetData()) ...[
                          _buildTicketAndBudgetCard(context, l10n)
                              .animate()
                              .fadeIn(duration: 600.ms),
                          const SizedBox(height: 18),
                        ],

                        // 4. Safety & Weather Warning
                        if (_hasSafetyAndWeatherData()) ...[
                          _buildSafetyAndWeatherCard(context, l10n)
                              .animate()
                              .fadeIn(duration: 650.ms),
                          const SizedBox(height: 18),
                        ],

                        // 5. Toilets, Parking, Mobile Signal & Facilities
                        _buildEssentialFacilitiesCard(context, l10n)
                            .animate()
                            .fadeIn(duration: 700.ms),
                        const SizedBox(height: 18),

                        // 6. Nearby Essentials (1-Tap Search)
                        _buildNearbyEssentialsSection(context, l10n)
                            .animate()
                            .fadeIn(duration: 750.ms),
                        const SizedBox(height: 18),

                        // 7. Reviews & Ratings
                        _buildReviewsSection(context, l10n)
                            .animate()
                            .fadeIn(duration: 800.ms),
                        const SizedBox(height: 22),

                        // 8. Description, Curated Story & Media
                        _buildStatPillStrip(context, l10n)
                            .animate()
                            .fadeIn(duration: 600.ms),
                        const SizedBox(height: 24),
                        if (widget.place.description.trim().isNotEmpty) ...[
                          _buildDescription(context, l10n)
                              .animate()
                              .fadeIn(duration: 600.ms),
                          const SizedBox(height: 24),
                        ],
                        if (widget.place.images.length > 1) ...[
                          _buildPhotoGallery(context, l10n)
                              .animate()
                              .fadeIn(duration: 600.ms),
                          const SizedBox(height: 24),
                        ],
                        if (widget.place.aiReason.trim().isNotEmpty) ...[
                          _buildAIReason(context, l10n)
                              .animate()
                              .fadeIn(delay: 200.ms, duration: 600.ms)
                              .slideY(begin: 0.1),
                          const SizedBox(height: 24),
                        ],
                        _buildSponsoredExperience()
                            .animate()
                            .fadeIn(delay: 300.ms, duration: 600.ms),
                        const SizedBox(height: 28),
                        _buildGoodToKnowCard(context, l10n)
                            .animate()
                            .fadeIn(delay: 400.ms, duration: 600.ms),
                        const SizedBox(height: 28),
                        if (_hasFieldNotes())
                          _buildFieldNotesCard(context, l10n)
                              .animate()
                              .fadeIn(delay: 500.ms, duration: 600.ms),
                        if (_hasFieldNotes()) const SizedBox(height: 24),
                        _buildEtiquetteSection(context, l10n)
                            .animate()
                            .fadeIn(delay: 600.ms, duration: 600.ms),
                        const SizedBox(height: 20),
                        _buildNearbyPlacesSection(context, l10n)
                            .animate()
                            .fadeIn(delay: 800.ms, duration: 600.ms),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                )
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const BannerAdWidget(),
          SafeArea(
            top: false,
            child: _buildBottomActions(context, ref, l10n),
          ),
        ],
      ),
    );
  }

  Widget _buildOpeningHoursBanner(BuildContext context, AppLocalizations l10n) {
    final status = OpeningHoursService.evaluate(
      widget.place.openingHours,
      weeklyHours: widget.place.weeklyHours,
      temporarilyClosed: widget.place.temporarilyClosed,
      closureNote: widget.place.closureNote,
      closureUntil: widget.place.closureUntil,
      holidayHoursNote: widget.place.holidayHoursNote,
      riskTags: widget.place.riskTags,
      monsoonNote: widget.place.monsoonNote,
    );

    Color statusColor = AppTheme.colors.green;
    IconData statusIcon = Icons.check_circle_outline_rounded;
    switch (status.status) {
      case OpenStatus.open:
      case OpenStatus.alwaysOpen:
        statusColor = AppTheme.colors.green;
        statusIcon = Icons.check_circle_outline_rounded;
        break;
      case OpenStatus.closingSoon:
        statusColor = Colors.orange;
        statusIcon = Icons.access_time_rounded;
        break;
      case OpenStatus.closed:
        statusColor = AppTheme.errorRed;
        statusIcon = Icons.cancel_outlined;
        break;
      case OpenStatus.unknown:
        statusColor = Theme.of(context).colorScheme.primary;
        statusIcon = Icons.access_time_rounded;
        break;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: statusColor.withValues(alpha: isDark ? 0.35 : 0.25),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: Icon(statusIcon, color: statusColor, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          status.statusLabel.toUpperCase(),
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: statusColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                        if (status.hoursToday.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Text(
                            "·",
                            style: TextStyle(
                                color: AppTheme.textSecondary(context)),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              status.hoursToday,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary(context),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      status.closingOrOpeningTime,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.textSecondary(context),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (status.closureReason != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.errorRed.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border:
                    Border.all(color: AppTheme.errorRed.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      size: 14, color: AppTheme.errorRed),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      status.closureReason!,
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.errorRed,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (status.poyaNotice != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.brightness_2_outlined,
                    size: 13, color: AppPalette.sigiriyaOchre),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    status.poyaNotice!,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textSecondary(context),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRouteTravelTimeSection(
      BuildContext context, AppLocalizations l10n) {
    final result = TravelTimeService.calculate(
      distanceKm: widget.place.distanceKm,
      district: widget.place.district,
      roadType: widget.place.roadType,
      roadCondition: widget.place.roadCondition,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceMuted(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primaryBorder(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.directions_car_filled_outlined,
                        size: 20, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        "APPROXIMATE TRAVEL TIME",
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  "${result.straightLineKm.toStringAsFixed(1)} km",
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            result.isStraightLineEstimate
                ? "Based on straight-line distance—not a live route, traffic, or navigation ETA. Open Directions for a current route."
                : "Sri Lanka terrain-weighted route estimate (${widget.place.district})",
            style: GoogleFonts.inter(
              fontSize: 11.5,
              color: AppTheme.textSecondary(context),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _travelModeCard(
                  context,
                  icon: Icons.directions_car_rounded,
                  label: "Car / Van",
                  time: result.carTime,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _travelModeCard(
                  context,
                  icon: Icons.electric_rickshaw_rounded,
                  label: "Tuk-Tuk",
                  time: result.tukTukTime,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _travelModeCard(
                  context,
                  icon: Icons.two_wheeler_rounded,
                  label: "Scooter",
                  time: result.bikeTime,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _travelModeCard(
                  context,
                  icon: Icons.hiking_rounded,
                  label: "Hike",
                  time: result.walkTime,
                ),
              ),
            ],
          ),
          if (result.terrainNote.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.terrain_rounded,
                    size: 14, color: AppPalette.sigiriyaOchre),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    result.terrainNote,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textSecondary(context),
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => TravelTimeService.launchLiveDirections(
                lat: widget.place.lat,
                lng: widget.place.lng,
                placeName: widget.place.name,
              ),
              icon: const Icon(Icons.turn_right_rounded, size: 18),
              label: Text(
                "Open Turn-by-Turn Navigation",
                style: GoogleFonts.inter(
                    fontSize: 13, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _travelModeCard(BuildContext context,
      {required IconData icon, required String label, required String time}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryBorder(context)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary(context),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            time,
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketAndBudgetCard(
      BuildContext context, AppLocalizations l10n) {
    final ticket = widget.place.ticketRange.trim();
    final budget = widget.place.budgetCategory.trim();
    final guide = widget.place.guideRequired.trim();

    final hasTicket = ticket.isNotEmpty;
    final hasBudget = budget.isNotEmpty;
    final hasGuide = guide.isNotEmpty;

    if (!hasTicket && !hasBudget && !hasGuide) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceMuted(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.primaryBorder(context)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppPalette.sigiriyaOchre.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.confirmation_number_outlined,
                color: AppPalette.sigiriyaOchre, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "ADMISSION & BUDGET",
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                        color: AppPalette.sigiriyaOchre,
                      ),
                    ),
                    if (hasBudget)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color:
                              AppPalette.sigiriyaOchre.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          budget.toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppPalette.sigiriyaOchre,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  hasTicket ? ticket : "Free Entry / No Admission Fee",
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary(context),
                  ),
                ),
                if (hasGuide) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.person_pin_circle_outlined,
                          size: 13, color: AppPalette.rust),
                      const SizedBox(width: 5),
                      Text(
                        "Guide: $guide",
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppPalette.rust,
                        ),
                      ),
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

  bool _hasTicketAndBudgetData() {
    final place = widget.place;
    return place.ticketRange.trim().isNotEmpty ||
        place.budgetCategory.trim().isNotEmpty ||
        place.guideRequired.trim().isNotEmpty;
  }

  bool _hasSafetyAndWeatherData() {
    final place = widget.place;
    final hasConfiguredRisk = place.safetyLevel.trim().isNotEmpty ||
        place.wildlifeHazard.trim().isNotEmpty ||
        place.rainSensitivity.trim().isNotEmpty ||
        place.monsoonNote.trim().isNotEmpty ||
        place.riskTags.isNotEmpty;
    if (hasConfiguredRisk) return true;

    return DisasterAlertService.instance.evaluateLocationHazard(
          district: place.district,
          locationTitle: place.name,
          weatherCondition: null,
        ) !=
        null;
  }

  Widget _buildSafetyAndWeatherCard(
      BuildContext context, AppLocalizations l10n) {
    final safety = widget.place.safetyLevel.trim();
    final wildlife = widget.place.wildlifeHazard.trim();
    final rain = widget.place.rainSensitivity.trim();
    final monsoon = widget.place.monsoonNote.trim();
    final riskTags = widget.place.riskTags;

    final hazard = DisasterAlertService.instance.evaluateLocationHazard(
      district: widget.place.district,
      locationTitle: widget.place.name,
      // rainSensitivity is static place metadata, not a live observation.
      // Passing it here created false NBRO alerts on every rainy-sensitive
      // destination. Live weather must be supplied by the weather service.
      weatherCondition: null,
    );

    final hasRisk = safety.isNotEmpty ||
        wildlife.isNotEmpty ||
        rain.isNotEmpty ||
        monsoon.isNotEmpty ||
        riskTags.isNotEmpty ||
        hazard != null;

    if (!hasRisk) return const SizedBox.shrink();

    final isSevere = riskTags.any((t) =>
            t.toLowerCase().contains("high") ||
            t.toLowerCase().contains("danger") ||
            t.toLowerCase().contains("flood")) ||
        safety.toLowerCase().contains("high") ||
        safety.toLowerCase().contains("extreme");

    final cardColor = isSevere ? AppTheme.errorRed : Colors.amber.shade700;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cardColor.withValues(alpha: 0.3), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shield_outlined, size: 18, color: cardColor),
              const SizedBox(width: 8),
              Text(
                "SAFETY & WEATHER ADVISORY",
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                  color: cardColor,
                ),
              ),
              const Spacer(),
              if (safety.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: cardColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    "Safety: $safety",
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: cardColor,
                    ),
                  ),
                ),
            ],
          ),
          if (wildlife.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.pets_rounded,
                    size: 14, color: AppPalette.rust),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Wildlife: $wildlife",
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary(context),
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (rain.isNotEmpty || monsoon.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.cloud_outlined,
                    size: 14, color: Colors.lightBlue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    monsoon.isNotEmpty ? monsoon : "Rain Sensitivity: $rain",
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppTheme.textSecondary(context),
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (riskTags.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: riskTags.map((tag) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: cardColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border:
                        Border.all(color: cardColor.withValues(alpha: 0.25)),
                  ),
                  child: Text(
                    tag,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: cardColor,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
          if (hazard != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: hazard.badgeColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: hazard.badgeColor.withValues(alpha: 0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning_rounded,
                          size: 16, color: hazard.badgeColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          hazard.title,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: hazard.badgeColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hazard.subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppTheme.textPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hazard.message,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppTheme.textSecondary(context),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEssentialFacilitiesCard(
      BuildContext context, AppLocalizations l10n) {
    final toilets = widget.place.toilets.trim();
    final parking = widget.place.parkingRange.trim();
    final signal = widget.place.mobileSignal.trim();
    final wheelchair = widget.place.wheelchairAccess.trim();
    final food = widget.place.foodNearby.trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceMuted(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primaryBorder(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.inventory_2_outlined,
                  size: 18, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                "FACILITIES & ACCESSIBILITY",
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _facilityBadge(
                context,
                icon: Icons.wc_rounded,
                label: "Toilets",
                value: toilets.isNotEmpty ? toilets : "Not reported",
                isPositive: toilets.isEmpty
                    ? null
                    : !toilets.toLowerCase().contains("no"),
              ),
              _facilityBadge(
                context,
                icon: Icons.local_parking_rounded,
                label: "Parking",
                value: parking.isNotEmpty ? parking : "Not reported",
                isPositive: parking.isEmpty
                    ? null
                    : !parking.toLowerCase().contains("no"),
              ),
              _facilityBadge(
                context,
                icon: Icons.signal_cellular_alt_rounded,
                label: "Mobile Signal",
                value: signal.isNotEmpty ? signal : "Not reported",
                isPositive: signal.isEmpty
                    ? null
                    : !signal.toLowerCase().contains("no") &&
                        !signal.toLowerCase().contains("poor"),
              ),
              if (food.isNotEmpty)
                _facilityBadge(
                  context,
                  icon: Icons.restaurant_rounded,
                  label: "Food",
                  value: food,
                  isPositive: !food.toLowerCase().contains("no"),
                ),
              if (wheelchair.isNotEmpty)
                _facilityBadge(
                  context,
                  icon: Icons.accessible_rounded,
                  label: "Wheelchair",
                  value: wheelchair,
                  isPositive: wheelchair.toLowerCase().contains("yes") ||
                      wheelchair.toLowerCase().contains("full"),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _buildLocalDrinkPrompt(context, l10n),
        ],
      ),
    );
  }

  Widget _facilityBadge(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required bool? isPositive,
  }) {
    final color = isPositive == null
        ? AppTheme.textSecondary(context)
        : isPositive
            ? Theme.of(context).colorScheme.primary
            : AppTheme.errorRed;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryBorder(context)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label.toUpperCase(),
                style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textSecondary(context),
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLocalDrinkPrompt(BuildContext context, AppLocalizations l10n) {
    final localDrink =
        HealthSafetyService.instance.getRecommendationForLocation(
      district: widget.place.district,
      title: widget.place.name,
      category: widget.place.category,
    );
    final waterStatus = HealthSafetyService.instance.getWaterSafetyLevel(
      category: widget.place.category,
      terrain: widget.place.safetyLevel,
      title: widget.place.name,
    );

    return InkWell(
      onTap: () => _showWaterAndHydrationSheet(context, l10n),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: localDrink.themeColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border:
              Border.all(color: localDrink.themeColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Text(localDrink.emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        l10n.waterSafetyTitle,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: localDrink.themeColor,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: localDrink.themeColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          waterStatus == WaterSafetyLevel.remoteWilderness
                              ? "Carry Water"
                              : "Safe Hydration",
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: localDrink.themeColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "${HealthSafetyLocalization.drinkTitle(l10n, localDrink.id)} (${HealthSafetyLocalization.drinkPrice(l10n, localDrink.id)})",
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary(context),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: localDrink.themeColor),
          ],
        ),
      ),
    );
  }

  void _showWaterAndHydrationSheet(
      BuildContext context, AppLocalizations l10n) {
    final drinks = HealthSafetyService.instance.getAllLocalDrinks();
    final rules = HealthSafetyService.essentialWaterSafetyRules;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.92,
        minChildSize: 0.45,
        builder: (_, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color:
                        AppTheme.textSecondary(context).withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              Row(
                children: [
                  const Text("🥥", style: TextStyle(fontSize: 28)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.drinkLocalHeroTitle,
                          style: GoogleFonts.outfit(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary(context),
                          ),
                        ),
                        Text(
                          l10n.drinkLocalHeroSubtitle,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppTheme.textSecondary(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              // Regional Hero Drinks
              ...drinks.map((drink) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: drink.themeColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: drink.themeColor.withValues(alpha: 0.25)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(drink.emoji,
                                style: const TextStyle(fontSize: 20)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                HealthSafetyLocalization.drinkTitle(
                                    l10n, drink.id),
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: drink.themeColor,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: drink.themeColor.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                HealthSafetyLocalization.drinkPrice(
                                    l10n, drink.id),
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: drink.themeColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )),
              Text(
                l10n.waterSafetySubtitle,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  height: 1.3,
                  color: AppTheme.textSecondary(context),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                l10n.waterSafetyTitle,
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary(context),
                ),
              ),
              const SizedBox(height: 10),
              _buildFoodSafetyTips(context),
              const SizedBox(height: 12),
              // Bottled water & food safety rules
              ...rules.map((rule) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceMuted(context),
                      borderRadius: BorderRadius.circular(14),
                      border:
                          Border.all(color: AppTheme.primaryBorder(context)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          rule.icon == 'verified'
                              ? Icons.verified_rounded
                              : rule.icon == 'ac_unit'
                                  ? Icons.ac_unit_rounded
                                  : rule.icon == 'no_drinks'
                                      ? Icons.no_drinks_rounded
                                      : Icons.medical_services_rounded,
                          size: 20,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                HealthSafetyLocalization.ruleText(
                                    l10n, rule.id),
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    final uri = Uri.parse(
                      'https://www.google.com/maps/search/?api=1&query=supermarket+water+near+${widget.place.lat},${widget.place.lng}',
                    );
                    launchUrl(uri, mode: LaunchMode.externalApplication);
                  },
                  icon: const Icon(Icons.storefront_rounded, size: 18),
                  label: Text(
                    l10n.findSafeWaterAction,
                    style: GoogleFonts.inter(
                        fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFoodSafetyTips(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tips = FoodSafetyGuidance.tips(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceMuted(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryBorder(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n?.foodSafetyTipsTitle ?? 'Food safety tips',
              style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary(context))),
          const SizedBox(height: 8),
          ...tips.map((tip) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('• $tip',
                    style: GoogleFonts.inter(
                        fontSize: 11.5,
                        height: 1.3,
                        color: AppTheme.textSecondary(context))),
              )),
          Text(
              l10n?.foodSafetyDisclaimer ??
                  'General guidance only; seek professional care for persistent or severe symptoms.',
              style: GoogleFonts.inter(
                  fontSize: 10, color: AppTheme.textSecondary(context))),
        ],
      ),
    );
  }

  Widget _buildNearbyEssentialsSection(
      BuildContext context, AppLocalizations l10n) {
    final essentials = [
      (Icons.local_hospital_rounded, "Hospital", "රෝහල්", "hospital"),
      (Icons.local_police_rounded, "Police", "පොලිසිය", "police station"),
      (Icons.local_gas_station_rounded, "Fuel", "ඉන්ධන", "petrol station"),
      (Icons.atm_rounded, "ATM", "ATM", "atm"),
      (Icons.restaurant_rounded, "Food", "ආපනශාලා", "restaurant"),
      (Icons.wc_rounded, "Toilets", "වැසිකිළි", "public toilet"),
      (
        Icons.directions_bus_rounded,
        "Transport",
        "ප්‍රවාහන",
        "bus stand train station"
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.near_me_rounded,
                    size: 18, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  "NEARBY ESSENTIALS (1-TAP)",
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            Text(
              "Live Map Search",
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: essentials.map((item) {
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Material(
                  color: AppTheme.surfaceMuted(context),
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      TravelTimeService.launchNearbySearch(
                        lat: widget.place.lat,
                        lng: widget.place.lng,
                        query: item.$4,
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border:
                            Border.all(color: AppTheme.primaryBorder(context)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(item.$1,
                              size: 16,
                              color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                item.$2,
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary(context),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewsSection(BuildContext context, AppLocalizations l10n) {
    final ratingValue = widget.place.rating;
    final popularity = widget.place.touristPopularity.isNotEmpty
        ? widget.place.touristPopularity
        : "Curated Heritage Gem";

    if (ratingValue <= 0) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppTheme.surfaceMuted(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.primaryBorder(context)),
        ),
        child: Row(
          children: [
            Icon(Icons.rate_review_outlined,
                color: AppTheme.textSecondary(context)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'No verified traveler reviews yet',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary(context),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceMuted(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primaryBorder(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "TRAVELER REVIEWS & RATINGS",
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.colors.green.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified_rounded,
                        size: 12, color: AppTheme.colors.green),
                    const SizedBox(width: 4),
                    Text(
                      "Community Verified",
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        ratingValue.toStringAsFixed(1),
                        style: GoogleFonts.outfit(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.textPrimary(context),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "/ 5.0",
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary(context),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: List.generate(5, (index) {
                      return Icon(
                        index < ratingValue.round()
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        size: 16,
                        color: AppPalette.sigiriyaOchre,
                      );
                    }),
                  ),
                ],
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.primaryBorder(context)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        popularity,
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary(context),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        "Based on real explorer feedback and local cultural curators.",
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppTheme.textSecondary(context),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
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

    if (cat.contains("temple") ||
        cat.contains("culture") ||
        cat.contains("historical")) {
      title = l10n.culturalEtiquette;
      icon = Icons.temple_buddhist_outlined;
      tips = [
        l10n.etiquetteTipRemoveShoes,
        l10n.etiquetteTipDressModestly,
        l10n.etiquetteTipAskPhotoPermission,
        l10n.etiquetteTipNoBackToStatues,
      ];
    } else if (cat.contains("nature") ||
        cat.contains("waterfall") ||
        cat.contains("hiking")) {
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
              Icon(icon,
                  color: Theme.of(context).colorScheme.primary, size: 18),
              const SizedBox(width: 10),
              Text(
                title,
                style: GoogleFonts.outfit(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary(context),
                    letterSpacing: 0.3),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...tips.map((tip) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  "·  $tip",
                  style: GoogleFonts.inter(
                      color:
                          AppTheme.textPrimary(context).withValues(alpha: 0.75),
                      fontSize: 12.5),
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
        stretchModes: const [
          StretchMode.zoomBackground,
          StretchMode.blurBackground
        ],
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
                    Theme.of(context)
                        .scaffoldBackgroundColor
                        .withValues(alpha: 0.85),
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
                      MaterialPageRoute(
                          builder: (context) =>
                              AudioGuideScreen(place: widget.place)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _heroIconButton(
                    context,
                    icon: Icons.wallet_membership_outlined,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const HeritagePassportScreen()),
                    ),
                  ),
                ],
              ),
            ),
            if (widget.place.category.isNotEmpty)
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

  Widget _heroIconButton(BuildContext context,
      {required IconData icon, required VoidCallback onTap}) {
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
          const Icon(Icons.account_balance_outlined,
              color: Colors.white, size: 13),
          const SizedBox(width: 7),
          Text(
            L10nUtils.getLocalizedCategory(context, widget.place.category)
                .toUpperCase(),
            style: GoogleFonts.outfit(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppTheme.colors.white,
                letterSpacing: 1.5),
          ),
        ],
      ),
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
                        letterSpacing: -0.4)
                    .copyWith(
                  fontFamilyFallback: [
                    GoogleFonts.abhayaLibre().fontFamily!,
                    GoogleFonts.hindGuntur().fontFamily!
                  ],
                ),
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.location_on_rounded,
                      color: Theme.of(context).colorScheme.primary, size: 13),
                  SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      widget.place.distanceKm > 0
                          ? "${widget.place.district} · ${widget.place.distanceKm.toStringAsFixed(1)} km"
                          : widget.place.district,
                      style: GoogleFonts.inter(
                          fontSize: 11.5,
                          color: AppTheme.textSecondary(context),
                          fontWeight: FontWeight.w600),
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
            final nowBookmarked =
                await UserPreferenceService.toggleBookmark(widget.place.id);
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
            _isBookmarked
                ? Icons.bookmark_rounded
                : Icons.bookmark_border_rounded,
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

  void _openGalleryViewer(
      BuildContext context, List<PlaceImageModel> images, int initialIndex) {
    HapticFeedback.selectionClick();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _FullscreenGalleryViewer(
            images: images, initialIndex: initialIndex),
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
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.9),
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
                    Text(l10n.oracleVision,
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.primary,
                            fontSize: 11,
                            letterSpacing: 0.5)),
                    if (canTranslate)
                      GestureDetector(
                        onTap: _isTranslating ? null : _translateDescription,
                        child: Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withValues(alpha: 0.2)),
                          ),
                          child: _isTranslating
                              ? SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 1.5,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary))
                              : Text(
                                  l10n.tapToTranslate,
                                  style: GoogleFonts.inter(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary),
                                ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 16),
                Text(_translatedAiReason ?? widget.place.aiReason,
                    style: GoogleFonts.inter(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.9),
                      height: 1.7,
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                    ).copyWith(
                      fontFamilyFallback: [
                        GoogleFonts.abhayaLibre().fontFamily!,
                        GoogleFonts.hindGuntur().fontFamily!
                      ],
                    )),
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
      final translated =
          await TranslationService.translate(widget.place.aiReason, 'si');
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
        _directionsPillLabel(l10n),
        onTap: () => _openDirections(context, l10n),
      ),
      if (widget.place.bestTime.isNotEmpty)
        _statPill(context, Icons.schedule_rounded,
            l10n.bestAtLabel(widget.place.bestTime)),
      if (widget.place.ticketRange.isNotEmpty)
        _statPill(context, Icons.confirmation_number_outlined,
            widget.place.ticketRange),
      // openingHours is captured by the admin form (Travel Insights tab) and
      // parsed by DiscoveryPlace, but had no widget displaying it anywhere
      // on this screen — a visitor could never see when a place is open.
      if (widget.place.openingHours.isNotEmpty)
        _statPill(
            context, Icons.access_time_rounded, widget.place.openingHours),
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

  // Free, offline estimates — no Directions API/billing involved. Each is a
  // flat average speed rather than real routing, so these are rough "about
  // this long" figures, not turn-by-turn ETAs (road type/traffic aren't
  // factored in). Speeds reflect typical Sri Lankan road conditions (mixed
  // paved/unpaved, hills, traffic) for each mode.
  static const double _walkSpeedKmh = 4.5;
  static const double _bikeSpeedKmh = 28.0;
  static const double _carSpeedKmh = 35.0;

  String _estimateTimeLabel(double distanceKm, double speedKmh) {
    final minutes = (distanceKm / speedKmh * 60).round();
    return minutes < 60
        ? '$minutes min'
        : '${(minutes / 60).floor()}h ${minutes % 60}m';
  }

  String _directionsPillLabel(AppLocalizations l10n) {
    final distanceKm = widget.place.distanceKm;
    if (distanceKm <= 0) return l10n.getDirections;
    return '${distanceKm.toStringAsFixed(1)} km · ~${_estimateTimeLabel(distanceKm, _bikeSpeedKmh)}';
  }

  Future<void> _openDirections(
      BuildContext context, AppLocalizations l10n) async {
    HapticFeedback.selectionClick();
    if (widget.place.distanceKm <= 0) {
      await _launchMaps();
      return;
    }
    if (!context.mounted) return;
    await showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.colors.transparent,
      builder: (sheetContext) => _VehicleEtaSheet(
        distanceKm: widget.place.distanceKm,
        placeName: widget.place.name,
        walkSpeedKmh: _walkSpeedKmh,
        bikeSpeedKmh: _bikeSpeedKmh,
        carSpeedKmh: _carSpeedKmh,
        estimateLabel: _estimateTimeLabel,
        onOpenMaps: () async {
          Navigator.pop(sheetContext);
          await _launchMaps();
        },
      ),
    );
  }

  Future<void> _launchMaps() async {
    final lat = widget.place.lat;
    final lng = widget.place.lng;
    final label = Uri.encodeComponent(widget.place.name);
    // geo: is handled by whatever maps app is installed (Google Maps,
    // or any other) — falls back to a Google Maps web URL if no app
    // claims the geo: scheme (e.g. some emulators, or GPS disabled).
    final geoUri = Uri.parse('geo:$lat,$lng?q=$lat,$lng($label)');
    final webUri =
        Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');

    final launched = await canLaunchUrl(geoUri) && await launchUrl(geoUri);
    if (!launched && await canLaunchUrl(webUri)) {
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
      return;
    }
    if (!launched) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.couldNotOpenMaps)));
    }
  }

  Widget _statPill(BuildContext context, IconData icon, String label,
      {Color? accent, VoidCallback? onTap}) {
    final color = accent ?? AppTheme.textPrimary(context);
    final pill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: accent != null
            ? accent.withValues(alpha: 0.15)
            : AppTheme.surfaceMuted(context),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.inter(
                fontSize: 11.5, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
    if (onTap == null) return pill;
    return Material(
      color: AppTheme.colors.transparent,
      borderRadius: BorderRadius.circular(100),
      child: InkWell(
          borderRadius: BorderRadius.circular(100), onTap: onTap, child: pill),
    );
  }

  Widget _buildGoodToKnowCard(BuildContext context, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.goodToKnow,
          style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary(context)),
        ),
        const SizedBox(height: 14),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.primaryBorder(context)),
          ),
          child: Column(
            children: [
              _goodToKnowRow(
                  context,
                  Icons.info_outline,
                  l10n.theKnowledge,
                  Theme.of(context).colorScheme.primary,
                  _buildDetailsChips(context, l10n),
                  showDivider: true),
              _goodToKnowRow(
                  context,
                  Icons.warning_amber_rounded,
                  l10n.safetyProtocols,
                  AppTheme.errorRed,
                  _buildRiskTags(context),
                  showDivider: true),
              _goodToKnowRow(
                  context,
                  Icons.local_cafe_outlined,
                  l10n.provisions,
                  AppTheme.colors.teal.shade700,
                  _buildFacilities(context),
                  showDivider: false),
            ],
          ),
        ),
      ],
    );
  }

  Widget _goodToKnowRow(BuildContext context, IconData icon, String title,
      Color iconColor, Widget content,
      {required bool showDivider}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: showDivider
          ? BoxDecoration(
              border: Border(
                  bottom: BorderSide(color: AppTheme.primaryBorder(context))))
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
                style: GoogleFonts.outfit(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary(context)),
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
              style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary(context)),
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
                style: GoogleFonts.inter(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.sigiriyaOchre(context)),
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
            itemBuilder: (context, i) => _fieldNoteTile(
                context, compact[i].$1, compact[i].$2, compact[i].$3),
          ),
        if (compact.isNotEmpty && prose.isNotEmpty) const SizedBox(height: 12),
        for (var i = 0; i < prose.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          _fieldNoteProseRow(context, prose[i].$1, prose[i].$2, prose[i].$3),
        ],
      ],
    );
  }

  List<(IconData, String, String, bool)> _fieldNoteEntries(
      BuildContext context, AppLocalizations l10n) {
    final p = widget.place;
    return <(IconData, String, String, bool)>[
      (
        Icons.signal_cellular_alt_rounded,
        l10n.fieldNoteMobileSignal,
        p.mobileSignal,
        false
      ),
      (
        Icons.route_outlined,
        l10n.fieldNoteRoadCondition,
        p.roadCondition,
        false
      ),
      (Icons.hiking_rounded, l10n.fieldNoteActivities, p.activities, true),
      (
        Icons.trending_up_rounded,
        l10n.fieldNotePopularity,
        p.touristPopularity,
        false
      ),
      (
        Icons.family_restroom_rounded,
        l10n.fieldNoteFamilyFriendly,
        p.familyFriendly,
        false
      ),
      (Icons.savings_outlined, l10n.fieldNoteBudget, p.budgetCategory, false),
      (Icons.wc_rounded, l10n.fieldNoteToilets, p.toilets, false),
      (
        Icons.restaurant_outlined,
        l10n.fieldNoteFoodNearby,
        p.foodNearby,
        false
      ),
      (
        Icons.accessible_rounded,
        l10n.fieldNoteWheelchairAccess,
        p.wheelchairAccess,
        false
      ),
      (Icons.forest_outlined, l10n.fieldNoteCamping, p.campingAllowed, false),
      (Icons.shield_outlined, l10n.fieldNoteSafetyLevel, p.safetyLevel, false),
      (
        Icons.pets_outlined,
        l10n.fieldNoteWildlifeHazard,
        p.wildlifeHazard,
        true
      ),
      (
        Icons.person_pin_circle_outlined,
        l10n.fieldNoteGuideRequired,
        p.guideRequired,
        false
      ),
      (
        Icons.water_drop_outlined,
        l10n.fieldNoteRainSensitivity,
        p.rainSensitivity,
        false
      ),
      (Icons.cloud_outlined, l10n.fieldNoteMonsoonNote, p.monsoonNote, true),
      (Icons.surfing_outlined, l10n.fieldNoteSurfing, p.surfing, false),
      if ((double.tryParse(p.heightM) ?? 0) > 0)
        (Icons.height_rounded, l10n.fieldNoteHeight, "${p.heightM} m", false),
      if ((double.tryParse(p.lengthKm) ?? 0) > 0)
        (
          Icons.straighten_rounded,
          l10n.fieldNoteLength,
          "${p.lengthKm} km",
          false
        ),
    ].where((e) => e.$3.trim().isNotEmpty).toList();
  }

  Widget _fieldNoteProseRow(
      BuildContext context, IconData icon, String label, String value) {
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
                  style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textSecondary(context),
                      letterSpacing: 0.3),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary(context),
                      height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _fieldNoteTile(
      BuildContext context, IconData icon, String label, String value) {
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
            style: GoogleFonts.inter(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: AppTheme.textSecondary(context),
                letterSpacing: 0.2),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary(context)),
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
        if (widget.place.category.isNotEmpty)
          _chip(
              context,
              L10nUtils.getLocalizedCategory(context, widget.place.category),
              Theme.of(context).colorScheme.primary),
        if (widget.place.roadType.isNotEmpty)
          _chip(context, "${l10n.road}: ${widget.place.roadType}",
              Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)),
        if (widget.place.vehicleAccess.isNotEmpty)
          _chip(context, "${l10n.access}: ${widget.place.vehicleAccess}",
              Theme.of(context).colorScheme.secondary),
        if (widget.place.parkingRange.isNotEmpty)
          _chip(context, "${l10n.parking}: ${widget.place.parkingRange}",
              Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2)),
      ],
    );
  }

  Widget _buildRiskTags(BuildContext context) {
    if (widget.place.riskTags.isEmpty) {
      return Text(AppLocalizations.of(context)!.noRiskTagsFound,
          style: TextStyle(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.5),
              fontSize: 13));
    }
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: widget.place.riskTags
          .map((t) => _chip(context, t, AppTheme.errorRed))
          .toList(),
    );
  }

  Widget _buildFacilities(BuildContext context) {
    if (widget.place.facilities.isEmpty) {
      return Text(AppLocalizations.of(context)!.noFacilitiesFound,
          style: TextStyle(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.5),
              fontSize: 13));
    }
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: widget.place.facilities
          .map((t) => _chip(context, t, AppTheme.colors.primary))
          .toList(),
    );
  }

  bool _hasFieldNotes() {
    final p = widget.place;
    return [
          p.mobileSignal,
          p.roadCondition,
          p.activities,
          p.touristPopularity,
          p.familyFriendly,
          p.budgetCategory,
          p.toilets,
          p.foodNearby,
          p.wheelchairAccess,
          p.campingAllowed,
          p.safetyLevel,
          p.wildlifeHazard,
          p.guideRequired,
          p.rainSensitivity,
          p.monsoonNote,
          p.surfing,
        ].any((v) => v.trim().isNotEmpty) ||
        (double.tryParse(p.heightM) ?? 0) > 0 ||
        (double.tryParse(p.lengthKm) ?? 0) > 0;
  }

  Widget _chip(BuildContext context, String label, Color color) {
    final isNeutral = color ==
            Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4) ||
        color == Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isNeutral
            ? AppTheme.surfaceMuted(context)
            : color.withValues(alpha: 0.12),
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

  Widget _buildBottomActions(
      BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    return Container(
      color: AppTheme.colors.transparent,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      child: Row(
        children: [
          Semantics(
            button: true,
            selected: _isBookmarked,
            label: _isBookmarked
                ? l10n.bookmarkRemovedSnackbar
                : l10n.bookmarkAddedSnackbar,
            child: Tooltip(
              message: _isBookmarked
                  ? l10n.bookmarkRemovedSnackbar
                  : l10n.bookmarkAddedSnackbar,
              child: Container(
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
                      final nowBookmarked =
                          await UserPreferenceService.toggleBookmark(
                              widget.place.id);
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
                      _isBookmarked
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                      color: _isBookmarked
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
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
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.32),
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
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100)),
                ),
                onPressed: () async {
                  HapticFeedback.mediumImpact();
                  final nowAdded = await UserPreferenceService.toggleItinerary(
                      widget.place.id);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(nowAdded
                        ? l10n.itineraryAddedSnackbar(widget.place.name)
                        : l10n.itineraryRemovedSnackbar),
                  ));
                },
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.auto_fix_high, size: 20),
                      const SizedBox(width: 10),
                      Text(l10n.addToDestiny,
                          style: GoogleFonts.inter(
                              fontSize: 14, fontWeight: FontWeight.w700)),
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

  Widget _buildNearbyPlacesSection(
      BuildContext context, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.near_me_outlined,
                color: Theme.of(context).colorScheme.primary, size: 18),
            const SizedBox(width: 8),
            Text(
              "Nearby Places",
              style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary(context)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 140,
          child: FutureBuilder<Result<List<DiscoveryPlace>, AppError>>(
            future: ref
                .read(discoveryRepositoryProvider)
                .getNearbyPlaces(widget.place),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.isFailure) {
                return Center(
                    child: Text("Unable to load nearby places.",
                        style: GoogleFonts.inter(
                            color: AppTheme.textSecondary(context))));
              }

              final places = snapshot.data!.valueOrNull!;
              if (places.isEmpty) {
                return Center(
                    child: Text("No nearby places found.",
                        style: GoogleFonts.inter(
                            color: AppTheme.textSecondary(context))));
              }

              return ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: places.length,
                separatorBuilder: (context, index) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final place = places[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              PlaceDetailsScreen(place: place),
                        ),
                      );
                    },
                    child: Container(
                      width: 120,
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceMuted(context),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CachedImage(
                            url: place.imageUrl,
                            width: 120,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  place.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textPrimary(context)),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "${place.distanceKm.toStringAsFixed(1)} km",
                                  style: GoogleFonts.inter(
                                      fontSize: 10,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
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

  const _FullscreenGalleryViewer(
      {required this.images, required this.initialIndex});

  @override
  State<_FullscreenGalleryViewer> createState() =>
      _FullscreenGalleryViewerState();
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
              icon: Icon(Icons.close_rounded,
                  color: AppTheme.colors.white, size: 28),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.colors.black54,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  '${_currentIndex + 1} / ${widget.images.length}',
                  style: GoogleFonts.inter(
                      color: AppTheme.colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Vehicle-type ETA picker shown from the "Get Directions" pill — lets the
/// visitor see a rough distance/time estimate per travel mode (walk/bike/car)
/// before jumping out to the device's maps app. Estimates are flat
/// average-speed calculations (see the speed constants in
/// PlaceDetailsScreen), not real routing.
class _VehicleEtaSheet extends StatefulWidget {
  final double distanceKm;
  final String placeName;
  final double walkSpeedKmh;
  final double bikeSpeedKmh;
  final double carSpeedKmh;
  final String Function(double distanceKm, double speedKmh) estimateLabel;
  final VoidCallback onOpenMaps;

  const _VehicleEtaSheet({
    required this.distanceKm,
    required this.placeName,
    required this.walkSpeedKmh,
    required this.bikeSpeedKmh,
    required this.carSpeedKmh,
    required this.estimateLabel,
    required this.onOpenMaps,
  });

  @override
  State<_VehicleEtaSheet> createState() => _VehicleEtaSheetState();
}

enum _TravelMode { walk, bike, car }

class _VehicleEtaSheetState extends State<_VehicleEtaSheet> {
  _TravelMode _selected = _TravelMode.bike;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: 24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.surfaceMuted(context),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            widget.placeName,
            style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary(context)),
          ),
          const SizedBox(height: 4),
          Text(
            '${widget.distanceKm.toStringAsFixed(1)} km ${l10n.awayLabel}',
            style: GoogleFonts.inter(
                fontSize: 13, color: AppTheme.textSecondary(context)),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                  child: _modeOption(context, _TravelMode.walk,
                      Icons.directions_walk_rounded, l10n.travelModeWalk)),
              const SizedBox(width: 10),
              Expanded(
                  child: _modeOption(context, _TravelMode.bike,
                      Icons.two_wheeler_rounded, l10n.travelModeBike)),
              const SizedBox(width: 10),
              Expanded(
                  child: _modeOption(context, _TravelMode.car,
                      Icons.directions_car_filled_rounded, l10n.travelModeCar)),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: widget.onOpenMaps,
              icon: const Icon(Icons.map_outlined),
              label: Text(l10n.openInMaps,
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor:
                    isDark ? AppTheme.colors.black : AppTheme.colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(100)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _modeOption(
      BuildContext context, _TravelMode mode, IconData icon, String label) {
    final isSelected = _selected == mode;
    final speed = switch (mode) {
      _TravelMode.walk => widget.walkSpeedKmh,
      _TravelMode.bike => widget.bikeSpeedKmh,
      _TravelMode.car => widget.carSpeedKmh,
    };
    final color = isSelected
        ? Theme.of(context).colorScheme.primary
        : AppTheme.textSecondary(context);

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selected = mode);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.12)
              : AppTheme.surfaceMuted(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : AppTheme.colors.transparent,
              width: 1.5),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 11.5, fontWeight: FontWeight.w700, color: color)),
            const SizedBox(height: 2),
            Text(
              widget.estimateLabel(widget.distanceKm, speed),
              style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color.withValues(alpha: 0.8)),
            ),
          ],
        ),
      ),
    );
  }
}
