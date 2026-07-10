class GuideClientNote {
  final String noteId;
  final String guideId;
  final String touristId;
  final String note;
  final DateTime createdAt;
  final DateTime updatedAt;

  GuideClientNote({
    required this.noteId,
    required this.guideId,
    required this.touristId,
    required this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'noteId': noteId,
    'guideId': guideId,
    'touristId': touristId,
    'note': note,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory GuideClientNote.fromJson(Map<String, dynamic> json) => GuideClientNote(
    noteId: json['noteId'],
    guideId: json['guideId'],
    touristId: json['touristId'],
    note: json['note'] ?? '',
    createdAt: DateTime.parse(json['createdAt']),
    updatedAt: DateTime.parse(json['updatedAt']),
  );
}
