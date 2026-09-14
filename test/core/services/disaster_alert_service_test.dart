import 'package:flutter_test/flutter_test.dart';
import 'package:hidden_gems_sl/core/services/disaster_alert_service.dart';

void main() {
  final service = DisasterAlertService.instance;

  test('does not manufacture a live alert without an observation', () {
    expect(service.evaluateLocationHazard(district: 'Badulla'), isNull);
    expect(
      service.evaluateLocationHazard(
        district: 'Badulla',
        weatherCondition: 'Heavy rain',
      ),
      isNull,
    );
  });

  test('classifies rainfall thresholds for landslide districts', () {
    expect(service.evaluateLocationHazard(district: 'Badulla', rainfall24hMm: 80)!.level, HazardAlertLevel.yellowWatch);
    expect(service.evaluateLocationHazard(district: 'Badulla', rainfall24hMm: 110)!.level, HazardAlertLevel.amberWarning);
    expect(service.evaluateLocationHazard(district: 'Badulla', rainfall24hMm: 160)!.level, HazardAlertLevel.redEvacuation);
  });

  test('route advice detects highland and flood basin endpoints', () {
    expect(service.routeRiskAdvice(origin: 'Colombo', destination: 'Badulla'), contains('highland'));
    expect(service.routeRiskAdvice(origin: 'Colombo', destination: 'Kelaniya'), contains('flood'));
    expect(service.routeRiskAdvice(origin: 'Jaffna', destination: 'Mannar'), isNull);
  });
}
