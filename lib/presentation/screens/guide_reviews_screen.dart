import 'package:hidden_gems_sl/core/theme/app_theme.dart';
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
import '../../core/utils/secure_logger.dart';
import '../../l10n/app_localizations.dart';

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
        backgroundColor: AppTheme.colors.amberAccent,
        icon: Icon(Icons.edit_note, color: AppTheme.colors.black87),
        label: Text(AppLocalizations.of(context)!.writeReviewButton, style: GoogleFonts.outfit(color: AppTheme.colors.black87, fontWeight: FontWeight.bold)),
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
                if (snapshot.hasError) {
                  SecureLogger.error("Failed to load guide reviews", snapshot.error);
                  return SliverFillRemaining(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, color: AppTheme.colors.redAccent, size: 48),
                            const SizedBox(height: 16),
                            Text(
                              AppLocalizations.of(context)!.failedToLoadReviewsMessage,
                              style: GoogleFonts.inter(color: AppTheme.colors.white70),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
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
      expandedHeight: 80.0,
      backgroundColor: AppTheme.colors.transparent,
      elevation: 0,
      pinned: true,
      leading: Builder(
        builder: (context) => IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textPrimary(context), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      flexibleSpace: Builder(
        builder: (context) => FlexibleSpaceBar(
          titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
          title: Text(
            AppLocalizations.of(context)!.reviewsTitle,
            style: GoogleFonts.outfit(fontWeight: FontWeight.w800, letterSpacing: -0.5, fontSize: 20, color: AppTheme.textPrimary(context)),
          ),
        ),
      ),
    );
  }

  Future<bool> _canViewAnalytics() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return false;
    
    // If the guide is viewing their own dashboard, enforce the entitlement.
    if (userId == widget.guideId) {
      try {
        return await ref.read(subscriptionServiceProvider).hasEntitlement(userId, 'analyticsAccess');
      } catch (e) {
        SecureLogger.warning("Entitlement verification failed: $e");
        return false;
      }
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
        borderColor: AppTheme.colors.amber.withValues(alpha: 0.3),
        child: Column(
          children: [
            Icon(Icons.lock_person_rounded, size: 48, color: AppTheme.colors.amber),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.premiumAnalyticsLockedTitle,
              style: GoogleFonts.outfit(color: AppTheme.colors.amber, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 2),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.premiumAnalyticsLockedMessage,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: AppTheme.colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // Navigate to subscription screen
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionScreen()));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.colors.amber,
                foregroundColor: AppTheme.colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: Text(AppLocalizations.of(context)!.upgradeNowButton, style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrustHeader(GuideAnalyticsSnapshot snapshot) {
    return Builder(builder: (context) {
      final primary = Theme.of(context).colorScheme.primary;
      final primaryDark = Color.lerp(primary, AppTheme.colors.black, 0.35)!;
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [primary, primaryDark],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(color: primary.withValues(alpha: 0.25), blurRadius: 20, offset: const Offset(0, 10)),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.trustScoreLabel,
                        style: GoogleFonts.inter(color: AppTheme.colors.white.withValues(alpha: 0.8), fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "${snapshot.trustScore.toInt()}%",
                        style: GoogleFonts.outfit(fontSize: 30, fontWeight: FontWeight.w800, color: AppTheme.colors.white),
                      ),
                    ],
                  ),
                  _buildTierBadge(snapshot.trustScore / 100.0),
                ],
              ),
              const SizedBox(height: 22),
              Divider(color: AppTheme.colors.white.withValues(alpha: 0.15), height: 1),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMiniStat(snapshot.completedTours.toString(), AppLocalizations.of(context)!.miniStatTrips),
                  _buildMiniStat("${snapshot.ratingAverage.toStringAsFixed(1)} ★", AppLocalizations.of(context)!.miniStatRating),
                  _buildMiniStat(snapshot.totalSafetyIncidents.toString(), AppLocalizations.of(context)!.miniStatIncidents),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildTierBadge(double score) {
    return Builder(builder: (context) {
      final l10n = AppLocalizations.of(context)!;
      String tier = l10n.tierBronze;
      if (score >= 0.9) {
        tier = l10n.tierDiamond;
      } else if (score >= 0.7) {
        tier = l10n.tierGold;
      } else if (score >= 0.5) {
        tier = l10n.tierSilver;
      }

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          tier,
          style: GoogleFonts.inter(color: AppTheme.colors.white, fontSize: 11, fontWeight: FontWeight.w700),
        ),
      );
    });
  }

  Widget _buildMiniStat(String value, String label) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.outfit(color: AppTheme.colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label, style: GoogleFonts.inter(color: AppTheme.colors.white.withValues(alpha: 0.75), fontSize: 11, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildReviewCard(TourReview review) {
    return Builder(builder: (context) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(color: AppTheme.colors.black.withValues(alpha: 0.05), blurRadius: 14, offset: const Offset(0, 5)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ...List.generate(5, (index) => Icon(
                  Icons.star_rounded,
                  size: 14,
                  color: index < review.overallRating ? AppTheme.colors.amber : AppTheme.surfaceMuted(context),
                )),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.colors.greenAccent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.verified_rounded, color: AppTheme.colors.greenAccent, size: 10),
                      const SizedBox(width: 4),
                      Text(
                        AppLocalizations.of(context)!.verifiedTripBadge,
                        style: GoogleFonts.inter(color: AppTheme.colors.greenAccent, fontSize: 10, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              review.comment,
              style: GoogleFonts.inter(color: AppTheme.textSecondary(context), fontSize: 14, height: 1.6).copyWith(
                fontFamilyFallback: [GoogleFonts.abhayaLibre().fontFamily!, GoogleFonts.hindGuntur().fontFamily!],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  width: 24, height: 24,
                  decoration: BoxDecoration(color: AppTheme.surfaceMuted(context), shape: BoxShape.circle),
                  child: Icon(Icons.person_rounded, color: AppTheme.textSecondary(context), size: 14),
                ),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context)!.touristShortIdLabel(review.touristId.substring(0, 4)),
                  style: GoogleFonts.inter(color: AppTheme.textPrimary(context), fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Text(
                  "${review.createdAt.day}/${review.createdAt.month}/${review.createdAt.year}",
                  style: GoogleFonts.inter(color: AppTheme.textSecondary(context), fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildEmptyState() {
    return Builder(builder: (context) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.rate_review_outlined, size: 56, color: AppTheme.textSecondary(context).withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.noReviewsYetTitle,
              style: GoogleFonts.outfit(color: AppTheme.textPrimary(context), fontWeight: FontWeight.w700, fontSize: 18, letterSpacing: -0.3),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.noReviewsYetSubtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: AppTheme.textSecondary(context), fontSize: 13),
            ),
          ],
        ),
      ).animate().fadeIn();
    });
  }
}
