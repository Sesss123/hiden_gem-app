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
import 'package:google_maps_flutter/google_maps_flutter.dart';

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

  @override
  void initState() {
    super.initState();
    _loadCache();
  }

  Future<void> _loadCache() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('offline_snapshot_${widget.sessionId}');
    if (data != null) {
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

                final session = snapshot.data;
                if (session == null) {
                  return _cachedSnapshot != null 
                    ? _buildHubContent(_cachedSnapshot!.lastSession) 
                    : _buildNotFound();
                }

                // Update cache when online
                _updateCache(session, []);

                return _buildHubContent(session);
              },
            ),
            _buildBroadcastOverlay(),
          ],
        ),
      ),
    );
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
          const Icon(Icons.error_outline, color: Colors.white24, size: 64),
          const SizedBox(height: 16),
          Text("SESSION NOT FOUND", style: GoogleFonts.outfit(color: Colors.white38)),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      expandedHeight: 100,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: OracleUI.neonText(
          "COMPANION HUB",
          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2),
        ),
      ),
    );
  }

  Widget _buildStatusCard(TourSession session) {
    return OracleUI.glassContainer(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: session.status == 'active' ? Colors.greenAccent.withValues(alpha: 0.2) : Colors.white10,
            child: Icon(
              session.status == 'active' ? Icons.verified : Icons.hourglass_empty,
              color: session.status == 'active' ? Colors.greenAccent : Colors.white38,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.status == 'active' ? "SECURE TOUR ACTIVE" : "PREPARING TOUR",
                  style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                Text(
                  "Status: ${session.status.toUpperCase()}",
                  style: GoogleFonts.inter(color: Colors.white54, fontSize: 11),
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
      'assembling': {'label': 'ASSEMBLING GROUP', 'icon': Icons.group_add_outlined, 'color': Colors.blueAccent},
      'en_route': {'label': 'EN ROUTE', 'icon': Icons.directions_bus_filled_outlined, 'color': Colors.orangeAccent},
      'at_site': {'label': 'AT DESTINATION', 'icon': Icons.museum_outlined, 'color': Colors.greenAccent},
      'break_time': {'label': 'FREE TIME / BREAK', 'icon': Icons.coffee_outlined, 'color': Colors.purpleAccent},
      'returning': {'label': 'RETURNING TO BASE', 'icon': Icons.keyboard_return_rounded, 'color': Colors.cyanAccent},
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
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
              color: current['color'] as Color,
            ),
          ),
          const Spacer(),
          const SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white12),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).scale(begin: const Offset(0.95, 1));
  }

  Widget _buildNavigationTools(TourSession session) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OracleUI.neonText(
          "LIVE NAVIGATION",
          style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 2),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildNavCard(
                icon: Icons.person_pin_circle_outlined,
                title: "FIND GUIDE",
                subtitle: "Live Tracking",
                color: Colors.blueAccent,
                onTap: () => _openMap(session, 'guide'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildNavCard(
                icon: Icons.location_searching_rounded,
                title: "FIND VEHICLE",
                subtitle: "Parked Spot",
                color: Colors.orangeAccent,
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
            Text(title, style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
            Text(subtitle, style: GoogleFonts.inter(fontSize: 9, color: Colors.white38)),
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
              const Icon(Icons.flag_rounded, color: Colors.greenAccent, size: 18),
              const SizedBox(width: 8),
              OracleUI.neonText("MEETING POINT", style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            session.meetingPointName,
            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            "Return here if lost or separated from group.",
            style: GoogleFonts.inter(fontSize: 11, color: Colors.white38),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              icon: const Icon(Icons.near_me_outlined, size: 16),
              label: const Text("NAVIGATE TO POINT"),
              onPressed: () => _openMap(session, 'meeting'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.greenAccent,
                backgroundColor: Colors.greenAccent.withValues(alpha: 0.05),
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
                    const Icon(Icons.campaign_rounded, color: Colors.redAccent, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      "GUIDE ANNOUNCEMENT",
                      style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.redAccent),
                    ),
                    const Spacer(),
                    Text(
                      "JUST NOW",
                      style: GoogleFonts.inter(fontSize: 8, color: Colors.white24),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  latest.body,
                  style: GoogleFonts.inter(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 16),
                if (latest.requiresAck)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.greenAccent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      onPressed: () {
                        // Acknowledge logic
                      },
                      child: Text("I ACKNOWLEDGE", style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black)),
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
        OracleUI.neonText(
          "MISSION EXTENSIONS",
          style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 2),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: Icons.family_restroom_rounded, 
                title: "SHARE LIVE", 
                subtitle: "Family Access", 
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const FamilyShareScreen())),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                icon: Icons.star_rate_rounded, 
                title: "RATE MISSION", 
                subtitle: "Build Reputation",
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
            Icon(icon, color: Colors.white70, size: 20),
            const SizedBox(height: 8),
            Text(title, style: GoogleFonts.outfit(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
            Text(subtitle, style: GoogleFonts.inter(color: Colors.white38, fontSize: 9)),
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
          height: 60,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.person_search_rounded, color: Colors.orangeAccent),
            label: Text("HELP! I'M LOST", style: GoogleFonts.outfit(color: Colors.orangeAccent, fontWeight: FontWeight.bold, letterSpacing: 1)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.orangeAccent, width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () => _triggerImLost(session),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 80,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent.withValues(alpha: 0.1),
              side: const BorderSide(color: Colors.redAccent, width: 2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            onPressed: () => _triggerSos(session),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 28),
                const SizedBox(width: 16),
                Text(
                  "EMERGENCY SOS",
                  style: GoogleFonts.outfit(
                    color: Colors.redAccent,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
        ).animate().shimmer(duration: 2.seconds, color: Colors.redAccent.withValues(alpha: 0.2)),
        const SizedBox(height: 16),
        Text(
          "Instant alert to Admin, Police, and Hub.",
          style: GoogleFonts.inter(color: Colors.white24, fontSize: 11),
        ),
      ],
    );
  }

  Future<void> _triggerImLost(TourSession session) async {
    HapticFeedback.heavyImpact();
    try {
      final pos = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));
      
      // Update presence so guide sees them on the map
      await _presenceRepo.updateParticipantPresence(
        sessionId: session.sessionId,
        userId: 'tourist_${AuthService().currentUser?.uid ?? "unknown"}',
        position: pos,
        role: 'tourist',
      );

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
          const SnackBar(content: Text("SIGNAL SENT! STAY WHERE YOU ARE."), backgroundColor: Colors.orangeAccent),
        );
      }
    } catch (e) {
      debugPrint("Lost Trigger Error: $e");
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
        const SnackBar(
          content: Text("SOS ALERT BROADCASTED TO ALL AUTHORITIES!"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
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
