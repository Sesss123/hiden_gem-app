import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/oracle_ui_system.dart';
import '../../data/models/booking_request.dart';
import '../../data/repositories/booking_repository.dart';
import '../../data/services/subscription_service.dart';
import 'subscription_screen.dart';
import '../../core/utils/secure_logger.dart';
import '../../l10n/app_localizations.dart';

class GuideEarningsScreen extends ConsumerStatefulWidget {
  const GuideEarningsScreen({super.key});

  @override
  ConsumerState<GuideEarningsScreen> createState() => _GuideEarningsScreenState();
}

class _GuideEarningsScreenState extends ConsumerState<GuideEarningsScreen> {
  String _selectedFilter = 'all'; // all, pending, paid, disputed

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(title: Text(l10n.earningsTitle)),
        body: Center(child: Text(l10n.pleaseLogInViewEarningsMessage, style: TextStyle(color: AppTheme.textPrimary(context)))),
      );
    }

    final bookingRepo = ref.watch(bookingRepositoryProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.colors.transparent,
        elevation: 0,
        title: Text(
          l10n.earningsTitle,
          style: GoogleFonts.outfit(fontWeight: FontWeight.w800, letterSpacing: -0.5, fontSize: 20, color: AppTheme.textPrimary(context)),
        ),
        centerTitle: false,
      ),
      body: OracleUI.auraBackground(
        child: SafeArea(
          child: StreamBuilder<List<BookingRequest>>(
            stream: bookingRepo.getInbox(uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator(color: AppTheme.colors.amber));
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text(l10n.errorLoadingFinancialDataMessage(snapshot.error.toString()), style: TextStyle(color: AppTheme.colors.redAccent)),
                );
              }

              final allRequests = snapshot.data ?? [];
              // Only count accepted, session_ready, completed tours for financial calculations
              final validRequests = allRequests.where((r) => 
                r.status == 'accepted' || r.status == 'session_ready' || r.status == 'completed'
              ).toList();

              double totalNet = 0;
              double pendingPayout = 0;
              double completedPayout = 0;
              double totalCommission = 0;

              for (var req in validRequests) {
                final gross = req.quotedPrice ?? 0.0;
                final net = req.guideNetAmount ?? (gross * 0.90);
                final comm = req.commissionAmount ?? (gross * 0.10);

                totalNet += net;
                totalCommission += comm;

                if (req.payoutStatus == 'paid') {
                  completedPayout += net;
                } else if (req.payoutStatus == 'pending' || req.payoutStatus.isEmpty) {
                  pendingPayout += net;
                }
              }

              final filteredList = validRequests.where((req) {
                if (_selectedFilter == 'all') return true;
                final status = req.payoutStatus.isEmpty ? 'pending' : req.payoutStatus;
                return status == _selectedFilter;
              }).toList();

              return Column(
                children: [
                  _buildSummarySection(l10n, totalNet, pendingPayout, completedPayout, totalCommission),
                  const SizedBox(height: 16),
                  _buildActionButtons(context, l10n, pendingPayout),
                  const SizedBox(height: 16),
                  _buildAnalyticsSection(uid, validRequests),
                  const SizedBox(height: 16),
                  _buildFilterChips(l10n),
                  const SizedBox(height: 8),
                  Expanded(
                    child: filteredList.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
                            physics: const BouncingScrollPhysics(),
                            itemCount: filteredList.length,
                            itemBuilder: (context, index) {
                              return _buildTransactionCard(context, l10n, filteredList[index]);
                            },
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSummarySection(AppLocalizations l10n, double totalNet, double pendingPayout, double completedPayout, double totalCommission) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.colors.black : AppPalette.ink,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(l10n.totalNetEarningsLabel, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.colors.white.withValues(alpha: 0.65))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: AppPaletteDark.gold.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(100)),
                      child: Text(l10n.netPercentageLabel, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppPaletteDark.gold)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  l10n.lkrAmountLabel(totalNet.toStringAsFixed(0)),
                  style: GoogleFonts.outfit(fontSize: 30, fontWeight: FontWeight.w800, color: AppTheme.colors.white),
                ),
                const SizedBox(height: 18),
                Divider(color: AppTheme.colors.white.withValues(alpha: 0.1), height: 1),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _buildSubStat(l10n.subStatPending, l10n.lkrAmountLabel(pendingPayout.toStringAsFixed(0))),
                    ),
                    Expanded(
                      child: _buildSubStat(l10n.subStatPaidOut, l10n.lkrAmountLabel(completedPayout.toStringAsFixed(0))),
                    ),
                    Expanded(
                      child: _buildSubStat(l10n.subStatPlatformFee, l10n.lkrAmountLabel(totalCommission.toStringAsFixed(0))),
                    ),
                  ],
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0),
        ],
      ),
    );
  }

  Widget _buildSubStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w500, color: AppTheme.colors.white.withValues(alpha: 0.5))),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.colors.white)),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, AppLocalizations l10n, double pendingPayout) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: () => _showWithdrawDialog(context, pendingPayout),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: AppTheme.colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                elevation: 0,
              ),
              icon: const Icon(Icons.account_balance_wallet_rounded, size: 18),
              label: Text(l10n.requestPayoutButton, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 1,
            child: ElevatedButton.icon(
              onPressed: () => _showPayoutSettingsDialog(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.surfaceMuted(context),
                foregroundColor: AppTheme.textPrimary(context),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                elevation: 0,
              ),
              icon: const Icon(Icons.settings_outlined, size: 18),
              label: Text(l10n.bankButtonLabel, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsSection(String uid, List<BookingRequest> validRequests) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: FutureBuilder<bool>(
        future: SubscriptionService().hasEntitlement(uid, 'advancedAnalytics'),
        builder: (context, snapshot) {
          final unlocked = snapshot.data ?? false;
          if (!snapshot.hasData) return const SizedBox.shrink();
          return unlocked
              ? _buildAnalyticsCard(validRequests)
              : _buildAnalyticsLockedCard(context);
        },
      ),
    );
  }

  Widget _buildAnalyticsCard(List<BookingRequest> validRequests) {
    final completed = validRequests.where((r) => r.status == 'completed').length;
    final clientIds = validRequests.map((r) => r.touristId).toList();
    final uniqueClients = clientIds.toSet().length;
    final repeatClients = clientIds.length - uniqueClients;
    final repeatRate = uniqueClients == 0 ? 0.0 : (repeatClients / uniqueClients) * 100;
    final avgBookingValue = validRequests.isEmpty
        ? 0.0
        : validRequests.map((r) => r.quotedPrice ?? 0.0).reduce((a, b) => a + b) / validRequests.length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: AppTheme.colors.black.withValues(alpha: 0.05), blurRadius: 14, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.insights_rounded, size: 16, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text(AppLocalizations.of(context)!.clientAnalyticsTitle, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary(context))),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildAnalyticsStat(AppLocalizations.of(context)!.analyticsStatCompletedTours, "$completed")),
              Expanded(child: _buildAnalyticsStat(AppLocalizations.of(context)!.analyticsStatUniqueClients, "$uniqueClients")),
              Expanded(child: _buildAnalyticsStat(AppLocalizations.of(context)!.analyticsStatRepeatRate, "${repeatRate.toStringAsFixed(0)}%")),
            ],
          ),
          const SizedBox(height: 4),
          Text(AppLocalizations.of(context)!.avgBookingValueLabel, style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary(context))),
          Text(AppLocalizations.of(context)!.lkrAmountLabel(avgBookingValue.toStringAsFixed(0)), style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary(context))),
        ],
      ),
    );
  }

  Widget _buildAnalyticsStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary(context))),
        Text(label, style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textSecondary(context))),
      ],
    );
  }

  Widget _buildAnalyticsLockedCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceMuted(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderColor(context)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.lock_outline_rounded, color: Theme.of(context).colorScheme.primary, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppLocalizations.of(context)!.clientAnalyticsTitle, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textPrimary(context))),
                Text(AppLocalizations.of(context)!.clientAnalyticsLockedSubtitle, style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary(context))),
              ],
            ),
          ),
          TextButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionScreen())),
            child: Text(AppLocalizations.of(context)!.upgradeButtonLabel, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12, color: Theme.of(context).colorScheme.primary)),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(AppLocalizations l10n) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _filterChip('all', l10n.filterChipAllBookings),
          const SizedBox(width: 8),
          _filterChip('pending', l10n.filterChipPendingPayout),
          const SizedBox(width: 8),
          _filterChip('paid', l10n.filterChipPaidOut),
          const SizedBox(width: 8),
          _filterChip('disputed', l10n.filterChipDisputed),
        ],
      ),
    );
  }

  Widget _filterChip(String filterKey, String label) {
    final isSelected = _selectedFilter == filterKey;
    return OracleUI.glassChip(
      context: context,
      label: label,
      isSelected: isSelected,
      onTap: () => setState(() => _selectedFilter = filterKey),
    );
  }

  Widget _buildTransactionCard(BuildContext context, AppLocalizations l10n, BookingRequest req) {
    final gross = req.quotedPrice ?? 0.0;
    final net = req.guideNetAmount ?? (gross * 0.90);
    final status = req.payoutStatus.isEmpty ? 'pending' : req.payoutStatus;

    Color statusColor;
    String statusLabel;
    if (status == 'paid') {
      statusColor = AppTheme.colors.green;
      statusLabel = l10n.payoutStatusPaid;
    } else if (status == 'disputed') {
      statusColor = AppTheme.colors.redAccent;
      statusLabel = l10n.payoutStatusDisputed;
    } else {
      statusColor = AppTheme.colors.orange;
      statusLabel = l10n.payoutStatusPending;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: AppTheme.colors.black.withValues(alpha: 0.05), blurRadius: 14, offset: const Offset(0, 5)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.monetization_on_outlined, color: Theme.of(context).colorScheme.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.tourBookingIdLabel(req.bookingId.substring(0, 6).toUpperCase()),
                  style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: -0.2, color: AppTheme.textPrimary(context)),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.guestCountDateLabel(req.guestCount, req.requestedDate.toString().split(' ')[0]),
                  style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary(context)),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(statusLabel, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: statusColor)),
                    ),
                    if (req.paidAt != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        l10n.viaPayHereDateLabel(req.paidAt!.toString().split(' ')[0]),
                        style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textSecondary(context).withValues(alpha: 0.6)),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                l10n.lkrAmountLabel(net.toStringAsFixed(0)),
                style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.colors.green[700]),
              ),
              const SizedBox(height: 2),
              Text(
                l10n.grossLkrLabel(gross.toStringAsFixed(0)),
                style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary(context).withValues(alpha: 0.6), decoration: TextDecoration.lineThrough),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildEmptyState() {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.account_balance_wallet_outlined, size: 56, color: AppTheme.textSecondary(context).withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text(
            l10n.noTransactionsFoundTitle,
            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.3, color: AppTheme.textPrimary(context)),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.noTransactionsFoundSubtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary(context)),
          ),
        ],
      ),
    );
  }

  void _showWithdrawDialog(BuildContext context, double pendingPayout) {
    final l10n = AppLocalizations.of(context)!;
    if (pendingPayout <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.noPendingFundsMessage)),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l10n.requestPayoutDialogTitle, style: GoogleFonts.outfit(color: AppTheme.textPrimary(context), fontWeight: FontWeight.bold)),
        content: Text(
          l10n.requestPayoutDialogMessage(pendingPayout.toStringAsFixed(0)),
          style: GoogleFonts.inter(color: AppTheme.textSecondary(context), fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancelButton, style: GoogleFonts.inter(color: AppTheme.textSecondary(context), fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              SecureLogger.info("Guide requested payout: LKR $pendingPayout", tag: "Finance");
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.payoutRequestSubmittedMessage),
                  backgroundColor: AppTheme.colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
              elevation: 0,
            ),
            child: Text(l10n.confirmPayoutButton, style: GoogleFonts.inter(color: AppTheme.colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showPayoutSettingsDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bankController = TextEditingController(text: "Bank of Ceylon (BOC)");
    final accController = TextEditingController(text: "1002345678");

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l10n.payoutAccountSettingsTitle, style: GoogleFonts.outfit(color: AppTheme.textPrimary(context), fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: bankController,
              style: TextStyle(color: AppTheme.textPrimary(context)),
              decoration: InputDecoration(labelText: l10n.bankNameWalletProviderLabel, labelStyle: TextStyle(color: AppTheme.textSecondary(context))),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: accController,
              style: TextStyle(color: AppTheme.textPrimary(context)),
              decoration: InputDecoration(labelText: l10n.accountPhoneNumberLabel, labelStyle: TextStyle(color: AppTheme.textSecondary(context))),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancelButton, style: GoogleFonts.inter(color: AppTheme.textSecondary(context), fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.payoutAccountSettingsUpdatedMessage)),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
              elevation: 0,
            ),
            child: Text(l10n.saveButtonLabel, style: GoogleFonts.inter(color: AppTheme.colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    ).whenComplete(() {
      bankController.dispose();
      accController.dispose();
    });
  }
}
