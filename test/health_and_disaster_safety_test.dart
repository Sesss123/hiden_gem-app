import 'package:flutter_test/flutter_test.dart';
import 'package:hidden_gems_sl/core/services/health_safety_service.dart';
import 'package:hidden_gems_sl/core/services/disaster_alert_service.dart';

void main() {
  group('HealthSafetyService Tests', () {
    test('Returns King Coconut as default tropical hydration super-drink', () {
      final drink = HealthSafetyService.instance.getRecommendationForLocation(
        district: 'Galle',
        title: 'Unawatuna Beach',
      );
      expect(drink.id, equals('thambili'));
      expect(drink.fairPriceLkr, contains('100 – 150'));
      expect(drink.sinhalaTitle, equals('තැඹිලි වතුර'));
    });

    test('Returns Palmyrah juice for Northern and Eastern districts', () {
      final drink = HealthSafetyService.instance.getRecommendationForLocation(
        district: 'Jaffna',
        title: 'Nallur Kandaswamy Kovil',
      );
      expect(drink.id, equals('palmyrah'));
      expect(drink.fairPriceLkr, contains('80 – 120'));
      expect(drink.sinhalaTitle, equals('නැවුම් තල් බීම'));
    });

    test('Returns Herbal Tea for Hill Country and sacred locations', () {
      final drink = HealthSafetyService.instance.getRecommendationForLocation(
        district: 'Nuwara Eliya',
        title: 'Horton Plains',
      );
      expect(drink.id, equals('herbal_tea'));
      expect(drink.fairPriceLkr, contains('60 – 100'));
      expect(drink.sinhalaTitle, contains('බෙලිමල්'));
    });

    test('Evaluates water safety levels properly', () {
      final wilderness = HealthSafetyService.instance.getWaterSafetyLevel(
        category: 'Hiking Trail',
        title: 'Knuckles Mountain Range',
      );
      expect(wilderness, equals(WaterSafetyLevel.remoteWilderness));

      final museum = HealthSafetyService.instance.getWaterSafetyLevel(
        category: 'Heritage',
        title: 'Peradeniya Botanical Garden',
      );
      expect(museum, equals(WaterSafetyLevel.filteredOnSite));

      final standard = HealthSafetyService.instance.getWaterSafetyLevel(
        category: 'Cultural',
        title: 'Polonnaruwa Vatadage',
      );
      expect(standard, equals(WaterSafetyLevel.carrySealedWater));
    });

    test('Essential water safety rules include SLS 894, tube ice and Jeewani', () {
      final rules = HealthSafetyService.essentialWaterSafetyRules;
      expect(rules.length, greaterThanOrEqualTo(4));
      final slsRule = rules.firstWhere((r) => r['title']!.contains('SLS 894'));
      expect(slsRule['body'], contains('SLS 894'));
    });
  });

  group('DisasterAlertService Tests', () {
    test('Flags NBRO Level 1/2 landslide warnings for Badulla during heavy rain', () {
      final alert = DisasterAlertService.instance.evaluateLocationHazard(
        district: 'Badulla',
        locationTitle: 'Ella Rock Pass',
        rainfall24hMm: 110.0,
      );
      expect(alert, isNotNull);
      expect(alert!.type, equals(HazardType.landslide));
      expect(alert.level, equals(HazardAlertLevel.amberWarning));
      expect(alert.helplineNumber, equals('117'));
    });

    test('Flags river basin flood advisory for Kelani river during storm', () {
      final alert = DisasterAlertService.instance.evaluateLocationHazard(
        district: 'Colombo',
        locationTitle: 'Kelaniya Temple Access Road',
        weatherCondition: 'Thunderstorm',
      );
      expect(alert, isNotNull);
      expect(alert!.type, equals(HazardType.riverFlood));
      expect(alert.regionOrDistrict, equals('Kelani River'));
      expect(alert.helplineNumber, equals('117'));
    });

    test('Returns null when no severe rain or hazard exists in safe area', () {
      final alert = DisasterAlertService.instance.evaluateLocationHazard(
        district: 'Anuradhapura',
        locationTitle: 'Ruwanwelisaya',
        weatherCondition: 'Clear',
      );
      expect(alert, isNull);
    });

    test('Includes standard emergency DMC and ambulance hotlines', () {
      expect(DisasterAlertService.emergencyHotlines['117'], contains('DMC'));
      expect(DisasterAlertService.emergencyHotlines['1990'], contains('Suwa Seriya'));
    });
  });
}
