import 'dart:convert';
import 'dart:ui';
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
import '../../data/datasources/live_events_service.dart';
import '../../data/datasources/user_preference_service.dart';
import '../../data/datasources/trip_cache_service.dart';
import '../../data/models/event_model.dart';
import '../widgets/skeleton_loaders.dart';

class EventCalendarScreen extends StatefulWidget {
  const EventCalendarScreen({super.key});

  @override
  State<EventCalendarScreen> createState() => _EventCalendarScreenState();
}

class _EventCalendarScreenState extends State<EventCalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<EventModel> _selectedEvents = [];
  List<EventModel> _topPicks = [];
  EventCategory? _selectedCategory;
  bool _isLoading = true;
  final CalendarFormat _calendarFormat = CalendarFormat.month;
  final _userProfile = UserPreferenceService.getProfile();
  final ScreenshotController _screenshotController = ScreenshotController();

  final List<String> _musicGenres = [
    "Techno", "House", "Acoustic", "Jazz", "Traditional", "Rock", "Electronic"
  ];
  List<String> _selectedMusicPreferences = [];

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _selectedMusicPreferences = List<String>.from(_userProfile.preferredStyles.where((i) => _musicGenres.contains(i)));
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    _updateEvents();
    _topPicks = LiveEventsService.getPersonalizedEvents(
      _userProfile.vibe, 
      [..._userProfile.preferredStyles, ..._selectedMusicPreferences],
    );
    setState(() => _isLoading = false);
  }

  void _updateEvents() {
    final allEvents = LiveEventsService.getEventsForTrip(_selectedDay!, 1);
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
    return Screenshot(
      controller: _screenshotController,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textPrimary(context), size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              onPressed: _showPreferenceDialog,
              icon: Icon(Icons.tune_rounded, color: AppTheme.textSecondary(context), size: 20),
            ),
            IconButton(
              onPressed: _shareScreen,
              icon: Icon(Icons.ios_share, color: AppTheme.textSecondary(context), size: 20),
            ),
            SizedBox(width: 8),
          ],
          title: OracleUI.neonText(
            "TEMPORAL ORACLE",
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 4,
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
                OracleUI.neonText(
                  "CELESTIAL ALIGNMENTS",
                  style: GoogleFonts.inter(
                    fontSize: 12, 
                    fontWeight: FontWeight.w900, 
                    letterSpacing: 2, 
                    color: AppTheme.textSecondary(context).withValues(alpha: 0.5)
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

  Widget _buildModernCalendar() {
    return OracleUI.glassContainer(
      padding: EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(32),
      borderColor: Theme.of(context).dividerColor.withValues(alpha: 0.1),
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
          titleTextStyle: GoogleFonts.outfit(color: AppTheme.textPrimary(context), fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1),
          leftChevronIcon: Icon(Icons.chevron_left, color: Theme.of(context).colorScheme.primary),
          rightChevronIcon: Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.primary),
        ),
        calendarStyle: CalendarStyle(
          defaultTextStyle: GoogleFonts.inter(color: AppTheme.textPrimary(context).withValues(alpha: 0.6), fontSize: 13),
          weekendTextStyle: GoogleFonts.inter(color: AppTheme.textSecondary(context).withValues(alpha: 0.5), fontSize: 13),
          selectedDecoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary, 
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
                blurRadius: 10,
                spreadRadius: 2,
              )
            ],
          ),
          selectedTextStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          todayDecoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1), 
            shape: BoxShape.circle,
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
    return SizedBox(
      height: 46,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: [
          _filterChip("ALL", null, Icons.auto_awesome_mosaic_rounded),
          ...EventCategory.values.map((cat) => _filterChip(cat.name.toUpperCase(), cat, _getCategoryIcon(cat))),
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

  Widget _buildEventList() {
    if (_isLoading) return _buildSkeletonList();
    if (_selectedEvents.isEmpty) return _buildEmptyState();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OracleUI.neonText(
          "AVAILABLE EVENTS",
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            color: AppTheme.textSecondary(context).withValues(alpha: 0.5),
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
      child: OracleUI.glassContainer(
        padding: EdgeInsets.all(20),
        borderRadius: BorderRadius.circular(24),
        borderColor: isRecommended 
            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)
            : Theme.of(context).dividerColor.withValues(alpha: 0.1),
        child: Row(
          children: [
            OracleUI.glassContainer(
              padding: EdgeInsets.all(12),
              borderRadius: BorderRadius.circular(16),
              borderColor: event.categoryColor.withValues(alpha: 0.2),
              child: Icon(event.categoryIcon, color: event.categoryColor, size: 20),
            ),
            SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.name.toUpperCase(), 
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(color: AppTheme.textPrimary(context), fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5)
                  ),
                  Text(
                    "${event.location} • ${event.category.name.toUpperCase()}", 
                    style: GoogleFonts.inter(color: AppTheme.textSecondary(context).withValues(alpha: 0.7), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)
                  ),
                ],
              ),
            ),
            if (isPinned)
              Icon(Icons.bookmark_rounded, color: Theme.of(context).colorScheme.primary, size: 18)
            else
              Icon(Icons.chevron_right_rounded, color: AppTheme.textSecondary(context).withValues(alpha: 0.3), size: 20),
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
      backgroundColor: Colors.transparent,
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
                      Image.network("https://images.unsplash.com/photo-1514525253361-bee8a4874051?w=800&q=80", fit: BoxFit.cover),
                      Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withValues(alpha: 0.6)]))),
                      Positioned(
                        bottom: 24, left: 24,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            OracleUI.glassChip(context: context, label: event.category.name.toUpperCase(), isSelected: true),
                            SizedBox(height: 12),
                            OracleUI.neonText(event.name.toUpperCase(), style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 32),
              Text(
                "TEMPORAL DATA", 
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
                    label: Text("ACQUIRE PASS", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.black,
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
                      label: Text(isPinned ? "UNPIN" : "PIN TO HUD"),
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
                        child: Image.network(
                          "https://images.unsplash.com/photo-1533174072545-7a4b6ad7a6c3?w=400&q=80",
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
                            event.name.toUpperCase(), 
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(color: AppTheme.textPrimary(context), fontSize: 13, fontWeight: FontWeight.w900)
                          ),
                          SizedBox(height: 4),
                          Text(
                            "HIGH PROBABILITY", 
                            style: GoogleFonts.inter(color: Theme.of(context).colorScheme.primary, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)
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
            "NO TEMPORAL ALIGNMENTS", 
            style: GoogleFonts.inter(color: AppTheme.textSecondary(context).withValues(alpha: 0.3), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 2)
          ),
        ],
      ),
    );
  }

  void _showPreferenceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: StatefulBuilder(
          builder: (context, setModalState) => OracleUI.glassContainer(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
            borderColor: Theme.of(context).dividerColor.withValues(alpha: 0.2),
            padding: EdgeInsets.all(32),
            opacity: 0.15, 
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
                OracleUI.neonText(
                  "PERSONAL VIBE HUD", 
                  style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.textPrimary(context))
                ),
                SizedBox(height: 12),
                Text(
                  "Fine-tune the temporal oracle with your stylistic preferences.",
                  style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary(context).withValues(alpha: 0.7)),
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
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                        blurRadius: 15,
                        spreadRadius: 2,
                      )
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () { _loadData(); Navigator.pop(context); },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.black,
                      padding: EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 0,
                    ),
                    child: Text("SYNC PREFERENCES", style: GoogleFonts.outfit(fontWeight: FontWeight.w900, letterSpacing: 1)),
                  ),
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
            content: Text("Failed to share timeline: ${e.toString()}"),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}
