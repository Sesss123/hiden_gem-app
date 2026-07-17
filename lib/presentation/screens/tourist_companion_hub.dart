import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/oracle_ui_system.dart';
import '../../data/models/tour_session.dart';
import '../../data/repositories/tour_session_repository.dart';
import 'package:flutter/services.dart';
import '../../data/repositories/broadcast_repository.dart';
import '../../data/repositories/presence_repository.dart';
import '../../data/models/broadcast_message.dart';
import 'map_explorer_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import '../../data/datasources/auth_service.dart';
import 'family_share_screen.dart';
import 'guide_reviews_screen.dart';
import '../../data/models/offline_snapshot.dart';
import 'dart:convert';
import 'dart:async';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/services/monsoon_broadcast_service.dart';
import 'review_submission_screen.dart';
import '../../core/theme/app_theme.dart';
import 'package:hidden_gems_sl/core/utils/secure_logger.dart';
import '../../core/services/secure_entitlements.dart';
import '../../core/services/emergency_translator_service.dart';
import 'emergency_translator_screen.dart';
import 'premium_hub_screen.dart';
import '../../l10n/app_localizations.dart';

class TouristCompanionHub extends StatefulWidget {
  final String sessionId;
  const TouristCompanionHub({super.key, required this.sessionId});

  @override
  State<TouristCompanionHub> createState() => _TouristCompanionHubState();
}

class _TouristCompanionHubState extends State<TouristCompanionHub> {
  final _sessionRepo = TourSessionRepository();
  final _broadcastRepo = BroadcastRepository();
  final _presenceRepo = PresenceRepository();
  DateTime? _lastSosTime;
  OfflineSnapshot? _cachedSnapshot;
  StreamSubscription? _broadcastSub;
  bool _reviewPromptShown = false;

  @override
  void initState() {
    super.initState();
    _loadCache();
    _initMonsoonListener();
  }

