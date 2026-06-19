class SubscriptionRecord {
  final String subscriptionId;
  final String accountType; // guide, operator
  final String accountId; // guideId or operatorId
  
  // Plan Details
  final String planId; // free, pro, elite, starter, growth, enterprise
  final String status; // active, expired, cancelled, past_due
  final Map<String, dynamic> entitlements; // {activeSessionLimit, featuredAllowed, etc.}
  
  // Dates
  final DateTime startedAt;
  final DateTime expiresAt;
  final DateTime? cancelledAt;
  
  // Billing
  final String paymentProvider; // stripe, payhere, apple, google
  final String? externalSubscriptionId;
  final String currency;
  final double amount;
  final String billingPeriod; // monthly, yearly

  SubscriptionRecord({
    required this.subscriptionId,
    required this.accountType,
    required this.accountId,
    required this.planId,
    this.status = 'active',
    this.entitlements = const {},
    required this.startedAt,
    required this.expiresAt,
    this.cancelledAt,
    this.paymentProvider = 'stripe',
    this.externalSubscriptionId,
    this.currency = 'USD',
    this.amount = 0.0,
    this.billingPeriod = 'monthly',
  });

  Map<String, dynamic> toJson() => {
    'subscriptionId': subscriptionId,
    'accountType': accountType,
    'accountId': accountId,
    'planId': planId,
    'status': status,
    'entitlements': entitlements,
    'startedAt': startedAt.toIso8601String(),
    'expiresAt': expiresAt.toIso8601String(),
    'cancelledAt': cancelledAt?.toIso8601String(),
    'paymentProvider': paymentProvider,
    'externalSubscriptionId': externalSubscriptionId,
    'currency': currency,
    'amount': amount,
    'billingPeriod': billingPeriod,
  };

  factory SubscriptionRecord.fromJson(Map<String, dynamic> json) => SubscriptionRecord(
    subscriptionId: json['subscriptionId'],
    accountType: json['accountType'],
    accountId: json['accountId'],
    planId: json['planId'],
    status: json['status'] ?? 'active',
    entitlements: Map<String, dynamic>.from(json['entitlements'] ?? {}),
    startedAt: DateTime.parse(json['startedAt']),
    expiresAt: DateTime.parse(json['expiresAt']),
    cancelledAt: json['cancelledAt'] != null ? DateTime.parse(json['cancelledAt']) : null,
    paymentProvider: json['paymentProvider'] ?? 'stripe',
    externalSubscriptionId: json['externalSubscriptionId'],
    currency: json['currency'] ?? 'USD',
    amount: (json['amount'] ?? 0.0).toDouble(),
    billingPeriod: json['billingPeriod'] ?? 'monthly',
  );
}
