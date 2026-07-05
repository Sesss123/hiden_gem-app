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
      backgroundColor: AppTheme.colors.transparent,
      body: OracleUI.auraBackground(
        child: FutureBuilder<GuideListing?>(
          future: listingFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final guide = snapshot.data;
            if (guide == null) {
              return Center(child: Text("Guide profile not found", style: TextStyle(color: AppTheme.colors.white24)));
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
              IconButton(
                icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.colors.white, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
              IconButton(
                icon: Icon(Icons.share_rounded, color: AppTheme.colors.white70),
                onPressed: () {},
              ),
            ],
          ),
        ),
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
                _buildTrustCard(context, guide),
                const SizedBox(height: 32),
                _buildBio(guide),
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
    return Container(
      height: 420,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.colors.black,
        image: guide.coverPhotos.isNotEmpty 
          ? DecorationImage(image: NetworkImage(guide.coverPhotos.first), fit: BoxFit.cover, opacity: 0.6)
          : null,
      ),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.colors.black, AppTheme.colors.black.withValues(alpha: 0.1), AppTheme.colors.black],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
          ),
          Positioned(
            bottom: 40, left: 24, right: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.colors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.colors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    guide.guideCategory.toUpperCase(),
                    style: GoogleFonts.inter(color: AppTheme.colors.primary, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  guide.displayName,
                  style: GoogleFonts.outfit(color: AppTheme.colors.white, fontSize: 36, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.location_on_rounded, color: AppTheme.colors.white24, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      guide.regions.join(" • "),
                      style: GoogleFonts.inter(color: AppTheme.colors.white54, fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrustCard(BuildContext context, GuideListing guide) {
    return OracleUI.premiumGlassCard(
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStat("EXPERIENCE", "${guide.yearsExperience}Y"),
          _buildStatDivider(),
          _buildStat("RATING", guide.ratingAverage.toStringAsFixed(1), icon: Icons.star_rounded),
          _buildStatDivider(),
          _buildStat("RANK", guide.trustTierPublic.toUpperCase()),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1);
  }

  Widget _buildStat(String label, String value, {IconData? icon}) {
    return Column(
      children: [
        Text(label, style: GoogleFonts.inter(color: AppTheme.colors.white24, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        const SizedBox(height: 8),
        Row(
          children: [
            if (icon != null) Icon(icon, color: AppTheme.colors.amberAccent, size: 14),
            if (icon != null) const SizedBox(width: 4),
            Text(value, style: GoogleFonts.outfit(color: AppTheme.colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
          ],
        ),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(width: 1, height: 30, color: AppTheme.colors.white.withValues(alpha: 0.05));
  }

  Widget _buildBio(GuideListing guide) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "ABOUT MISSIONS",
          style: GoogleFonts.inter(color: AppTheme.colors.white38, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 2),
        ),
        const SizedBox(height: 16),
        Text(
          guide.bio ?? "No mission brief provided.",
          style: GoogleFonts.inter(color: AppTheme.colors.white70, fontSize: 15, height: 1.6),
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 10, runSpacing: 10,
          children: guide.specializations.map((s) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.colors.white.withValues(alpha: 0.05)),
            ),
            child: Text(s, style: GoogleFonts.inter(color: AppTheme.colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
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
              "MISSION PACKS",
              style: GoogleFonts.inter(color: AppTheme.colors.white38, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 2),
            ),
            const SizedBox(height: 20),
            ...snapshot.data!.map((p) => _buildPackageCard(context, p)),
          ],
        );
      },
    );
  }

  Widget _buildPackageCard(BuildContext context, Map<String, dynamic> data) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: OracleUI.glassContainer(
        padding: const EdgeInsets.all(20),
        borderRadius: BorderRadius.circular(24),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['title'] ?? 'Standard Package',
                    style: GoogleFonts.outfit(color: AppTheme.colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    data['description'] ?? '',
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(color: AppTheme.colors.white38, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.schedule_rounded, color: AppTheme.colors.white24, size: 14),
                      const SizedBox(width: 6),
                      Text("${data['durationHours']}H", style: GoogleFonts.outfit(color: AppTheme.colors.white54, fontSize: 12)),
                      const SizedBox(width: 16),
                      Icon(Icons.group_rounded, color: AppTheme.colors.white24, size: 14),
                      const SizedBox(width: 6),
                      Text("${data['maxGuests']} GUESTS", style: GoogleFonts.outfit(color: AppTheme.colors.white54, fontSize: 12)),
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
                  style: GoogleFonts.outfit(color: AppTheme.colors.white, fontWeight: FontWeight.w900, fontSize: 20),
                ),
                Text("TOTAL", style: GoogleFonts.inter(color: AppTheme.colors.white10, fontSize: 10, fontWeight: FontWeight.w900)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, GuideListing guide) {
    return Positioned(
      bottom: 0, left: 0, right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.colors.black, AppTheme.colors.transparent],
            begin: Alignment.bottomCenter, end: Alignment.topCenter,
          ),
        ),
        child: Row(
          children: [
            OracleUI.glassContainer(
              padding: const EdgeInsets.all(16),
              borderRadius: BorderRadius.circular(16),
              child: Icon(Icons.chat_bubble_outline_rounded, color: AppTheme.colors.white),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => BookingRequestScreen(guideId: guide.guideId)),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.colors.primary,
                  foregroundColor: AppTheme.colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: Text(
                  "REQUEST MISSION",
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w900, letterSpacing: 2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
