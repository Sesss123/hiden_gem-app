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
          content: Text('Plan removed from Oracle cache', style: GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w600)),
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
            const Color(0xFFFFD700).withValues(alpha: 0.8),
            const Color(0xFFFFD700).withValues(alpha: 0.0),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Icon(Icons.view_in_ar, color: Colors.black, size: 28),
          if (hasAR) ...[
            const SizedBox(width: 12),
            Text(
              "VIEW IN AR",
              style: GoogleFonts.outfit(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _launchARShortcut(BuildContext context, String name) {
    final arData = ARPlaceData(
      arSupported: true,
      arTier: 1,
      arBrandName: "Heritage AR",
      arModelUrl: "https://raw.githubusercontent.com/KhronosGroup/glTF-Sample-Models/master/2.0/AntiqueCamera/glTF-Binary/AntiqueCamera.glb",
      arHistoricalModelUrl: "https://raw.githubusercontent.com/KhronosGroup/glTF-Sample-Models/master/2.0/AntiqueCamera/glTF-Binary/AntiqueCamera.glb",
      arModelScale: 0.05,
      historicalPeriod: "Anuradhapura Era",
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
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Theme.of(context).colorScheme.onSurface),
        title: OracleUI.neonText(
          "SAVED JOURNEYS",
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w900,
            fontSize: 14,
            letterSpacing: 2,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        actions: [
          if (_plans.isNotEmpty)
            IconButton(
              icon: Icon(Icons.delete_sweep_rounded, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4), size: 22),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => OracleUI.glassContainer(
                    child: AlertDialog(
                      backgroundColor: Colors.transparent,
                      title: OracleUI.neonText('Clear Archives', style: GoogleFonts.outfit(fontSize: 20)),
                      content: Text('This will permanently erase all local manifests.', style: GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7))),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text('ABORT', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4), fontWeight: FontWeight.bold))),
                        TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('ERASE ALL', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold))),
                      ],
                    ),
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
          OracleUI.glassContainer(
            padding: const EdgeInsets.all(32),
            borderRadius: BorderRadius.circular(50),
            borderColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
            child: Icon(Icons.bookmark_outline_rounded, size: 56, color: Theme.of(context).colorScheme.primary),
          ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 3.seconds),
          const SizedBox(height: 24),
          OracleUI.neonText('The Oracle Archives Are Empty', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Manifest your journey to see it saved here.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4), fontSize: 13)),
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
        final (:id, :plan) = _plans[i];
        final summary = plan.tripSummary;
        final cachedAgo = plan.cachedAt != null ? _timeAgo(plan.cachedAt!) : 'Unknown date';

        return Dismissible(
          key: Key(id),
          direction: DismissDirection.horizontal,
          background: _buildARSwipeBackground(plan),
          secondaryBackground: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(20)),
            child: const Icon(Icons.delete_outline, color: Colors.white),
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
                  const SnackBar(content: Text("No AR spots in this plan"))
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
            child: OracleUI.glassContainer(
              padding: const EdgeInsets.all(16),
              borderRadius: BorderRadius.circular(20),
              borderColor: Theme.of(context).dividerColor.withValues(alpha: 0.1),
              child: Row(
                children: [
                  OracleUI.glassContainer(
                    width: 52,
                    height: 52,
                    borderRadius: BorderRadius.circular(12),
                    borderColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                    child: Icon(Icons.map_rounded, color: Theme.of(context).colorScheme.primary, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${summary.fromCity} → ${summary.destinationCity}',
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
                            _chip(Icons.nights_stay_outlined, '${summary.days}d'),
                            _chip(Icons.people_outline, summary.groupType),
                            _chip(Icons.account_balance_wallet_outlined,
                                'Rs. ${_fmt(summary.userBudgetLkr)}'),
                            if (plan.itinerary.any((day) => day.items.any((item) => item.arSupported)))
                              OracleUI.glassContainer(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                borderRadius: BorderRadius.circular(6),
                                borderColor: const Color(0xFFFFD700).withValues(alpha: 0.3),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.view_in_ar_rounded, size: 10, color: Color(0xFFFFD700)),
                                    SizedBox(width: 4),
                                    Text(
                                      "AR",
                                      style: TextStyle(
                                        color: Color(0xFFFFD700),
                                        fontWeight: FontWeight.w900,
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
                          'SAVED $cachedAgo',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
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
          label.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 10,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }

  String _fmt(int v) {
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}K';
    return v.toString();
  }
}
