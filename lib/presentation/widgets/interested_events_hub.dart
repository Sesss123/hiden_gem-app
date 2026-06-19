import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../data/datasources/trip_cache_service.dart';
import '../../data/models/event_model.dart';
import '../screens/event_calendar_screen.dart';
import 'skeleton_loaders.dart';

class InterestedEventsHub extends StatefulWidget {
  const InterestedEventsHub({super.key});

  @override
  State<InterestedEventsHub> createState() => _InterestedEventsHubState();
}

class _InterestedEventsHubState extends State<InterestedEventsHub> {
  List<EventModel> _interestedEvents = [];
  bool _isLoadingEvents = true;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoadingEvents = true);
    await Future.delayed(const Duration(milliseconds: 600));
    final rawEvents = TripCacheService.getInterestedEvents();
    if (mounted) {
      setState(() {
        _interestedEvents = rawEvents.map((e) => EventModel.fromJson(json.decode(e))).toList();
        _isLoadingEvents = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "MY INTERESTED EVENTS",
              style: AppTheme.labelStyle(context),
            ),
            if (_interestedEvents.isNotEmpty)
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const EventCalendarScreen()),
                ),
                child: Text(
                  "VIEW CALENDAR",
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.modernGreen(context),
                    letterSpacing: 1,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (_isLoadingEvents)
          _buildHubShimmer()
        else if (_interestedEvents.isEmpty)
          _buildEmptyEventsState()
        else
          SizedBox(
            height: 160,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              itemCount: _interestedEvents.length,
              separatorBuilder: (_, __) => const SizedBox(width: 16),
              itemBuilder: (context, index) {
                return _buildMiniEventCard(_interestedEvents[index]);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildHubShimmer() {
    return SizedBox(
      height: 160,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.only(right: 16),
          child: ModernTracerShimmer(
            child: Container(
              width: 140,
              decoration: BoxDecoration(
                color: AppTheme.textSecondary(context).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyEventsState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: AppTheme.glassDecoration(context, opacity: 0.05),
      child: Column(
        children: [
          Icon(Icons.event_available_outlined, color: AppTheme.textSecondary(context).withValues(alpha: 0.2), size: 40),
          const SizedBox(height: 12),
          Text(
            "No events pinned yet",
            style: GoogleFonts.inter(color: AppTheme.textSecondary(context), fontSize: 13),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const EventCalendarScreen()),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppTheme.modernGreen(context).withValues(alpha: 0.5)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              "EXPLORE EVENTS",
              style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.modernGreen(context)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniEventCard(EventModel event) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const EventCalendarScreen()),
      ),
      child: Container(
        width: 150,
        decoration: AppTheme.glassDecoration(context, opacity: 0.1).copyWith(
          border: Border.all(color: event.categoryColor.withValues(alpha: 0.3)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: event.categoryColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                event.category.name.toUpperCase(),
                style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.bold, color: event.categoryColor),
              ),
            ),
            const Spacer(),
            Text(
              event.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary(context)),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 10, color: AppTheme.textSecondary(context).withValues(alpha: 0.6)),
                const SizedBox(width: 4),
                Text(
                  event.date ?? "SOON",
                  style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textSecondary(context).withValues(alpha: 0.6)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
