import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/oracle_ui_system.dart';
import '../../data/models/incident_report.dart';
import '../../data/repositories/incident_repository.dart';

class IncidentDetailScreen extends ConsumerStatefulWidget {
  final String incidentId;
  const IncidentDetailScreen({super.key, required this.incidentId});

  @override
  ConsumerState<IncidentDetailScreen> createState() => _IncidentDetailScreenState();
}

class _IncidentDetailScreenState extends ConsumerState<IncidentDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final incidentRepo = ref.watch(incidentRepositoryProvider);

    return Scaffold(
      body: OracleUI.auraBackground(
        child: StreamBuilder<List<IncidentReport>>(
          stream: incidentRepo.getActiveIncidents(), // Using a hack for now, in reality should fetch by ID
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            
            final incident = (snapshot.data ?? []).firstWhere(
              (element) => element.incidentId == widget.incidentId,
              orElse: () => IncidentReport(
                incidentId: '404', 
                incidentNumber: 'INV-404', 
                sessionId: 'none',
                guideId: 'none',
                touristId: 'none',
                reportedBy: 'sys', 
                reportedByRole: 'system', 
                type: 'error', 
                severity: 'low', 
                title: 'Incident Not Found', 
                description: 'Record was sanitized or moved.', 
                status: 'closed', 
                createdAt: DateTime.now(), 
                updatedAt: DateTime.now(), 
              ),
            );

            return CustomScrollView(
              slivers: [
                _buildAppBar(incident),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildMainInfo(incident),
                        const SizedBox(height: 32),
                        _buildTimelineHeader(),
                        const SizedBox(height: 20),
                        ..._buildTimeline(incident),
                        const SizedBox(height: 48),
                        _buildStatusActions(incident),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildAppBar(IncidentReport incident) {
    final severityColor = incident.severity == 'critical' ? Colors.redAccent : Colors.orangeAccent;

    return SliverAppBar(
      expandedHeight: 200.0,
      backgroundColor: Colors.transparent,
      elevation: 0,
      pinned: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.share_rounded, color: Colors.white60),
          onPressed: () {},
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: Text(
          incident.incidentNumber,
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            letterSpacing: 3,
            color: severityColor,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [severityColor.withValues(alpha: 0.15), Colors.transparent],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Center(
            child: Icon(Icons.shield_rounded, color: severityColor.withValues(alpha: 0.2), size: 80),
          ),
        ),
      ),
    );
  }

  Widget _buildMainInfo(IncidentReport incident) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "CURRENT STATUS",
                  style: GoogleFonts.inter(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
                const SizedBox(height: 4),
                OracleUI.neonText(
                  incident.status.toUpperCase(),
                  style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "SEVERITY",
                  style: GoogleFonts.inter(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: incident.severity == 'critical' ? Colors.redAccent.withValues(alpha: 0.1) : Colors.orangeAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: incident.severity == 'critical' ? Colors.redAccent.withValues(alpha: 0.3) : Colors.orangeAccent.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    incident.severity.toUpperCase(),
                    style: GoogleFonts.inter(
                      color: incident.severity == 'critical' ? Colors.redAccent : Colors.orangeAccent,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 32),
        Text(
          incident.title,
          style: GoogleFonts.outfit(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
        ).animate().fadeIn().slideX(begin: 0.1),
        const SizedBox(height: 12),
        Text(
          incident.description,
          style: GoogleFonts.inter(color: Colors.white70, fontSize: 14, height: 1.6),
        ).animate().fadeIn(delay: 200.ms),
      ],
    );
  }

  Widget _buildTimelineHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "INCIDENT TIMELINE",
          style: GoogleFonts.inter(color: Colors.white24, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 2),
        ),
        Text(
          "ENCRYPTED LOG",
          style: GoogleFonts.inter(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3), fontSize: 10, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  List<Widget> _buildTimeline(IncidentReport incident) {
    if (incident.timelineEvents.isEmpty) {
      return [const Text("No timeline active.", style: TextStyle(color: Colors.white12))];
    }

    return incident.timelineEvents.map((e) {
      final isLast = incident.timelineEvents.last == e;
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 12, height: 12,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5), blurRadius: 8)],
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(width: 1, color: Colors.white.withValues(alpha: 0.1)),
                  ),
              ],
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          (e['type'] as String).toUpperCase().replaceAll('_', ' '),
                          style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.5),
                        ),
                        Text(
                          "2m ago", // In reality, format the timestamp
                          style: GoogleFonts.inter(color: Colors.white10, fontSize: 10),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      e['description'] as String,
                      style: GoogleFonts.inter(color: Colors.white30, fontSize: 12),
                    ),
                  ],
                ),
              ).animate().fadeIn().slideY(begin: 0.2),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildStatusActions(IncidentReport incident) {
    return OracleUI.glassContainer(
      padding: const EdgeInsets.all(24),
      borderRadius: BorderRadius.circular(24),
      borderColor: Colors.white.withValues(alpha: 0.05),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.verified_user_rounded, color: Colors.cyanAccent, size: 20),
              const SizedBox(width: 12),
              Text(
                "VERIFIED AUDIT LOG",
                style: GoogleFonts.inter(color: Colors.cyanAccent, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            "This report is locked for forensic integrity. Only authorized admins can modify status.",
            style: GoogleFonts.inter(color: Colors.white24, fontSize: 11),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("ADD EVIDENCE"),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("ESCALATE", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
