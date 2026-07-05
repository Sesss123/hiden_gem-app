import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/oracle_ui_system.dart';
import '../../data/models/booking_request.dart';
import '../../data/repositories/booking_repository.dart';
import '../../core/utils/secure_logger.dart';

class GuideEarningsScreen extends ConsumerStatefulWidget {
  const GuideEarningsScreen({super.key});

  @override
  ConsumerState<GuideEarningsScreen> createState() => _GuideEarningsScreenState();
}

class _GuideEarningsScreenState extends ConsumerState<GuideEarningsScreen> {
  String _selectedFilter = 'all'; // all, pending, paid, disputed

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(title: const Text("Earnings & Payouts")),
        body: const Center(child: Text("Please log in to view earnings.", style: TextStyle(color: Colors.white))),
      );
    }

    final bookingRepo = ref.watch(bookingRepositoryProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'EARNINGS & PAYOUTS',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 16),
        ),
        centerTitle: true,
      ),
      body: OracleUI.auraBackground(
        child: SafeArea(
          child: StreamBuilder<List<BookingRequest>>(
            stream: bookingRepo.getInbox(uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Colors.amber));
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text("Error loading financial data: ${snapshot.error}", style: const TextStyle(color: Colors.redAccent)),
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
                  _buildSummarySection(totalNet, pendingPayout, completedPayout, totalCommission),
                  const SizedBox(height: 16),
                  _buildActionButtons(context, pendingPayout),
                  const SizedBox(height: 16),
                  _buildFilterChips(),
                  const SizedBox(height: 8),
                  Expanded(
                    child: filteredList.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
                            physics: const BouncingScrollPhysics(),
                            itemCount: filteredList.length,
                            itemBuilder: (context, index) {
                              return _buildTransactionCard(context, filteredList[index]);
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

  Widget _buildSummarySection(double totalNet, double pendingPayout, double completedPayout, double totalCommission) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppPalette.rust.withValues(alpha: 0.25),
                  const Color(0xFF1B263B).withValues(alpha: 0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppPalette.rust.withValues(alpha: 0.4), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: AppPalette.rust.withValues(alpha: 0.15),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("TOTAL NET EARNINGS", style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70, letterSpacing: 1.2)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                      child: Text("90% ORACLE NET", style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.amber)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  "LKR ${totalNet.toStringAsFixed(0)}",
                  style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 16),
                const Divider(color: Colors.white12, height: 1),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildSubStat("⏳ PENDING PAYOUT", "LKR ${pendingPayout.toStringAsFixed(0)}", Colors.amberAccent),
                    ),
                    Container(width: 1, height: 36, color: Colors.white12),
                    Expanded(
                      child: _buildSubStat("✅ PAID OUT", "LKR ${completedPayout.toStringAsFixed(0)}", Colors.greenAccent),
                    ),
                    Container(width: 1, height: 36, color: Colors.white12),
                    Expanded(
                      child: _buildSubStat("🏛️ ORACLE FEE", "LKR ${totalCommission.toStringAsFixed(0)}", Colors.white60),
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

  Widget _buildSubStat(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(label, style: GoogleFonts.outfit(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white54)),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: valueColor)),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, double pendingPayout) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: () => _showWithdrawDialog(context, pendingPayout),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppPalette.rust,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 4,
              ),
              icon: const Icon(Icons.account_balance_wallet_rounded, size: 18),
              label: Text("REQUEST PAYOUT", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 1,
            child: OutlinedButton.icon(
              onPressed: () => _showPayoutSettingsDialog(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.textPrimary(context),
                side: BorderSide(color: AppTheme.borderColor(context)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.settings_outlined, size: 18),
              label: Text("BANK", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _filterChip('all', 'All Bookings'),
          const SizedBox(width: 8),
          _filterChip('pending', '⏳ Pending Payout'),
          const SizedBox(width: 8),
          _filterChip('paid', '✅ Paid Out'),
          const SizedBox(width: 8),
          _filterChip('disputed', '⚠️ Disputed'),
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

  Widget _buildTransactionCard(BuildContext context, BookingRequest req) {
    final gross = req.quotedPrice ?? 0.0;
    final net = req.guideNetAmount ?? (gross * 0.90);
    final status = req.payoutStatus.isEmpty ? 'pending' : req.payoutStatus;

    Color statusColor;
    String statusLabel;
    if (status == 'paid') {
      statusColor = Colors.green;
      statusLabel = "✅ PAID";
    } else if (status == 'disputed') {
      statusColor = Colors.redAccent;
      statusLabel = "⚠️ DISPUTED";
    } else {
      statusColor = Colors.orange;
      statusLabel = "⏳ PENDING";
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor(context)),
        boxShadow: AppTheme.softShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppPalette.rust.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.monetization_on_outlined, color: AppPalette.rust, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Tour Booking #${req.bookingId.substring(0, 6).toUpperCase()}",
                  style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary(context)),
                ),
                const SizedBox(height: 4),
                Text(
                  "${req.guestCount} Guests • ${req.requestedDate.toString().split(' ')[0]}",
                  style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary(context)),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(statusLabel, style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor)),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Tour: ${req.status.toUpperCase()}",
                      style: GoogleFonts.outfit(fontSize: 10, color: AppTheme.textSecondary(context)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "LKR ${net.toStringAsFixed(0)}",
                style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green[700]),
              ),
              const SizedBox(height: 2),
              Text(
                "Gross: LKR ${gross.toStringAsFixed(0)}",
                style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary(context).withValues(alpha: 0.6), decoration: TextDecoration.lineThrough),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.account_balance_wallet_outlined, size: 56, color: AppTheme.textSecondary(context).withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text(
            "No Transactions Found",
            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary(context)),
          ),
          const SizedBox(height: 8),
          Text(
            "When you complete tour bookings, your net payouts\nwill appear here automatically.",
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary(context)),
          ),
        ],
      ),
    );
  }

  void _showWithdrawDialog(BuildContext context, double pendingPayout) {
    if (pendingPayout <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No pending funds available for payout withdrawal.")),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Request Payout", style: GoogleFonts.outfit(color: AppTheme.textPrimary(context), fontWeight: FontWeight.bold)),
        content: Text(
          "You are requesting a transfer of LKR ${pendingPayout.toStringAsFixed(0)} to your registered Bank Account / Mobile Money wallet.\n\nTransfers are processed by the Oracle finance team within 24 business hours.",
          style: GoogleFonts.inter(color: AppTheme.textSecondary(context), fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("CANCEL", style: GoogleFonts.outfit(color: AppTheme.textSecondary(context))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              SecureLogger.info("Guide requested payout: LKR $pendingPayout", tag: "Finance");
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("✅ Payout request submitted successfully!"),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppPalette.rust),
            child: Text("CONFIRM PAYOUT", style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showPayoutSettingsDialog(BuildContext context) {
    final bankController = TextEditingController(text: "Bank of Ceylon (BOC)");
    final accController = TextEditingController(text: "1002345678");

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Payout Account Settings", style: GoogleFonts.outfit(color: AppTheme.textPrimary(context), fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: bankController,
              style: TextStyle(color: AppTheme.textPrimary(context)),
              decoration: InputDecoration(labelText: "Bank Name / Wallet Provider", labelStyle: TextStyle(color: AppTheme.textSecondary(context))),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: accController,
              style: TextStyle(color: AppTheme.textPrimary(context)),
              decoration: InputDecoration(labelText: "Account / Phone Number", labelStyle: TextStyle(color: AppTheme.textSecondary(context))),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("CANCEL", style: GoogleFonts.outfit(color: AppTheme.textSecondary(context))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("✅ Payout account settings updated!")),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppPalette.rust),
            child: Text("SAVE", style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
