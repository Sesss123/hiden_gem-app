import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hidden_gems_sl/l10n/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:hidden_gems_sl/data/repositories/discovery_repository.dart';
import '../../core/theme/oracle_ui_system.dart';
import '../../core/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/discovery_place.dart';
import '../widgets/skeleton_loaders.dart';
import 'map_explorer_screen.dart';
import '../../data/models/village_experience.dart';
import '../../data/datasources/village_experience_service.dart';
import '../../core/utils/image_utils.dart';
import '../../core/localization/l10n_utils.dart';
import 'place_details_screen.dart';
import 'event_calendar_screen.dart';

class DiscoveryScreen extends ConsumerStatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  ConsumerState<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends ConsumerState<DiscoveryScreen> {
  Position? _currentPosition;
  
  List<DiscoveryPlace> _allPlaces = [];
  List<DiscoveryPlace> _oraclePicks = [];
  List<DiscoveryPlace> _naturePicks = [];
  List<DiscoveryPlace> _culturePicks = [];
  List<DiscoveryPlace> _arPicks = [];
  List<DiscoveryPlace> _filteredList = [];
  List<VillageExperience> _villageExperiences = [];
  
  bool _isLoading = true;
  String _selectedFilter = "all";
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  // Advanced Filters
  double _maxDistance = 100.0;
  String _selectedPriceRange = "All";
  bool _onlyAR = false;

