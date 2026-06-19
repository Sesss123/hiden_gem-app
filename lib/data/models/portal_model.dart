import 'package:equatable/equatable.dart';

class AncestralPortal extends Equatable {
  final String id;
  final String locationName;
  final String era; // e.g., "12th Century Polonnaruwa"
  final String panoramaImageUrl;
  final String description;
  final List<String> keyArtifacts;

  const AncestralPortal({
    required this.id,
    required this.locationName,
    required this.era,
    required this.panoramaImageUrl,
    required this.description,
    required this.keyArtifacts,
  });

  factory AncestralPortal.fromJson(Map<String, dynamic> json) {
    return AncestralPortal(
      id: json['id'] ?? '',
      locationName: json['locationName'] ?? '',
      era: json['era'] ?? '',
      panoramaImageUrl: json['panoramaImageUrl'] ?? '',
      description: json['description'] ?? '',
      keyArtifacts: List<String>.from(json['keyArtifacts'] ?? []),
    );
  }

  @override
  List<Object?> get props => [id, locationName, era, panoramaImageUrl, description, keyArtifacts];
}
