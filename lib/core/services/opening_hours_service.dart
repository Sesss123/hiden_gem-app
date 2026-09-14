import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum OpenStatus {
  open,
  closingSoon,
  closed,
  alwaysOpen,
  unknown,
}

class StructuredOpeningHours {
  final OpenStatus status;
  final String badgeText;
  final String detailText;
  final String? holidayNote;
  final String? temporaryClosureNote;
  final String rawHours;
  final Color badgeColor;

  const StructuredOpeningHours({
    required this.status,
    required this.badgeText,
    required this.detailText,
    this.holidayNote,
    this.temporaryClosureNote,
    required this.rawHours,
    required this.badgeColor,
  });

  bool get isOpen =>
      status == OpenStatus.open ||
      status == OpenStatus.closingSoon ||
      status == OpenStatus.alwaysOpen;

  String get statusLabel => badgeText;
  String get hoursToday => rawHours;
  String get closingOrOpeningTime => detailText;
  String? get closureReason => temporaryClosureNote;
  String? get poyaNotice => holidayNote;
}

/// Robust, pure on-device parser for Sri Lankan heritage sites and attractions opening hours.
class OpeningHoursService {
  static StructuredOpeningHours evaluate(
    String? rawHours, {
    Map<String, dynamic> weeklyHours = const {},
    bool temporarilyClosed = false,
    String? closureNote,
    String? closureUntil,
    String? holidayHoursNote,
    String? monsoonNote,
    List<String>? riskTags,
    String? description,
    DateTime? currentTime,
  }) {
    final instantUtc = (currentTime ?? DateTime.now()).toUtc();
    final sriLankaNow = instantUtc.add(const Duration(hours: 5, minutes: 30));
    final until = closureUntil == null || closureUntil.isEmpty
        ? null
        : DateTime.tryParse(closureUntil)?.toUtc();
    final closureActive = temporarilyClosed &&
        (until == null || until.isAfter(instantUtc));
    if (closureActive) {
      final sriLankaUntil = until?.add(const Duration(hours: 5, minutes: 30));
      return StructuredOpeningHours(
        status: OpenStatus.closed,
        badgeText: 'Temporarily Closed',
        detailText: until == null
            ? 'Reopening time not announced'
            : 'Closed until ${sriLankaUntil!.year}-${sriLankaUntil.month.toString().padLeft(2, '0')}-${sriLankaUntil.day.toString().padLeft(2, '0')} ${_formatTimeOfDay(TimeOfDay(hour: sriLankaUntil.hour, minute: sriLankaUntil.minute))} (Sri Lanka time)',
        holidayNote: holidayHoursNote?.trim().isEmpty == false
            ? holidayHoursNote
            : null,
        temporaryClosureNote: closureNote?.trim().isEmpty == false
            ? closureNote
            : 'Temporary closure reported by the place administrator.',
        rawHours: rawHours?.trim() ?? '',
        badgeColor: AppPalette.error,
      );
    }
    if (weeklyHours.isNotEmpty) {
      return _fromWeeklyHours(
        weeklyHours,
        sriLankaNow,
        holidayHoursNote: holidayHoursNote,
      );
    }
    return parse(
        rawHours,
        monsoonNote: monsoonNote,
        riskTags: riskTags,
        description: description,
        currentTime: sriLankaNow,
      );
  }

