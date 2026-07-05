class FamilyShareLink {
  final String shareId;
  final String touristId;
  final String sessionId;
  
  // Recipient
  final String recipientName;
  final String? recipientContact; // Email or Phone
  
  // Security
  final String shareToken; // Secure random token
  final DateTime expiresAt;
  final bool isActive;
  final Map<String, bool> permissions; 
  // Matrix: show_status, show_identity, show_meeting_point, show_emergency
  
  // Stats
  final int viewCount;

  FamilyShareLink({
    required this.shareId,
    required this.touristId,
    required this.sessionId,
    required this.recipientName,
    this.recipientContact,
    required this.shareToken,
    required this.expiresAt,
    this.isActive = true,
    this.permissions = const {
      'show_status': true,
      'show_identity': true,
      'show_meeting_point': true,
      'show_emergency': true,
    },
    this.viewCount = 0,
  });

  Map<String, dynamic> toJson() => {
    'shareId': shareId,
    'touristId': touristId,
    'sessionId': sessionId,
    'recipientName': recipientName,
    'recipientContact': recipientContact,
    'shareToken': shareToken,
    'expiresAt': expiresAt.toIso8601String(),
    'isActive': isActive,
    'permissions': permissions,
    'viewCount': viewCount,
  };

  factory FamilyShareLink.fromJson(Map<String, dynamic> json) => FamilyShareLink(
    shareId: json['shareId'],
    touristId: json['touristId'],
    sessionId: json['sessionId'],
    recipientName: json['recipientName'],
    recipientContact: json['recipientContact'],
    shareToken: json['shareToken'],
    expiresAt: DateTime.parse(json['expiresAt']),
    isActive: json['isActive'] ?? true,
    permissions: Map<String, bool>.from(json['permissions'] ?? {}),
    viewCount: json['viewCount'] ?? 0,
  );

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  FamilyShareLink copyWith({
    String? shareId,
    String? touristId,
    String? sessionId,
    String? recipientName,
    String? recipientContact,
    String? shareToken,
    DateTime? expiresAt,
    bool? isActive,
    Map<String, bool>? permissions,
    int? viewCount,
  }) {
    return FamilyShareLink(
      shareId: shareId ?? this.shareId,
      touristId: touristId ?? this.touristId,
      sessionId: sessionId ?? this.sessionId,
      recipientName: recipientName ?? this.recipientName,
      recipientContact: recipientContact ?? this.recipientContact,
      shareToken: shareToken ?? this.shareToken,
      expiresAt: expiresAt ?? this.expiresAt,
      isActive: isActive ?? this.isActive,
      permissions: permissions ?? this.permissions,
      viewCount: viewCount ?? this.viewCount,
    );
  }
}
