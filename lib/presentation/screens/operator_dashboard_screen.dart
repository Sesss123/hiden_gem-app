import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/oracle_ui_system.dart';
import '../../data/repositories/operator_repository.dart';
import '../../data/models/operator_account.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/models/guide_application.dart';
import '../../data/models/guide_status.dart';
import '../../data/models/incident_report.dart';
import '../../data/models/user_profile.dart';
import '../../data/repositories/guide_application_repository.dart';
import '../../data/repositories/incident_repository.dart';
import '../../data/repositories/user_repository.dart';

class OperatorDashboardScreen extends ConsumerStatefulWidget {
  const OperatorDashboardScreen({super.key});

  @override
  ConsumerState<OperatorDashboardScreen> createState() => _OperatorDashboardScreenState();
}

class _OperatorDashboardScreenState extends ConsumerState<OperatorDashboardScreen> {
  int _activeSectorIndex = 0; // 0: Operations, 1: Guardianship, 2: Safety, 3: Citizenship
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Scaffold(body: Center(child: Text("Access Denied")));

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.transparent,
      body: OracleUI.auraBackground(
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
              return const Center(child: Text("Access Denied"));
            }
            
            final userData = userSnapshot.data!.data() as Map<String, dynamic>? ?? {};
            final String trueRole = userData['role'] ?? 'user';
            final bool isAdmin = trueRole == 'admin';
            
            if (trueRole == 'banned') {
              return const Center(child: Text("Access Denied"));
            }

            final operatorStream = ref.watch(operatorRepositoryProvider).streamOperator(user.uid);

            return StreamBuilder<OperatorAccount?>(
              stream: operatorStream,
              builder: (context, opSnapshot) {
                if (opSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final op = opSnapshot.data;
                
                // If not an admin and not an operator, show onboarding
                if (op == null && !isAdmin) return _buildOnboarding(context);

                return Row(
                  children: [
                    // Prism Side Rail
                    _buildSideRail(isAdmin),
                    
                    // Dynamic Main Viewport
                    Expanded(
                      child: _buildMainViewport(op, isAdmin),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildSideRail(bool isAdmin) {
    return OracleUI.glassContainer(
      width: 80,
      padding: const EdgeInsets.symmetric(vertical: 40),
      borderRadius: const BorderRadius.only(topRight: Radius.circular(32), bottomRight: Radius.circular(32)),
      borderGradient: OracleUI.premiumBorderGradient,
      child: Column(
        children: [
          _navIcon(0, Icons.grid_view_rounded, "OPS"),
          const SizedBox(height: 32),
          _navIcon(2, Icons.shield_rounded, "SAFE"),
          if (isAdmin) ...[
            const SizedBox(height: 32),
            _navIcon(1, Icons.verified_user_rounded, "GUARD"),
            const SizedBox(height: 32),
            _navIcon(3, Icons.people_alt_rounded, "CITZ"),
          ],
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white24),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _navIcon(int index, IconData icon, String label) {
    final isSelected = _activeSectorIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _activeSectorIndex = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: 300.ms,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              boxShadow: isSelected ? [
                BoxShadow(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3), blurRadius: 15)
              ] : null,
            ),
            child: Icon(icon, color: isSelected ? Colors.black : Colors.white54, size: 24),
          ),
          const SizedBox(height: 4),
          Text(label, style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.white24, letterSpacing: 1)),
        ],
      ),
    );
  }

  Widget _buildMainViewport(OperatorAccount? op, bool isAdmin) {
    final List<Widget> sectors = [
       _buildOperationsSector(op),
      _buildGuardianshipSector(),
      _buildSafetySector(),
      _buildCitizenshipSector(),
    ];

    return AnimatedSwitcher(
      duration: 400.ms,
      transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
      child: keySectorWrapper(sectors[_activeSectorIndex]),
    );
  }

  Widget keySectorWrapper(Widget child) {
    return Container(
      key: ValueKey(_activeSectorIndex),
      child: CustomScrollView(
        slivers: [
          _buildPrismHeader(),
          SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: SliverToBoxAdapter(child: child),
          ),
        ],
      ),
    );
  }

  Widget _buildPrismHeader() {
    final titles = ["OPERATIONS ENGINE", "GUARDIANSHIP HUB", "SAFETY CONSOLE", "CITIZENSHIP MATRIX"];
    return SliverAppBar(
      floating: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OracleUI.neonText(
            titles[_activeSectorIndex],
            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 4, color: Colors.white),
          ),
          Text("PRISM COMMAND ALPHA", style: GoogleFonts.inter(color: const Color(0xFF00E676), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        ],
      ),
    );
  }

