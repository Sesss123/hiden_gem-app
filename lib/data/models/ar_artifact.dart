import 'package:equatable/equatable.dart';

/// Model for hidden artifacts within an AR scene for Gamification.
class ARArtifact extends Equatable {
  final String id;
  final String name;
  final String description;
  final String modelUrl; // If empty, can use a generic "Treasure" model
  final List<double> relativePosition; // [x, y, z] relative to the main heritage model
  final int points;
  final String rarity; // common, rare, legendary

  const ARArtifact({
    required this.id,
    required this.name,
    required this.description,
    this.modelUrl = '',
    required this.relativePosition,
    this.points = 100,
    this.rarity = 'common',
  });

  factory ARArtifact.fromMap(Map<String, dynamic> map) {
    return ARArtifact(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String? ?? '',
      modelUrl: map['model_url'] as String? ?? '',
      relativePosition: List<double>.from(map['relative_position'] as List),
      points: map['points'] as int? ?? 100,
      rarity: map['rarity'] as String? ?? 'common',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'model_url': modelUrl,
      'relative_position': relativePosition,
      'points': points,
      'rarity': rarity,
    };
  }

  @override
  List<Object?> get props => [id, name, description, modelUrl, relativePosition, points, rarity];
}
