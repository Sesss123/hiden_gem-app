import 'guide_status.dart';

class GuideApplication {
  final String userId;
  final String licenseNumber;
  final String bio;
  final String category;
  final String? licenseDocUrl;
  final String? nicDocUrl;
  final String? selfieDocUrl;
  final GuideStatus status;
  final String? adminComment;
  final DateTime appliedAt;
  final DateTime? reviewedAt;

  GuideApplication({
    required this.userId,
    required this.licenseNumber,
    required this.bio,
    required this.category,
    this.licenseDocUrl,
    this.nicDocUrl,
    this.selfieDocUrl,
    this.status = GuideStatus.pending,
    this.adminComment,
    required this.appliedAt,
    this.reviewedAt,
  });

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'licenseNumber': licenseNumber,
    'bio': bio,
    'category': category,
    'licenseDocUrl': licenseDocUrl,
    'nicDocUrl': nicDocUrl,
    'selfieDocUrl': selfieDocUrl,
    'status': status.name,
    'adminComment': adminComment,
    'appliedAt': appliedAt.toIso8601String(),
    'reviewedAt': reviewedAt?.toIso8601String(),
  };

  factory GuideApplication.fromJson(Map<String, dynamic> json) => GuideApplication(
    userId: json['userId'],
    licenseNumber: json['licenseNumber'],
    bio: json['bio'],
    category: json['category'],
    licenseDocUrl: json['licenseDocUrl'],
    nicDocUrl: json['nicDocUrl'],
    selfieDocUrl: json['selfieDocUrl'],
    status: GuideStatus.values.byName(json['status'] ?? 'pending'),
    adminComment: json['adminComment'],
    appliedAt: DateTime.parse(json['appliedAt'] ?? DateTime.now().toIso8601String()),
    reviewedAt: json['reviewedAt'] != null ? DateTime.parse(json['reviewedAt']) : null,
  );
}
