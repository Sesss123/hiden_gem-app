import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/oracle_ui_system.dart';
import '../../data/services/subscription_service.dart';
import '../../data/models/subscription_record.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Scaffold(body: Center(child: Text("Access Denied")));

    final activeSubFuture = ref.watch(subscriptionServiceProvider).getActiveSubscription(user.uid);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: OracleUI.auraBackground(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildAppBar(),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCurrentStatusSection(activeSubFuture),
                    const SizedBox(height: 48),
                    OracleUI.neonText(
                      "SERVICE TIERS",
                      style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 4, color: Colors.white),
                    ),
                    const SizedBox(height: 24),
                    _buildPlanCard(
                      title: "FREE TIER",
                      price: "0",
                      description: "Essential tour tools for verified guides.",
                      features: ["Basic Operations", "Verified Badge", "Standard SOS"],
                      isPopular: false,
                    ),
                    _buildPlanCard(
                      title: "PRO COMMANDER",
                      price: "29",
                      description: "Elevate your visibility and tools.",
                      features: ["Featured Listings", "Advanced Analytics", "Client Analytics", "Priority SOS"],
                      isPopular: true,
                      color: const Color(0xFF00E676),
                    ),
                    _buildPlanCard(
                      title: "ELITE AGENCY",
                      price: "89",
                      description: "Full fleet and company management.",
                      features: ["Team Management", "Operator Dashboard", "White-label Branding", "Family Share Pro"],
                      isPopular: false,
                      color: Colors.amberAccent,
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      floating: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: OracleUI.neonText(
        "FLEET COMMAND",
        style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 4, color: Colors.white),
      ),
    );
  }

  Widget _buildCurrentStatusSection(Future<SubscriptionRecord?> future) {
    return FutureBuilder<SubscriptionRecord?>(
      future: future,
      builder: (context, snapshot) {
        final sub = snapshot.data;
        return OracleUI.glassContainer(
          padding: const EdgeInsets.all(24),
          borderRadius: BorderRadius.circular(24),
          child: Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF00E676).withValues(alpha: 0.1)),
                child: const Icon(Icons.verified_user_rounded, color: Color(0xFF00E676)),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("CURRENT PLAN", style: GoogleFonts.inter(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                    Text(
                      sub?.planId.toUpperCase() ?? "FREE TIER",
                      style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                    ),
                    if (sub != null)
                      Text("Expires: ${sub.expiresAt.day}/${sub.expiresAt.month}/${sub.expiresAt.year}", style: GoogleFonts.inter(color: Colors.white24, fontSize: 12)),
                  ],
                ),
              ),
              if (sub == null)
                TextButton(onPressed: () {}, child: Text("UPGRADE", style: GoogleFonts.inter(color: const Color(0xFF00E676), fontWeight: FontWeight.bold))),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPlanCard({
    required String title,
    required String price,
    required String description,
    required List<String> features,
    bool isPopular = false,
    Color color = Colors.white38,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: OracleUI.premiumGlassCard(
        padding: const EdgeInsets.all(32),
        showGlow: isPopular,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isPopular)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(color: const Color(0xFF00E676), borderRadius: BorderRadius.circular(6)),
                child: Text("MOST POPULAR", style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.black)),
              ),
            Text(title, style: GoogleFonts.outfit(color: color, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 2)),
            const SizedBox(height: 8),
            Row(
              textBaseline: TextBaseline.alphabetic,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              children: [
                Text("\$$price", style: GoogleFonts.outfit(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w900)),
                const SizedBox(width: 4),
                Text("/MONTH", style: GoogleFonts.inter(color: Colors.white24, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            Text(description, style: GoogleFonts.inter(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 32),
            ...features.map((f) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.white12, size: 16),
                  const SizedBox(width: 12),
                  Text(f, style: GoogleFonts.inter(color: Colors.white54, fontSize: 13)),
                ],
              ),
            )),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: isPopular ? const Color(0xFF00E676) : Colors.white.withValues(alpha: 0.05),
                  foregroundColor: isPopular ? Colors.black : Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  side: isPopular ? null : BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: Text("SELECT MISSION TIER", style: GoogleFonts.outfit(fontWeight: FontWeight.w900, letterSpacing: 1.5)),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.1);
  }
}
