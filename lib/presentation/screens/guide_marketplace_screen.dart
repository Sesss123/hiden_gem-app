import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repositories/marketplace_repository.dart';
import '../../data/models/guide_listing.dart';
import 'guide_public_profile_screen.dart';
import '../../core/services/security_orchestrator.dart';
import '../widgets/banner_ad_widget.dart';
import '../widgets/native_ad_widget.dart';

class GuideMarketplaceScreen extends ConsumerStatefulWidget {
  const GuideMarketplaceScreen({super.key});

  @override
  ConsumerState<GuideMarketplaceScreen> createState() => _GuideMarketplaceScreenState();
}

class _GuideMarketplaceScreenState extends ConsumerState<GuideMarketplaceScreen> {
  String _searchQuery = "";
  String? _selectedCategory;
  String? _selectedRegion;
  bool _hideLowerTiers = false;

  final List<String> _categories = ["Chauffeur", "Site", "Adventure", "Heritage", "Wildlife"];
  final List<String> _regions = ["Central", "Southern", "Western", "Northern", "Eastern"];

  @override
  Widget build(BuildContext context) {
    final featuredFuture = ref.watch(marketplaceRepositoryProvider).getFeaturedGuides();
    final searchFuture = ref.watch(marketplaceRepositoryProvider).searchMarketplace(
      category: _selectedCategory,
      region: _selectedRegion,
    );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSearchHeader(),
                    const SizedBox(height: 24),
                    _buildFeaturedSection(featuredFuture),
                    const SizedBox(height: 32),
                    _buildMarketplaceHeader(),
                    const SizedBox(height: 16),
                    _buildCategoryFilters(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildGuideList(searchFuture),
              ),
            ),
          ],
        ),
      bottomNavigationBar: const BannerAdWidget(),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      floating: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textPrimary(context), size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        "EXPLORE MISSIONS",
        style: GoogleFonts.outfit(
          fontSize: 16,
          fontWeight: FontWeight.w900,
          letterSpacing: 4,
          color: AppTheme.textPrimary(context),
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.tune_rounded, color: AppTheme.textSecondary(context)),
          onPressed: _showFilterSheet,
        ),
      ],
    );
  }

  Widget _buildSearchHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.secondaryBorder(context)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: TextField(
        onChanged: (v) => setState(() => _searchQuery = v),
        style: GoogleFonts.inter(color: AppTheme.textPrimary(context)),
        decoration: InputDecoration(
          hintText: "Find your perfect guide...",
          hintStyle: GoogleFonts.inter(color: AppTheme.textSecondary(context), fontSize: 14),
          border: InputBorder.none,
          icon: Icon(Icons.search_rounded, color: AppTheme.textSecondary(context)),
        ),
      ),
    );
  }

  Widget _buildFeaturedSection(Future<List<GuideListing>> future) {
    // Mini-Guard A: Integrity Check for Featured Section
    if (!SecurityOrchestrator().isKeyValid(SecurityKey.integrity)) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<List<GuideListing>>(
      future: future,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox.shrink();
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome_rounded, color: AppPalette.rust, size: 16),
                const SizedBox(width: 8),
                Text(
                  "FEATURED ELITE",
                  style: GoogleFonts.inter(
                    color: AppPalette.rust,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (snapshot.hasError)
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text("Unable to load featured guides.", style: GoogleFonts.inter(color: Colors.redAccent)),
              )
            else if (!snapshot.hasData || snapshot.data!.isEmpty)
              const SizedBox()
            else
              SizedBox(
              height: 180,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  final guide = snapshot.data![index];
                  return _buildFeaturedCard(guide);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFeaturedCard(GuideListing guide) {
    return GestureDetector(
      onTap: () async {
        // Mini-Guard B: Deep Nexus check for Elite Profile Navigation
        final isAuthorized = await SecurityOrchestrator().verifyPremiumNexus();
        if (!mounted) return;
        if (!isAuthorized) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Subscription Verification Failed. Try again.")),
          );
          return;
        }
        
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => GuidePublicProfileScreen(guideId: guide.guideId)),
        );
      },
      child: Container(
        width: 280,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.secondaryBorder(context)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Stack(
          children: [
            // Info
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppPalette.rust.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppPalette.rust.withValues(alpha: 0.2)),
                        ),
                        child: Text(
                          guide.trustTierPublic.toUpperCase(),
                          style: GoogleFonts.inter(color: AppPalette.rust, fontSize: 9, fontWeight: FontWeight.w900),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        "${guide.currency} ${guide.hourlyRate}/hr",
                        style: GoogleFonts.outfit(color: AppTheme.textPrimary(context), fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    guide.displayName,
                    style: GoogleFonts.outfit(color: AppTheme.textPrimary(context), fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    guide.specializations.take(2).join(" • "),
                    style: GoogleFonts.inter(color: AppTheme.textSecondary(context), fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 600.ms).scale(begin: const Offset(0.95, 0.95));
  }

  Widget _buildMarketplaceHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "GUIDE FLEET",
          style: GoogleFonts.inter(
            color: AppTheme.textPrimary(context),
            fontSize: 14,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
        Text(
          "VERIFIED TRUST",
          style: GoogleFonts.inter(
            color: AppTheme.textSecondary(context),
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryFilters() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = _selectedCategory == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: FilterChip(
              label: Text(cat, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : AppTheme.textPrimary(context))),
              selected: isSelected,
              onSelected: (_) => setState(() => _selectedCategory = isSelected ? null : cat),
              selectedColor: Theme.of(context).primaryColor,
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: AppTheme.secondaryBorder(context))),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGuideList(Future<MarketplacePage> future) {
    // Mini-Guard C: Server Residency Proof for Main Index
    if (!SecurityOrchestrator().isKeyValid(SecurityKey.serverProof)) {
       return const Center(child: Text("Service synchronization required."));
    }

    return FutureBuilder<MarketplacePage>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Padding(
            padding: EdgeInsets.all(40.0),
            child: CircularProgressIndicator(),
          ));
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(40.0),
              child: Text(
                "Oracle connection disrupted.",
                style: GoogleFonts.inter(color: Colors.redAccent),
              ),
            ),
          );
        }
        
        final guides = (snapshot.data?.listings ?? []).where((g) {
          if (_searchQuery.isEmpty) return true;
          final q = _searchQuery.toLowerCase();
          return g.displayName.toLowerCase().contains(q) ||
                 (g.bio?.toLowerCase().contains(q) ?? false) ||
                 g.specializations.any((s) => s.toLowerCase().contains(q));
        }).toList();
        if (guides.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(40.0),
              child: Text(
                "No guides match your query",
                style: GoogleFonts.inter(color: AppTheme.textSecondary(context)),
              ),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: guides.length + 1,
          itemBuilder: (context, index) {
            // Insert a Native Ad after the 3rd item
            if (index == 3) {
              return const NativeAdWidget();
            }
            
            // Adjust index if after ad
            final guideIndex = index > 3 ? index - 1 : index;
            if (guideIndex >= guides.length) return null;
            
            final guide = guides[guideIndex];
            return _buildGuideCard(guide, guideIndex);
          },
        );
      },
    );
  }

  Widget _buildGuideCard(GuideListing guide, int index) {
    final tierColor = guide.trustTierPublic == 'Excellent' 
        ? Colors.amberAccent 
        : (guide.trustTierPublic == 'Strong' ? const Color(0xFF00E676) : const Color(0xFF64748B));
    
    final tierIcon = guide.trustTierPublic == 'Excellent'
        ? Icons.workspace_premium_rounded
        : (guide.trustTierPublic == 'Strong' ? Icons.verified_rounded : Icons.shield_outlined);

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => GuidePublicProfileScreen(guideId: guide.guideId)),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppTheme.secondaryBorder(context)),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left Accent Strip
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(28),
                      bottomLeft: Radius.circular(28),
                    ),
                    gradient: LinearGradient(
                      colors: [tierColor, tierColor.withValues(alpha: 0.1)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
                
                // Main Content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top Row: Avatar + Name + Tier Badge
                        Row(
                          children: [
                            // Avatar with Neon Ring
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [tierColor, tierColor.withValues(alpha: 0.2)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(color: tierColor.withValues(alpha: 0.15), blurRadius: 12, spreadRadius: 1),
                                ],
                              ),
                              child: Container(
                                width: 52, height: 52,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.black,
                                  image: guide.profilePhotoUrl != null 
                                    ? DecorationImage(image: NetworkImage(guide.profilePhotoUrl!), fit: BoxFit.cover)
                                    : null,
                                ),
                                child: guide.profilePhotoUrl == null 
                                  ? Icon(Icons.person_outline_rounded, color: tierColor.withValues(alpha: 0.5), size: 26)
                                  : null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            
                            // Name + Category
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          guide.displayName,
                                          style: GoogleFonts.outfit(color: AppTheme.textPrimary(context), fontSize: 17, fontWeight: FontWeight.w800),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Icon(tierIcon, color: tierColor, size: 16),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "${guide.guideCategory} • ${guide.regions.first}",
                                    style: GoogleFonts.inter(color: AppTheme.textSecondary(context), fontSize: 11, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                            
                            // Price Tag
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: tierColor.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: tierColor.withValues(alpha: 0.15)),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    "${guide.currency} ${guide.hourlyRate}",
                                    style: GoogleFonts.outfit(color: AppTheme.textPrimary(context), fontWeight: FontWeight.w900, fontSize: 15),
                                  ),
                                  Text(
                                    "/hr",
                                    style: GoogleFonts.inter(color: AppTheme.textSecondary(context), fontSize: 9, fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Divider
                        Container(
                          height: 1,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [tierColor.withValues(alpha: 0.15), Colors.transparent],
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 14),
                        
                        // Bottom Row: Rating + Specializations + Trust Tier
                        Row(
                          children: [
                            // Star Rating
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.amberAccent.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.star_rounded, color: Colors.amberAccent, size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    guide.ratingAverage.toStringAsFixed(1),
                                    style: GoogleFonts.outfit(color: Colors.amberAccent, fontSize: 12, fontWeight: FontWeight.w800),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    "(${guide.reviewCount})",
                                    style: GoogleFonts.inter(color: Colors.white24, fontSize: 9),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            
                            // Specializations (up to 2)
                            ...guide.specializations.take(2).map((s) => Container(
                              margin: const EdgeInsets.only(right: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppTheme.secondaryBorder(context)),
                              ),
                              child: Text(
                                s,
                                style: GoogleFonts.inter(color: AppTheme.textSecondary(context), fontSize: 10, fontWeight: FontWeight.w600),
                              ),
                            )),
                            
                            const Spacer(),
                            
                            // Trust Tier Badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: tierColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: tierColor.withValues(alpha: 0.2)),
                              ),
                              child: Text(
                                guide.trustTierPublic.toUpperCase(),
                                style: GoogleFonts.inter(color: tierColor, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: (index * 80).ms, duration: 500.ms).slideY(begin: 0.08, curve: Curves.easeOutCubic);
  }


  void _showFilterSheet() {
    // Mini-Guard D: Session Health check for Filter UI
    if (!SecurityOrchestrator().isKeyValid(SecurityKey.sessionHealth)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Security Cooldown: Check back in 1 minute.")),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "ADVANCED FILTERS",
              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 2, color: AppTheme.textPrimary(context)),
            ),
            const SizedBox(height: 24),
            Text("REGION", style: GoogleFonts.inter(color: AppTheme.textSecondary(context), fontSize: 10, fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: _regions.map((r) => FilterChip(
                label: Text(r, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: _selectedRegion == r ? Colors.white : AppTheme.textPrimary(context))),
                selected: _selectedRegion == r,
                onSelected: (_) => setState(() => _selectedRegion = _selectedRegion == r ? null : r),
                selectedColor: Theme.of(context).primaryColor,
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: AppTheme.secondaryBorder(context))),
              )).toList(),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("EXCELLENT TIERS ONLY", style: GoogleFonts.inter(color: AppTheme.textPrimary(context), fontSize: 13, fontWeight: FontWeight.bold)),
                Switch(
                  value: _hideLowerTiers,
                  activeThumbColor: const Color(0xFF00E676),
                  onChanged: (v) => setState(() => _hideLowerTiers = v),
                ),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text("APPLY FILTERS", style: TextStyle(fontWeight: FontWeight.w900)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
