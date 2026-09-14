import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Severity of natural hazard travel alert
enum HazardAlertLevel {
  none,
  yellowWatch,  // Level 1: Rainfall > 75mm / 24h. Be watchful along slopes & rockfall zones.
  amberWarning, // Level 2: Rainfall > 100mm / 24h. Avoid night driving on mountain passes.
  redEvacuation,// Level 3: Rainfall > 150mm / 24h. Active slope failure / road blocks.
}

/// Nature of the travel hazard
enum HazardType {
  landslide,
  riverFlood,
  monsoonStorm,
}

/// Travel hazard advisory object
class TravelHazardAlert {
  final String id;
  final String title;
  final String sinhalaTitle;
  final String subtitle;
  final String message;
  final String sinhalaMessage;
  final HazardAlertLevel level;
  final HazardType type;
  final String regionOrDistrict;
  final List<String> travelAdvice;
  final String helplineNumber;
  final String helplineName;
  final Color badgeColor;
  /// Provenance and freshness metadata. Alerts without a source must not be
  /// presented as official live warnings.
  final String source;
  final DateTime? updatedAt;
  final DateTime? expiresAt;

  const TravelHazardAlert({
    required this.id,
    required this.title,
    required this.sinhalaTitle,
    required this.subtitle,
    required this.message,
    required this.sinhalaMessage,
    required this.level,
    required this.type,
    required this.regionOrDistrict,
    required this.travelAdvice,
    required this.helplineNumber,
    required this.helplineName,
    required this.badgeColor,
    this.source = 'Local advisory engine',
    this.updatedAt,
    this.expiresAt,
  });

  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);
}

/// Sri Lanka Disaster Management & NBRO Travel Safety Evaluator
class DisasterAlertService {
  DisasterAlertService._();
  static final DisasterAlertService instance = DisasterAlertService._();

  String? routeRiskAdvice({required String origin, required String destination}) {
    final route = '$origin $destination'.toLowerCase();
    final highland = nbroLandslideDistricts.any(route.contains);
    final flood = floodRiverBasins.values.expand((towns) => towns).any(route.contains);
    if (highland && flood) {
      return 'This route includes landslide-prone highlands and a flood-basin area. Check current NBRO/DMC alerts, prefer daylight travel, and use an alternate route when an official warning is active.';
    }
    if (highland) {
      return 'This route includes landslide-prone highland terrain. Check current NBRO alerts and prefer daylight travel during heavy rain.';
    }
    if (flood) {
      return 'This route includes a flood-basin area. Check current DMC alerts and never drive through submerged roads.';
    }
    return null;
  }

