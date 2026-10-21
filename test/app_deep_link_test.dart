import 'package:flutter_test/flutter_test.dart';
import 'package:hidden_gems_sl/core/navigation/app_deep_link.dart';

void main() {
  test('parses valid join deep links', () {
    final pathLink = AppDeepLink.parse(Uri.parse('hiddengems://join/ABC234'));
    final queryLink =
        AppDeepLink.parse(Uri.parse('hiddengems://join?token=abc234'));

    expect(pathLink?.joinToken, 'ABC234');
    expect(queryLink?.joinToken, 'ABC234');
  });

  test('rejects unrelated, malformed, and family tracking links', () {
    expect(AppDeepLink.parse(Uri.parse('hiddengems://place/ABC234')), isNull);
    expect(AppDeepLink.parse(Uri.parse('hiddengems://join/ABC1O0')), isNull);
    expect(
      AppDeepLink.parse(Uri.parse('https://api.hidengem.xyz/join/ABC234')),
      isNull,
    );
  });
}
