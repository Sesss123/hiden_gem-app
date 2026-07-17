import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

class TourType {
  final String fieldKey;
  final IconData icon;
  final String Function(AppLocalizations) label;

  const TourType({required this.fieldKey, required this.icon, required this.label});
}

const List<TourType> kTourTypes = [
  TourType(fieldKey: 'doesBoatSafari', icon: Icons.directions_boat_filled_rounded, label: _boatSafari),
  TourType(fieldKey: 'doesWildlifeSafari', icon: Icons.pets_rounded, label: _wildlifeSafari),
  TourType(fieldKey: 'doesHiking', icon: Icons.terrain_rounded, label: _hiking),
  TourType(fieldKey: 'doesDiving', icon: Icons.scuba_diving_rounded, label: _diving),
  TourType(fieldKey: 'doesCulturalTours', icon: Icons.temple_buddhist_rounded, label: _culturalTours),
];

String _boatSafari(AppLocalizations l10n) => l10n.tourTypeBoatSafari;
String _wildlifeSafari(AppLocalizations l10n) => l10n.tourTypeWildlifeSafari;
String _hiking(AppLocalizations l10n) => l10n.tourTypeHiking;
String _diving(AppLocalizations l10n) => l10n.tourTypeDiving;
String _culturalTours(AppLocalizations l10n) => l10n.tourTypeCulturalTours;

/// Shared guide-category taxonomy — consolidates the two lists that were
/// previously hand-duplicated in marketplace_results_screen.dart and
/// guide_listing_editor_screen.dart.
const List<String> kGuideCategories = [
  'Chauffeur',
  'Site Guide',
  'Adventure',
  'Wildlife',
  'Heritage',
  'Photography',
];
