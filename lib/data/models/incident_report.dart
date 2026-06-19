class IncidentReport {
  final String incidentId;
  final String incidentNumber; // Human-readable (e.g. INC-001)
  final String sessionId;
  final String guideId;
  final String touristId;
  final String reportedBy;
  final String reportedByRole; // "guide", "tourist", "admin"
  final String type; // medical, lost_person, harassment, unsafe_vehicle, unsafe_area, fraud, guide_misconduct, tourist_misconduct, weather, property_loss
  final String severity; // low, medium, high, critical
  final String title;
  final String description;
  final double? lat;
  final double? lng;
  final List<String> attachments;
  final String status; // open, under_review, resolved, escalated, dismissed
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? resolvedAt;
  final String? resolvedBy;
  final String? resolutionNote;
  final String? linkedSosAlertId;
  final String? assignedAdminId;
  final int timelineCount;
  final List<Map<String, dynamic>> timelineEvents; // {type, description, timestamp, userId, role}

  IncidentReport({
    required this.incidentId,
    required this.incidentNumber,
    required this.sessionId,
    required this.guideId,
    required this.touristId,
    required this.reportedBy,
    required this.reportedByRole,
    required this.type,
    required this.severity,
    required this.title,
    required this.description,
    this.lat,
    this.lng,
    this.attachments = const [],
    this.status = 'open',
    required this.createdAt,
    required this.updatedAt,
    this.resolvedAt,
    this.resolvedBy,
    this.resolutionNote,
    this.linkedSosAlertId,
    this.assignedAdminId,
    this.timelineCount = 0,
    this.timelineEvents = const [],
  });

  Map<String, dynamic> toJson() => {
    'incidentId': incidentId,
    'incidentNumber': incidentNumber,
    'sessionId': sessionId,
    'guideId': guideId,
    'touristId': touristId,
    'reportedBy': reportedBy,
    'reportedByRole': reportedByRole,
    'type': type,
    'severity': severity,
    'title': title,
    'description': description,
    'lat': lat,
    'lng': lng,
    'attachments': attachments,
    'status': status,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'resolvedAt': resolvedAt?.toIso8601String(),
    'resolvedBy': resolvedBy,
    'resolutionNote': resolutionNote,
    'linkedSosAlertId': linkedSosAlertId,
    'assignedAdminId': assignedAdminId,
    'timelineCount': timelineCount,
    'timelineEvents': timelineEvents,
  };

  factory IncidentReport.fromJson(Map<String, dynamic> json) => IncidentReport(
    incidentId: json['incidentId'],
    incidentNumber: json['incidentNumber'] ?? 'INC-UNK',
    sessionId: json['sessionId'],
    guideId: json['guideId'],
    touristId: json['touristId'],
    reportedBy: json['reportedBy'],
    reportedByRole: json['reportedByRole'] ?? 'unknown',
    type: json['type'],
    severity: json['severity'],
    title: json['title'],
    description: json['description'],
    lat: (json['lat'])?.toDouble(),
    lng: (json['lng'])?.toDouble(),
    attachments: List<String>.from(json['attachments'] ?? []),
    status: json['status'] ?? 'open',
    createdAt: DateTime.parse(json['createdAt']),
    updatedAt: DateTime.parse(json['updatedAt']),
    resolvedAt: json['resolvedAt'] != null ? DateTime.parse(json['resolvedAt']) : null,
    resolvedBy: json['resolvedBy'],
    resolutionNote: json['resolutionNote'],
    linkedSosAlertId: json['linkedSosAlertId'],
    assignedAdminId: json['assignedAdminId'],
    timelineCount: json['timelineCount'] ?? 0,
    timelineEvents: List<Map<String, dynamic>>.from(json['timelineEvents'] ?? []),
  );
}
