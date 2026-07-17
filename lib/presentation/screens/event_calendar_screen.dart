import 'dart:convert';
import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../core/theme/oracle_ui_system.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/monsoon_broadcast_service.dart';
import '../../data/datasources/live_events_service.dart';
import '../../data/datasources/dynamic_content_service.dart';
import '../../data/datasources/user_preference_service.dart';
import '../../data/datasources/trip_cache_service.dart';
import '../../data/models/event_model.dart';
import '../widgets/cached_image.dart';
import '../widgets/skeleton_loaders.dart';
import '../widgets/custom_buttons.dart';
import '../../l10n/app_localizations.dart';

class EventCalendarScreen extends StatefulWidget {
  const EventCalendarScreen({super.key});

  @override
  State<EventCalendarScreen> createState() => _EventCalendarScreenState();
}

class _EventCalendarScreenState extends State<EventCalendarScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<EventModel> _selectedEvents = [];
  List<EventModel> _topPicks = [];
  EventCategory? _selectedCategory;
  bool _isLoading = true;
  List<Map<String, dynamic>>? _dynamicEvents;
  final CalendarFormat _calendarFormat = CalendarFormat.month;
  final _userProfile = UserPreferenceService.getProfile();
  final ScreenshotController _screenshotController = ScreenshotController();

  final List<String> _musicGenres = [
    "Techno", "House", "Acoustic", "Jazz", "Traditional", "Rock", "Electronic"
  ];
  StreamSubscription? _broadcastSub;
  List<String> _selectedMusicPreferences = [];

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _selectedMusicPreferences = List<String>.from(_userProfile.preferredStyles.where((i) => _musicGenres.contains(i)));
    _loadData();
    _broadcastSub = MonsoonBroadcastService().broadcastStream.listen((alert) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.hazardWarningMessage(alert['message'] ?? l10n.extremeWeatherAlertFallback)),
            backgroundColor: AppTheme.colors.redAccent,
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _broadcastSub?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    _dynamicEvents = await DynamicContentService.fetchEvents();
    _updateEvents();
    _topPicks = LiveEventsService.getPersonalizedEvents(
      _userProfile.vibe,
      [..._userProfile.preferredStyles, ..._selectedMusicPreferences],
      dynamicEvents: _dynamicEvents,
    );
    setState(() => _isLoading = false);
  }

  void _updateEvents() {
    final allEvents = LiveEventsService.getEventsForTrip(_selectedDay!, 1, dynamicEvents: _dynamicEvents);
    setState(() {
      if (_selectedCategory == null) {
        _selectedEvents = allEvents;
      } else {
        _selectedEvents = allEvents.where((e) => e.category == _selectedCategory).toList();
      }
    });
  }

  List<EventModel> _getEventsForDay(DateTime day) {
    final events = LiveEventsService.getEventsForTrip(day, 1);
    if (_selectedCategory == null) return events;
    return events.where((e) => e.category == _selectedCategory).toList();
  }

  bool _isRecommended(EventModel event) {
    if (_topPicks.any((p) => p.name == event.name)) return true;
    final vibe = _userProfile.vibe.toLowerCase();
    if (vibe == 'party' || vibe == 'luxury') {
      return event.category == EventCategory.party;
    } else if (vibe == 'explorer' || vibe == 'nature') {
      return event.category == EventCategory.cultural || event.category == EventCategory.festival;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Screenshot(
      controller: _screenshotController,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: AppTheme.colors.transparent,
          automaticallyImplyLeading: false,
          centerTitle: false,
          titleSpacing: 24,
          actions: [
            _circleIconButton(Icons.tune_rounded, _showPreferenceDialog),
            const SizedBox(width: 8),
            _circleIconButton(Icons.ios_share, _shareScreen),
            const SizedBox(width: 20),
          ],
          title: Text(
            AppLocalizations.of(context)!.eventsTitle,
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              color: AppTheme.textPrimary(context),
            ),
          ),
        ),
        body: OracleUI.auraBackground(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildModernCalendar(),
                SizedBox(height: 40),
                
                _buildCategoryFilters(),
                SizedBox(height: 32),
                
                _buildEventList(),
                
                SizedBox(height: 48),
                Text(
                  AppLocalizations.of(context)!.topPicksForYouTitle,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary(context),
                  ),
                ),
                SizedBox(height: 24),
                _buildTopPicksSection(),
                SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _circleIconButton(IconData icon, VoidCallback onTap) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: AppTheme.surfaceMuted(context),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        onPressed: onTap,
        icon: Icon(icon, color: AppTheme.textSecondary(context), size: 17),
      ),
    );
  }

  Widget _buildModernCalendar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceMuted(context),
        borderRadius: BorderRadius.circular(24),
      ),
      child: TableCalendar(
        firstDay: DateTime.utc(2023, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        calendarFormat: _calendarFormat,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
            _updateEvents();
          });
        },
        eventLoader: _getEventsForDay,
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: GoogleFonts.outfit(color: AppTheme.textPrimary(context), fontWeight: FontWeight.w700, fontSize: 15),
          leftChevronIcon: Icon(Icons.chevron_left, color: Theme.of(context).colorScheme.primary),
          rightChevronIcon: Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.primary),
        ),
        calendarStyle: CalendarStyle(
          defaultTextStyle: GoogleFonts.inter(color: AppTheme.textPrimary(context).withValues(alpha: 0.6), fontSize: 13),
          weekendTextStyle: GoogleFonts.inter(color: AppTheme.textSecondary(context).withValues(alpha: 0.5), fontSize: 13),
          selectedDecoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(10),
          ),
          selectedTextStyle: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontWeight: FontWeight.bold),
          todayDecoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3), width: 1),
          ),
          todayTextStyle: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),
          markerDecoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, shape: BoxShape.circle),
          markersMaxCount: 1,
        ),
        calendarBuilders: CalendarBuilders(
          markerBuilder: (context, date, events) {
            if (events.isNotEmpty) {
              return Positioned(
                bottom: 6,
                child: Container(
                  width: 4, height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5), blurRadius: 4, spreadRadius: 1)
                    ],
                  ),
                ),
              );
            }
            return null;
          },
        ),
      ),
    ).animate().fadeIn(duration: 600.ms).scale(begin: const Offset(0.95, 0.95));
  }

  Widget _buildCategoryFilters() {
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      height: 46,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: [
          _filterChip(l10n.categoryAllFilter, null, Icons.auto_awesome_mosaic_rounded),
          ...EventCategory.values.map((cat) => _filterChip(_categoryLabel(cat, l10n), cat, _getCategoryIcon(cat))),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(EventCategory category) {
    switch (category) {
      case EventCategory.beach: return Icons.beach_access_rounded;
      case EventCategory.cultural: return Icons.museum_rounded;
      case EventCategory.religious: return Icons.temple_buddhist_rounded;
      case EventCategory.sports: return Icons.sports_kabaddi_rounded;
      case EventCategory.seasonal: return Icons.festival_rounded;
      case EventCategory.festival: return Icons.celebration_rounded;
      case EventCategory.party: return Icons.nightlife_rounded;
    }
  }

  Widget _filterChip(String label, EventCategory? category, IconData icon) {
    final isSelected = _selectedCategory == category;
    return Padding(
      padding: EdgeInsets.only(right: 12),
      child: OracleUI.glassChip(
        context: context,
        label: label,
        icon: icon,
        isSelected: isSelected,
        onTap: () {
          HapticFeedback.lightImpact();
          setState(() {
            _selectedCategory = category;
            _updateEvents();
          });
        },
      ),
    );
  }

  String _categoryLabel(EventCategory category, AppLocalizations l10n) {
    switch (category) {
      case EventCategory.beach: return l10n.categoryBeach;
      case EventCategory.cultural: return l10n.categoryCultural;
      case EventCategory.religious: return l10n.categoryReligious;
      case EventCategory.sports: return l10n.categorySports;
      case EventCategory.seasonal: return l10n.categorySeasonal;
      case EventCategory.festival: return l10n.categoryFestival;
      case EventCategory.party: return l10n.categoryParty;
    }
  }

  Widget _buildEventList() {
    if (_isLoading) return _buildSkeletonList();
    if (_selectedEvents.isEmpty) return _buildEmptyState();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.availableEventsTitle,
          style: GoogleFonts.outfit(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary(context),
          ),
        ),
        SizedBox(height: 20),
        ..._selectedEvents.asMap().entries.map((entry) {
          final index = entry.key;
          final event = entry.value;
          return Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: _buildEventCard(event)
                .animate()
                .fadeIn(duration: 400.ms, delay: (index * 100).ms)
                .slideX(begin: 0.05),
          );
        }),
      ],
    );
  }

  Widget _buildEventCard(EventModel event) {
    final isPinned = TripCacheService.isEventPinned(event.name);
    final isRecommended = _isRecommended(event);

    return GestureDetector(
      onTap: () => _showEventDetails(event),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: AppTheme.colors.black.withValues(alpha: 0.06), blurRadius: 18, offset: const Offset(0, 8)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: event.categoryColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(event.categoryIcon, color: event.categoryColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(color: AppTheme.textPrimary(context), fontWeight: FontWeight.w700, fontSize: 13)
                  ),
                  const SizedBox(height: 2),
                  Text(
                    AppLocalizations.of(context)!.eventLocationCategoryLabel(event.location ?? '', _categoryLabel(event.category, AppLocalizations.of(context)!)),
                    style: GoogleFonts.inter(color: AppTheme.textSecondary(context), fontSize: 11, fontWeight: FontWeight.w500)
                  ),
                ],
              ),
            ),
            if (isRecommended && !isPinned)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Icon(Icons.auto_awesome_rounded, color: Theme.of(context).colorScheme.primary, size: 14),
              ),
            if (isPinned)
              Icon(Icons.bookmark_rounded, color: Theme.of(context).colorScheme.primary, size: 18)
            else
              Icon(Icons.chevron_right_rounded, color: AppTheme.textSecondary(context).withValues(alpha: 0.5), size: 18),
          ],
        ),
      ),
    );
  }

  void _showEventDetails(EventModel event) {
    final isPinned = TripCacheService.isEventPinned(event.name);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, scrollController) => OracleUI.glassContainer(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
          borderColor: Theme.of(context).dividerColor.withValues(alpha: 0.1),
          padding: EdgeInsets.zero,
          child: ListView(
            controller: scrollController,
            padding: EdgeInsets.all(32),
            children: [
              Center(
                child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Theme.of(context).dividerColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(2))),
              ),
              SizedBox(height: 32),
              OracleUI.glassContainer(
                height: 200, width: double.infinity,
                borderRadius: BorderRadius.circular(32),
                borderColor: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                padding: EdgeInsets.zero,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedImage(url: "https://images.unsplash.com/photo-1514525253361-bee8a4874051?w=800&q=80", fit: BoxFit.cover),
                      Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [AppTheme.colors.transparent, AppTheme.colors.black.withValues(alpha: 0.6)]))),
                      Positioned(
                        bottom: 24, left: 24,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            OracleUI.glassChip(context: context, label: _categoryLabel(event.category, AppLocalizations.of(context)!).toUpperCase(), isSelected: true),
                            SizedBox(height: 12),
                            OracleUI.neonText(event.name.toUpperCase(), style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w900, color: AppTheme.colors.white)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 32),
              Text(
                AppLocalizations.of(context)!.temporalDataLabel,
                style: GoogleFonts.inter(color: AppTheme.textSecondary(context), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 2)
              ),
              SizedBox(height: 12),
              Text(
                event.description,
                 style: GoogleFonts.inter(color: AppTheme.textPrimary(context).withValues(alpha: 0.8), fontSize: 15, height: 1.6),
              ),
              SizedBox(height: 32),
              if (event.ticketUrl != null)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => LiveEventsService.launchTicketUrl(event.ticketUrl!),
                    icon: Icon(Icons.confirmation_num_outlined, size: 18),
                    label: Text(AppLocalizations.of(context)!.acquirePassButton, style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: AppTheme.colors.black,
                      padding: EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 0,
                    ),
                  ),
                ),
              SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _togglePin(event),
                      icon: Icon(isPinned ? Icons.bookmark_rounded : Icons.bookmark_border_rounded, size: 18),
                      label: Text(isPinned ? AppLocalizations.of(context)!.unpinButton : AppLocalizations.of(context)!.pinToHudButton),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.textPrimary(context),
                        side: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  OracleUI.glassContainer(
                    padding: EdgeInsets.all(12),
                    borderRadius: BorderRadius.circular(20),
                    borderColor: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                    child: IconButton(
                      icon: Icon(Icons.map_outlined, color: AppTheme.textPrimary(context)),
                      onPressed: () => _openInMaps(event.lat ?? 0, event.lng ?? 0, event.name),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopPicksSection() {
    if (_isLoading) return _buildSkeletonTopPicks();
    if (_topPicks.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 240,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _topPicks.length,
        itemBuilder: (context, index) {
          final event = _topPicks[index];
          return Container(
            width: 200,
            margin: EdgeInsets.only(right: 20),
            child: GestureDetector(
              onTap: () => _showEventDetails(event),
              child: OracleUI.glassContainer(
                padding: EdgeInsets.all(4),
                borderRadius: BorderRadius.circular(28),
                borderColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: CachedImage(
                          url: "https://images.unsplash.com/photo-1533174072545-7a4b6ad7a6c3?w=400&q=80",
                          fit: BoxFit.cover, width: double.infinity,
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.name,
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(color: AppTheme.textPrimary(context), fontSize: 13, fontWeight: FontWeight.w700)
                          ),
                          SizedBox(height: 4),
                          Text(
                            AppLocalizations.of(context)!.recommendedForYouLabel,
                            style: GoogleFonts.inter(color: Theme.of(context).colorScheme.primary, fontSize: 10, fontWeight: FontWeight.w600)
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ).animate().fadeIn(delay: (index * 200).ms, duration: 600.ms).slideX(begin: 0.2);
        },
      ),
    );
  }

  Widget _buildSkeletonList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(3, (index) => Padding(
        padding: EdgeInsets.only(bottom: 16),
        child: ModernTracerShimmer(
          child: Container(
            height: 90,
            decoration: BoxDecoration(color: Theme.of(context).dividerColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(24)),
          ),
        ),
      )),
    );
  }

  Widget _buildSkeletonTopPicks() {
    return SizedBox(
      height: 240,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        itemBuilder: (_, __) => Padding(
          padding: EdgeInsets.only(right: 20),
          child: ModernTracerShimmer(
            child: Container(
              width: 200,
              decoration: BoxDecoration(color: Theme.of(context).dividerColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(28)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return OracleUI.glassContainer(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 40),
      borderRadius: BorderRadius.circular(32),
      child: Column(
        children: [
          Icon(Icons.event_busy, color: AppTheme.textSecondary(context).withValues(alpha: 0.3), size: 40),
          SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.noEventsOnDayMessage,
            style: GoogleFonts.inter(color: AppTheme.textSecondary(context), fontSize: 12, fontWeight: FontWeight.w600)
          ),
        ],
      ),
    );
  }

  void _showPreferenceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.colors.transparent,
      isScrollControlled: true,
      barrierColor: AppTheme.colors.black.withValues(alpha: 0.7),
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: StatefulBuilder(
          builder: (context, setModalState) => OracleUI.glassContainer(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
            borderColor: Theme.of(context).dividerColor.withValues(alpha: 0.2),
            padding: EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4, 
                    decoration: BoxDecoration(color: Theme.of(context).dividerColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(2))
                  ),
                ),
                SizedBox(height: 24),
                Text(
                  AppLocalizations.of(context)!.musicPreferencesTitle,
                  style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary(context), letterSpacing: -0.3),
                ),
                SizedBox(height: 6),
                Text(
                  AppLocalizations.of(context)!.fineTuneOracleMessage,
                  style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary(context)),
                ),
                SizedBox(height: 24),
                Wrap(
                  spacing: 12, runSpacing: 12,
                  children: _musicGenres.map((genre) {
                    final isSelected = _selectedMusicPreferences.contains(genre);
                    return OracleUI.glassChip(
                      context: context,
                      label: genre,
                      isSelected: isSelected,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setModalState(() {
                          if (isSelected) {
                            _selectedMusicPreferences.remove(genre);
                          } else {
                            _selectedMusicPreferences.add(genre);
                          }
                        });
                      },
                    );
                  }).toList(),
                ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),
                SizedBox(height: 32),
                PrimaryButton(
                  label: AppLocalizations.of(context)!.syncPreferencesButton,
                  onPressed: () { _loadData(); Navigator.pop(context); },
                ),
                SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openInMaps(double lat, double lng, String label) async {
    final url = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _togglePin(EventModel event) async {
    await TripCacheService.toggleInterestedEvent(event.name, json.encode(event.toJson()));
    if (mounted) setState(() {});
  }

  Future<void> _shareScreen() async {
    try {
      final Uint8List? image = await _screenshotController.capture();
      if (image != null) {
        final directory = await getApplicationDocumentsDirectory();
        final imagePath = await File('${directory.path}/temporal_oracle.png').create();
        await imagePath.writeAsBytes(image);
        await SharePlus.instance.share(ShareParams(files: [XFile(imagePath.path)], text: "Consulting the Temporal Oracle... 🇱🇰🌌"));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.failedToShareTimelineMessage(e.toString())),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}
