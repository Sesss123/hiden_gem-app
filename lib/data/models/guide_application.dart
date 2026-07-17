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
  final DateTime? licenseExpiryDate;

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
    this.licenseExpiryDate,
  });

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'license_number': licenseNumber,
    'bio': bio,
    'category': category,
    'license_doc_url': licenseDocUrl,
    'nic_doc_url': nicDocUrl,
    'selfie_doc_url': selfieDocUrl,
    'status': status.name,
    'admin_comment': adminComment,
    'applied_at': appliedAt.toIso8601String(),
    'reviewed_at': reviewedAt?.toIso8601String(),
    'license_expiry_date': licenseExpiryDate?.toIso8601String(),
  };

  factory GuideApplication.fromJson(Map<String, dynamic> json) => GuideApplication(
    userId: json['user_id'] ?? json['userId'],
    licenseNumber: json['license_number'] ?? json['licenseNumber'],
    bio: json['bio'],
    category: json['category'],
    licenseDocUrl: json['license_doc_url'] ?? json['licenseDocUrl'],
    nicDocUrl: json['nic_doc_url'] ?? json['nicDocUrl'],
    selfieDocUrl: json['selfie_doc_url'] ?? json['selfieDocUrl'],
    status: GuideStatus.values.byName(json['status'] ?? 'pending'),
    adminComment: json['admin_comment'] ?? json['adminComment'],
    appliedAt: DateTime.parse(json['applied_at'] ?? json['appliedAt'] ?? DateTime.now().toIso8601String()),
    reviewedAt: (json['reviewed_at'] ?? json['reviewedAt']) != null
        ? DateTime.parse(json['reviewed_at'] ?? json['reviewedAt'])
        : null,
    licenseExpiryDate: (json['license_expiry_date'] ?? json['licenseExpiryDate']) != null
        ? DateTime.parse(json['license_expiry_date'] ?? json['licenseExpiryDate'])
        : null,
  );
}
