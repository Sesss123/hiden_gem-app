import 'package:hidden_gems_sl/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/oracle_ui_system.dart';
import '../../data/models/incident_report.dart';
import '../../data/repositories/incident_repository.dart';
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
                if (snapshot.hasError) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Text("Offline Error: ${snapshot.error}", style: TextStyle(color: AppTheme.colors.redAccent)),
                    ),
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
      expandedHeight: 80.0,
      backgroundColor: AppTheme.colors.transparent,
      elevation: 0,
      pinned: true,
      flexibleSpace: Builder(
        builder: (context) => FlexibleSpaceBar(
          titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
          title: Text(
            "Safety console",
            style: GoogleFonts.outfit(fontWeight: FontWeight.w800, letterSpacing: -0.5, fontSize: 20, color: AppTheme.textPrimary(context)),
          ),
        ),
      ),
    );
  }

  Widget _buildReportHeader() {
    return Builder(builder: (context) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surfaceMuted(context),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.colors.redAccent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.shield_rounded, color: AppTheme.colors.redAccent, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Secure operations",
                    style: GoogleFonts.outfit(
                      color: AppTheme.textPrimary(context),
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "All incidents logged with audit trail",
                    style: GoogleFonts.inter(
                      color: AppTheme.textSecondary(context),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildFilterChips() {
    return Builder(builder: (context) {
      return Container(
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: ['Active', 'Resolved', 'My Reports'].map((filter) {
            final isSelected = _selectedFilter == filter;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => setState(() => _selectedFilter = filter),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.textPrimary(context) : AppTheme.surfaceMuted(context),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    filter,
                    style: GoogleFonts.inter(
                      color: isSelected ? Theme.of(context).colorScheme.surface : AppTheme.textSecondary(context),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      );
    });
  }

  Widget _buildIncidentCard(IncidentReport incident) {
    final severityColor = incident.severity == 'critical' ? AppTheme.colors.redAccent : AppTheme.colors.orangeAccent;

    return Builder(builder: (context) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border(left: BorderSide(color: severityColor, width: 4)),
          boxShadow: [
            BoxShadow(color: AppTheme.colors.black.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, 6)),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => IncidentDetailScreen(incidentId: incident.incidentId)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          incident.incidentNumber,
                          style: GoogleFonts.outfit(
                            color: severityColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                            letterSpacing: 0.5,
                          ),
                        ),
                        if (incident.priorityTier > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppPalette.heroOchre.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Text(
                              'PRIORITY',
                              style: GoogleFonts.outfit(color: AppPalette.heroOchre, fontWeight: FontWeight.w800, fontSize: 9, letterSpacing: 0.5),
                            ),
                          ),
                        ],
                      ],
                    ),
                    _buildStatusChip(context, incident.status),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  incident.title,
                  style: GoogleFonts.outfit(
                    color: AppTheme.textPrimary(context),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  incident.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: AppTheme.textSecondary(context),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.access_time_rounded, color: AppTheme.textSecondary(context), size: 14),
                    const SizedBox(width: 4),
                    Text(
                      "${incident.createdAt.hour}:${incident.createdAt.minute.toString().padLeft(2, '0')}",
                      style: GoogleFonts.inter(color: AppTheme.textSecondary(context), fontSize: 11),
                    ),
                    const Spacer(),
                    Text(
                      "${incident.timelineCount} updates",
                      style: GoogleFonts.inter(
                        color: Theme.of(context).colorScheme.primary,
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
    });
  }

  Widget _buildStatusChip(BuildContext context, String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceMuted(context),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        _sentenceCase(status),
        style: GoogleFonts.inter(
          color: AppTheme.textSecondary(context),
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  String _sentenceCase(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1).toLowerCase();
  }

  Widget _buildEmptyState() {
    return Builder(builder: (context) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline_rounded, size: 56, color: AppTheme.textSecondary(context).withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text(
              "No critical incidents",
              style: GoogleFonts.outfit(
                color: AppTheme.textPrimary(context),
                fontWeight: FontWeight.w700,
                fontSize: 18,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Session operations are within safety parameters.",
              style: GoogleFonts.inter(color: AppTheme.textSecondary(context), fontSize: 13),
            ),
          ],
        ),
      ).animate().fadeIn();
    });
  }

  Widget _buildReportFAB() {
    return FloatingActionButton.extended(
      onPressed: () => _showReportDialog(),
      backgroundColor: AppTheme.colors.redAccent,
      icon: Icon(Icons.add_alert_rounded, color: AppTheme.colors.white),
      label: Text(
        "Report incident",
        style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppTheme.colors.white),
      ),
    ).animate().scale(delay: 1.seconds);
  }

  void _showReportDialog() {
    // Simplified for now, in reality a multi-step form
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        builder: (_, controller) => Builder(builder: (context) {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: ListView(
              controller: controller,
              padding: const EdgeInsets.all(32),
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(color: AppTheme.surfaceMuted(context), borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  "File an incident",
                  style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.4, color: AppTheme.textPrimary(context)),
                ),
                const SizedBox(height: 8),
                Text(
                  "Provide accurate details, this is logged with an audit trail.",
                  style: GoogleFonts.inter(color: AppTheme.textSecondary(context), fontSize: 12),
                ),
                const SizedBox(height: 32),
                _buildLargeField(context, "Incident title", Icons.title_rounded),
                const SizedBox(height: 20),
                _buildLargeField(context, "Description of event", Icons.description_rounded, maxLines: 4),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.colors.redAccent,
                      foregroundColor: AppTheme.colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                      elevation: 0,
                    ),
                    child: Text("Transmit report", style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14)),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildLargeField(BuildContext context, String hint, IconData icon, {int maxLines = 1}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceMuted(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        maxLines: maxLines,
        style: TextStyle(color: AppTheme.textPrimary(context)),
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: AppTheme.textSecondary(context), size: 20),
          hintStyle: TextStyle(color: AppTheme.textSecondary(context), fontSize: 13),
          border: InputBorder.none,
        ),
      ),
    );
  }
}
