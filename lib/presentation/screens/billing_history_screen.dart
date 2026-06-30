import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../core/theme/oracle_ui_system.dart';
import '../../data/services/subscription_service.dart';
import '../../data/models/subscription_record.dart';

class BillingHistoryScreen extends ConsumerWidget {
  const BillingHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Scaffold(body: Center(child: Text("Access Denied")));

    final billingStream = ref.watch(subscriptionServiceProvider).getBillingHistory(user.uid);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: OracleUI.auraBackground(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              floating: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              title: OracleUI.neonText(
                "BILLING HISTORY",
                style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 4, color: Colors.white),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(24),
              sliver: StreamBuilder<List<SubscriptionRecord>>(
                stream: billingStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: Colors.cyanAccent)));
                  }

                  if (snapshot.hasError) {
                    return SliverFillRemaining(child: Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.redAccent))));
                  }

                  final records = snapshot.data ?? [];
                  if (records.isEmpty) {
                    return SliverFillRemaining(
                      child: Center(
                        child: Text("No billing history found.", style: GoogleFonts.inter(color: Colors.white54, fontSize: 14)),
                      ),
                    );
                  }

                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final record = records[index];
                        return _buildBillingCard(record);
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

  Widget _buildBillingCard(SubscriptionRecord record) {
    final isCancelled = record.status == 'cancelled';
    final isExpired = record.status == 'expired';
    final isActive = record.status == 'active';
    
    Color statusColor = Colors.white54;
    if (isActive) statusColor = const Color(0xFF00E676);
    if (isCancelled) statusColor = Colors.orangeAccent;
    if (isExpired) statusColor = Colors.redAccent;

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
                  "PLAN: ${record.planId.toUpperCase()}",
                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    record.status.toUpperCase(),
                    style: GoogleFonts.inter(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(color: Colors.white12, height: 1),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildDateItem("STARTED", startedDate),
                _buildDateItem("EXPIRES", expiresDate),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              "ID: ${record.subscriptionId}",
              style: GoogleFonts.inter(color: Colors.white24, fontSize: 9, letterSpacing: 1),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateItem(String label, String date) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
        const SizedBox(height: 2),
        Text(date, style: GoogleFonts.inter(color: Colors.white, fontSize: 12)),
      ],
    );
  }
}
