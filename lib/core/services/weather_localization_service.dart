import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

/// Centralized utility for localizing OpenWeatherMap condition strings
/// and evaluating weather safety advisories across Sri Lankan travel regions.
class WeatherLocalizationService {
  /// Returns a traveler-localized weather condition string.
  static String getLocalizedCondition(BuildContext context, String rawCondition) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return rawCondition;

    final lower = rawCondition.trim().toLowerCase();

    if (lower.contains('clear') || lower.contains('sun')) {
      return l10n.weatherConditionClear;
    } else if (lower.contains('thunder') || lower.contains('storm')) {
      return l10n.weatherConditionThunderstorm;
    } else if (lower.contains('rain')) {
      return l10n.weatherConditionRain;
    } else if (lower.contains('drizzle')) {
      return l10n.weatherConditionDrizzle;
    } else if (lower.contains('cloud') || lower.contains('overcast')) {
      return l10n.weatherConditionClouds;
    } else if (lower.contains('mist') || lower.contains('fog') || lower.contains('haze')) {
      return l10n.weatherConditionMist;
    }

    return rawCondition.isNotEmpty ? rawCondition : l10n.weatherConditionClear;
  }

  /// Evaluates whether current weather condition requires a safety caution.
  static bool isSevereWeather(String condition) {
    final lower = condition.trim().toLowerCase();
    return lower.contains('thunder') ||
        lower.contains('storm') ||
        lower.contains('heavy rain') ||
        lower.contains('rain') ||
        lower.contains('squall') ||
        lower.contains('tornado');
  }

  /// Returns localized rain / storm safety advisory when applicable.
  static String? getSevereWeatherAdvisory(BuildContext context, String condition) {
    if (!isSevereWeather(condition)) return null;
    final l10n = AppLocalizations.of(context);
    return l10n?.rainSafetyAdvisory ??
        'Rain / Thunderstorm Alert: Carry an umbrella and exercise caution on winding roads.';
  }
}
