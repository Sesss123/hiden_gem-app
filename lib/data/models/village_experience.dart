class VillageExperience {
  final String id;
  final String name;
  final String district;
  final String hostName;
  final String experienceType; // e.g., Cooking, Farming, Crafting
  final double price;
  final double lat;
  final double lng;
  final String imageUrl;
  final String description;

  VillageExperience({
    required this.id,
    required this.name,
    required this.district,
    required this.hostName,
    required this.experienceType,
    required this.price,
    required this.lat,
    required this.lng,
    required this.imageUrl,
    required this.description,
  });

  factory VillageExperience.fromMap(Map<String, dynamic> map) {
    return VillageExperience(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      district: map['district'] ?? '',
      hostName: map['host_name'] ?? '',
      experienceType: map['experience_type'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      lat: (map['location']?.latitude ?? 0.0).toDouble(),
      lng: (map['location']?.longitude ?? 0.0).toDouble(),
      imageUrl: map['image_url'] ?? '',
      description: map['description'] ?? '',
    );
  }
}
