class BookingRequest {
  final String bookingId;
  final String touristId;
  final String? touristDisplayName; // Snapshot at booking time — guides can't read tourist user docs
  final String? guideId;
  final String? operatorId;
  final String? packageId;
  
  // Details
  final DateTime requestedDate;
  final int guestCount;
  final String? notes;
  
  // Status Lifecycle
  final String status; // pending, accepted, declined, expired, cancelled_by_tourist, cancelled_by_guide, session_ready, completed
  
  // Pricing & Snapshot (Frozen at booking time)
  final double? quotedPrice;
  final String? currency;
  final Map<String, dynamic>? packageSnapshot;
  final List<String> includedItemsSnapshot;

  // Payouts & Revenue
  final double? commissionAmount;
  final double? guideNetAmount;
  final double? operatorNetAmount;
  final String payoutStatus; // pending, paid, disputed, refunded
  
  final DateTime createdAt;
  final DateTime? respondedAt;
  final String? responseNote;
  
  // Tracking
  final String? linkedSessionId;
  final String? deviceHash;

  // Priority Leads (Pro/Elite guide subscription benefit)
  final bool isPriority;

  BookingRequest({
    required this.bookingId,
    required this.touristId,
    this.touristDisplayName,
    this.guideId,
    this.operatorId,
    this.packageId,
    required this.requestedDate,
    required this.guestCount,
    this.notes,
    this.status = 'pending',
    this.quotedPrice,
    this.currency,
    this.packageSnapshot,
    this.includedItemsSnapshot = const [],
    this.commissionAmount,
    this.guideNetAmount,
    this.operatorNetAmount,
    this.payoutStatus = 'pending',
    required this.createdAt,
    this.respondedAt,
    this.responseNote,
    this.linkedSessionId,
    this.deviceHash,
    this.isPriority = false,
  });

  Map<String, dynamic> toJson() => {
    'bookingId': bookingId,
    'touristId': touristId,
    'touristDisplayName': touristDisplayName,
    'guideId': guideId,
    'operatorId': operatorId,
    'packageId': packageId,
    'requestedDate': requestedDate.toIso8601String(),
    'guestCount': guestCount,
    'notes': notes,
    'status': status,
    'quotedPrice': quotedPrice,
    'currency': currency,
    'packageSnapshot': packageSnapshot,
    'includedItemsSnapshot': includedItemsSnapshot,
    'commissionAmount': commissionAmount,
    'guideNetAmount': guideNetAmount,
    'operatorNetAmount': operatorNetAmount,
    'payoutStatus': payoutStatus,
    'createdAt': createdAt.toIso8601String(),
    'respondedAt': respondedAt?.toIso8601String(),
    'responseNote': responseNote,
    'linkedSessionId': linkedSessionId,
    'deviceHash': deviceHash,
    'isPriority': isPriority,
  };

  factory BookingRequest.fromJson(Map<String, dynamic> json) => BookingRequest(
    bookingId: json['bookingId'],
    touristId: json['touristId'],
    touristDisplayName: json['touristDisplayName'],
    guideId: json['guideId'],
    operatorId: json['operatorId'],
    packageId: json['packageId'],
    requestedDate: DateTime.parse(json['requestedDate']),
    guestCount: json['guestCount'] ?? 1,
    notes: json['notes'],
    status: json['status'] ?? 'pending',
    quotedPrice: (json['quotedPrice'] as num?)?.toDouble(),
    currency: json['currency'],
    packageSnapshot: json['packageSnapshot'],
    includedItemsSnapshot: List<String>.from(json['includedItemsSnapshot'] ?? []),
    commissionAmount: (json['commissionAmount'] as num?)?.toDouble(),
    guideNetAmount: (json['guideNetAmount'] as num?)?.toDouble(),
    operatorNetAmount: (json['operatorNetAmount'] as num?)?.toDouble(),
    payoutStatus: json['payoutStatus'] ?? 'pending',
    createdAt: DateTime.parse(json['createdAt']),
    respondedAt: json['respondedAt'] != null ? DateTime.parse(json['respondedAt']) : null,
    responseNote: json['responseNote'],
    linkedSessionId: json['linkedSessionId'],
    deviceHash: json['deviceHash'],
    isPriority: json['isPriority'] ?? false,
  );
}
