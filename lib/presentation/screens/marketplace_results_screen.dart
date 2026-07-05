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
                color: AppTheme.colors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.colors.white.withValues(alpha: 0.2)),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.colors.white, size: 18),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "ORACLE GUIDES",
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2.5,
                    color: AppTheme.colors.amber[400],
                  ),
                ),
                Text(
                  "Verified Local Experts",
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.colors.white,
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
          return ChoiceChip(
            label: Text(
              cat,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppTheme.colors.black : AppTheme.colors.white70,
              ),
            ),
            selected: isSelected,
            selectedColor: AppTheme.colors.amber[400],
            backgroundColor: AppTheme.colors.white.withValues(alpha: 0.08),
            side: BorderSide(
              color: isSelected ? AppTheme.colors.amber : AppTheme.colors.white.withValues(alpha: 0.2),
            ),
            onSelected: (_) => _onCategorySelected(cat),
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
          return const Center(child: CircularProgressIndicator(color: AppTheme.colors.amber));
        }
        if (snapshot.hasError) {
          return Center(
            child: Text("Error loading guides: ${snapshot.error}", style: const TextStyle(color: AppTheme.colors.white70)),
          );
        }
        final listings = snapshot.data ?? [];
        if (listings.isEmpty) {
          return _buildEmptyState("No verified guides published yet.");
        }
        return _buildListingsGrid(listings, isPaginated: false);
      },
    );
  }

  Widget _buildSearchResults(BuildContext context, MarketplaceSearchState state) {
    if (state.isLoading && state.results.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.colors.amber));
    }
    if (state.error != null && state.results.isEmpty) {
      return Center(
        child: Text(state.error!, style: const TextStyle(color: AppTheme.colors.redAccent)),
      );
    }
    if (state.results.isEmpty) {
      return _buildEmptyState("No guides found matching '${state.normalizedQuery}'");
    }
    return _buildListingsGrid(state.results, isPaginated: true, isLoadingMore: state.isLoading);
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_search_outlined, size: 64, color: AppTheme.colors.white.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 16, color: AppTheme.colors.white70),
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
      color: AppTheme.colors.amber,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        itemCount: listings.length + (isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == listings.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: CircularProgressIndicator(color: AppTheme.colors.amber)),
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
          color: AppTheme.colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.colors.white.withValues(alpha: 0.15)),
          boxShadow: [
            BoxShadow(
              color: AppTheme.colors.black.withValues(alpha: 0.2),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: SizedBox(
                  width: 80,
                  height: 80,
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
                            color: AppTheme.colors.amber.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.colors.amber.withValues(alpha: 0.5)),
                          ),
                          child: Text(
                            listing.guideCategory.toUpperCase(),
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.colors.amber[300],
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, color: AppTheme.colors.amber, size: 18),
                            const SizedBox(width: 4),
                            Text(
                              listing.ratingAverage.toStringAsFixed(1),
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: AppTheme.colors.white,
                              ),
                            ),
                            Text(
                              " (${listing.reviewCount})",
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppTheme.colors.white60,
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
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.colors.white,
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
                            const Icon(Icons.language, color: AppTheme.colors.white60, size: 14),
                            const SizedBox(width: 6),
                            Text(
                              listing.languages.take(2).join(", "),
                              style: GoogleFonts.inter(fontSize: 12, color: AppTheme.colors.white70),
                            ),
                          ],
                        ),
                        Text(
                          "${listing.currency} ${listing.hourlyRate.toStringAsFixed(0)}/hr",
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.colors.greenAccent[400],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.colors.white.withValues(alpha: 0.4), size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
