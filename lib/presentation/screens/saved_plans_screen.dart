import 'package:hidden_gems_sl/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hidden_gems_sl/data/datasources/trip_cache_service.dart';
import '../../core/theme/oracle_ui_system.dart';
import '../../data/models/trip_plan_model.dart';
import '../widgets/interested_events_hub.dart';
import 'ar_viewer_screen.dart';
import 'results_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';
import '../../data/models/ar_place_data.dart';
import '../../l10n/app_localizations.dart';

class SavedPlansScreen extends ConsumerStatefulWidget {
  const SavedPlansScreen({super.key});

  @override
  ConsumerState<SavedPlansScreen> createState() => _SavedPlansScreenState();
}

class _SavedPlansScreenState extends ConsumerState<SavedPlansScreen> {
  late List<({String id, TripPlan plan})> _plans;

  @override
  void initState() {
    super.initState();
    _plans = TripCacheService.getSavedPlans();
  }

  void _deletePlan(String id) async {
    await TripCacheService.deleteSavedPlan(id);
    if (mounted) setState(() => _plans = TripCacheService.getSavedPlans());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.planRemovedSnackbar, style: GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w600)),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).cardTheme.color,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.2))),
        ),
      );
    }
  }

  void _openPlan(TripPlan plan) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ResultsScreen(plan: plan, cacheState: CacheReadResult.fresh),
      ),
    );
  }

  Widget _buildARSwipeBackground(TripPlan plan) {
    final hasAR = plan.itinerary.expand((d) => d.items).any((i) => i.arSupported);
    return Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.only(left: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.0),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(Icons.view_in_ar, color: AppTheme.colors.black, size: 28),
          if (hasAR) ...[
            const SizedBox(width: 12),
            Text(
              AppLocalizations.of(context)!.viewInArLabel,
              style: GoogleFonts.outfit(
                color: AppTheme.colors.black,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _launchARShortcut(BuildContext context, String name) {
    final l10n = AppLocalizations.of(context)!;
    final arData = ARPlaceData(
      arSupported: true,
      arTier: 1,
      arBrandName: l10n.arBrandNameHeritage,
      arModelUrl: "https://raw.githubusercontent.com/KhronosGroup/glTF-Sample-Models/master/2.0/AntiqueCamera/glTF-Binary/AntiqueCamera.glb",
      arHistoricalModelUrl: "https://raw.githubusercontent.com/KhronosGroup/glTF-Sample-Models/master/2.0/AntiqueCamera/glTF-Binary/AntiqueCamera.glb",
      arModelScale: 0.05,
      historicalPeriod: l10n.ancientHeritageSite,
      audioUrlSi: "",
      audioUrlEn: "",
      fallbackVideoUrl: "",
      arContentVersion: 1,
      hotspots: [],
      artifacts: [],
      targetLat: 7.9575,
      targetLng: 80.7603,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ARViewerScreen(
          arData: arData,
          placeName: name,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: AppTheme.colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: Theme.of(context).colorScheme.onSurface),
        title: Text(
          l10n.savedTripsTitle,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            letterSpacing: -0.5,
            color: AppTheme.textPrimary(context),
          ),
        ),
        actions: [
          if (_plans.isNotEmpty)
            IconButton(
              icon: Icon(Icons.delete_sweep_rounded, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4), size: 22),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    title: Text(l10n.clearSavedTripsTitle, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.3, color: AppTheme.textPrimary(context))),
                    content: Text(l10n.clearSavedTripsMessage, style: GoogleFonts.inter(color: AppTheme.textSecondary(context))),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(l10n.cancel, style: TextStyle(color: AppTheme.textSecondary(context), fontWeight: FontWeight.w600))),
                      TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: Text(l10n.eraseAllButton, style: TextStyle(color: AppTheme.colors.redAccent, fontWeight: FontWeight.w700))),
                    ],
                  ),
                );
                if (confirm == true) {
                  await TripCacheService.clearAll();
                  if (mounted) setState(() => _plans = []);
                }
              },
            ),
        ],
      ),
      body: OracleUI.auraBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 120, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const InterestedEventsHub(),
              const SizedBox(height: 48),
              if (_plans.isEmpty) _buildEmpty() else _buildList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppTheme.surfaceMuted(context),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.bookmark_outline_rounded, size: 56, color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(height: 24),
          Text(AppLocalizations.of(context)!.noSavedTripsTitle, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.3, color: AppTheme.textPrimary(context))),
          const SizedBox(height: 8),
          Text(AppLocalizations.of(context)!.noSavedTripsSubtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: AppTheme.textSecondary(context), fontSize: 13)),
        ],
      ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1),
    );
  }

  Widget _buildList() {
    return ListView.separated(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _plans.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, i) {
        final l10n = AppLocalizations.of(context)!;
        final (:id, :plan) = _plans[i];
        final summary = plan.tripSummary;
        final cachedAgo = plan.cachedAt != null ? _timeAgo(plan.cachedAt!, l10n) : l10n.unknownDateLabel;

        return Dismissible(
          key: Key(id),
          direction: DismissDirection.horizontal,
          background: _buildARSwipeBackground(plan),
          secondaryBackground: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
                color: AppTheme.colors.redAccent.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(20)),
            child: Icon(Icons.delete_outline, color: AppTheme.colors.white),
          ),
          confirmDismiss: (direction) async {
            if (direction == DismissDirection.startToEnd) {
              final arItem = plan.itinerary
                  .expand((day) => day.items)
                  .where((item) => item.arSupported)
                  .firstOrNull;
              if (arItem != null) {
                HapticFeedback.heavyImpact();
                _launchARShortcut(context, arItem.title);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.noArSpotsSnackbar))
                );
              }
              return false;
            }
            return true;
          },
          onDismissed: (_) => _deletePlan(id),
          child: GestureDetector(
            onTap: () => _openPlan(plan),
            onLongPress: () {
              final arItem = plan.itinerary
                  .expand((day) => day.items)
                  .where((item) => item.arSupported)
                  .firstOrNull;
              if (arItem != null) {
                HapticFeedback.heavyImpact();
                _launchARShortcut(context, arItem.title);
              }
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.colors.black.withValues(alpha: 0.10),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.map_rounded, color: Theme.of(context).colorScheme.primary, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.tripRouteLabel(summary.fromCity, summary.destinationCity),
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 12,
                          runSpacing: 4,
                          children: [
                            _chip(Icons.nights_stay_outlined, l10n.tripDaysChip(summary.days)),
                            _chip(Icons.people_outline, summary.groupType),
                            _chip(Icons.account_balance_wallet_outlined,
                                l10n.tripBudgetChip(_fmt(summary.userBudgetLkr))),
                            if (plan.itinerary.any((day) => day.items.any((item) => item.arSupported)))
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(100),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.view_in_ar_rounded, size: 10, color: Theme.of(context).colorScheme.primary),
                                    SizedBox(width: 4),
                                    Text(
                                      l10n.arBadgeLabel,
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.primary,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.savedTimeAgoLabel(cachedAgo),
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            color: AppTheme.textSecondary(context).withValues(alpha: 0.6),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2)),
                ],
              ),
            ),
          ),
        ).animate().fadeIn(delay: (100 * i).ms).slideY(begin: 0.1, end: 0);
      },
    );
  }

  Widget _chip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)),
        const SizedBox(width: 5),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            color: AppTheme.textSecondary(context),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _timeAgo(DateTime dt, AppLocalizations l10n) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return l10n.minutesAgoShort(diff.inMinutes);
    if (diff.inHours < 24) return l10n.hoursAgoShort(diff.inHours);
    if (diff.inDays < 7) return l10n.daysAgoShort(diff.inDays);
    return l10n.weeksAgoShort((diff.inDays / 7).floor());
  }

  String _fmt(int v) {
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}K';
    return v.toString();
  }
}
