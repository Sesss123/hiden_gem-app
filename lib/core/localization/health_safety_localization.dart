import '../../l10n/app_localizations.dart';
import '../../data/datasources/price_catalog_service.dart';
import 'price_localization.dart';

class HealthSafetyLocalization {
  HealthSafetyLocalization._();

  static String drinkTitle(AppLocalizations l10n, String id) => switch (id) {
        'thambili' => l10n.thambiliTitle,
        'palmyrah' => l10n.palmyrahTitle,
        'herbal_tea' => l10n.herbalTeaTitle,
        _ => l10n.waterSafetyTitle,
      };

  static String drinkPrice(AppLocalizations l10n, String id) => PriceLocalization.display(
      l10n, PriceCatalogService.instance.price('drinks.$id'));

  static String ruleText(AppLocalizations l10n, String id) => switch (id) {
        'sealed_water' => l10n.slsCertificationTip,
        'ice' => l10n.iceSafetyTip,
        'tap_water' => l10n.tapWaterWarning,
        'ors' => l10n.jeewaniTip,
        _ => l10n.waterSafetySubtitle,
      };
}