  static StructuredOpeningHours _fromWeeklyHours(
    Map<String, dynamic> weekly,
    DateTime now, {
    String? holidayHoursNote,
  }) {
    const keys = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
    final key = keys[now.weekday - 1];
    final row = weekly[key];
    final hours = row is Map ? Map<String, dynamic>.from(row) : const <String, dynamic>{};
    final holiday = holidayHoursNote?.trim().isEmpty == false
        ? holidayHoursNote
        : 'Hours may differ on Sri Lankan public holidays.';

    // An overnight schedule belongs to the previous day (for example,
    // Monday 20:00–02:00 must still be open at 00:30 on Tuesday).
    final previousKey = keys[(now.weekday + 5) % 7];
    final previousRaw = weekly[previousKey];
    final previous = previousRaw is Map
        ? Map<String, dynamic>.from(previousRaw)
        : const <String, dynamic>{};
    final previousOpen = _parse24(previous['open']?.toString());
    final previousClose = _parse24(previous['close']?.toString());
    if (previous['closed'] != true && previousOpen != null && previousClose != null) {
      final previousStart = previousOpen.hour * 60 + previousOpen.minute;
      final previousEnd = previousClose.hour * 60 + previousClose.minute;
      final current = now.hour * 60 + now.minute;
      if (previousEnd <= previousStart && current < previousEnd) {
        final remaining = previousEnd - current;
        final soon = remaining <= 60;
        return StructuredOpeningHours(
          status: soon ? OpenStatus.closingSoon : OpenStatus.open,
          badgeText: soon ? 'Closing Soon' : 'Open Now',
          detailText: 'Closes at ${_formatTimeOfDay(previousClose)}${soon ? ' ($remaining min)' : ''}',
          holidayNote: holiday,
          rawHours: '${_formatTimeOfDay(previousOpen)} – ${_formatTimeOfDay(previousClose)}',
          badgeColor: soon ? AppPalette.warning : AppPalette.success,
        );
      }
    }
    if (hours.isEmpty) {
      return StructuredOpeningHours(
        status: OpenStatus.unknown,
        badgeText: 'Hours Not Listed',
        detailText: 'Today’s hours are not listed; confirm before travelling',
        holidayNote: holiday,
        rawHours: 'Not listed',
        badgeColor: AppTheme.colors.grey,
      );
    }
    if (hours['closed'] == true) {
      return StructuredOpeningHours(
        status: OpenStatus.closed,
        badgeText: 'Closed Today',
        detailText: 'Scheduled weekly closure',
        holidayNote: holiday,
        rawHours: 'Closed',
        badgeColor: AppPalette.error,
      );
    }
    final open = _parse24(hours['open']?.toString());
    final close = _parse24(hours['close']?.toString());
    if (open == null || close == null) {
      return StructuredOpeningHours(
        status: OpenStatus.unknown,
        badgeText: 'Hours Not Confirmed',
        detailText: 'Confirm with the venue before travelling',
        holidayNote: holiday,
        rawHours: 'Not confirmed',
        badgeColor: AppTheme.colors.grey,
      );
    }
    final current = now.hour * 60 + now.minute;
    final start = open.hour * 60 + open.minute;
    final end = close.hour * 60 + close.minute;
    final overnight = end <= start;
    final isOpen = overnight ? (current >= start || current < end) : (current >= start && current < end);
    final remaining = overnight
        ? (current >= start ? 1440 - current + end : end - current)
        : end - current;
    final range = '${_formatTimeOfDay(open)} – ${_formatTimeOfDay(close)}';
    if (isOpen) {
      final soon = remaining <= 60;
      return StructuredOpeningHours(
        status: soon ? OpenStatus.closingSoon : OpenStatus.open,
        badgeText: soon ? 'Closing Soon' : 'Open Now',
        detailText: 'Closes at ${_formatTimeOfDay(close)}${soon ? ' ($remaining min)' : ''}',
        holidayNote: holiday,
        rawHours: range,
        badgeColor: soon ? AppPalette.warning : AppPalette.success,
      );
    }
    return StructuredOpeningHours(
      status: OpenStatus.closed,
      badgeText: 'Closed Now',
      detailText: current < start ? 'Opens at ${_formatTimeOfDay(open)}' : 'Closed for today',
      holidayNote: holiday,
      rawHours: range,
      badgeColor: AppPalette.error,
    );
  }

