import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hidden_gems_sl/data/datasources/monetization_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockClient adsOffClient;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    MonetizationService().resetForTesting();
    adsOffClient = MockClient((_) async => http.Response(
          '{"success":true,"ads_enabled":false}',
          200,
          headers: {'content-type': 'application/json'},
        ));
  });

  group('MonetizationService Remote Toggle Tests', () {
    test('Default ads status is enabled', () {
      final service = MonetizationService();
      expect(service.isAdsEnabled, isTrue);
    });

    test('Loads cached ads toggle from SharedPreferences when offline', () async {
      SharedPreferences.setMockInitialValues({
        'app_ads_enabled_master': false,
      });

      final service = MonetizationService();
      // syncRemoteAdConfig will read the local cache first
      await service.syncRemoteAdConfig(
        client: MockClient((_) async => throw Exception('offline')),
      );

      expect(service.isAdsEnabled, isFalse);
      expect(service.canShowInterstitial, isFalse);
    });

    test('showRewardedAd unlocks reward automatically without ad when ads are OFF', () async {
      SharedPreferences.setMockInitialValues({
        'app_ads_enabled_master': false,
      });

      final service = MonetizationService();
      await service.syncRemoteAdConfig(client: adsOffClient);

      bool rewardClaimed = false;
      final result = await service.showRewardedAd(
        onRewardEarned: (reward) {
          rewardClaimed = true;
          expect(reward.amount, equals(1));
        },
      );

      expect(result, isTrue);
      expect(rewardClaimed, isTrue);
    });

    test('showInterstitialAd returns false immediately without ad when ads are OFF', () async {
      SharedPreferences.setMockInitialValues({
        'app_ads_enabled_master': false,
      });

      final service = MonetizationService();
      await service.syncRemoteAdConfig(client: adsOffClient);

      final result = await service.showInterstitialAd();
      expect(result, isFalse);
    });
  });
}
