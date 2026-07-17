import 'package:hidden_gems_sl/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/oracle_ui_system.dart';
import '../../data/models/guide_application.dart';
import '../../data/models/guide_status.dart';
import '../../data/repositories/guide_application_repository.dart';
import 'admin_guide_verification_detail_screen.dart';
import '../../l10n/app_localizations.dart';

final _guideApplicationRepoProvider = Provider((ref) => GuideApplicationRepository());

class AdminGuideVerificationScreen extends ConsumerStatefulWidget {
  const AdminGuideVerificationScreen({super.key});

  @override
  ConsumerState<AdminGuideVerificationScreen> createState() => _AdminGuideVerificationScreenState();
}

class _AdminGuideVerificationScreenState extends ConsumerState<AdminGuideVerificationScreen> {
  String _selectedFilter = 'pending';

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(_guideApplicationRepoProvider);
    final isDerivedExpiryFilter = _selectedFilter == 'expiring_soon' || _selectedFilter == 'expired';
    final applicationsStream = isDerivedExpiryFilter
        ? repo.getApplicationsByStatus(GuideStatus.approved.name)
        : repo.getApplicationsByStatus(_selectedFilter);

    return Scaffold(
      body: OracleUI.auraBackground(
        child: CustomScrollView(
          slivers: [
            _buildAppBar(),
            SliverToBoxAdapter(child: _buildFilterChips()),
            StreamBuilder<List<GuideApplication>>(
              stream: applicationsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasError) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Text(
                        AppLocalizations.of(context)!.offlineErrorMessage(snapshot.error.toString()),
                        style: TextStyle(color: AppTheme.colors.redAccent),
                      ),
                    ),
                  );
                }

                var applications = snapshot.data ?? [];
                if (isDerivedExpiryFilter) {
                  final now = DateTime.now();
                  applications = applications.where((a) {
                    if (a.licenseExpiryDate == null) return false;
                    final isExpired = a.licenseExpiryDate!.isBefore(now);
                    if (_selectedFilter == 'expired') return isExpired;
                    final daysUntilExpiry = a.licenseExpiryDate!.difference(now).inDays;
                    return !isExpired && daysUntilExpiry <= 30;
                  }).toList();
                }

                if (applications.isEmpty) {
                  return SliverFillRemaining(child: _buildEmptyState());
                }

                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => OracleUI.staggeredEntrance(
                        index: index,
                        child: _buildApplicationCard(applications[index]),
                      ),
                      childCount: applications.length,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
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
            AppLocalizations.of(context)!.adminVerificationConsoleTitle,
            style: GoogleFonts.outfit(fontWeight: FontWeight.w800, letterSpacing: -0.5, fontSize: 20, color: AppTheme.textPrimary(context)),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Builder(builder: (context) {
      final l10n = AppLocalizations.of(context)!;
      final filters = {
        'pending': l10n.filterPending,
        'approved': l10n.filterApproved,
        'rejected': l10n.filterRejected,
        'expiring_soon': l10n.filterExpiringSoon,
        'expired': l10n.filterExpired,
      };
      return Container(
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: filters.entries.map((entry) {
            final filter = entry.key;
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
                    entry.value,
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

  Widget _buildApplicationCard(GuideApplication application) {
    final statusColor = _statusColor(application.status);
    return Builder(builder: (context) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border(left: BorderSide(color: statusColor, width: 4)),
          boxShadow: [
            BoxShadow(color: AppTheme.colors.black.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, 6)),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AdminGuideVerificationDetailScreen(application: application)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.licenseNumberDisplayLabel(application.licenseNumber),
                  style: GoogleFonts.outfit(color: AppTheme.textPrimary(context), fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 6),
                Text(
                  application.category,
                  style: GoogleFonts.inter(color: AppTheme.textSecondary(context), fontSize: 12),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.access_time_rounded, color: AppTheme.textSecondary(context), size: 14),
                    const SizedBox(width: 4),
                    Text(
                      AppLocalizations.of(context)!.appliedOnLabel(_formatDate(application.appliedAt)),
                      style: GoogleFonts.inter(color: AppTheme.textSecondary(context), fontSize: 11),
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

  Color _statusColor(GuideStatus status) {
    switch (status) {
      case GuideStatus.approved:
        return AppTheme.colors.greenAccent;
      case GuideStatus.rejected:
      case GuideStatus.suspended:
        return AppTheme.colors.redAccent;
      case GuideStatus.pending:
      case GuideStatus.none:
        return AppTheme.colors.amber;
    }
  }

  String _formatDate(DateTime date) => "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

  Widget _buildEmptyState() {
    return Builder(builder: (context) {
      final l10n = AppLocalizations.of(context)!;
      final filterLabels = {
        'pending': l10n.filterPending,
        'approved': l10n.filterApproved,
        'rejected': l10n.filterRejected,
        'expiring_soon': l10n.filterExpiringSoon,
        'expired': l10n.filterExpired,
      };
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline_rounded, size: 56, color: AppTheme.textSecondary(context).withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text(
              l10n.noApplicationsFoundMessage(filterLabels[_selectedFilter] ?? _selectedFilter),
              style: GoogleFonts.outfit(color: AppTheme.textPrimary(context), fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ],
        ),
      ).animate().fadeIn();
    });
  }
}
