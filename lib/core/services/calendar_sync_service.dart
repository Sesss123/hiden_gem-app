import 'package:device_calendar/device_calendar.dart';
import '../utils/secure_logger.dart';

/// One-way, guide-triggered push of accepted/session_ready bookings into the
/// device's native calendar (Google Calendar app on Android, etc). No
/// automatic background sync — the guide taps a button in the inbox and this
/// runs once, so there's no surprise write to their personal calendar.
class CalendarSyncService {
  static const String _calendarName = 'Hidden Gems SL Tours';

  final DeviceCalendarPlugin _plugin = DeviceCalendarPlugin();

  /// Requests permission, finds/creates the app's dedicated calendar, and
  /// writes one event per provided booking. Returns the number of events
  /// successfully written, or throws with a user-facing message on failure.
  Future<int> syncBookings(List<CalendarSyncEntry> entries) async {
    final permission = await _plugin.requestPermissions();
    if (permission.data != true) {
      throw Exception('Calendar permission was not granted.');
    }

    final calendarId = await _findOrCreateCalendar();
    if (calendarId == null) {
      throw Exception('Could not access or create a calendar on this device.');
    }

    var synced = 0;
    for (final entry in entries) {
      final start = TZDateTime.from(entry.start, local);
      final end = TZDateTime.from(entry.end, local);
      final event = Event(
        calendarId,
        title: entry.title,
        description: entry.description,
        start: start,
        end: end,
      );
      final result = await _plugin.createOrUpdateEvent(event);
      if (result?.data != null) {
        synced++;
      } else {
        SecureLogger.warning(
          'Failed to sync booking ${entry.bookingId} to calendar: ${result?.errors.map((e) => e.errorMessage).join(', ')}',
          tag: 'CalendarSync',
        );
      }
    }
    return synced;
  }

  Future<String?> _findOrCreateCalendar() async {
    final existing = await _plugin.retrieveCalendars();
    final match = existing.data?.firstWhere(
      (c) => c.name == _calendarName,
      orElse: () => Calendar(),
    );
    if (match?.id != null) return match!.id;

    final created = await _plugin.createCalendar(_calendarName);
    return created.data;
  }
}

class CalendarSyncEntry {
  final String bookingId;
  final String title;
  final String description;
  final DateTime start;
  final DateTime end;

  CalendarSyncEntry({
    required this.bookingId,
    required this.title,
    required this.description,
    required this.start,
    required this.end,
  });
}