  final List<String> _filters = [
    "all", "nature", "waterfall", "hiking", "culture", "coastal", "family", "budget", "ar"
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      if (mounted) setState(() {});
    });
    _initDiscovery();
  }

  Future<void> _initDiscovery({bool forceRefresh = false}) async {
    if (!forceRefresh) setState(() => _isLoading = true);
    
    final repo = ref.read(discoveryRepositoryProvider);
    _currentPosition = await repo.getCurrentLocation();
    
    _allPlaces = await repo.getDiscoveryPlaces(
      userLat: _currentPosition?.latitude,
      userLng: _currentPosition?.longitude,
      forceRefresh: forceRefresh,
    );

    _oraclePicks = await repo.getAiRecommendations(_allPlaces);
    
    _naturePicks = _allPlaces.where((p) => 
      p.category.toLowerCase().contains("nature") || 
      p.category.toLowerCase().contains("waterfall") ||
      p.category.toLowerCase().contains("hiking")
    ).toList();
    
    _culturePicks = _allPlaces.where((p) => 
      p.category.toLowerCase().contains("culture") || 
      p.category.toLowerCase().contains("historical") ||
      p.category.toLowerCase().contains("village")
    ).toList();
    
    _arPicks = _allPlaces.where((p) => p.arSupported).toList();

    _villageExperiences = await VillageExperienceService.getNearbyExperiences(
      lat: _currentPosition?.latitude ?? 7.8731,
      lng: _currentPosition?.longitude ?? 80.7718,
    );

    if (!mounted) return;
    _applyFilter();
  }

  String _resolveDistrict(DiscoveryPlace place) {
    if (place.district.isNotEmpty) return place.district;
    
    final nameLower = place.name.toLowerCase();
    
    final districtMap = {
      'colombo': 'Colombo',
      'galle': 'Galle',
      'unawatuna': 'Galle',
      'hikkaduwa': 'Galle',
      'kandy': 'Kandy',
      'pinnawala': 'Kegalle',
      'ella': 'Badulla',
      'badulla': 'Badulla',
      'bandarawela': 'Badulla',
      'ohiya': 'Badulla',
      'nuwara eliya': 'Nuwara Eliya',
      'hatton': 'Nuwara Eliya',
      'nanu oya': 'Nuwara Eliya',
      'jaffna': 'Jaffna',
      'trincomalee': 'Trincomalee',
      'batticaloa': 'Batticaloa',
      'negombo': 'Gampaha',
      'katunayake': 'Gampaha',
      'anuradhapura': 'Anuradhapura',
      'polonnaruwa': 'Polonnaruwa',
      'sigiriya': 'Matale',
      'dambulla': 'Matale',
      'habarana': 'Matale',
      'matara': 'Matara',
      'mirissa': 'Matara',
      'weligama': 'Matara',
      'hambantota': 'Hambantota',
      'tangalle': 'Hambantota',
      'kataragama': 'Monaragala',
      'tissamaharama': 'Hambantota',
      'arugam bay': 'Ampara',
      'ampara': 'Ampara',
      'ratnapura': 'Ratnapura',
      'kurunegala': 'Kurunegala',
      'monaragala': 'Monaragala',
      'mannar': 'Mannar',
      'vavuniya': 'Vavuniya',
      'chilaw': 'Puttalam',
      'puttalam': 'Puttalam',
      'kalpitiya': 'Puttalam',
      'avissawella': 'Colombo',
    };

    for (final entry in districtMap.entries) {
      if (nameLower.contains(entry.key)) {
        return entry.value;
      }
    }

    return 'Sri Lanka'; // Default fallback
  }

  void _applyFilter() {
    final cleanFilter = _selectedFilter.toLowerCase();
    
    setState(() => _isLoading = true);

    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) return;
      
      final List<DiscoveryPlace> results = _allPlaces.where((p) {
        // 1. Category Filter
        bool matchesCategory = true;
        if (cleanFilter != "all") {
          final cat = p.category.toLowerCase();
          final name = p.name.toLowerCase();
          final resolvedDistrict = _resolveDistrict(p).toLowerCase();

          if (cleanFilter == "nature") {
            matchesCategory = cat.contains("nature") || cat.contains("hiking") || cat.contains("waterfall") || cat.contains("park") || cat.contains("village");
          } else if (cleanFilter == "waterfall") {
            matchesCategory = cat.contains("waterfall") || name.contains("waterfall") || name.contains("ella");
          } else if (cleanFilter == "hiking") {
            matchesCategory = cat.contains("hiking") || cat.contains("mountain") || cat.contains("peak") || name.contains("peak");
          } else if (cleanFilter == "culture") {
            matchesCategory = cat.contains("culture") || cat.contains("histor") || cat.contains("temple") || cat.contains("village");
          } else if (cleanFilter == "coastal") {
            matchesCategory = cat.contains("coast") || cat.contains("beach") || cat.contains("ocean") || resolvedDistrict.contains("galle") || resolvedDistrict.contains("jaffna");
          } else if (cleanFilter == "budget") {
            matchesCategory = p.ticketRange.toLowerCase().contains("free") || p.ticketRange.contains("50") || p.ticketRange.contains("100");
          } else if (cleanFilter == "family") {
            matchesCategory = p.vehicleAccess.toLowerCase().contains("all vehicles") || p.roadType.toLowerCase().contains("paved");
          } else if (cleanFilter == "ar") {
            matchesCategory = p.arSupported;
          } else {
            matchesCategory = cat.contains(cleanFilter) || name.contains(cleanFilter) || resolvedDistrict.contains(cleanFilter);
          }
        }

        if (!matchesCategory) return false;

        // 2. Distance Filter
        if (p.distanceKm > _maxDistance) return false;

        // 3. Price Filter — numeric threshold-based (not fragile string matching)
        if (_selectedPriceRange != "All") {
          final price = p.ticketRange.toLowerCase();
          final numMatch = RegExp(r'\d+').firstMatch(price);
          final priceNum = numMatch != null ? int.tryParse(numMatch.group(0)!) ?? 0 : 0;
          if (_selectedPriceRange == "Free" && priceNum != 0) return false;
          if (_selectedPriceRange == "Economy" && (priceNum == 0 || priceNum > 2000)) return false;
          if (_selectedPriceRange == "Premium" && priceNum <= 2000) return false;
        }

        // 4. AR Filter
        if (_onlyAR && !p.arSupported) return false;

        return true;
      }).toList();

      setState(() {
        _filteredList = results;
        _isLoading = false;
      });
    });
  }

  void _showDiscoveryFilterModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          
          return Container(
            height: MediaQuery.of(context).size.height * 0.7,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A).withValues(alpha: 0.95) : Colors.white.withValues(alpha: 0.95),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
              border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)),
            ),
            child: OracleUI.glassContainer(
              radius: const BorderRadius.vertical(top: Radius.circular(40)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Center(
                    child: Container(
                      width: 60,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      OracleUI.neonText(
                        "DISCOVERY FILTERS",
                        style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.secondary),
                      ),
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            _maxDistance = 100.0;
                            _selectedPriceRange = "All";
                            _onlyAR = false;
                          });
                        },
                        child: Text("RESET", style: GoogleFonts.outfit(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold, letterSpacing: 1)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  
                  // Distance Selector
                  Text(
                    "MAXIMUM RADIUS: ${_maxDistance.toInt()} KM",
                    style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary(context), letterSpacing: 1),
                  ),
                  Slider(
                    value: _maxDistance,
                    min: 5,
                    max: 100,
                    divisions: 19,
                    activeColor: Theme.of(context).colorScheme.primary,
                    onChanged: (val) {
                      setModalState(() => _maxDistance = val);
                    },
                  ),
                  const SizedBox(height: 32),

                  // Price Range
                  Text(
                    "BUDGET LEVEL",
                    style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary(context), letterSpacing: 1),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ["All", "Free", "Economy", "Premium"].map((p) {
                      final isSelected = _selectedPriceRange == p;
                      final primary = Theme.of(context).colorScheme.primary;
                      return GestureDetector(
                        onTap: () => setModalState(() => _selectedPriceRange = p),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? primary.withValues(alpha: 0.15)
                                : Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: isSelected
                                  ? primary.withValues(alpha: 0.6)
                                  : Colors.white.withValues(alpha: 0.15),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            p.toUpperCase(),
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected
                                  ? AppTheme.textPrimary(context)
                                  : AppTheme.textSecondary(context),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 40),

                  // AR Toggle
                  OracleUI.glassContainer(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.view_in_ar_rounded, color: Theme.of(context).colorScheme.secondary),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "HERITAGE AR SEARCH",
                                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary(context)),
                                ),
                                Text(
                                  "ONLY SHOW AR ENABLED SPOTS",
                                  style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textSecondary(context)),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Switch(
                          value: _onlyAR,
                          activeThumbColor: Theme.of(context).colorScheme.secondary,
                          onChanged: (val) => setModalState(() => _onlyAR = val),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        HapticFeedback.heavyImpact();
                        Navigator.pop(context);
                        _applyFilter();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(
                        "REVEAL DESTINIES",
                        style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      ),
    );
  }

  void _onFilterChanged(String filter) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selectedFilter == filter) {
        _selectedFilter = "all"; // Toggle off back to All
      } else {
        _selectedFilter = filter;
      }
      _searchQuery = "";
      _searchController.clear();
    });
    _applyFilter();
  }

  void _onSearchSubmitted(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchQuery = "";
        _selectedFilter = "all";
        _searchController.clear();
      });
      _applyFilter();
      return;
    }
    
    HapticFeedback.selectionClick();
    setState(() {
      _searchQuery = query;
      _selectedFilter = "all"; // Map search resets to 'All' instead of empty string
      _isLoading = true;
    });
    
    final repository = ref.read(discoveryRepositoryProvider);
    final aiResults = await repository.getAiRecommendations(_allPlaces, customQuery: query);
    
    if (mounted) {
      setState(() {
        _filteredList = aiResults;
        _isLoading = false;
      });
    }
  }

  void _openPlaceDetails(DiscoveryPlace place) {
    HapticFeedback.lightImpact();
    Navigator.push(context, MaterialPageRoute(builder: (_) => PlaceDetailsScreen(place: place)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: OracleUI.auraBackground(
        child: Stack(
          children: [
            RefreshIndicator(
              onRefresh: () => _initDiscovery(forceRefresh: true),
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              color: Theme.of(context).colorScheme.primary,
              displacement: 100,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                slivers: [
                  _buildLocationHeader(),
                  SliverToBoxAdapter(
                    child: _buildFilters(l10n),
                  ),
                  if (_isLoading)
                    SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => const DiscoveryCardSkeleton(),
                          childCount: 3,
                        ),
                      ),
                    )
                  else if (_searchQuery.isNotEmpty)
                    _buildListView(l10n)
                  else if (_selectedFilter != "all")
                    _buildListView(l10n)
                  else
                    _buildExploreView(l10n),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _currentPosition == null ? null : FloatingActionButton(
        heroTag: 'map_fab',
        onPressed: () {
          HapticFeedback.mediumImpact();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MapExplorerScreen(initialPosition: LatLng(_currentPosition!.latitude, _currentPosition!.longitude)),
            ),
          );
        },
        backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)),
        ),
        child: Icon(Icons.map_outlined, color: Theme.of(context).colorScheme.primary),
      ),
    );
  }

  Widget _buildLocationHeader() {
    final l10n = AppLocalizations.of(context)!;
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Padding(
          padding: const EdgeInsets.fromLTRB(20, 60, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              OracleUI.neonText(
                l10n.discoveryHeader,
                style: GoogleFonts.outfit(
                  fontSize: 32,
                  color: Theme.of(context).colorScheme.secondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              OracleUI.glassContainer(
                height: 54,
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                radius: BorderRadius.circular(27),
                child: Row(
                  children: [
                    Icon(Icons.search, color: Theme.of(context).colorScheme.primary, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onSubmitted: _onSearchSubmitted,
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration(
                          hintText: l10n.searchHint,
                          hintStyle: GoogleFonts.inter(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.clear, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), size: 18),
                                  onPressed: () {
                                    setState(() {
                                      _searchController.clear();
                                      _searchQuery = "";
                                      _selectedFilter = "all";
                                    });
                                    _applyFilter();
                                  },
                                )
                              : null,
                        ),
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.tune, color: Theme.of(context).colorScheme.primary, size: 22),
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        _showDiscoveryFilterModal();
                      },
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilters(AppLocalizations l10n) {
    return Container(
      height: 48,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        physics: const BouncingScrollPhysics(),
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: OracleUI.glassChip(
              context: context,
              label: L10nUtils.getFilterLabel(context, filter),
              isSelected: isSelected,
              onTap: () => _onFilterChanged(filter),
            ),
          );
        },
      ),
    );
  }

  Widget _buildExploreView(AppLocalizations l10n) {
    return SliverList(
      delegate: SliverChildListDelegate([
        if (_oraclePicks.isNotEmpty) ...[
          _buildSectionTitle(l10n.picksForYou, Icons.auto_awesome),
          _buildHorizontalCards(_oraclePicks, l10n, isOracle: true),
          const SizedBox(height: 32),
        ],
        if (_arPicks.isNotEmpty) ...[
          _buildSectionTitle(l10n.exploreInAr, Icons.view_in_ar),
          _buildHorizontalCards(_arPicks, l10n, isAR: true),
          const SizedBox(height: 32),
        ],
        if (_naturePicks.isNotEmpty) ...[
          _buildSectionTitle(l10n.bestNatureNearby, Icons.park_outlined),
          _buildHorizontalCards(_naturePicks, l10n),
          const SizedBox(height: 32),
        ],
        if (_culturePicks.isNotEmpty) ...[
          _buildSectionTitle(l10n.topCultureSpots, Icons.temple_buddhist_outlined),
          _buildHorizontalCards(_culturePicks, l10n),
          const SizedBox(height: 32),
        ],
        if (_villageExperiences.isNotEmpty) ...[
          _buildSectionTitle(l10n.villageStayTitle, Icons.home_work_outlined),
          _buildVillageCards(_villageExperiences),
          const SizedBox(height: 32),
        ],
      ]),
    );
  }

  Widget _buildVillageCards(List<VillageExperience> experiences) {
    return SizedBox(
      height: 240,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: experiences.length,
        itemBuilder: (context, index) {
          final exp = experiences[index];
          return OracleUI.staggeredEntrance(
            index: index,
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                // Navigate to Event Calendar — best match for Soulscape experiences
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => const EventCalendarScreen(),
                ));
              },
              child: Container(
                width: 220,
                margin: const EdgeInsets.symmetric(horizontal: 10),
                child: OracleUI.premiumGlassCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                          child: CachedNetworkImage(
                            imageUrl: exp.imageUrl, 
                            fit: BoxFit.cover, 
                            width: double.infinity,
                            placeholder: (context, url) => Container(color: Colors.white.withValues(alpha: 0.05)),
                            errorWidget: (context, url, error) => const Icon(Icons.broken_image_outlined, color: Colors.white24),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                exp.name.toUpperCase(),
                                style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary(context), letterSpacing: 0.5),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.person_pin_rounded, size: 10, color: Theme.of(context).colorScheme.secondary),
                                  const SizedBox(width: 4),
                                  Text(
                                    exp.hostName.toUpperCase(),
                                    style: GoogleFonts.inter(fontSize: 9, color: AppTheme.textSecondary(context), fontWeight: FontWeight.w600, letterSpacing: 0.5),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              OracleUI.neonText(
                                "LKR ${exp.price}",
                                style: GoogleFonts.outfit(fontSize: 11, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w900),
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
          );
        },
      ),
    );
  }

  Widget _buildListView(AppLocalizations l10n) {
    if (_filteredList.isEmpty) {
      return SliverFillRemaining(
        child: OracleUI.staggeredEntrance(
          index: 0,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                OracleUI.premiumGlassCard(
                  padding: const EdgeInsets.all(32),
                  child: Icon(Icons.search_off_rounded, size: 64, color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)),
                ),
                const SizedBox(height: 32),
                OracleUI.neonText(
                  l10n.noMatchesNearby.toUpperCase(), 
                  style: GoogleFonts.outfit(
                    fontSize: 20, 
                    fontWeight: FontWeight.bold, 
                    color: AppTheme.textPrimary(context),
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    l10n.tryIncreasingDistance, 
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: AppTheme.textSecondary(context), 
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                TextButton.icon(
                  onPressed: () => setState(() {
                    _selectedFilter = "all";
                    _maxDistance = 100.0;
                    _applyFilter();
                  }),
                  icon: Icon(Icons.refresh_rounded, color: Theme.of(context).colorScheme.primary),
                  label: Text("RESET ALL FILTERS", style: GoogleFonts.outfit(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold, letterSpacing: 1)),
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final place = _filteredList[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: OracleUI.staggeredEntrance(
                index: index,
                child: _buildListCard(place, l10n),
              ),
            );
          },
          childCount: _filteredList.length,
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary, size: 18),
          const SizedBox(width: 12),
          OracleUI.neonText(
            title.toUpperCase(), 
            style: GoogleFonts.outfit(
              fontSize: 14, 
              fontWeight: FontWeight.bold, 
              color: AppTheme.textPrimary(context),
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideX(begin: -0.1);
  }

  Widget _buildHorizontalCards(List<DiscoveryPlace> places, AppLocalizations l10n, {bool isOracle = false, bool isAR = false}) {
    return SizedBox(
      height: (isOracle || isAR) ? 300 : 260,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: places.length,
        itemBuilder: (context, index) {
          final place = places[index];
          return OracleUI.staggeredEntrance(
            index: index,
            child: GestureDetector(
              onTap: () => _openPlaceDetails(place),
              child: Container(
                width: (isOracle || isAR) ? 260 : 180,
                margin: const EdgeInsets.symmetric(horizontal: 10),
                child: OracleUI.premiumGlassCard(
                  padding: EdgeInsets.zero,
                  showGlow: isOracle || isAR,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 5,
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                                child: CachedNetworkImage(
                                  imageUrl: place.imageUrl.isNotEmpty ? place.imageUrl : ImageUtils.getPlaceholderImage(place.category, place.name),
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(color: Colors.white.withValues(alpha: 0.05)),
                                  errorWidget: (context, url, error) => const Icon(Icons.broken_image_outlined, color: Colors.white24),
                                ),
                              ),
                            ),
                            if (place.arSupported)
                              Positioned(
                                top: 12,
                                right: 12,
                                child: OracleUI.glassContainer(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  radius: BorderRadius.circular(12),
                                  opacity: 0.2,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.view_in_ar_rounded, color: Theme.of(context).colorScheme.secondary, size: 14),
                                      const SizedBox(width: 6),
                                      Text(
                                        "AR",
                                        style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: isOracle ? 6 : 4,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                place.name.toUpperCase(),
                                style: GoogleFonts.outfit(
                                  fontSize: isOracle ? 16 : 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary(context),
                                  letterSpacing: 0.5,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(Icons.location_on_rounded, size: 12, color: Theme.of(context).colorScheme.primary),
                                  const SizedBox(width: 4),
                                  Text(
                                    "${place.distanceKm.toStringAsFixed(1)} KM",
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      color: AppTheme.textSecondary(context),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Spacer(),
                                  Flexible(
                                    child: OracleUI.neonText(
                                      place.ticketRange.toUpperCase(),
                                      style: GoogleFonts.outfit(
                                        fontSize: 10,
                                        color: Theme.of(context).colorScheme.primary,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (isOracle && place.aiReason.isNotEmpty) ...[
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)),
                                  ),
                                  child: Text(
                                    place.aiReason,
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontStyle: FontStyle.italic,
                                      color: AppTheme.textPrimary(context).withValues(alpha: 0.8),
                                      height: 1.4,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ]
                            ],
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildListCard(DiscoveryPlace place, AppLocalizations l10n) {
    return OracleUI.premiumGlassCard(
      padding: EdgeInsets.zero,
      radius: BorderRadius.circular(24),
      showGlow: place.arSupported,
      child: InkWell(
        onTap: () => _openPlaceDetails(place),
        borderRadius: BorderRadius.circular(24),
        child: Row(
          children: [
            // Image Left
            SizedBox(
              width: 130,
              height: 140,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  bottomLeft: Radius.circular(24),
                ),
                child: CachedNetworkImage(
                  imageUrl: place.imageUrl.isNotEmpty ? place.imageUrl : ImageUtils.getPlaceholderImage(place.category, place.name),
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(color: Colors.white.withValues(alpha: 0.05)),
                  errorWidget: (context, url, error) => const Icon(Icons.broken_image_outlined, color: Colors.white24),
                ),
              ),
            ),
            // Content Right
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      place.name.toUpperCase(),
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary(context),
                        letterSpacing: 0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      L10nUtils.getLocalizedCategory(context, place.category).toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                        color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.8),
                      ),
                    ),
                    if (place.arSupported) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.view_in_ar_rounded, size: 10, color: Theme.of(context).colorScheme.secondary),
                            const SizedBox(width: 6),
                            Text(
                              "HERITAGE AR",
                              style: GoogleFonts.outfit(
                                color: Theme.of(context).colorScheme.secondary,
                                fontWeight: FontWeight.bold,
                                fontSize: 9,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const Spacer(),
                    Row(
                      children: [
                        Icon(Icons.location_on_rounded, size: 14, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 4),
                        Text(
                          "${place.distanceKm.toStringAsFixed(1)} KM",
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textSecondary(context),
                          ),
                        ),
                        const Spacer(),
                        Flexible(
                          child: OracleUI.neonText(
                            place.ticketRange.toUpperCase(),
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: Theme.of(context).colorScheme.primary,
                            ),
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
    );
  }
}
