class Vehicle {
  final String id;
  final String guideId;
  final String vehicleNumber;
  final String type; // Tuk Tuk, Car, Van, Bus, Boat
  final int seatCapacity;
  final String driverName;
  final bool isActive;
  final String? imageUrl;
  final DateTime createdAt;

  Vehicle({
    required this.id,
    required this.guideId,
    required this.vehicleNumber,
    required this.type,
    required this.seatCapacity,
    required this.driverName,
    this.isActive = true,
    this.imageUrl,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'guideId': guideId,
    'vehicleNumber': vehicleNumber,
    'type': type,
    'seatCapacity': seatCapacity,
    'driverName': driverName,
    'isActive': isActive,
    'imageUrl': imageUrl,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Vehicle.fromJson(Map<String, dynamic> json) => Vehicle(
    id: json['id'],
    guideId: json['guideId'],
    vehicleNumber: json['vehicleNumber'],
    type: json['type'],
    seatCapacity: json['seatCapacity'] ?? 4,
    driverName: json['driverName'],
    isActive: json['isActive'] ?? true,
    imageUrl: json['imageUrl'],
    createdAt: DateTime.parse(json['createdAt']),
  );
}