  // --- SECTOR 0: OPERATIONS ---
  Widget _buildOperationsSector(OperatorAccount? op) {
    if (op == null) return _buildAdminOperationsOverview();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildOverviewCards(op),
        const SizedBox(height: 32),
        _buildTeamSection(op),
        const SizedBox(height: 32),
        _buildFleetSection(op),
      ],
    );
  }

  Widget _buildAdminOperationsOverview() {
    return Column(
      children: [
        const SizedBox(height: 100),
        Icon(Icons.query_stats_rounded, size: 64, color: Colors.white10),
        const SizedBox(height: 24),
        Text("GENERAL SYSTEM OVERVIEW", style: GoogleFonts.outfit(color: Colors.white38, fontWeight: FontWeight.bold)),
        Text("Operations metrics aggregated for super-admins.", style: GoogleFonts.inter(color: Colors.white10, fontSize: 12)),
      ],
    );
  }

  // --- SECTOR 1: GUARDIANSHIP (Guide Reviews) ---
  Widget _buildGuardianshipSector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("PENDING APPLICATIONS", style: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 2)),
        const SizedBox(height: 20),
        StreamBuilder<List<GuideApplication>>(
          stream: GuideApplicationRepository().getPendingApplications(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final apps = snapshot.data ?? [];
            if (apps.isEmpty) return _buildEmptyState("No pending guardians found.", Icons.verified_user_outlined);

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: apps.length,
              itemBuilder: (context, index) => _buildApplicationCard(apps[index]),
            );
          },
        ),
      ],
    );
  }

  Widget _buildApplicationCard(GuideApplication app) {
    return OracleUI.premiumGlassCard(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          const CircleAvatar(backgroundColor: Colors.white10, child: Icon(Icons.person, color: Colors.white54)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("User ID: ${app.userId}", style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                Text("License: ${app.licenseNumber}", style: GoogleFonts.inter(color: Colors.white38, fontSize: 11)),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.check_circle_outline, color: Colors.greenAccent),
                onPressed: () => _updateAppStatus(app.userId, GuideStatus.approved),
              ),
              IconButton(
                icon: const Icon(Icons.cancel_outlined, color: Colors.redAccent),
                onPressed: () => _updateAppStatus(app.userId, GuideStatus.rejected),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _updateAppStatus(String uid, GuideStatus status) async {
     await GuideApplicationRepository().reviewApplication(
      userId: uid, 
      status: status,
      adminComment: "Reviewed via Prism Command Center",
    );
    if (mounted) {
       OracleNotification.show(context, "Identity ${status.name} successfully.");
    }
  }

  // --- SECTOR 2: SAFETY ---
  Widget _buildSafetySector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("CRITICAL INCIDENTS", style: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 2)),
        const SizedBox(height: 20),
        StreamBuilder<List<IncidentReport>>(
          stream: IncidentRepository().getActiveIncidents(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final incidents = snapshot.data ?? [];
            if (incidents.isEmpty) return _buildEmptyState("All mission parameters safe.", Icons.security_rounded);

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: incidents.length,
              itemBuilder: (context, index) => _buildIncidentCommandCard(incidents[index]),
            );
          },
        ),
      ],
    );
  }

  Widget _buildIncidentCommandCard(IncidentReport incident) {
    final color = incident.severity == 'critical' ? Colors.redAccent : Colors.orangeAccent;
    return OracleUI.glassContainer(
      margin: const EdgeInsets.only(bottom: 16),
      borderColor: color.withValues(alpha: 0.3),
      child: ListTile(
        title: Text(incident.title, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text(incident.description, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(color: Colors.white38, fontSize: 11)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Text(incident.severity.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  // --- SECTOR 3: CITIZENSHIP (User Management) ---
  Widget _buildCitizenshipSector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("SYSTEM CITIZENS", style: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 2)),
        const SizedBox(height: 20),
        StreamBuilder<List<UserProfile>>(
          stream: UserRepository().getAllUsers(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final users = snapshot.data ?? [];
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: users.length,
              itemBuilder: (context, index) => _buildUserMatrixTile(users[index]),
            );
          },
        ),
      ],
    );
  }

  Widget _buildUserMatrixTile(UserProfile user) {
    return OracleUI.glassContainer(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: Colors.white10, child: Text(user.role.substring(0, 1).toUpperCase(), style: const TextStyle(color: Colors.white24))),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("IDENTIFIER: ${user.uid.substring(0, 8).toUpperCase()}", style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                Text("Role: ${user.role.toUpperCase()}", style: GoogleFonts.inter(color: Colors.white38, fontSize: 11)),
                Text("Status: ${user.isPremium ? 'Premium Oracle' : 'Standard Visitor'}", style: GoogleFonts.inter(color: Colors.white38, fontSize: 11)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.security_rounded, color: Colors.white24),
            onPressed: () => _showUserActions(user),
          ),
        ],
      ),
    );
  }

  void _showUserActions(UserProfile user) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            OracleUI.neonText("NEURAL OVERRIDE"),
            const SizedBox(height: 32),
            ListTile(
              leading: const Icon(Icons.star_rounded, color: Colors.amberAccent),
              title: const Text("GRANT PREMIUM", style: TextStyle(color: Colors.white)),
              onTap: () {
                UserRepository().togglePremium(user.uid, true); 
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.block_rounded, color: Colors.redAccent),
              title: const Text("BAN IDENTITY", style: TextStyle(color: Colors.white)),
              onTap: () {
                UserRepository().banUser(user.uid);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String msg, IconData icon) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 60),
          Icon(icon, color: Colors.white10, size: 48),
          const SizedBox(height: 16),
          Text(msg, style: GoogleFonts.inter(color: Colors.white10)),
        ],
      ),
    );
  }

  // --- REUSED COMPONENTS FROM OLD DASHBOARD (REFINED) ---
  Widget _buildOverviewCards(OperatorAccount op) {
    return Row(
      children: [
        Expanded(child: _buildMetricCard("LIVE SESSIONS", op.currentActiveSessions.toString(), Icons.radar_rounded, const Color(0xFF00E676))),
        const SizedBox(width: 16),
        Expanded(child: _buildMetricCard("TEAM UNIT", op.teamGuideIds.length.toString(), Icons.groups_rounded, Colors.blueAccent)),
        const SizedBox(width: 16),
        Expanded(child: _buildMetricCard("HUB RATING", op.averageTeamRating.toStringAsFixed(1), Icons.star_rounded, Colors.amberAccent)),
      ],
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon, Color color) {
    return OracleUI.glassContainer(
      padding: const EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 12),
          Text(value, style: GoogleFonts.outfit(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
          Text(label, style: GoogleFonts.inter(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        ],
      ),
    );
  }

  Widget _buildTeamSection(OperatorAccount op) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("MISSION GUIDES", style: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 2)),
            IconButton(icon: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF00E676)), onPressed: () {}),
          ],
        ),
        const SizedBox(height: 16),
        if (op.teamGuideIds.isEmpty)
          _buildEmptyState("No team members drafted.", Icons.person_add_disabled_outlined)
        else
          ...op.teamGuideIds.map((id) => _buildTeamMemberTile(id)),
      ],
    );
  }

  Widget _buildTeamMemberTile(String guideId) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: OracleUI.glassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        borderRadius: BorderRadius.circular(20),
        child: Row(
          children: [
            const CircleAvatar(backgroundColor: Colors.white10, child: Icon(Icons.person_rounded, color: Colors.white38)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Agent $guideId", style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                  Text("OFF-MISSION", style: GoogleFonts.inter(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFleetSection(OperatorAccount op) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("ASSET FLEET", style: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 2)),
        const SizedBox(height: 16),
        OracleUI.glassContainer(
          padding: const EdgeInsets.all(24),
          borderRadius: BorderRadius.circular(24),
          child: Row(
            children: [
              const Icon(Icons.local_shipping_rounded, color: Colors.white24, size: 32),
              const SizedBox(width: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("${op.vehicleIds.length} ASSETS DEPLOYED", style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                  Text("Operational Readiness: 100%", style: GoogleFonts.inter(color: Colors.white24, fontSize: 11)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOnboarding(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            OracleUI.glassContainer(
              padding: const EdgeInsets.all(24),
              borderRadius: BorderRadius.circular(32),
              child: const Icon(Icons.business_center_rounded, color: Colors.white24, size: 48),
            ),
            const SizedBox(height: 32),
            OracleUI.neonText("OPERATOR REGISTRATION"),
            const SizedBox(height: 16),
            Text(
              "Access restricted to agency partners and super-admins.",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: Colors.white38, fontSize: 14, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

