/// Model for local business partners (Hotels, Guides, Cafes) for Phase 4 integration.
class BusinessPartner {
  final String id;
  final String name;
  final String category; // 'hotel', 'guide', 'cafe', 'artisan'
  final String description;
  final String imageUrl;
  final double rating;
  final String priceRange;
  final double lat;
  final double lng;
  final String bookingUrl; // Direct link or WhatsApp link
  final bool isVerified;

  // Curator Deals — premium-only discounts at partner boutique stays/cafes.
  final bool isPremiumDeal;
  final int discountPercent; // 0 when isPremiumDeal is false
  final String dealDescription;
  final DateTime? dealValidUntil;

  double distanceKm;

  BusinessPartner({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.imageUrl,
    required this.rating,
    required this.priceRange,
    required this.lat,
    required this.lng,
    required this.bookingUrl,
    this.isVerified = false,
    this.isPremiumDeal = false,
    this.discountPercent = 0,
    this.dealDescription = '',
    this.dealValidUntil,
    this.distanceKm = 0.0,
  });

  bool get hasActiveDeal =>
      isPremiumDeal && (dealValidUntil == null || dealValidUntil!.isAfter(DateTime.now()));

  factory BusinessPartner.fromJson(Map<String, dynamic> json) {
    return BusinessPartner(
      id: json['id'].toString(),
      name: json['name'] as String,
      category: json['category'] as String,
      description: json['description'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? 'https://images.unsplash.com/photo-1566073771259-6a8506099945?q=80&w=2070',
      rating: (json['rating'] as num?)?.toDouble() ?? 4.0,
      priceRange: json['priceRange'] as String? ?? '\$\$',
      lat: (json['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (json['lng'] as num?)?.toDouble() ?? 0.0,
      bookingUrl: json['bookingUrl'] as String? ?? '',
      isVerified: json['isVerified'] as bool? ?? false,
      isPremiumDeal: json['isPremiumDeal'] as bool? ?? false,
      discountPercent: (json['discountPercent'] as num?)?.toInt() ?? 0,
      dealDescription: json['dealDescription'] as String? ?? '',
      dealValidUntil: json['dealValidUntil'] != null
          ? DateTime.tryParse(json['dealValidUntil'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'category': category,
    'description': description,
    'imageUrl': imageUrl,
    'rating': rating,
    'priceRange': priceRange,
    'lat': lat,
    'lng': lng,
    'bookingUrl': bookingUrl,
    'isVerified': isVerified,
    'isPremiumDeal': isPremiumDeal,
    'discountPercent': discountPercent,
    'dealDescription': dealDescription,
    'dealValidUntil': dealValidUntil?.toIso8601String(),
  };
}
