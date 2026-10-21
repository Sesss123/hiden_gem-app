import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  String source(String path) => File(path).readAsStringSync();

  test('location-sensitive flows do not fall back to Colombo', () {
    final home = source('lib/presentation/screens/home_screen.dart');
    final guide =
        source('lib/presentation/screens/guide_dashboard_screen.dart');
    final booking =
        source('lib/presentation/screens/booking_inbox_screen.dart');
    final planner = source('lib/presentation/screens/loading_plan_screen.dart');

    expect(home, isNot(contains('initialPosition: LatLng(6.9271, 79.8612)')));
    expect(guide, isNot(contains('double lat = 6.9271')));
    expect(booking, isNot(contains('double sessionLat = 6.9271')));
    expect(planner, isNot(contains('?? [6.9271, 79.8612]')));
  });

  test('missing backend key does not force offline startup', () {
    final config = source('lib/core/config/app_config.dart');
    final missingKeyCheck = RegExp(
      r'if \(isPlaceholder\(hiddenGemsApiKey\)\) \{([\s\S]*?)\n    \}',
    ).firstMatch(config);

    expect(missingKeyCheck, isNotNull);
    expect(missingKeyCheck!.group(1), isNot(contains('throw ')));
  });
}
