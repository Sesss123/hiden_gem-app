import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hidden_gems_sl/data/datasources/price_catalog_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final service = PriceCatalogService.instance;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    service.clearForTesting();
  });

  test('missing catalog key has no numeric fallback', () {
    expect(service.price('subscriptions.heritage.monthly'), isNull);
  });

  test('loads a server-managed fixed price', () async {
    final client = MockClient((_) async => http.Response(
      '{"success":true,"prices":{"drinks.thambili":{"key":"drinks.thambili","display_mode":"fixed","amount":175,"currency":"LKR"}}}', 200));
    await service.sync(client: client);
    final price = service.price('drinks.thambili');
    expect(price?.amount, 175);
    expect(price?.currency, 'LKR');
    expect(price?.mode, PriceDisplayMode.fixed);
  });

  test('offline mode uses only last server cache', () async {
    SharedPreferences.setMockInitialValues({
      'server_price_catalog_v1':
        '{"subscriptions.heritage.monthly":{"display_mode":"contact"}}'
    });
    await service.sync(client: MockClient((_) async => throw Exception('offline')));
    expect(service.price('subscriptions.heritage.monthly')?.mode, PriceDisplayMode.contact);
    expect(service.price('subscriptions.heritage.monthly')?.amount, isNull);
  });
}
