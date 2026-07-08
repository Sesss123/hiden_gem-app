import 'package:hidden_gems_sl/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/oracle_ui_system.dart';
import '../../data/repositories/marketplace_repository.dart';
import '../../data/models/guide_listing.dart';
import 'booking_request_screen.dart';

class GuidePublicProfileScreen extends ConsumerWidget {
  final String guideId;
  const GuidePublicProfileScreen({super.key, required this.guideId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final marketplaceRepo = ref.watch(marketplaceRepositoryProvider);
    final listingFuture = marketplaceRepo.getListing(guideId);
    final packageFuture = marketplaceRepo.getGuidePackages(guideId);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: OracleUI.auraBackground(
        child: FutureBuilder<GuideListing?>(
          future: listingFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary));
            }
            final guide = snapshot.data;
            if (guide == null) {
              return Center(child: Text("Guide profile not found", style: TextStyle(color: AppTheme.textSecondary(context))));
            }
            
            // Track view on load
            marketplaceRepo.trackProfileView(guide.listingId);

            return Stack(
              children: [
                _buildScrollableContent(context, guide, packageFuture),
                _buildActionButtons(context, guide),
                _buildAppBar(context),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Positioned(
      top: 0, left: 0, right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildCircularIconButton(Icons.arrow_back_ios_new_rounded, () => Navigator.pop(context)),
              _buildCircularIconButton(Icons.share_rounded, () {}),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCircularIconButton(IconData icon, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.colors.black.withValues(alpha: 0.3),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: AppTheme.colors.white, size: 20),
        onPressed: onTap,
      ),
    );
  }

  Widget _buildScrollableContent(BuildContext context, GuideListing guide, Future<List<Map<String, dynamic>>> packageFuture) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _buildHeader(context, guide)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildIdentity(context, guide),
                const SizedBox(height: 24),
                _buildTrustCard(context, guide),
                const SizedBox(height: 32),
                _buildBio(context, guide),
                const SizedBox(height: 32),
                _buildPackageList(context, packageFuture),
                const SizedBox(height: 120),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, GuideListing guide) {
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
    return Container(
      height: 240,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppPalette.earth,
        image: guide.coverPhotos.isNotEmpty
          ? DecorationImage(image: NetworkImage(guide.coverPhotos.first), fit: BoxFit.cover, opacity: 0.75)
          : null,
      ),
      child: Stack(
        children: [
          // Fade the photo into the page background at the bottom so the
          // name/badge sit on a light surface below the hero.
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [scaffoldBg.withValues(alpha: 0), scaffoldBg],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.55, 1.0],
              ),
            ),
          ),
          Positioned(
            top: 90, left: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                guide.guideCategory,
                style: GoogleFonts.inter(color: Theme.of(context).colorScheme.primary, fontSize: 11, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdentity(BuildContext context, GuideListing guide) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          guide.displayName,
          style: GoogleFonts.outfit(color: AppTheme.textPrimary(context), fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.location_on_rounded, color: AppTheme.textSecondary(context), size: 16),
            const SizedBox(width: 6),
            Text(
              guide.regions.join(" • "),
              style: GoogleFonts.inter(color: AppTheme.textSecondary(context), fontSize: 14),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTrustCard(BuildContext context, GuideListing guide) {
    return Row(
      children: [
        Expanded(child: _buildStatTile(context, "Experience", "${guide.yearsExperience} years")),
        const SizedBox(width: 12),
        Expanded(child: _buildStatTile(context, "Rating", "★ ${guide.ratingAverage.toStringAsFixed(1)}")),
        const SizedBox(width: 12),
        Expanded(child: _buildStatTile(context, "Rank", guide.trustTierPublic)),
      ],
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1);
  }

  Widget _buildStatTile(BuildContext context, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceMuted(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.inter(color: AppTheme.textSecondary(context), fontSize: 11, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(value, style: GoogleFonts.outfit(color: AppTheme.textPrimary(context), fontSize: 15, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildBio(BuildContext context, GuideListing guide) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "About",
          style: GoogleFonts.outfit(color: AppTheme.textPrimary(context), fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: -0.2),
        ),
        const SizedBox(height: 12),
        Text(
          guide.bio ?? "No bio provided.",
          style: GoogleFonts.inter(color: AppTheme.textSecondary(context), fontSize: 15, height: 1.6),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 10, runSpacing: 10,
          children: guide.specializations.map((s) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.surfaceMuted(context),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(s, style: GoogleFonts.inter(color: AppTheme.textPrimary(context), fontSize: 12, fontWeight: FontWeight.w600)),
          )).toList(),
        ),
      ],
    ).animate().fadeIn(delay: 400.ms);
  }

  Widget _buildPackageList(BuildContext context, Future<List<Map<String, dynamic>>> future) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: future,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox.shrink();
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Packages",
              style: GoogleFonts.outfit(color: AppTheme.textPrimary(context), fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: -0.2),
            ),
            const SizedBox(height: 16),
            ...snapshot.data!.map((p) => _buildPackageCard(context, p)),
          ],
        );
      },
    );
  }

  Widget _buildPackageCard(BuildContext context, Map<String, dynamic> data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: AppTheme.colors.black.withValues(alpha: 0.05), blurRadius: 14, offset: const Offset(0, 5)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['title'] ?? 'Standard package',
                  style: GoogleFonts.outfit(color: AppTheme.textPrimary(context), fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: -0.2),
                ),
                const SizedBox(height: 6),
                Text(
                  data['description'] ?? '',
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(color: AppTheme.textSecondary(context), fontSize: 12),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.schedule_rounded, color: AppTheme.textSecondary(context), size: 14),
                    const SizedBox(width: 6),
                    Text("${data['durationHours']}h", style: GoogleFonts.inter(color: AppTheme.textSecondary(context), fontSize: 12)),
                    const SizedBox(width: 16),
                    Icon(Icons.group_rounded, color: AppTheme.textSecondary(context), size: 14),
                    const SizedBox(width: 6),
                    Text("${data['maxGuests']} guests", style: GoogleFonts.inter(color: AppTheme.textSecondary(context), fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "\$${data['price']}",
                style: GoogleFonts.outfit(color: AppTheme.textPrimary(context), fontWeight: FontWeight.w800, fontSize: 18),
              ),
              Text("Total", style: GoogleFonts.inter(color: AppTheme.textSecondary(context), fontSize: 10, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, GuideListing guide) {
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
    return Positioned(
      bottom: 0, left: 0, right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [scaffoldBg, scaffoldBg.withValues(alpha: 0)],
            begin: Alignment.bottomCenter, end: Alignment.topCenter,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: AppTheme.colors.black.withValues(alpha: 0.06), blurRadius: 14, offset: const Offset(0, 5)),
                ],
              ),
              child: Icon(Icons.chat_bubble_outline_rounded, color: AppTheme.textPrimary(context)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(100),
                  boxShadow: [
                    BoxShadow(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.35), blurRadius: 24, offset: const Offset(0, 12)),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => BookingRequestScreen(guideId: guide.guideId)),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: AppTheme.colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                    elevation: 0,
                  ),
                  child: Text(
                    "Request this guide",
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