  static TimeOfDay? _parse24(String? value) {
    final match = RegExp(r'^(\d{2}):(\d{2})$').firstMatch(value ?? '');
    if (match == null) return null;
    final hour = int.tryParse(match.group(1)!);
    final minute = int.tryParse(match.group(2)!);
    if (hour == null || minute == null || hour > 23 || minute > 59) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  static StructuredOpeningHours parse(
    String? rawHours, {
    String? monsoonNote,
    List<String>? riskTags,
    String? description,
    DateTime? currentTime,
  }) {
    final now = currentTime ?? DateTime.now();
    final clean = (rawHours ?? '').trim();

    // 1. Check for temporary closure flags in description, monsoonNote, or riskTags
    String? tempClosure;
    final combinedNotes = '${monsoonNote ?? ''} ${description ?? ''} ${(riskTags ?? []).join(' ')}'.toLowerCase();
    if (combinedNotes.contains('temporarily closed') ||
        combinedNotes.contains('closed for maintenance') ||
        combinedNotes.contains('closed for renovation') ||
        combinedNotes.contains('entry prohibited') ||
        combinedNotes.contains('closed during monsoon')) {
      tempClosure = 'Temporary closure reported: Entry may be restricted or closed for maintenance.';
    }

    // Default holiday notice for Sri Lankan tourist sites (Poya days / public holidays)
    const String holidayNotice = 'Opening hours may differ on Full Moon Poya days and Sri Lankan public holidays.';

    if (clean.isEmpty || clean.toLowerCase() == 'not reported' || clean.toLowerCase() == 'n/a') {
      return StructuredOpeningHours(
        status: OpenStatus.unknown,
        badgeText: 'Hours Not Listed',
        detailText: 'Check with local guides or visitor desk upon arrival',
        holidayNote: holidayNotice,
        temporaryClosureNote: tempClosure,
        rawHours: clean.isNotEmpty ? clean : 'Not reported',
        badgeColor: AppTheme.colors.grey,
      );
    }

    final lower = clean.toLowerCase();

    // 2. Open 24 hours / Anytime / Natural outdoor spots
    if (lower.contains('24') ||
        lower.contains('anytime') ||
        lower.contains('always open') ||
        lower.contains('all day')) {
      return StructuredOpeningHours(
        status: OpenStatus.alwaysOpen,
        badgeText: 'Open 24 Hours',
        detailText: 'Accessible all day and night (Daylight recommended for safety)',
        holidayNote: holidayNotice,
        temporaryClosureNote: tempClosure,
        rawHours: clean,
        badgeColor: AppPalette.success,
      );
    }

    // 3. Fully closed
    if (lower == 'closed' || lower.startsWith('closed on')) {
      return StructuredOpeningHours(
        status: OpenStatus.closed,
        badgeText: 'Closed',
        detailText: clean,
        holidayNote: holidayNotice,
        temporaryClosureNote: tempClosure,
        rawHours: clean,
        badgeColor: AppPalette.error,
      );
    }

    // 4. Try parsing time ranges: e.g. "8:00 AM - 5:00 PM", "06:00 - 18:00", "08:30 AM to 05:00 PM"
    final parsed = _tryParseTimeRange(clean, now);
    if (parsed != null) {
      final openTime = parsed.$1;
      final closeTime = parsed.$2;

      final currentMinutes = now.hour * 60 + now.minute;
      final openMinutes = openTime.hour * 60 + openTime.minute;
      final closeMinutes = closeTime.hour * 60 + closeTime.minute;

      final closeTimeStr = _formatTimeOfDay(closeTime);
      final openTimeStr = _formatTimeOfDay(openTime);

      if (currentMinutes >= openMinutes && currentMinutes < closeMinutes) {
        final minutesLeft = closeMinutes - currentMinutes;
        if (minutesLeft <= 60) {
          return StructuredOpeningHours(
            status: OpenStatus.closingSoon,
            badgeText: 'Closing Soon',
            detailText: 'Closes at $closeTimeStr ($minutesLeft mins left)',
            holidayNote: holidayNotice,
            temporaryClosureNote: tempClosure,
            rawHours: clean,
            badgeColor: AppPalette.warning,
          );
        }

        return StructuredOpeningHours(
          status: OpenStatus.open,
          badgeText: 'Open Now',
          detailText: 'Open until $closeTimeStr today',
          holidayNote: holidayNotice,
          temporaryClosureNote: tempClosure,
          rawHours: clean,
          badgeColor: AppPalette.success,
        );
      } else if (currentMinutes < openMinutes) {
        return StructuredOpeningHours(
          status: OpenStatus.closed,
          badgeText: 'Closed Now',
          detailText: 'Opens today at $openTimeStr',
          holidayNote: holidayNotice,
          temporaryClosureNote: tempClosure,
          rawHours: clean,
          badgeColor: AppPalette.error,
        );
      } else {
        return StructuredOpeningHours(
          status: OpenStatus.closed,
          badgeText: 'Closed for the Day',
          detailText: 'Closed at $closeTimeStr • Opens tomorrow at $openTimeStr',
          holidayNote: holidayNotice,
          temporaryClosureNote: tempClosure,
          rawHours: clean,
          badgeColor: AppPalette.error,
        );
      }
    }

    // Unstructured text cannot safely prove that a venue is currently open.
    return StructuredOpeningHours(
      status: OpenStatus.unknown,
      badgeText: 'Hours Not Confirmed',
      detailText: 'Confirm upon arrival at ticket booth',
      holidayNote: holidayNotice,
      temporaryClosureNote: tempClosure,
      rawHours: clean,
      badgeColor: AppTheme.colors.grey,
    );
  }

  static (TimeOfDay, TimeOfDay)? _tryParseTimeRange(String text, DateTime now) {
    // Splits by '-' or 'to' or '–'
    final separatorRegex = RegExp(r'\s*(?:-|–|to)\s*', caseSensitive: false);
    final parts = text.split(separatorRegex);
    if (parts.length != 2) return null;

    final open = _parseSingleTime(parts[0].trim());
    final close = _parseSingleTime(parts[1].trim());

    if (open != null && close != null) {
      return (open, close);
    }
    return null;
  }

  static TimeOfDay? _parseSingleTime(String str) {
    final clean = str.trim().toUpperCase();

    // 12-hour format: e.g. "8:00 AM", "08:30 PM", "8 AM", "5 PM"
    final regex12 = RegExp(r'^(\d{1,2})(?::(\d{2}))?\s*(AM|PM)$');
    final match12 = regex12.firstMatch(clean);
    if (match12 != null) {
      int hour = int.parse(match12.group(1)!);
      final minute = int.parse(match12.group(2) ?? '0');
      final period = match12.group(3)!;

      if (period == 'PM' && hour < 12) hour += 12;
      if (period == 'AM' && hour == 12) hour = 0;

      return TimeOfDay(hour: hour, minute: minute);
    }

    // 24-hour format: e.g. "08:00", "17:30", "06:00"
    final regex24 = RegExp(r'^(\d{1,2}):(\d{2})$');
    final match24 = regex24.firstMatch(clean);
    if (match24 != null) {
      final hour = int.parse(match24.group(1)!);
      final minute = int.parse(match24.group(2)!);
      if (hour >= 0 && hour <= 23 && minute >= 0 && minute <= 59) {
        return TimeOfDay(hour: hour, minute: minute);
      }
    }

    return null;
  }

  static String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }
}
