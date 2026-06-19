import 'package:equatable/equatable.dart';

class HeritageStamp extends Equatable {
  final String id;
  final String placeName;
  final String imageUrl;
  final DateTime claimDate;
  final String rarity; // Common, Rare, Mythic
  final String hash; // Simulated blockchain hash

  const HeritageStamp({
    required this.id,
    required this.placeName,
    required this.imageUrl,
    required this.claimDate,
    required this.rarity,
    required this.hash,
  });

  factory HeritageStamp.fromJson(Map<String, dynamic> json) {
    return HeritageStamp(
      id: json['id'] ?? '',
      placeName: json['placeName'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      claimDate: DateTime.parse(json['claimDate']),
      rarity: json['rarity'] ?? 'Common',
      hash: json['hash'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'placeName': placeName,
      'imageUrl': imageUrl,
      'claimDate': claimDate.toIso8601String(),
      'rarity': rarity,
      'hash': hash,
    };
  }

  @override
  List<Object?> get props => [id, placeName, rarity, hash];
}
