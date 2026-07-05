import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/oracle_ui_system.dart';
import '../../data/models/family_share_link.dart';
import '../../data/models/tour_session.dart';

class SharedViewScreen extends StatefulWidget {
  final String shareToken;

  const SharedViewScreen({
    super.key,
    required this.shareToken,
  });

  @override
  State<SharedViewScreen> createState() => _SharedViewScreenState();
}

class _SharedViewScreenState extends State<SharedViewScreen> {
  bool _isLoading = true;
  bool _isExpiredOrInvalid = false;
  FamilyShareLink? _link;
  TourSession? _session;
  Timer? _refreshTimer;
  bool _viewCountIncremented = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    // Auto-refresh displayed data periodically (every 30 seconds)
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) _loadData();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final docSnap = await FirebaseFirestore.instance
          .collection('family_share_links')
          .doc(widget.shareToken)
          .get();

      if (!docSnap.exists || docSnap.data() == null) {
        if (mounted) {
          setState(() {
            _isExpiredOrInvalid = true;
            _isLoading = false;
          });
          _refreshTimer?.cancel();
        }
        return;
      }

      final link = FamilyShareLink.fromJson(docSnap.data()!);

      // Check server-side / read-time expiry and active status
      if (!link.isActive || link.isExpired) {
        if (mounted) {
          setState(() {
            _isExpiredOrInvalid = true;
            _link = null;
            _session = null;
            _isLoading = false;
          });
          _refreshTimer?.cancel();
        }
        return;
      }

      // Increment viewCount only once per screen load
      if (!_viewCountIncremented) {
        _viewCountIncremented = true;
        FirebaseFirestore.instance
            .collection('family_share_links')
            .doc(widget.shareToken)
            .update({'viewCount': FieldValue.increment(1)})
            .catchError((_) {});
      }

      // Fetch tour session if available
      TourSession? session;
      try {
        final sessionSnap = await FirebaseFirestore.instance
            .collection('tour_sessions')
            .doc(link.sessionId)
            .get();
        if (sessionSnap.exists && sessionSnap.data() != null) {
          session = TourSession.fromJson(sessionSnap.data()!);
        }
      } catch (e) {
        debugPrint("Notice: Session data not accessible or offline: $e");
      }

      if (mounted) {
        setState(() {
          _link = link;
          _session = session;
          _isExpiredOrInvalid = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading share link: $e");
      if (mounted && _isLoading) {
        setState(() {
          _isExpiredOrInvalid = true;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: OracleUI.auraBackground(
        child: CustomScrollView(
          slivers: [
            _buildAppBar(),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: _isLoading
                    ? _buildLoadingState()
                    : _isExpiredOrInvalid
                        ? _buildExpiredState()
                        : _buildValidContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      floating: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      title: OracleUI.neonText(
        "LIVE MISSION TRACKING",
        style: GoogleFonts.outfit(
          fontSize: 14,
          fontWeight: FontWeight.w900,
          letterSpacing: 4,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 100),
        child: OracleUI.glassContainer(
          padding: const EdgeInsets.all(48),
          borderRadius: BorderRadius.circular(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Color(0xFF00E676)),
              const SizedBox(height: 24),
              Text(
                "Verifying Security Token...",
                style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                "Establishing encrypted connection to live mission feed.",
                style: GoogleFonts.inter(color: Colors.white38, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpiredState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: OracleUI.glassContainer(
          padding: const EdgeInsets.all(40),
          borderRadius: BorderRadius.circular(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.gpp_bad_rounded, color: Colors.redAccent, size: 64),
              const SizedBox(height: 24),
              Text(
                "Link Expired or Invalid",
                style: GoogleFonts.outfit(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                "This sharing link has expired, been deactivated by the sender, or is no longer valid.",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: Colors.white60, fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock_outline_rounded, color: Colors.redAccent, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      "Security policy enforced server-side",
                      style: GoogleFonts.inter(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95)),
    );
  }

  Widget _buildValidContent() {
    final link = _link!;
    final perms = link.permissions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHero(link),
        const SizedBox(height: 32),
        Text(
          "AUTHORIZED FEED DATA",
          style: GoogleFonts.inter(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 2),
        ),
        const SizedBox(height: 16),
        if (perms['show_emergency'] == true) ...[
          _buildEmergencySection(),
          const SizedBox(height: 16),
        ],
        if (perms['show_status'] == true) ...[
          _buildStatusSection(),
          const SizedBox(height: 16),
        ],
        if (perms['show_identity'] == true) ...[
          _buildIdentitySection(),
          const SizedBox(height: 16),
        ],
        if (perms['show_meeting_point'] == true) ...[
          _buildMeetingPointSection(),
          const SizedBox(height: 16),
        ],
        const SizedBox(height: 32),
        Center(
          child: Text(
            "🔒 End-to-end access protected by token authentication.\nAuto-refreshing every 30 seconds.",
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: Colors.white24, fontSize: 11, height: 1.5),
          ),
        ),
        const SizedBox(height: 60),
      ],
    );
  }

  Widget _buildHero(FamilyShareLink link) {
    return OracleUI.premiumGlassCard(
      padding: const EdgeInsets.all(28),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF00E676).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF00E676)),
                ),
                child: const Icon(Icons.shield_rounded, color: Color(0xFF00E676), size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("ACTIVE MISSION LINK", style: GoogleFonts.inter(color: const Color(0xFF00E676), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
                    const SizedBox(height: 4),
                    Text(link.recipientName, style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Divider(color: Colors.white.withValues(alpha: 0.1)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Session Expiry:", style: GoogleFonts.inter(color: Colors.white54, fontSize: 12)),
              Text(
                "${link.expiresAt.hour.toString().padLeft(2, '0')}:${link.expiresAt.minute.toString().padLeft(2, '0')}",
                style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }

  Widget _buildEmergencySection() {
    final isSos = _session?.sosActive == true;
    final color = isSos ? Colors.redAccent : const Color(0xFF00E676);

    return OracleUI.glassContainer(
      padding: const EdgeInsets.all(24),
      borderRadius: BorderRadius.circular(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(isSos ? Icons.warning_rounded : Icons.health_and_safety_rounded, color: color, size: 24),
              const SizedBox(width: 12),
              Text(
                isSos ? "🚨 SOS EMERGENCY TRIGGERED" : "SAFETY STATUS",
                style: GoogleFonts.outfit(color: color, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            isSos
                ? "Emergency alert has been triggered for this mission! Authorities and emergency responders have been notified."
                : "All safety signals are normal. Live tracking is active and monitoring companion sensors.",
            style: GoogleFonts.inter(color: Colors.white70, fontSize: 13, height: 1.5),
          ),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _buildStatusSection() {
    final status = _session?.status.toUpperCase() ?? 'ACTIVE';
    final phase = _session?.currentPhase.replaceAll('_', ' ').toUpperCase() ?? 'IN PROGRESS';

    return OracleUI.glassContainer(
      padding: const EdgeInsets.all(24),
      borderRadius: BorderRadius.circular(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("MISSION STATUS", style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF00E676).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF00E676)),
                ),
                child: Text(status, style: GoogleFonts.inter(color: const Color(0xFF00E676), fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow("Current Phase", phase),
          const SizedBox(height: 8),
          _buildInfoRow("Live Tracking", _session?.trackingEnabled == true ? "ENABLED (GPS ACTIVE)" : "STANDBY"),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _buildIdentitySection() {
    final guideDisplay = (_session?.guideId.length ?? 0) > 8
        ? _session!.guideId.substring(0, 8).toUpperCase()
        : (_session?.guideId.toUpperCase() ?? "VERIFIED GUIDE");

    return OracleUI.glassContainer(
      padding: const EdgeInsets.all(24),
      borderRadius: BorderRadius.circular(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("GUIDE & VEHICLE IDENTITY", style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          _buildInfoRow("Assigned Guide ID", guideDisplay),
          const SizedBox(height: 8),
          _buildInfoRow("Vehicle Number", _session?.vehicleNumber ?? "Not Specified / Walking Tour"),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _buildMeetingPointSection() {
    return OracleUI.glassContainer(
      padding: const EdgeInsets.all(24),
      borderRadius: BorderRadius.circular(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("DESIGNATED MEETING POINT", style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          _buildInfoRow("Location", _session?.meetingPointName ?? "Designated Tour Landmark"),
          if (_session?.meetingPointLat != null && _session?.meetingPointLng != null) ...[
            const SizedBox(height: 8),
            _buildInfoRow("Coordinates", "${_session!.meetingPointLat.toStringAsFixed(4)}, ${_session!.meetingPointLng.toStringAsFixed(4)}"),
          ],
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.inter(color: Colors.white54, fontSize: 13)),
        Text(value, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
      ],
    );
  }
}
