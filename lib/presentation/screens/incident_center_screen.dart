import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/oracle_ui_system.dart';
import '../../data/models/incident_report.dart';
import '../../data/repositories/incident_repository.dart';
import '../../data/repositories/tour_session_repository.dart';
import 'incident_detail_screen.dart';

class IncidentCenterScreen extends ConsumerStatefulWidget {
  final String? sessionId;
  const IncidentCenterScreen({super.key, this.sessionId});

  @override
  ConsumerState<IncidentCenterScreen> createState() => _IncidentCenterScreenState();
}

class _IncidentCenterScreenState extends ConsumerState<IncidentCenterScreen> {
  String _selectedFilter = 'Active';

  @override
  Widget build(BuildContext context) {
    final incidentRepo = ref.watch(incidentRepositoryProvider);
    final activeIncidentsStream = widget.sessionId != null 
        ? incidentRepo.getSessionIncidents(widget.sessionId!)
        : incidentRepo.getActiveIncidents();

    return Scaffold(
      body: OracleUI.auraBackground(
        child: CustomScrollView(
          slivers: [
            _buildAppBar(),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: _buildReportHeader(),
              ),
            ),
            SliverToBoxAdapter(
              child: _buildFilterChips(),
            ),
            StreamBuilder<List<IncidentReport>>(
              stream: activeIncidentsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                
                final incidents = snapshot.data ?? [];
                if (incidents.isEmpty) {
                  return SliverFillRemaining(child: _buildEmptyState());
                }

                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => OracleUI.staggeredEntrance(
                        index: index,
                        child: _buildIncidentCard(incidents[index]),
                      ),
                      childCount: incidents.length,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: _buildReportFAB(),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120.0,
      backgroundColor: Colors.transparent,
      elevation: 0,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
        title: OracleUI.neonText(
          "SAFETY CONSOLE",
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            color: Colors.white,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.redAccent.withValues(alpha: 0.1), Colors.transparent],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReportHeader() {
    return OracleUI.glassContainer(
      padding: const EdgeInsets.all(24),
      borderRadius: BorderRadius.circular(24),
      borderColor: Colors.redAccent.withValues(alpha: 0.2),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.redAccent.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.shield_rounded, color: Colors.redAccent, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "SECURE OPERATIONS",
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "All incident reports are logged with immutable audit trails.",
                  style: GoogleFonts.inter(
                    color: Colors.white60,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: ['Active', 'Resolved', 'My Reports'].map((filter) {
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: OracleUI.glassChip(
              context: context,
              label: filter,
              isSelected: isSelected,
              onTap: () => setState(() => _selectedFilter = filter),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildIncidentCard(IncidentReport incident) {
    final severityColor = incident.severity == 'critical' ? Colors.redAccent : Colors.orangeAccent;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: OracleUI.glassContainer(
        padding: const EdgeInsets.all(20),
        borderRadius: BorderRadius.circular(24),
        borderColor: severityColor.withValues(alpha: 0.2),
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => IncidentDetailScreen(incidentId: incident.incidentId)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    incident.incidentNumber,
                    style: GoogleFonts.outfit(
                      color: severityColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      letterSpacing: 1,
                    ),
                  ),
                  _buildStatusChip(incident.status),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                incident.title,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                incident.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: Colors.white60,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.access_time_rounded, color: Colors.white24, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    "${incident.createdAt.hour}:${incident.createdAt.minute.toString().padLeft(2, '0')}",
                    style: GoogleFonts.inter(color: Colors.white24, fontSize: 11),
                  ),
                  const Spacer(),
                  Text(
                    "${incident.timelineCount} Updates",
                    style: GoogleFonts.inter(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Text(
        status.toUpperCase(),
        style: GoogleFonts.inter(
          color: Colors.white30,
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline_rounded, size: 64, color: Colors.white.withValues(alpha: 0.05)),
          const SizedBox(height: 16),
          Text(
            "NO CRITICAL INCIDENTS",
            style: GoogleFonts.outfit(
              color: Colors.white12,
              fontWeight: FontWeight.w900,
              fontSize: 16,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Session operations are within safety parameters.",
            style: GoogleFonts.inter(color: Colors.white10, fontSize: 12),
          ),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _buildReportFAB() {
    return FloatingActionButton.extended(
      onPressed: () => _showReportDialog(),
      backgroundColor: Colors.redAccent,
      icon: const Icon(Icons.add_alert_rounded, color: Colors.white),
      label: Text(
        "REPORT INCIDENT",
        style: GoogleFonts.inter(fontWeight: FontWeight.w900, letterSpacing: 1),
      ),
    ).animate().scale(delay: 1.seconds);
  }

  void _showReportDialog() {
    // Simplified for now, in reality a multi-step form
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0A0D11),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.all(32),
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 32),
              OracleUI.neonText(
                "FILE INCIDENT",
                style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 2, color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                "Provide accurate details. Forensic logging active.",
                style: GoogleFonts.inter(color: Colors.white30, fontSize: 12),
              ),
              const SizedBox(height: 32),
              _buildLargeField("Incident Title", Icons.title_rounded),
              const SizedBox(height: 20),
              _buildLargeField("Description of event", Icons.description_rounded, maxLines: 4),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text("TRANSMIT REPORT", style: TextStyle(fontWeight: FontWeight.w900)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLargeField(String hint, IconData icon, {int maxLines = 1}) {
    return OracleUI.glassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      borderRadius: BorderRadius.circular(16),
      borderColor: Colors.white.withValues(alpha: 0.05),
      child: TextField(
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: Colors.white24, size: 20),
          hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
          border: InputBorder.none,
        ),
      ),
    );
  }
}
