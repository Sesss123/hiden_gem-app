import 'package:url_launcher/url_launcher.dart';
import '../models/event_model.dart';
import 'sri_lanka_event_dataset.dart';

class LiveEventsService {
  /// Returns a list of structured events happening during a specific trip window
  static List<EventModel> getEventsForTrip(DateTime startDate, int durationDays, {List<Map<String, dynamic>>? dynamicEvents}) {
    DateTime endDate = startDate.add(Duration(days: durationDays));
    List<EventModel> results = [];
    
    final sourceEvents = dynamicEvents ?? SriLankaEvents.events;

    for (var event in sourceEvents) {
      if (event.containsKey("date")) {
        // Single Day Event
        final parts = event["date"].split("-");
        try {
          DateTime eventDate = DateTime(startDate.year, int.parse(parts[0]), int.parse(parts[1]));

          // Check if event falls within trip dates (inclusive padding)
          if ((eventDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
              eventDate.isBefore(endDate.add(const Duration(days: 1)))) || isSameDay(eventDate, startDate) || isSameDay(eventDate, endDate)) {
            results.add(EventModel.fromJson(event));
          }
        } catch (_) {}
      } else if (event.containsKey("start") && event.containsKey("end")) {
        // Multi-Day or Seasonal Event
        try {
          final s = event["start"].split("-");
          final e = event["end"].split("-");

          DateTime eventStart = DateTime(startDate.year, int.parse(s[0]), int.parse(s[1]));
          DateTime eventEnd = DateTime(startDate.year, int.parse(e[0]), int.parse(e[1]));

          // Handle seasons crossing the year mark
          if (eventEnd.isBefore(eventStart)) {
            eventEnd = eventEnd.add(const Duration(days: 365));
          }

          bool overlap = startDate.isBefore(eventEnd.add(const Duration(days: 1))) && 
                         endDate.isAfter(eventStart.subtract(const Duration(days: 1)));
          
          if (overlap) {
            results.add(EventModel.fromJson(event));
          }
        } catch (_) {}
      }
    }

    return results;
  }

  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Convenience wrapper for AI payload injection specifically
  static List<String> getEventsForDates(String startDateStr, int durationDays, {List<Map<String, dynamic>>? dynamicEvents}) {
    try {
      final start = DateTime.parse(startDateStr);
      final events = getEventsForTrip(start, durationDays, dynamicEvents: dynamicEvents);
      
      return events.map((e) {
        String base = "${e.name} (${e.category.name})";
        if (e.location != null) base += " in ${e.location}";
        base += ": ${e.description}";
        return base;
      }).toList();
    } catch (_) {
      return [];
    }
  }

  /// Returns today's active events
  static List<EventModel> getTodayEvents() {
    DateTime today = DateTime.now();
    return getEventsForTrip(today, 1);
  }

  /// Returns events happening in the coming week (Phase 3: Coming Up Soon)
  static List<EventModel> getUpcomingEvents({int limit = 5}) {
    DateTime today = DateTime.now();
    final allUpcoming = getEventsForTrip(today, 7);
    allUpcoming.sort((a, b) {
      if (a.date != null && b.date != null) return a.date!.compareTo(b.date!);
      return 0;
    });
    return allUpcoming.take(limit).toList();
  }

  /// Returns events personalized for the user (Phase 3: Top Picks)
  static List<EventModel> getPersonalizedEvents(String userVibe, List<String> userInterests, {int limit = 3}) {
    final allEvents = SriLankaEvents.events.map((e) => EventModel.fromJson(e)).toList();
    
    // Simple scoring algorithm
    List<({EventModel event, double score})> scoredEvents = [];
    
    for (var event in allEvents) {
      double score = 0;
      
      // Match category to vibe
      if (event.category.name == userVibe.toLowerCase()) score += 5;
      
      // Match tags to interests
      for (var tag in event.tags) {
        if (userInterests.any((interest) => interest.toLowerCase().contains(tag.toLowerCase()))) {
          score += 2;
        }
      }
      
      // Match music genre for party vibe
      if (userVibe.toLowerCase() == 'party') {
        for (var artist in event.lineup) {
          if (artist.musicGenre != null && 
              userInterests.any((i) => i.toLowerCase().contains(artist.musicGenre!.toLowerCase()))) {
            score += 3;
          }
        }
      }

      if (score > 0) {
        scoredEvents.add((event: event, score: score));
      }
    }

    scoredEvents.sort((a, b) => b.score.compareTo(a.score));
    return scoredEvents.map((e) => e.event).take(limit).toList();
  }

  /// Launch external ticket booking URL
  static Future<void> launchTicketUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }
}
