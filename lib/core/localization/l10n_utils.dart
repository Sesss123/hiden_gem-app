import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

class L10nUtils {
  /// Maps a raw category string (e.g. from Firestore) to a localized string.
  static String getLocalizedCategory(BuildContext context, String category) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return category;

    final normalized = category.toLowerCase().trim();

    if (normalized.contains('nature')) return l10n.categoryNature;
    if (normalized.contains('waterfall')) return l10n.categoryWaterfall;
    if (normalized.contains('hiking')) return l10n.categoryHiking;
    if (normalized.contains('culture')) return l10n.categoryCulture;
    if (normalized.contains('historical')) return l10n.categoryCulture;
    if (normalized.contains('coast')) return l10n.categoryCoastal;
    if (normalized.contains('beach')) return l10n.categoryCoastal;
    if (normalized.contains('family')) return l10n.categoryFamily;
    if (normalized.contains('budget')) return l10n.categoryBudget;
    if (normalized.contains('free')) return l10n.categoryBudget;
    
    return category; // Fallback to raw string if no mapping exists
  }

  /// Maps a filter key to its localized label with emoji.
  static String getFilterLabel(BuildContext context, String filterKey) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return filterKey;

    switch (filterKey) {
      case 'all': return l10n.filterAll;
      case 'nature': return l10n.filterNature;
      case 'waterfall': return l10n.filterWaterfall;
      case 'hiking': return l10n.filterHiking;
      case 'culture': return l10n.filterCulture;
      case 'coastal': return l10n.filterCoastal;
      case 'family': return l10n.filterFamily;
      case 'budget': return l10n.filterBudget;
      case 'ar': return l10n.filterAr;
      default: return filterKey;
    }
  }
}