  void _initMonsoonListener() {
    _broadcastSub = MonsoonBroadcastService().broadcastStream.listen((alert) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppTheme.colors.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: AppTheme.colors.redAccent, width: 2)),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppTheme.colors.redAccent, size: 28),
              const SizedBox(width: 10),
              Expanded(child: Text(l10n.monsoonHazardAlertTitle, style: GoogleFonts.outfit(color: AppTheme.colors.white, fontWeight: FontWeight.bold, fontSize: 18))),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.districtLabel(alert['district'] ?? l10n.districtGeneralFallback), style: GoogleFonts.inter(color: AppTheme.colors.redAccent, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              Text(alert['message']?.toString() ?? l10n.severeMonsoonWeatherDetectedMessage, style: GoogleFonts.inter(color: AppTheme.colors.white70, fontSize: 14)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l10n.acknowledgeButton, style: GoogleFonts.outfit(color: AppTheme.colors.amberAccent, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    });
  }

  @override
  void dispose() {
    _broadcastSub?.cancel();
    super.dispose();
  }

  Future<void> _loadCache() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('offline_snapshot_${widget.sessionId}');
    if (data != null) {
      if (!mounted) return;
      setState(() {
        _cachedSnapshot = OfflineSnapshot.fromJson(jsonDecode(data));
      });
    }
  }

  Future<void> _updateCache(TourSession session, List<BroadcastMessage> broadcasts) async {
    final snapshot = OfflineSnapshot(
      lastSession: session,
      recentBroadcasts: broadcasts,
      updatedAt: DateTime.now(),
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('offline_snapshot_${widget.sessionId}', jsonEncode(snapshot.toJson()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: OracleUI.auraBackground(
        child: Stack(
          children: [
            StreamBuilder<TourSession?>(
              stream: _sessionRepo.getActiveSession(widget.sessionId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(AppLocalizations.of(context)!.offlineErrorGenericMessage(snapshot.error.toString()), style: TextStyle(color: AppTheme.colors.redAccent)),
                  );
                }

                final session = snapshot.data;
                if (session == null) {
                  return _cachedSnapshot != null 
                    ? _buildHubContent(_cachedSnapshot!.lastSession) 
                    : _buildNotFound();
                }

                // Update cache when online
                _updateCache(session, []);
                _checkAndTriggerReviewPrompt(session);

                return _buildHubContent(session);
              },
            ),
            _buildBroadcastOverlay(),
          ],
        ),
      ),
    );
  }

  void _checkAndTriggerReviewPrompt(TourSession session) {
    if (session.status == 'completed' && session.isReviewEnabled && !_reviewPromptShown) {
      _reviewPromptShown = true;
      Future.delayed(const Duration(seconds: 30), () {
        if (!mounted) return;
        final l10n = AppLocalizations.of(context)!;
        showDialog(
          context: context,
          barrierDismissible: true,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppTheme.cardColor(context),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: AppTheme.colors.amber.withValues(alpha: 0.5))),
            title: Row(
              children: [
                Icon(Icons.star_rounded, color: AppTheme.colors.amber, size: 28),
                const SizedBox(width: 8),
                Text(l10n.tourCompletedTitle, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppTheme.textPrimary(context))),
              ],
            ),
            content: Text(l10n.tourCompletedRateMessage,
              style: GoogleFonts.inter(color: AppTheme.textSecondary(context))),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.reminderSetMessage)));
                },
                child: Text(l10n.remindLaterButton, style: GoogleFonts.inter(color: AppTheme.textSecondary(context), fontWeight: FontWeight.w600)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.colors.amber, foregroundColor: AppTheme.colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100))),
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ReviewSubmissionScreen(
                        sessionId: session.sessionId,
                        guideId: session.guideId,
                        touristId: AuthService().currentUser?.uid ?? 'guest_tourist',
                      ),
                    ),
                  );
                },
                child: Text(l10n.rateNowButton, style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        );
      });
    }
  }

  Widget _buildHubContent(TourSession session) {
    return CustomScrollView(
      slivers: [
        _buildAppBar(),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatusCard(session),
                const SizedBox(height: 24),
                _buildPhaseIndicator(session),
                const SizedBox(height: 24),
                _buildNavigationTools(session),
                const SizedBox(height: 24),
                _buildMeetingPointCard(session),
                const SizedBox(height: 24),
                _buildPhaseDSafetyInfo(session),
                const SizedBox(height: 24),
                _buildEmergencySection(session),
                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotFound() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, color: AppTheme.textSecondary(context).withValues(alpha: 0.4), size: 64),
          const SizedBox(height: 16),
          Text(AppLocalizations.of(context)!.sessionNotFoundMessage, style: GoogleFonts.outfit(color: AppTheme.textSecondary(context), fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      backgroundColor: AppTheme.colors.transparent,
      elevation: 0,
      expandedHeight: 100,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: Text(
          AppLocalizations.of(context)!.yourTourTitle,
          style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.5, color: AppTheme.textPrimary(context)),
        ),
      ),
    );
  }

  Widget _buildStatusCard(TourSession session) {
    final l10n = AppLocalizations.of(context)!;
    final isActive = session.status == 'active';
    final successColor = Theme.of(context).brightness == Brightness.dark ? const Color(0xFF5EC98A) : const Color(0xFF256029);
    final successFill = Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1A3328) : const Color(0xFFE8F3E9);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isActive ? successFill : AppTheme.surfaceMuted(context),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: isActive ? successColor.withValues(alpha: 0.15) : AppTheme.textSecondary(context).withValues(alpha: 0.15),
            child: Icon(
              isActive ? Icons.verified : Icons.hourglass_empty,
              color: isActive ? successColor : AppTheme.textSecondary(context),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isActive ? l10n.tourActiveTitle : l10n.preparingTourTitle,
                  style: GoogleFonts.outfit(color: isActive ? successColor : AppTheme.textPrimary(context), fontWeight: FontWeight.w700, fontSize: 15),
                ),
                Text(
                  isActive ? l10n.everythingOnTrackMessage : l10n.statusColonValueLabel(session.status),
                  style: GoogleFonts.inter(color: AppTheme.textSecondary(context), fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideX();
  }

  Widget _buildPhaseIndicator(TourSession session) {
    final l10n = AppLocalizations.of(context)!;
    final phaseMap = {
      'assembling': {'label': l10n.phaseAssemblingGroup, 'icon': Icons.group_add_outlined, 'color': AppTheme.colors.blueAccent},
      'en_route': {'label': l10n.phaseEnRoute, 'icon': Icons.directions_bus_filled_outlined, 'color': AppTheme.colors.orangeAccent},
      'at_site': {'label': l10n.phaseAtDestination, 'icon': Icons.museum_outlined, 'color': AppTheme.colors.greenAccent},
      'break_time': {'label': l10n.phaseFreeTimeBreak, 'icon': Icons.coffee_outlined, 'color': AppTheme.colors.purpleAccent},
      'returning': {'label': l10n.phaseReturningToBase, 'icon': Icons.keyboard_return_rounded, 'color': AppTheme.colors.cyanAccent},
    };

    final current = phaseMap[session.currentPhase] ?? phaseMap['assembling']!;

    return OracleUI.glassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: (current['color'] as Color).withValues(alpha: 0.2), shape: BoxShape.circle),
            child: Icon(current['icon'] as IconData, size: 14, color: current['color'] as Color),
          ),
          const SizedBox(width: 12),
          Text(
            current['label'] as String,
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: current['color'] as Color,
            ),
          ),
          const Spacer(),
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.textSecondary(context).withValues(alpha: 0.2)),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).scale(begin: const Offset(0.95, 1));
  }

  Widget _buildNavigationTools(TourSession session) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.liveNavigationTitle,
          style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary(context)),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildNavCard(
                icon: Icons.person_pin_circle_outlined,
                title: l10n.findGuideLabel,
                subtitle: l10n.liveTrackingLabel,
                color: AppTheme.colors.blueAccent,
                onTap: () => _openMap(session, 'guide'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildNavCard(
                icon: Icons.location_searching_rounded,
                title: l10n.findVehicleLabel,
                subtitle: l10n.parkedSpotLabel,
                color: AppTheme.colors.orangeAccent,
                onTap: () => _openMap(session, 'vehicle'),
              ),
            ),
          ],
        ),
      ],
    ).animate().fadeIn(delay: 400.ms);
  }

  Widget _buildNavCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: OracleUI.glassContainer(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 12),
            Text(title, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textPrimary(context))),
            Text(subtitle, style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textSecondary(context))),
          ],
        ),
      ),
    );
  }

  Widget _buildMeetingPointCard(TourSession session) {
    if (session.meetingPointName.isEmpty) return const SizedBox.shrink();

    return OracleUI.glassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flag_rounded, color: AppTheme.colors.greenAccent, size: 18),
              const SizedBox(width: 8),
              Text(AppLocalizations.of(context)!.meetingPointLabel, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textSecondary(context))),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            session.meetingPointName,
            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary(context)),
          ),
          const SizedBox(height: 4),
          Text(
            AppLocalizations.of(context)!.returnHereIfLostMessage,
            style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary(context)),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              icon: const Icon(Icons.near_me_outlined, size: 16),
              label: Text(AppLocalizations.of(context)!.navigateToPointButton),
              onPressed: () => _openMap(session, 'meeting'),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.colors.greenAccent,
                backgroundColor: AppTheme.colors.greenAccent.withValues(alpha: 0.05),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 600.ms);
  }


  Widget _buildBroadcastOverlay() {
    return StreamBuilder<List<BroadcastMessage>>(
      stream: _broadcastRepo.getActiveBroadcasts(widget.sessionId),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox.shrink();

        final l10n = AppLocalizations.of(context)!;
        final latest = snapshot.data!.first;
        // Only show if it was sent in the last 2 minutes
        if (DateTime.now().difference(latest.createdAt).inMinutes > 2) return const SizedBox.shrink();

        final myUid = AuthService().currentUser?.uid;
        final alreadyAcked = myUid != null && latest.acknowledgedBy.contains(myUid);

        return Positioned(
          top: 60,
          left: 20,
          right: 20,
          child: OracleUI.glassContainer(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.campaign_rounded, color: AppTheme.colors.redAccent, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      l10n.guideAnnouncementLabel,
                      style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.colors.redAccent),
                    ),
                    const Spacer(),
                    Text(
                      l10n.justNowLabel,
                      style: GoogleFonts.inter(fontSize: 9, color: AppTheme.textSecondary(context)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  latest.body,
                  style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textPrimary(context), fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 16),
                if (latest.requiresAck)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: alreadyAcked ? AppTheme.colors.greenAccent.withValues(alpha: 0.3) : AppTheme.colors.greenAccent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onPressed: alreadyAcked
                          ? null
                          : () async {
                              HapticFeedback.lightImpact();
                              final uid = myUid;
                              if (uid == null) return;
                              try {
                                await _broadcastRepo.acknowledgeMessage(widget.sessionId, latest.messageId, uid);
                              } catch (e) {
                                SecureLogger.error('[Broadcast] Failed to acknowledge message', e);
                              }
                            },
                      child: Text(
                        alreadyAcked ? l10n.acknowledgedLabel : l10n.iAcknowledgeButton,
                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.colors.black),
                      ),
                    ),
                  ),
              ],
            ),
          ).animate().slideY(begin: -1, end: 0, curve: Curves.easeOutBack),
        );
      },
    );
  }


  Widget _buildPhaseDSafetyInfo(TourSession session) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.moreLabel,
          style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary(context)),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: Icons.family_restroom_rounded,
                title: l10n.shareLiveLabel,
                subtitle: l10n.familyAccessLabel,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => FamilyShareScreen(sessionId: widget.sessionId))),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                icon: Icons.star_rate_rounded,
                title: l10n.rateTourLabel,
                subtitle: l10n.buildReputationLabel,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => GuideReviewsScreen(guideId: session.guideId))),
              ),
            ),
          ],
        ),
      ],
    ).animate().fadeIn(delay: 500.ms);
  }

  Widget _buildActionCard({
    required IconData icon, 
    required String title, 
    required String subtitle, 
    VoidCallback? onTap
  }) {
    return GestureDetector(
      onTap: onTap,
      child: OracleUI.glassContainer(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppTheme.textSecondary(context), size: 20),
            const SizedBox(height: 8),
            Text(title, style: GoogleFonts.inter(color: AppTheme.textPrimary(context), fontSize: 11, fontWeight: FontWeight.w700)),
            Text(subtitle, style: GoogleFonts.inter(color: AppTheme.textSecondary(context), fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencySection(TourSession session) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton.icon(
            icon: Icon(Icons.person_search_rounded, color: AppTheme.colors.orangeAccent),
            label: Text(l10n.helpImLostButton, style: GoogleFonts.inter(color: AppTheme.colors.orangeAccent, fontWeight: FontWeight.w700)),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppTheme.colors.orangeAccent, width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
            ),
            onPressed: () => _triggerImLost(session),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorRed,
              foregroundColor: AppTheme.colors.white,
              elevation: 0,
              shadowColor: AppTheme.errorRed.withValues(alpha: 0.4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
            ),
            onPressed: () => _triggerSos(session),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.warning_amber_rounded, color: AppTheme.colors.white, size: 22),
                const SizedBox(width: 10),
                Text(
                  l10n.emergencySosButton,
                  style: GoogleFonts.inter(
                    color: AppTheme.colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ).animate().shimmer(duration: 2.seconds, color: AppTheme.colors.white.withValues(alpha: 0.2)),
        const SizedBox(height: 16),
        Text(
          l10n.instantAlertAdminPoliceMessage,
          style: GoogleFonts.inter(color: AppTheme.textSecondary(context), fontSize: 11),
        ),
      ],
    );
  }

  Future<void> _triggerImLost(TourSession session) async {
    HapticFeedback.heavyImpact();
    final l10n = AppLocalizations.of(context)!;
    try {
      final pos = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));

      // Update presence so guide sees them on the map. The doc ID must be
      // exactly the caller's own auth UID — firestore.rules only allows a
      // presence write where presenceId == request.auth.uid, so a prefixed
      // ID like 'tourist_$uid' is silently denied.
      final touristUid = AuthService().currentUser?.uid;
      if (touristUid != null) {
        await _presenceRepo.updateParticipantPresence(
          sessionId: session.sessionId,
          userId: touristUid,
          position: pos,
          role: 'tourist',
        );
      }

      // Send critical broadcast
      final msg = BroadcastMessage(
        messageId: "lost_${DateTime.now().millisecondsSinceEpoch}",
        sessionId: session.sessionId,
        guideId: session.guideId,
        type: BroadcastType.safety,
        title: l10n.travelerLostBroadcastTitle,
        body: l10n.travelerLostBroadcastBody,
        priority: BroadcastPriority.critical,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(minutes: 30)),
      );

      await _broadcastRepo.sendBroadcast(msg);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.signalSentStayMessage), backgroundColor: AppTheme.colors.orangeAccent),
        );
      }
    } catch (e, st) {
      SecureLogger.error("Lost Trigger Error", e, st, "TouristCompanionHub");
    }
  }

  Future<void> _triggerSos(TourSession session) async {
    final now = DateTime.now();
    final l10n = AppLocalizations.of(context)!;
    if (_lastSosTime != null && now.difference(_lastSosTime!) < const Duration(seconds: 30)) {
      final remaining = 30 - now.difference(_lastSosTime!).inSeconds;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.sosCooledDownMessage(remaining))),
      );
      return;
    }

    HapticFeedback.vibrate();
    _lastSosTime = now;

    await _sessionRepo.triggerSos(session.sessionId, true);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.sosBroadcastedAuthoritiesMessage),
          backgroundColor: AppTheme.colors.redAccent,
        ),
      );
      await _offerEmergencyTranslator();
    }
  }

  /// Premium benefit: right after SOS is broadcast, offer to open the
  /// Emergency Translator so the tourist can immediately show/play a
  /// Sinhala explanation of their situation to whoever is helping them.
  Future<void> _offerEmergencyTranslator() async {
    if (!mounted) return;
    final isPremium = await SecureEntitlements().verifyPremium();
    if (!mounted) return;

    if (isPremium) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const EmergencyTranslatorScreen(initialType: EmergencySituationType.unsafe)),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        icon: Icon(Icons.translate_rounded, color: AppTheme.colors.redAccent, size: 32),
        title: Text(AppLocalizations.of(context)!.emergencyTranslatorTitle, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppTheme.textPrimary(context))),
        content: Text(
          AppLocalizations.of(context)!.emergencyTranslatorPremiumMessage,
          style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary(context), height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(context)!.notNowButton, style: TextStyle(color: AppTheme.textSecondary(context))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const PremiumHubScreen()));
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.colors.redAccent, foregroundColor: AppTheme.colors.white),
            child: Text(AppLocalizations.of(context)!.viewPlansButton),
          ),
        ],
      ),
    );
  }

  void _openMap(TourSession session, String target) {
    double lat;
    double lng;

    if (target == 'guide') {
      lat = session.lastGuideLat ?? session.meetingPointLat;
      lng = session.lastGuideLng ?? session.meetingPointLng;
    } else {
      lat = session.lastVehicleLat ?? session.meetingPointLat;
      lng = session.lastVehicleLng ?? session.meetingPointLng;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapExplorerScreen(
          initialPosition: LatLng(lat, lng),
        ),
      ),
    );
  }
}
