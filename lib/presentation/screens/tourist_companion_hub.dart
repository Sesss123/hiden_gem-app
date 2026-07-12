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
              Expanded(child: Text("MONSOON HAZARD ALERT", style: GoogleFonts.outfit(color: AppTheme.colors.white, fontWeight: FontWeight.bold, fontSize: 18))),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("District: ${alert['district'] ?? 'General'}", style: GoogleFonts.inter(color: AppTheme.colors.redAccent, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              Text(alert['message']?.toString() ?? "Severe monsoon weather detected.", style: GoogleFonts.inter(color: AppTheme.colors.white70, fontSize: 14)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text("ACKNOWLEDGE", style: GoogleFonts.outfit(color: AppTheme.colors.amberAccent, fontWeight: FontWeight.bold)),
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
                    child: Text("Offline Error: ${snapshot.error}", style: TextStyle(color: AppTheme.colors.redAccent)),
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
                Text("Tour Completed!", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppTheme.textPrimary(context))),
              ],
            ),
            content: Text("We hope you had an amazing experience! Would you like to rate your guide now? Your feedback helps guides maintain high standards.",
              style: GoogleFonts.inter(color: AppTheme.textSecondary(context))),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("⏰ Reminder set! We'll send a notification tomorrow.")));
                },
                child: Text("Remind later", style: GoogleFonts.inter(color: AppTheme.textSecondary(context), fontWeight: FontWeight.w600)),
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
                child: Text("Rate now ⭐", style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
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
          Text("Session not found", style: GoogleFonts.outfit(color: AppTheme.textSecondary(context), fontWeight: FontWeight.w600)),
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
          "Your tour",
          style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.5, color: AppTheme.textPrimary(context)),
        ),
      ),
    );
  }

  Widget _buildStatusCard(TourSession session) {
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
                  isActive ? "Tour active" : "Preparing tour",
                  style: GoogleFonts.outfit(color: isActive ? successColor : AppTheme.textPrimary(context), fontWeight: FontWeight.w700, fontSize: 15),
                ),
                Text(
                  isActive ? "Everything's on track" : "Status: ${session.status}",
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
    final phaseMap = {
      'assembling': {'label': 'Assembling group', 'icon': Icons.group_add_outlined, 'color': AppTheme.colors.blueAccent},
      'en_route': {'label': 'En route', 'icon': Icons.directions_bus_filled_outlined, 'color': AppTheme.colors.orangeAccent},
      'at_site': {'label': 'At destination', 'icon': Icons.museum_outlined, 'color': AppTheme.colors.greenAccent},
      'break_time': {'label': 'Free time / break', 'icon': Icons.coffee_outlined, 'color': AppTheme.colors.purpleAccent},
      'returning': {'label': 'Returning to base', 'icon': Icons.keyboard_return_rounded, 'color': AppTheme.colors.cyanAccent},
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Live navigation",
          style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary(context)),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildNavCard(
                icon: Icons.person_pin_circle_outlined,
                title: "Find guide",
                subtitle: "Live tracking",
                color: AppTheme.colors.blueAccent,
                onTap: () => _openMap(session, 'guide'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildNavCard(
                icon: Icons.location_searching_rounded,
                title: "Find vehicle",
                subtitle: "Parked spot",
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
              Text("Meeting point", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textSecondary(context))),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            session.meetingPointName,
            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary(context)),
          ),
          const SizedBox(height: 4),
          Text(
            "Return here if lost or separated from group.",
            style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary(context)),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              icon: const Icon(Icons.near_me_outlined, size: 16),
              label: const Text("Navigate to point"),
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
                      "Guide announcement",
                      style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.colors.redAccent),
                    ),
                    const Spacer(),
                    Text(
                      "Just now",
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
                        alreadyAcked ? "Acknowledged" : "I acknowledge",
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "More",
          style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary(context)),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: Icons.family_restroom_rounded,
                title: "Share live",
                subtitle: "Family access",
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => FamilyShareScreen(sessionId: widget.sessionId))),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                icon: Icons.star_rate_rounded,
                title: "Rate tour",
                subtitle: "Build reputation",
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
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton.icon(
            icon: Icon(Icons.person_search_rounded, color: AppTheme.colors.orangeAccent),
            label: Text("Help, I'm lost", style: GoogleFonts.inter(color: AppTheme.colors.orangeAccent, fontWeight: FontWeight.w700)),
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
                  "Emergency SOS",
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
          "Instant alert to admin, police, and hub.",
          style: GoogleFonts.inter(color: AppTheme.textSecondary(context), fontSize: 11),
        ),
      ],
    );
  }

  Future<void> _triggerImLost(TourSession session) async {
    HapticFeedback.heavyImpact();
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
        title: "TRAVELER LOST",
        body: "A traveler has signaled they are lost! Location shared on map.",
        priority: BroadcastPriority.critical,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(minutes: 30)),
      );

      await _broadcastRepo.sendBroadcast(msg);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("SIGNAL SENT! STAY WHERE YOU ARE."), backgroundColor: AppTheme.colors.orangeAccent),
        );
      }
    } catch (e, st) {
      SecureLogger.error("Lost Trigger Error", e, st, "TouristCompanionHub");
    }
  }

  Future<void> _triggerSos(TourSession session) async {
    final now = DateTime.now();
    if (_lastSosTime != null && now.difference(_lastSosTime!) < const Duration(seconds: 30)) {
      final remaining = 30 - now.difference(_lastSosTime!).inSeconds;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("SOS cooled down. Wait $remaining seconds.")),
      );
      return;
    }

    HapticFeedback.vibrate();
    _lastSosTime = now;
    
    await _sessionRepo.triggerSos(session.sessionId, true);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("SOS ALERT BROADCASTED TO ALL AUTHORITIES!"),
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
        title: Text("Emergency Translator", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppTheme.textPrimary(context))),
        content: Text(
          "Instantly explain your situation to Sri Lankan police or hospital staff in spoken Sinhala — a Premium safety feature.",
          style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary(context), height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Not now", style: TextStyle(color: AppTheme.textSecondary(context))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const PremiumHubScreen()));
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.colors.redAccent, foregroundColor: AppTheme.colors.white),
            child: const Text("View Plans"),
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
