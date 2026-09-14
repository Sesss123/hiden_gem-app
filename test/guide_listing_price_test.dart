import 'package:flutter_test/flutter_test.dart';
import 'package:hidden_gems_sl/data/models/guide_listing.dart';

Map<String, dynamic> listingJson() => {
  'listingId': 'g1', 'guideId': 'g1', 'displayName': 'Guide',
  'guideCategory': 'Chauffeur', 'hourlyRate': 4500, 'currency': 'LKR',
  'createdAt': '2026-09-14T00:00:00Z', 'updatedAt': '2026-09-14T00:00:00Z',
};

void main() {
  test('guide price and currency are required server data', () {
    final listing = GuideListing.fromJson(listingJson());
    expect(listing.hourlyRate, 4500);
    expect(listing.currency, 'LKR');
  });

  test('missing hourly price is rejected instead of becoming zero', () {
    final json = listingJson()..remove('hourlyRate');
    expect(() => GuideListing.fromJson(json), throwsA(isA<TypeError>()));
  });

  test('missing currency is rejected instead of defaulting to USD', () {
    final json = listingJson()..remove('currency');
    expect(() => GuideListing.fromJson(json), throwsA(isA<TypeError>()));
  });
}