  Future<String?> activeRouteRiskAdvice({required String origin, required String destination}) async {
    final localAdvice = routeRiskAdvice(origin: origin, destination: destination);
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('travel_alerts')
          .where('isActive', isEqualTo: true)
          .get(const GetOptions(source: Source.server));
      final route = '$origin $destination'.toLowerCase();
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final expiry = DateTime.tryParse('${data['expiresAt'] ?? ''}');
        if (expiry != null && expiry.isBefore(DateTime.now().toUtc())) continue;
        final districts = (data['districts'] as List?)?.map((e) => '$e'.toLowerCase()) ?? const Iterable<String>.empty();
        if (districts.any(route.contains)) {
          return '${data['title'] ?? 'Active travel alert'}: ${data['message'] ?? ''} Source: ${data['source'] ?? 'Not supplied'}';
        }
      }
    } catch (_) {
      // Offline/local advisory remains useful but is clearly not called live.
    }
    return localAdvice;
  }

  /// NBRO designated landslide-prone districts (mountainous & slope zones)
  static const Set<String> nbroLandslideDistricts = {
    'badulla',
    'nuwara eliya',
    'ratnapura',
    'kegalle',
    'kandy',
    'matale',
    'kalutara',
    'galle',
    'matara',
    'kurunegala',
  };

  /// High-risk river basins prone to rapid seasonal flash-flooding
  static const Map<String, List<String>> floodRiverBasins = {
    'Kelani River': ['colombo', 'kelaniya', 'avissawella', 'biyagama', 'ruwanwella'],
    'Kalu River': ['ratnapura', 'millaniya', 'horana', 'kalutara', 'kuruwita'],
    'Nilwala River': ['matara', 'akuressa', 'morawaka', 'thihagoda'],
    'Gin River': ['galle', 'baddegama', 'neluwa', 'thawalama'],
  };

  /// Evaluates hazards for a destination or traveler's current coordinates/district.
  TravelHazardAlert? evaluateLocationHazard({
    String? district,
    String? locationTitle,
    String? weatherCondition,
    double? rainfall24hMm,
  }) {
    // A missing observation means the live engine is unavailable. Never infer
    // a disaster from static place copy alone.
    if (rainfall24hMm == null) {
      return null;
    }
    final String query = '${district ?? ''} ${locationTitle ?? ''}'.toLowerCase();
    // Weather descriptions such as "Rain" do not include measured 24-hour
    // accumulation and must never be converted into an NBRO warning level.
    // Official alerts arrive through the admin-authored travel_alerts feed.
    final bool hasMeasuredHeavyRain = rainfall24hMm >= 75.0;

    // 1. Check NBRO Landslide Vulnerability
    final bool isLandslideDistrict = nbroLandslideDistricts.any((d) => query.contains(d));

    if (isLandslideDistrict && hasMeasuredHeavyRain) {
      if (rainfall24hMm >= 150.0) {
        return const TravelHazardAlert(
          id: 'nbro_red',
          title: 'Local rainfall risk estimate: Level 3',
          sinhalaTitle: 'දේශීය වර්ෂාපතන අවදානම් ඇස්තමේන්තුව: අදියර 3',
          subtitle: 'Extreme rainfall detected. Slope roads may be blocked.',
          message:
              'Measured 24-hour rainfall crossed the local Level 3 threshold. This is not an official NBRO notice; verify current NBRO/DMC instructions before travelling.',
          sinhalaMessage:
              'මෙය නිල NBRO නිවේදනයක් නොවේ. ගමන් කිරීමට පෙර NBRO/DMC නිල උපදෙස් පරීක්ෂා කරන්න.',
          level: HazardAlertLevel.redEvacuation,
          type: HazardType.landslide,
          regionOrDistrict: 'Highland Mountain Slopes',
          travelAdvice: [
            'Do not attempt mountain passes (Ella-Wellawaya, Ramboda, Hatton).',
            'Relocate to stable flat ground if near steep earth embankments.',
            'Dial 117 immediately for Disaster Management emergency rescue.',
          ],
          helplineNumber: '117',
          helplineName: 'Disaster Management Centre (DMC)',
          badgeColor: Color(0xFFEF4444),
          source: 'Local rainfall estimate — verify with NBRO/DMC',
        );
      } else if (rainfall24hMm >= 100.0) {
        return const TravelHazardAlert(
          id: 'nbro_amber',
          title: 'Local rainfall risk estimate: Level 2',
          sinhalaTitle: 'දේශීය වර්ෂාපතන අවදානම් ඇස්තමේන්තුව: අදියර 2',
          subtitle: 'Avoid night driving through mountain gaps and steep slopes.',
          message:
              'Continuous heavy rainfall. Beware of slope cracks, tilted trees, or muddy water springs on road verges.',
          sinhalaMessage:
              'අඛණ්ඩ තද වැසි නිසා කඳු බෑවුම් සහිත මාර්ග වල ගමන් කිරීමේදී ප්‍රවේශම් වන්න. රාත්‍රී කාලයේ කඳුකර මාර්ග භාවිතයෙන් වළකින්න.',
          level: HazardAlertLevel.amberWarning,
          type: HazardType.landslide,
          regionOrDistrict: 'Mountain Slopes & Gaps',
          travelAdvice: [
            'Avoid night journeys on winding mountain roads.',
            'Watch for rockfalls along roadside cutting slopes.',
            'Check road passability before departing with local drivers.',
          ],
          helplineNumber: '117',
          helplineName: 'Disaster Management Centre (DMC)',
          badgeColor: Color(0xFFF97316),
          source: 'Local rainfall estimate — verify with NBRO/DMC',
        );
      } else {
        // Yellow watch
        return const TravelHazardAlert(
          id: 'nbro_yellow',
          title: 'Local rainfall risk estimate: Level 1',
          sinhalaTitle: 'දේශීය වර්ෂාපතන අවදානම් ඇස්තමේන්තුව: අදියර 1',
          subtitle: 'Persistent rainfall in hilly terrain. Stay alert for rockfalls.',
          message:
              'Rainfall exceeded 75mm. Watch for roadside earth slips, fallen stones, and low-visibility mountain fog.',
          sinhalaMessage:
              'කඳුකර ප්‍රදේශයට ඇදහැලෙන වැසි නිසා පාරට පස් කඳු හෝ ගල් පෙරලීමේ අවදානම ගැන විමසිලිමත් වන්න.',
          level: HazardAlertLevel.yellowWatch,
          type: HazardType.landslide,
          regionOrDistrict: 'Hilly Terrains',
          travelAdvice: [
            'Drive slowly on mountain bends.',
            'Turn on headlights during mountain fog and mist.',
            'Keep emergency numbers handy (117 / 1990).',
          ],
          helplineNumber: '117',
          helplineName: 'Disaster Management Centre (DMC)',
          badgeColor: Color(0xFFEAB308),
          source: 'Local rainfall estimate — verify with NBRO/DMC',
        );
      }
    }

    // 2. Check Major River Flood Basin Vulnerability
    for (final entry in floodRiverBasins.entries) {
      final String riverName = entry.key;
      final List<String> towns = entry.value;
      if (towns.any((t) => query.contains(t)) && hasMeasuredHeavyRain) {
        return TravelHazardAlert(
          id: 'flood_${riverName.replaceAll(' ', '_').toLowerCase()}',
          title: 'River Basin Flood Advisory: $riverName',
          sinhalaTitle: 'ගංගා නිම්න ගංවතුර උපදේශනය: $riverName',
          subtitle: 'Low-lying access roads may experience rising water levels.',
          message:
              'Heavy catchment rainfall may cause minor inundation of low-lying byroads near $riverName basin. Keep to main highways.',
          sinhalaMessage:
              '$riverName ද්‍රෝණියේ පහත්බිම් මාර්ග ජලයෙන් යටවීමේ අවදානමක් පවතී. ප්‍රධාන මාර්ග පමණක් භාවිතා කරන්න.',
          level: HazardAlertLevel.amberWarning,
          type: HazardType.riverFlood,
          regionOrDistrict: riverName,
          travelAdvice: [
            'Do not drive through submerged causeways or unknown flood water.',
            'Stick to elevated A-grade and B-grade national highways.',
            'Verify ferry or boat transfer operations if crossing waterways.',
          ],
          helplineNumber: '117',
          helplineName: 'DMC Emergency Flood Hotline',
          badgeColor: const Color(0xFF0284C7),
          source: 'Local rainfall estimate — verify with DMC/Irrigation Department',
        );
      }
    }

    return null;
  }

  /// Emergency disaster hotlines in Sri Lanka
  static const Map<String, String> emergencyHotlines = {
    '117': 'Disaster Management Centre (DMC) - ආපදා සහන',
    '1990': 'Suwa Seriya Free Ambulance - සුවසැරිය ගිලන්රථ',
    '119': 'Police Emergency Service - පොලිස් හදිසි ඇමතුම්',
    '1912': 'Sri Lanka Tourist Police - සංචාරක පොලිසිය',
  };
}
