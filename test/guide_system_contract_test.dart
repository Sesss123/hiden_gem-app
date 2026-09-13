import 'package:flutter_test/flutter_test.dart';
import 'package:hidden_gems_sl/data/repositories/marketplace_repository.dart';
import 'package:hidden_gems_sl/data/services/payment_service.dart';

void main() {
  group('Guide marketplace and payment contracts', () {
    test('payment quote preserves the server-signed checkout URL', () {
      final redirect = Uri.parse(
        'https://example.test/payments/redirect/booking-1?expires=123&signature=abc',
      );

      final quote = PaymentQuote(
        amount: 12000,
        currency: 'LKR',
        redirectUrl: redirect,
      );

      expect(quote.redirectUrl, redirect);
      expect(quote.redirectUrl.queryParameters['signature'], 'abc');
    });

    test('marketplace pagination retains the backend next-page cursor', () {
      const page = MarketplacePage(
        listings: [],
        hasMore: true,
        nextPage: 3,
      );

      expect(page.hasMore, isTrue);
      expect(page.nextPage, 3);
    });

    test('empty marketplace page cannot request another page', () {
      expect(MarketplacePage.empty.hasMore, isFalse);
      expect(MarketplacePage.empty.nextPage, isNull);
    });
  });
}
