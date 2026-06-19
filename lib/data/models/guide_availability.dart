class GuideAvailability {
  final String listingId;
  final List<DateTime> blackoutDates;
  final List<RecurringSlot> recurringSlots;
  final bool isManualUnavailable;
  final Map<String, String> customNotes; // e.g., "Unavailable for Vesak"

  GuideAvailability({
    required this.listingId,
    this.blackoutDates = const [],
    this.recurringSlots = const [],
    this.isManualUnavailable = false,
    this.customNotes = const {},
  });

  Map<String, dynamic> toJson() => {
    'listingId': listingId,
    'blackoutDates': blackoutDates.map((d) => d.toIso8601String()).toList(),
    'recurringSlots': recurringSlots.map((s) => s.toJson()).toList(),
    'isManualUnavailable': isManualUnavailable,
    'customNotes': customNotes,
  };

  factory GuideAvailability.fromJson(Map<String, dynamic> json) => GuideAvailability(
    listingId: json['listingId'],
    blackoutDates: (json['blackoutDates'] as List<dynamic>?)
        ?.map((d) => DateTime.parse(d))
        .toList() ?? [],
    recurringSlots: (json['recurringSlots'] as List<dynamic>?)
        ?.map((s) => RecurringSlot.fromJson(s))
        .toList() ?? [],
    isManualUnavailable: json['isManualUnavailable'] ?? false,
    customNotes: Map<String, String>.from(json['customNotes'] ?? {}),
  );
}

class RecurringSlot {
  final int dayOfWeek; // 1 (Mon) - 7 (Sun)
  final String startTime; // "HH:mm"
  final String endTime; // "HH:mm"

  RecurringSlot({
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
  });

  Map<String, dynamic> toJson() => {
    'dayOfWeek': dayOfWeek,
    'startTime': startTime,
    'endTime': endTime,
  };

  factory RecurringSlot.fromJson(Map<String, dynamic> json) => RecurringSlot(
    dayOfWeek: json['dayOfWeek'],
    startTime: json['startTime'],
    endTime: json['endTime'],
  );
}
