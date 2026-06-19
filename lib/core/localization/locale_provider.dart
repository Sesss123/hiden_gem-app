import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/datasources/user_preference_service.dart';

part 'locale_provider.g.dart';

@riverpod
class LocaleNotifier extends _$LocaleNotifier {
  @override
  Locale? build() {
    final profile = UserPreferenceService.getProfile();
    if (profile.languageCode != null) {
      return Locale(profile.languageCode!);
    }
    return null;
  }

  Future<void> setLocale(Locale newLocale) async {
    state = newLocale;
    await UserPreferenceService.updateLanguage(newLocale.languageCode);
  }

  Future<void> toggleBilingual() async {
    final currentCode = state?.languageCode ?? 'en';
    final nextCode = currentCode == 'si' ? 'en' : 'si';
    await setLocale(Locale(nextCode));
  }
}
