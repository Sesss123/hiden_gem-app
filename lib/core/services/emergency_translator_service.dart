import 'translation_service.dart';
import 'voice_assistant_service.dart';

enum EmergencySituationType { medical, lost, accident, unsafe, other }

extension EmergencySituationTypeLabel on EmergencySituationType {
  String get englishLabel {
    switch (this) {
      case EmergencySituationType.medical:
        return "Medical emergency";
      case EmergencySituationType.lost:
        return "I am lost";
      case EmergencySituationType.accident:
        return "Traffic accident";
      case EmergencySituationType.unsafe:
        return "I feel unsafe";
      case EmergencySituationType.other:
        return "Emergency";
    }
  }
}

class EmergencyTranslatorResult {
  final String englishText;
  final String sinhalaText;
  const EmergencyTranslatorResult({required this.englishText, required this.sinhalaText});
}

/// Builds a plain-language emergency sentence (situation + GPS), translates
/// it to Sinhala, and can speak it aloud — so a tourist can hand their phone
/// to a bystander, police officer, or hospital staff and have their
/// situation and location communicated instantly, without a language
/// barrier. Reuses TranslationService (AI bridge + offline semantic
/// fallback) and VoiceAssistantService's existing Sinhala TTS tuning.
class EmergencyTranslatorService {
  /// A dedicated, richer offline phrase set for emergencies — the general
  /// TranslationService._getSemanticFallback() dictionary only covers basic
  /// tourist phrases (price/thank-you/hello) and doesn't have anything
  /// usable for a real emergency sentence, which is exactly the situation
  /// (no internet) this needs to work in.
  static const Map<EmergencySituationType, String> _offlineSinhalaTemplates = {
    EmergencySituationType.medical: "හදිසි වෛද්‍ය ගැටලුවක් තිබේ. කරුණාකර උදව් කරන්න.",
    EmergencySituationType.lost: "මම මගහැරී සිටිමි. කරුණාකර මට උදව් කරන්න.",
    EmergencySituationType.accident: "මාර්ග අනතුරක් සිදු වී ඇත. කරුණාකර උදව් කරන්න.",
    EmergencySituationType.unsafe: "මට අනාරක්ෂිත බවක් දැනේ. කරුණාකර පොලීසියට කතා කරන්න.",
    EmergencySituationType.other: "මට හදිසි උදව් අවශ්‍යයි.",
  };

  /// Builds the English situation sentence from the selected type, an
  /// optional free-text detail, and GPS coordinates (as a plain-language
  /// location description a non-technical listener can still act on).
  static String buildSituationText(
    EmergencySituationType type, {
    String? detail,
    double? lat,
    double? lng,
  }) {
    final buffer = StringBuffer(type.englishLabel);
    if (detail != null && detail.trim().isNotEmpty) {
      buffer.write('. ${detail.trim()}');
    }
    if (lat != null && lng != null) {
      buffer.write('. My location is ${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}.');
    }
    return buffer.toString();
  }

  /// Translates the situation to Sinhala. Falls back to a hand-written
  /// emergency template (not the generic tourist-phrase fallback) if the AI
  /// bridge is unreachable, so this still works with zero internet — the
  /// GPS coordinates are appended numerically either way, since digits read
  /// the same in both languages and don't need translation.
  static Future<EmergencyTranslatorResult> translateSituation(
    EmergencySituationType type, {
    String? detail,
    double? lat,
    double? lng,
  }) async {
    final englishText = buildSituationText(type, detail: detail, lat: lat, lng: lng);

    String sinhalaText;
    try {
      final translated = await TranslationService.translate(englishText, 'si');
      // TranslationService returns the original text unchanged if its own
      // fallback dictionary has no match — detect that case and use our
      // richer emergency-specific template instead of showing English text
      // under a "Sinhala" heading.
      sinhalaText = translated == englishText
          ? _localTemplate(type, lat: lat, lng: lng)
          : translated;
    } catch (_) {
      sinhalaText = _localTemplate(type, lat: lat, lng: lng);
    }

    return EmergencyTranslatorResult(englishText: englishText, sinhalaText: sinhalaText);
  }

  static String _localTemplate(EmergencySituationType type, {double? lat, double? lng}) {
    final template = _offlineSinhalaTemplates[type] ?? _offlineSinhalaTemplates[EmergencySituationType.other]!;
    if (lat != null && lng != null) {
      return '$template (${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)})';
    }
    return template;
  }

  /// Speaks the Sinhala text aloud using the app's existing Sinhala TTS
  /// tuning, so it can be played to a bystander/officer even if they can't
  /// read the screen.
  static Future<void> speakSinhala(String sinhalaText) {
    return VoiceAssistantService.speakAdvanced(sinhalaText, accent: 'lk_sinhala');
  }
}
