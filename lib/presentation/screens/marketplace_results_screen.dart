import 'package:hidden_gems_sl/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../core/theme/oracle_ui_system.dart';
import '../../data/models/guide_listing.dart';
import '../../data/repositories/marketplace_repository.dart';
import '../controllers/marketplace_search_controller.dart';
import '../widgets/marketplace_search_bar.dart';
import '../widgets/cached_image.dart';
import 'guide_public_profile_screen.dart';

class MarketplaceResultsScreen extends ConsumerStatefulWidget {
  const MarketplaceResultsScreen({super.key});

  @override
  ConsumerState<MarketplaceResultsScreen> createState() => _MarketplaceResultsScreenState();
}

class _MarketplaceResultsScreenState extends ConsumerState<MarketplaceResultsScreen> {
  final ScrollController _scrollController = ScrollController();
  late Future<List<GuideListing>> _defaultListingsFuture;
  String? _selectedCategory;

  final List<String> _categories = [
    'All',
    'Chauffeur',
    'Site Guide',
    'Adventure',
    'Wildlife',
    'Heritage',
    'Photography',
  ];

  @override
  void initState() {
    super.initState();
    _defaultListingsFuture = _loadDefaultListings();
    _scrollController.addListener(_onScroll);
  }

  Future<List<GuideListing>> _loadDefaultListings() async {
    final repo = ref.read(marketplaceRepositoryProvider);
    final featured = await repo.getFeaturedGuides();
    if (featured.isNotEmpty) {
      return featured;
    }
    // Fallback to general browse if no featured guides exist yet
    final page = await repo.searchMarketplace();
    return page.listings;
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(marketplaceSearchControllerProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onCategorySelected(String category) {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedCategory = category == 'All' ? null : category;
    });
    final controller = ref.read(marketplaceSearchControllerProvider.notifier);
    final currentQuery = ref.read(marketplaceSearchControllerProvider).normalizedQuery;
    if (currentQuery.length >= 2 || _selectedCategory != null) {
      controller.search(
        currentQuery.isEmpty ? 'a' : currentQuery,
        category: _selectedCategory,
      );
    } else {
      controller.clear();
      setState(() {
        _defaultListingsFuture = _loadDefaultListings();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(marketplaceSearchControllerProvider);
    final isSearching = searchState.normalizedQuery.length >= 2 || _selectedCategory != null;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: OracleUI.auraBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: MarketplaceSearchBar(
                  hintText: 'Search by name, language, or city...',
                  onCooldownMessage: (msg) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(msg), backgroundColor: AppTheme.colors.orange),
                    );
                  },
                ),
              ),
              _buildCategoryChips(context),
              const SizedBox(height: 10),
              Expanded(
                child: isSearching
                    ? _buildSearchResults(context, searchState)
                    : _buildDefaultBrowse(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.surfaceMuted(context),
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.borderColor(context)),
              ),
              child: Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textPrimary(context), size: 18),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Verified guides",
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                Text(
                  "Find your expert",
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: AppTheme.textPrimary(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = (_selectedCategory == null && cat == 'All') || (_selectedCategory == cat);
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return GestureDetector(
            onTap: () => _onCategorySelected(cat),
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isSelected ? (isDark ? AppTheme.colors.black : AppPalette.ink) : AppTheme.surfaceMuted(context),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                cat,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? AppTheme.colors.white : AppTheme.textSecondary(context),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDefaultBrowse(BuildContext context) {
    return FutureBuilder<List<GuideListing>>(
      future: _defaultListingsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary));
        }
        if (snapshot.hasError) {
          return Center(
            child: Text("Error loading guides: ${snapshot.error}", style: TextStyle(color: AppTheme.textSecondary(context))),
          );
        }
        final listings = snapshot.data ?? [];
        if (listings.isEmpty) {
          return _buildEmptyState(context, "No verified guides published yet.");
        }
        return _buildListingsGrid(listings, isPaginated: false);
      },
    );
  }

  Widget _buildSearchResults(BuildContext context, MarketplaceSearchState state) {
    if (state.isLoading && state.results.isEmpty) {
      return Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary));
    }
    if (state.error != null && state.results.isEmpty) {
      return Center(
        child: Text(state.error!, style: TextStyle(color: AppTheme.colors.redAccent)),
      );
    }
    if (state.results.isEmpty) {
      return _buildEmptyState(context, "No guides found matching '${state.normalizedQuery}'");
    }
    return _buildListingsGrid(state.results, isPaginated: true, isLoadingMore: state.isLoading);
  }

  Widget _buildEmptyState(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_search_outlined, size: 64, color: AppTheme.textSecondary(context).withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 16, color: AppTheme.textSecondary(context)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListingsGrid(List<GuideListing> listings, {required bool isPaginated, bool isLoadingMore = false}) {
    return RefreshIndicator(
      onRefresh: () async {
        if (isPaginated) {
          final query = ref.read(marketplaceSearchControllerProvider).normalizedQuery;
          ref.read(marketplaceSearchControllerProvider.notifier).search(query, category: _selectedCategory);
        } else {
          setState(() {
            _defaultListingsFuture = _loadDefaultListings();
          });
        }
      },
      color: Theme.of(context).colorScheme.primary,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        itemCount: listings.length + (isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == listings.length) {
            return Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary)),
            );
          }
          final listing = listings[index];
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 500),
            child: SlideAnimation(
              verticalOffset: 20.0,
              child: FadeInAnimation(
                child: _buildGuideCard(context, listing),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGuideCard(BuildContext context, GuideListing listing) {
    final photoUrl = listing.profilePhotoUrl ??
        (listing.coverPhotos.isNotEmpty ? listing.coverPhotos.first : "https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=500&auto=format&fit=crop&q=80");

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GuidePublicProfileScreen(guideId: listing.guideId),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: AppTheme.colors.black.withValues(alpha: 0.06),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  width: 80,
                  height: 80,
                  color: AppTheme.surfaceMuted(context),
                  child: CachedImage(
                    url: photoUrl,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.colors.amber.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(
                            listing.guideCategory,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.colors.amber[800],
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            Icon(Icons.star_rounded, color: AppTheme.colors.amber, size: 18),
                            const SizedBox(width: 4),
                            Text(
                              listing.ratingAverage.toStringAsFixed(1),
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: AppTheme.textPrimary(context),
                              ),
                            ),
                            Text(
                              " (${listing.reviewCount})",
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppTheme.textSecondary(context),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      listing.displayName,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.2,
                        color: AppTheme.textPrimary(context),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.language, color: AppTheme.textSecondary(context), size: 14),
                            const SizedBox(width: 6),
                            Text(
                              listing.languages.take(2).join(", "),
                              style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary(context)),
                            ),
                          ],
                        ),
                        Text(
                          "${listing.currency} ${listing.hourlyRate.toStringAsFixed(0)}/hr",
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.colors.green[700],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.textSecondary(context).withValues(alpha: 0.5), size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
