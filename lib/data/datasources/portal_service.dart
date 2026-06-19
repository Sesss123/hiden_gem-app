import '../../data/models/portal_model.dart';

class PortalService {
  static final List<AncestralPortal> _allPortals = [
    const AncestralPortal(
      id: 'sigiriya_kasyapa',
      locationName: 'Sigiriya Rock',
      era: '5th Century — King Kasyapa',
      panoramaImageUrl: 'https://images.unsplash.com/photo-1546708973-b339540b5162?q=80&w=2670&auto=format&fit=crop', // Placeholder 360 image
      description: 'Step into the pleasure gardens of King Kasyapa as they looked 1,500 years ago, with the Lion Gate fully intact.',
      keyArtifacts: ['Lion Gate', 'Mirror Wall', 'Symmetrical Gardens'],
    ),
    const AncestralPortal(
      id: 'pollonnaruwa_vatadage',
      locationName: 'Polonnaruwa Vatadage',
      era: '12th Century — Polonnaruwa Kingdom',
      panoramaImageUrl: 'https://images.unsplash.com/photo-1578330105307-f3900ac1048b?q=80&w=2070&auto=format&fit=crop', // Placeholder
      description: 'The circular relic house in its full glory, with polished stone pillars and intricate moonstones.',
      keyArtifacts: ['Moonstone', 'Buddha Statues', 'Pillar Carvings'],
    ),
  ];

  static AncestralPortal? getPortalForPlace(String placeName) {
    try {
      return _allPortals.firstWhere((p) => placeName.toLowerCase().contains(p.locationName.toLowerCase()));
    } catch (_) {
      return null;
    }
  }
}
