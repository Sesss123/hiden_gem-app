import 'package:flutter/material.dart';

class Artist {
  final String name;
  final String? imageUrl;
  final String? musicGenre;
  final String? socialLink;

  Artist({
    required this.name,
    this.imageUrl,
    this.musicGenre,
    this.socialLink,
  });

  factory Artist.fromJson(Map<String, dynamic> json) {
    return Artist(
      name: json['name'] ?? '',
      imageUrl: json['image_url'],
      musicGenre: json['music_genre'],
      socialLink: json['social_link'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'image_url': imageUrl,
      'music_genre': musicGenre,
      'social_link': socialLink,
    };
  }
}

enum EventCategory {
  beach,
  cultural,
  religious,
  sports,
  seasonal,
  festival,
  party,
}

class EventModel {
  final String name;
  final String description;
  final EventCategory category;
  final String? date; // MM-DD
  final String? start; // MM-DD
  final String? end; // MM-DD
  final String? location;
  final String? ticketUrl;
  final List<Artist> lineup;
  final double? latitude;
  final double? longitude;
  final List<String> tags;
  final int? priceLkr;

  EventModel({
    required this.name,
    required this.description,
    required this.category,
    this.date,
    this.start,
    this.end,
    this.location,
    this.ticketUrl,
    this.lineup = const [],
    this.latitude,
    this.longitude,
    this.tags = const [],
    this.priceLkr,
  });

  Color get categoryColor {
    switch (category) {
      case EventCategory.beach:
      case EventCategory.party:
        return const Color(0xFF1976D2); // Modern Blue
      case EventCategory.cultural:
      case EventCategory.religious:
      case EventCategory.festival:
        return const Color(0xFF2E7D32); // Modern Green
      case EventCategory.sports:
        return Colors.orangeAccent;
      case EventCategory.seasonal:
        return Colors.tealAccent;
    }
  }

  IconData get categoryIcon {
    switch (category) {
      case EventCategory.beach:
      case EventCategory.party:
        return Icons.beach_access;
      case EventCategory.cultural:
        return Icons.museum;
      case EventCategory.religious:
        return Icons.temple_buddhist;
      case EventCategory.festival:
        return Icons.celebration;
      case EventCategory.sports:
        return Icons.sports;
      case EventCategory.seasonal:
        return Icons.ac_unit;
    }
  }

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      category: _parseCategory(json['type'] ?? json['category']),
      date: json['date'],
      start: json['start'],
      end: json['end'],
      location: json['location'],
      ticketUrl: json['ticket_url'],
      lineup: (json['lineup'] as List?)?.map((a) => Artist.fromJson(a)).toList() ?? [],
      latitude: json['lat'],
      longitude: json['lng'],
      tags: List<String>.from(json['tags'] ?? []),
      priceLkr: json['price_lkr'],
    );
  }

  static EventCategory _parseCategory(String? type) {
    switch (type?.toLowerCase()) {
      case 'beach':
      case 'party':
        return EventCategory.party;
      case 'cultural':
        return EventCategory.cultural;
      case 'religious':
        return EventCategory.religious;
      case 'sports':
        return EventCategory.sports;
      case 'seasonal':
        return EventCategory.seasonal;
      case 'festival':
        return EventCategory.festival;
      default:
        return EventCategory.cultural;
    }
  }

  double? get lat => latitude;
  double? get lng => longitude;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'category': category.name,
      'date': date,
      'start': start,
      'end': end,
      'location': location,
      'ticket_url': ticketUrl,
      'lat': latitude,
      'lng': longitude,
      'lineup': lineup.map((a) => a.toJson()).toList(),
      'tags': tags,
      'price_lkr': priceLkr,
    };
  }
}
