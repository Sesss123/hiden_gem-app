import 'package:hidden_gems_sl/core/theme/app_theme.dart';
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
    return SliverAppBar(
      expandedHeight: 60.0,
      backgroundColor: AppTheme.colors.transparent,
      elevation: 0,
      pinned: true,
      leading: Builder(
        builder: (context) => IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textPrimary(context), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      actions: [
        Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.share_rounded, color: AppTheme.textSecondary(context)),
            onPressed: () {},
          ),
        ),
      ],
    );
  }

  Widget _buildMainInfo(IncidentReport incident) {
    return Builder(builder: (context) {
      final severityColor = incident.severity == 'critical' ? AppTheme.colors.redAccent : AppTheme.colors.orangeAccent;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            incident.incidentNumber,
            style: GoogleFonts.inter(color: AppTheme.colors.orange[700], fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Status",
                    style: GoogleFonts.inter(color: AppTheme.textSecondary(context), fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _sentenceCase(incident.status),
                    style: GoogleFonts.outfit(color: AppTheme.textPrimary(context), fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "Severity",
                    style: GoogleFonts.inter(color: AppTheme.textSecondary(context), fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: severityColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      _sentenceCase(incident.severity),
                      style: GoogleFonts.inter(
                        color: severityColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            incident.title,
            style: GoogleFonts.outfit(color: AppTheme.textPrimary(context), fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.5),
          ).animate().fadeIn().slideX(begin: 0.1),
          const SizedBox(height: 12),
          Text(
            incident.description,
            style: GoogleFonts.inter(color: AppTheme.textSecondary(context), fontSize: 14, height: 1.6),
          ).animate().fadeIn(delay: 200.ms),
        ],
      );
    });
  }

  String _sentenceCase(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1).toLowerCase();
  }

  Widget _buildTimelineHeader() {
    return Builder(builder: (context) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Timeline",
            style: GoogleFonts.inter(color: AppTheme.textPrimary(context), fontSize: 12, fontWeight: FontWeight.bold),
          ),
          Text(
            "Encrypted log",
            style: GoogleFonts.inter(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.6), fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ],
      );
    });
  }

  List<Widget> _buildTimeline(IncidentReport incident) {
    if (incident.timelineEvents.isEmpty) {
      return [
        Builder(builder: (context) => Text("No timeline active.", style: TextStyle(color: AppTheme.textSecondary(context)))),
      ];
    }

    return incident.timelineEvents.map((e) {
      final isLast = incident.timelineEvents.last == e;
      return Builder(builder: (context) {
        final dotColor = Theme.of(context).colorScheme.primary;
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 12, height: 12,
                    decoration: BoxDecoration(
                      color: dotColor,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: dotColor.withValues(alpha: 0.15), blurRadius: 0, spreadRadius: 4)],
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(width: 1, color: AppTheme.borderColor(context)),
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
                            _sentenceCase((e['type'] as String).replaceAll('_', ' ')),
                            style: GoogleFonts.inter(color: AppTheme.textPrimary(context), fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                          Text(
                            "2m ago", // In reality, format the timestamp
                            style: GoogleFonts.inter(color: AppTheme.textSecondary(context), fontSize: 10),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        e['description'] as String,
                        style: GoogleFonts.inter(color: AppTheme.textSecondary(context), fontSize: 11),
                      ),
                    ],
                  ),
                ).animate().fadeIn().slideY(begin: 0.2),
              ),
            ],
          ),
        );
      });
    }).toList();
  }

  Widget _buildStatusActions(IncidentReport incident) {
    return Builder(builder: (context) {
      return Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: AppTheme.colors.black.withValues(alpha: 0.05), blurRadius: 16, offset: const Offset(0, 6)),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.verified_user_rounded, color: AppTheme.colors.teal, size: 20),
                const SizedBox(width: 12),
                Text(
                  "Verified audit log",
                  style: GoogleFonts.outfit(color: AppTheme.textPrimary(context), fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              "This report is locked for forensic integrity. Only authorized admins can modify status.",
              style: GoogleFonts.inter(color: AppTheme.textSecondary(context), fontSize: 12),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textPrimary(context),
                      side: BorderSide(color: AppTheme.borderColor(context)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                    ),
                    child: const Text("Add evidence"),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                    ),
                    child: const Text("Escalate", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }
}
