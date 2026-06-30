import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/oracle_ui_system.dart';
import '../../data/models/tour_review.dart';
import '../../data/models/guide_analytics_snapshot.dart';
import '../../data/repositories/review_repository.dart';
import '../../data/repositories/analytics_repository.dart';
import '../../data/services/subscription_service.dart';
import 'review_submission_screen.dart';
import 'subscription_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GuideReviewsScreen extends ConsumerStatefulWidget {
  final String guideId;
  const GuideReviewsScreen({super.key, required this.guideId});

  @override
  ConsumerState<GuideReviewsScreen> createState() => _GuideReviewsScreenState();
}

class _GuideReviewsScreenState extends ConsumerState<GuideReviewsScreen> {
  @override
  Widget build(BuildContext context) {
    final reviewRepo = ref.watch(reviewRepositoryProvider);
    final analyticsRepo = ref.watch(analyticsRepositoryProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final userId = FirebaseAuth.instance.currentUser?.uid ?? 'guest_user';
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ReviewSubmissionScreen(
                guideId: widget.guideId,
                sessionId: 'direct_review_${DateTime.now().millisecondsSinceEpoch}',
                touristId: userId,
              ),
            ),
          );
        },
        backgroundColor: Colors.amberAccent,
        icon: const Icon(Icons.edit_note, color: Colors.black87),
        label: Text("WRITE REVIEW", style: GoogleFonts.outfit(color: Colors.black87, fontWeight: FontWeight.bold)),
      ),
      body: OracleUI.auraBackground(
        child: CustomScrollView(
          slivers: [
            _buildAppBar(),
            SliverToBoxAdapter(
              child: FutureBuilder<bool>(
                future: _canViewAnalytics(),
                builder: (context, entSnapshot) {
                  if (entSnapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
                  }
                  
                  final hasAccess = entSnapshot.data ?? false;
                  
                  if (!hasAccess) {
                    return _buildLockedPremiumFeature();
                  }

                  return FutureBuilder<GuideAnalyticsSnapshot?>(
                    future: analyticsRepo.getLatestSnapshot(widget.guideId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
                      }
                      final data = snapshot.data;
                      if (data == null) return const SizedBox.shrink();
                      return _buildTrustHeader(data);
                    },
                  );
                },
              ),
            ),
            FutureBuilder<ReviewPage>(
              future: reviewRepo.getGuideReviews(widget.guideId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SliverFillRemaining(child: Center(child: CircularProgressIndicator()));
                }
                final reviews = snapshot.data?.reviews ?? [];
                if (reviews.isEmpty) {
                  return SliverFillRemaining(child: _buildEmptyState());
                }

                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => OracleUI.staggeredEntrance(
                        index: index,
                        child: _buildReviewCard(reviews[index]),
                      ),
                      childCount: reviews.length,
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
      expandedHeight: 100.0,
      backgroundColor: Colors.transparent,
      elevation: 0,
      pinned: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
        title: OracleUI.neonText(
          "REPUTATION LOG",
          style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 2, color: Colors.white),
        ),
      ),
    );
  }

  Future<bool> _canViewAnalytics() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return false;
    
    // If the guide is viewing their own dashboard, enforce the entitlement.
    if (userId == widget.guideId) {
      return await ref.read(subscriptionServiceProvider).hasEntitlement(userId, 'analyticsAccess');
    }
    
    // Public profile visitors (Tourists, Operators) can see public stats.
    return true;
  }

  Widget _buildLockedPremiumFeature() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: OracleUI.glassContainer(
        padding: const EdgeInsets.all(32),
        borderRadius: BorderRadius.circular(32),
        borderColor: Colors.amber.withValues(alpha: 0.3),
        child: Column(
          children: [
            const Icon(Icons.lock_person_rounded, size: 48, color: Colors.amber),
            const SizedBox(height: 16),
            Text(
              "PREMIUM ANALYTICS LOCKED",
              style: GoogleFonts.outfit(color: Colors.amber, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 2),
            ),
            const SizedBox(height: 8),
            Text(
              "Upgrade to PRO or ELITE to unlock deep insights into your performance, trust score, and tourist feedback.",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // Navigate to subscription screen
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionScreen()));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: Text("UPGRADE NOW", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrustHeader(GuideAnalyticsSnapshot snapshot) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: OracleUI.glassContainer(
        padding: const EdgeInsets.all(24),
        borderRadius: BorderRadius.circular(32),
        showGlow: true,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "TRUST SCORE",
                      style: GoogleFonts.inter(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "${snapshot.trustScore.toInt()}%",
                      style: GoogleFonts.outfit(fontSize: 48, fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.primary),
                    ),
                  ],
                ),
                _buildTierBadge(snapshot.trustScore / 100.0),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMiniStat(snapshot.completedTours.toString(), "TRIPS"),
                _buildMiniStat("${snapshot.ratingAverage.toStringAsFixed(1)} ★", "RATING"),
                _buildMiniStat(snapshot.totalSafetyIncidents.toString(), "INCIDENTS"),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTierBadge(double score) {
    String tier = "BRONZE";
    Color color = Colors.brown;
    if (score >= 0.9) { tier = "DIAMOND"; color = Colors.cyanAccent; }
    else if (score >= 0.7) { tier = "GOLD"; color = Colors.amber; }
    else if (score >= 0.5) { tier = "SILVER"; color = Colors.blueGrey; }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(Icons.military_tech_rounded, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            tier,
            style: GoogleFonts.inter(color: color, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String value, String label) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: GoogleFonts.inter(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
      ],
    );
  }

  Widget _buildReviewCard(TourReview review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: OracleUI.glassContainer(
        padding: const EdgeInsets.all(20),
        borderRadius: BorderRadius.circular(24),
        borderColor: Colors.white.withValues(alpha: 0.05),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ...List.generate(5, (index) => Icon(
                  Icons.star_rounded, 
                  size: 14, 
                  color: index < review.overallRating ? Colors.amber : Colors.white12,
                )),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.greenAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified_rounded, color: Colors.greenAccent, size: 10),
                      const SizedBox(width: 4),
                      Text(
                        "VERIFIED MISSION",
                        style: GoogleFonts.inter(color: Colors.greenAccent, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              review.comment,
              style: GoogleFonts.inter(color: Colors.white70, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  width: 24, height: 24,
                  decoration: BoxDecoration(color: Colors.white10, shape: BoxShape.circle),
                  child: const Icon(Icons.person_rounded, color: Colors.white30, size: 14),
                ),
                const SizedBox(width: 8),
                Text(
                  "Tourist ${review.touristId.substring(0, 4)}", // Simplified
                  style: GoogleFonts.inter(color: Colors.white30, fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(
                  "${review.createdAt.day}/${review.createdAt.month}/${review.createdAt.year}",
                  style: GoogleFonts.inter(color: Colors.white12, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.rate_review_outlined, size: 64, color: Colors.white.withValues(alpha: 0.05)),
          const SizedBox(height: 16),
          Text(
            "NO MISSION LOGS",
            style: GoogleFonts.outfit(color: Colors.white12, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 2),
          ),
          const SizedBox(height: 8),
          Text(
            "Verified participants can leave feedback after session completion.",
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: Colors.white10, fontSize: 12),
          ),
        ],
      ),
    ).animate().fadeIn();
  }
}
