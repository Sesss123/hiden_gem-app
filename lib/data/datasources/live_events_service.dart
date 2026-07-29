import 'package:url_launcher/url_launcher.dart';
import '../models/event_model.dart';
import 'sri_lanka_event_dataset.dart';
import '../../core/utils/secure_logger.dart';

class LiveEventsService {
  /// Returns a list of structured events happening during a specific trip window
  static List<EventModel> getEventsForTrip(DateTime startDate, int durationDays, {List<Map<String, dynamic>>? dynamicEvents}) {
    DateTime endDate = startDate.add(Duration(days: durationDays));
    List<EventModel> results = [];
    
    final sourceEvents = dynamicEvents ?? SriLankaEvents.events;

    for (var event in sourceEvents) {
      // API sends "date"/"start"/"end" as keys that are present but null for
      // an admin-created event with no schedule set (nullable in validation
      // — see EventController::validateEvent()). containsKey() alone is true
      // for a null value too, so event["date"].split() used to throw, get
      // silently swallowed by the catch block below, and drop the event from
      // every day's view — an event with no date became invisible everywhere,
      // not "always visible" as an unscheduled/ongoing event arguably should be.
      final hasDate = event.containsKey("date") && event["date"] != null;
      final hasRange = event.containsKey("start") && event["start"] != null &&
          event.containsKey("end") && event["end"] != null;

      if (hasDate) {
        // Single Day Event
        final parts = event["date"].split("-");
        try {
          DateTime eventDate = DateTime(startDate.year, int.parse(parts[0]), int.parse(parts[1]));

          // Check if event falls within trip dates (inclusive padding)
          if ((eventDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
              eventDate.isBefore(endDate.add(const Duration(days: 1)))) || isSameDay(eventDate, startDate) || isSameDay(eventDate, endDate)) {
            results.add(EventModel.fromJson(event));
          }
        } catch (e) {
          SecureLogger.warning('Failed parsing single day event date ${event["date"]}: $e');
        }
      } else if (hasRange) {
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
        } catch (e) {
          SecureLogger.warning('Failed parsing multi-day event range: $e');
        }
      } else {
        // No schedule set at all — treat as always-on/ongoing rather than
        // invisible on every day, so an admin can publish an event before
        // its dates are finalized without it silently vanishing.
        results.add(EventModel.fromJson(event));
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
    } catch (e) {
      SecureLogger.warning('Failed to get events for dates $startDateStr: $e');
      return [];
    }
  }

  /// Returns today's active events.
  /// Pass [dynamicEvents] (from DynamicContentService.fetchEvents()) to use
  /// live backend data instead of the static fallback dataset.
  static List<EventModel> getTodayEvents({List<Map<String, dynamic>>? dynamicEvents}) {
    DateTime today = DateTime.now();
    return getEventsForTrip(today, 1, dynamicEvents: dynamicEvents);
  }

  /// Returns events happening in the coming week (Phase 3: Coming Up Soon)
  static List<EventModel> getUpcomingEvents({int limit = 5, List<Map<String, dynamic>>? dynamicEvents}) {
    DateTime today = DateTime.now();
    final allUpcoming = getEventsForTrip(today, 7, dynamicEvents: dynamicEvents);
    allUpcoming.sort((a, b) {
      if (a.date != null && b.date != null) return a.date!.compareTo(b.date!);
      return 0;
    });
    return allUpcoming.take(limit).toList();
  }

  /// Returns events personalized for the user (Phase 3: Top Picks)
  static List<EventModel> getPersonalizedEvents(String userVibe, List<String> userInterests, {int limit = 3, List<Map<String, dynamic>>? dynamicEvents}) {
    final allEvents = (dynamicEvents ?? SriLankaEvents.events).map((e) => EventModel.fromJson(e)).toList();
    
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
