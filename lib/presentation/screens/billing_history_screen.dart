import 'package:hidden_gems_sl/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../core/theme/oracle_ui_system.dart';
import '../../data/services/subscription_service.dart';
import '../../data/models/subscription_record.dart';
import '../../l10n/app_localizations.dart';

class BillingHistoryScreen extends ConsumerWidget {
  const BillingHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Scaffold(body: Center(child: Text(AppLocalizations.of(context)!.accessDeniedMessage)));

    final billingFuture = ref.watch(subscriptionServiceProvider).getBillingHistory(user.uid);

    return Scaffold(
      backgroundColor: AppTheme.colors.transparent,
      body: OracleUI.auraBackground(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              floating: true,
              backgroundColor: AppTheme.colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: Icon(Icons.arrow_back_rounded, color: AppTheme.colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              title: OracleUI.neonText(
                AppLocalizations.of(context)!.billingHistoryTitle,
                style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 4, color: AppTheme.colors.white),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(24),
              sliver: FutureBuilder<List<SubscriptionRecord>>(
                future: billingFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: AppTheme.colors.cyanAccent)));
                  }

                  if (snapshot.hasError) {
                    return SliverFillRemaining(child: Center(child: Text(AppLocalizations.of(context)!.errorGenericColonMessage(snapshot.error.toString()), style: TextStyle(color: AppTheme.colors.redAccent))));
                  }

                  final records = snapshot.data ?? [];
                  if (records.isEmpty) {
                    return SliverFillRemaining(
                      child: Center(
                        child: Text(AppLocalizations.of(context)!.noBillingHistoryFoundMessage, style: GoogleFonts.inter(color: AppTheme.colors.white54, fontSize: 14)),
                      ),
                    );
                  }

                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final record = records[index];
                        return _buildBillingCard(context, record);
                      },
                      childCount: records.length,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBillingCard(BuildContext context, SubscriptionRecord record) {
    final l10n = AppLocalizations.of(context)!;
    final isCancelled = record.status == 'cancelled';
    final isExpired = record.status == 'expired';
    final isActive = record.status == 'active';

    Color statusColor = AppTheme.colors.white54;
    if (isActive) statusColor = AppTheme.colors.primary;
    if (isCancelled) statusColor = AppTheme.colors.orangeAccent;
    if (isExpired) statusColor = AppTheme.colors.redAccent;

    final startedDate = DateFormat('MMM dd, yyyy').format(record.startedAt);
    final expiresDate = DateFormat('MMM dd, yyyy').format(record.expiresAt);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: OracleUI.glassContainer(
        padding: const EdgeInsets.all(20),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.planLabel(record.planId.toUpperCase()),
                  style: GoogleFonts.outfit(color: AppTheme.colors.white, fontSize: 16, fontWeight: FontWeight.w900),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    _statusLabel(record.status, l10n),
                    style: GoogleFonts.inter(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(color: AppTheme.colors.white12, height: 1),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildDateItem(l10n.startedLabel, startedDate),
                _buildDateItem(l10n.expiresLabel, expiresDate),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              l10n.idLabel(record.subscriptionId),
              style: GoogleFonts.inter(color: AppTheme.colors.white24, fontSize: 9, letterSpacing: 1),
            ),
          ],
        ),
      ),
    );
  }

  String _statusLabel(String status, AppLocalizations l10n) {
    switch (status) {
      case 'cancelled':
        return l10n.subscriptionStatusCancelled;
      case 'expired':
        return l10n.subscriptionStatusExpired;
      case 'active':
        return l10n.subscriptionStatusActive;
      default:
        return status.toUpperCase();
    }
  }

  Widget _buildDateItem(String label, String date) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(color: AppTheme.colors.white54, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
        const SizedBox(height: 2),
        Text(date, style: GoogleFonts.inter(color: AppTheme.colors.white, fontSize: 12)),
      ],
    );
  }
}
