import 'package:hidden_gems_sl/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/oracle_ui_system.dart';
import '../../data/models/incident_report.dart';
import '../../data/repositories/incident_repository.dart';
import '../../l10n/app_localizations.dart';

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
        // Watches this single doc by id directly — getActiveIncidents() is
        // status-filtered to {open, under_review, escalated} for the admin
        // dashboard and would 404 this screen the moment an admin resolves
        // or dismisses the incident, hiding the resolution from the
        // reporting user right when they need to see it.
        child: StreamBuilder<IncidentReport?>(
          stream: incidentRepo.watchIncident(widget.incidentId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final l10n = AppLocalizations.of(context)!;
            final incident = snapshot.data ?? IncidentReport(
                incidentId: '404',
                incidentNumber: 'INV-404',
                sessionId: 'none',
                guideId: 'none',
                touristId: 'none',
                reportedBy: 'sys',
                reportedByRole: 'system',
                type: 'error',
                severity: 'low',
                title: l10n.incidentNotFoundTitle,
                description: l10n.incidentNotFoundDescription,
                status: 'closed',
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
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
      final l10n = AppLocalizations.of(context)!;
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
                    l10n.statusLabel,
                    style: GoogleFonts.inter(color: AppTheme.textSecondary(context), fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _incidentStatusLabel(incident.status, l10n),
                    style: GoogleFonts.outfit(color: AppTheme.textPrimary(context), fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    l10n.severityLabel,
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
                      _severityLabel(incident.severity, l10n),
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
          if ((incident.resolutionNote ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.colors.teal.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.colors.teal.withValues(alpha: 0.25)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.check_circle_outline_rounded, color: AppTheme.colors.teal, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        l10n.resolutionNoteLabel,
                        style: GoogleFonts.inter(color: AppTheme.colors.teal, fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    incident.resolutionNote!,
                    style: GoogleFonts.inter(color: AppTheme.textPrimary(context), fontSize: 13, height: 1.5),
                  ),
                  if ((incident.resolvedBy ?? '').trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      l10n.resolvedByLabel(incident.resolvedBy!),
                      style: GoogleFonts.inter(color: AppTheme.textSecondary(context), fontSize: 10.5, fontWeight: FontWeight.w600),
                    ),
                  ],
                ],
              ),
            ).animate().fadeIn(delay: 250.ms),
          ],
        ],
      );
    });
  }

  // Timeline entries used to always show a hardcoded "2m ago" regardless of
  // the actual event — misleading for anything but the very first event on
  // a freshly-opened incident, and especially wrong for the resolution
  // entry a reporter would check hours or days after filing.
  String _formatTimelineTimestamp(String? isoTimestamp, AppLocalizations l10n) {
    if (isoTimestamp == null) return '';
    final parsed = DateTime.tryParse(isoTimestamp);
    if (parsed == null) return '';
    final diff = DateTime.now().difference(parsed);
    if (diff.inMinutes < 60) return l10n.minutesAgoLabel(diff.inMinutes < 1 ? 1 : diff.inMinutes);
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 30) return '${diff.inDays}d ago';
    return '${parsed.year}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')}';
  }

  String _timelineEventTypeLabel(String type, AppLocalizations l10n) {
    switch (type) {
      case 'sos_triggered':
        return l10n.timelineTypeSosTriggered;
      default:
        return type.replaceAll('_', ' ');
    }
  }

  String _incidentStatusLabel(String status, AppLocalizations l10n) {
    switch (status.toLowerCase()) {
      case 'open':
        return l10n.incidentStatusOpen;
      case 'investigating':
        return l10n.incidentStatusInvestigating;
      case 'resolved':
        return l10n.incidentStatusResolved;
      case 'closed':
        return l10n.incidentStatusClosed;
      default:
        return status;
    }
  }

  String _severityLabel(String severity, AppLocalizations l10n) {
    switch (severity.toLowerCase()) {
      case 'low':
        return l10n.broadcastPriorityLow;
      case 'normal':
      case 'medium':
        return l10n.broadcastPriorityNormal;
      case 'high':
        return l10n.broadcastPriorityHigh;
      case 'critical':
        return l10n.broadcastPriorityCritical;
      default:
        return severity;
    }
  }

  Widget _buildTimelineHeader() {
    return Builder(builder: (context) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            AppLocalizations.of(context)!.timelineLabel,
            style: GoogleFonts.inter(color: AppTheme.textPrimary(context), fontSize: 12, fontWeight: FontWeight.bold),
          ),
          Text(
            AppLocalizations.of(context)!.encryptedLogLabel,
            style: GoogleFonts.inter(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.6), fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ],
      );
    });
  }

  List<Widget> _buildTimeline(IncidentReport incident) {
    if (incident.timelineEvents.isEmpty) {
      return [
        Builder(builder: (context) => Text(AppLocalizations.of(context)!.noTimelineActiveMessage, style: TextStyle(color: AppTheme.textSecondary(context)))),
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
                            _timelineEventTypeLabel(e['type'] as String, AppLocalizations.of(context)!),
                            style: GoogleFonts.inter(color: AppTheme.textPrimary(context), fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                          Text(
                            _formatTimelineTimestamp(e['timestamp'] as String?, AppLocalizations.of(context)!),
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
                  AppLocalizations.of(context)!.verifiedAuditLogLabel,
                  style: GoogleFonts.outfit(color: AppTheme.textPrimary(context), fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.forensicIntegrityLockedMessage,
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
                    child: Text(AppLocalizations.of(context)!.addEvidenceButton),
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
                    child: Text(AppLocalizations.of(context)!.escalateButton, style: const TextStyle(fontWeight: FontWeight.bold)),
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
