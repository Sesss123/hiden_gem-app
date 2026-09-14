import 'package:intl/intl.dart';
import '../../data/datasources/price_catalog_service.dart';
import '../../l10n/app_localizations.dart';

class PriceLocalization {
  PriceLocalization._();
  static String display(AppLocalizations l10n, CatalogPrice? price) {
    if (price == null || !price.isUsable || price.mode == PriceDisplayMode.unavailable) return l10n.priceUnavailable;
    if (price.mode == PriceDisplayMode.contact) return l10n.contactForPrice;
    if (price.mode == PriceDisplayMode.free) return l10n.freePriceLabel;
    if (price.amount == null || price.currency == null) return l10n.priceUnavailable;
    final formatter = NumberFormat.currency(name: price.currency, decimalDigits: price.amount == price.amount!.roundToDouble() ? 0 : 2);
    final minimum = formatter.format(price.amount);
    final period = price.billingPeriod == null ? '' : '/${price.billingPeriod}';
    if (price.mode == PriceDisplayMode.from) return '${l10n.fromPriceLabel(minimum)}$period';
    if (price.mode == PriceDisplayMode.range && price.maxAmount != null) {
      return '${l10n.priceRangeLabel(minimum, formatter.format(price.maxAmount))}$period';
    }
    return '$minimum$period';
  }
}
