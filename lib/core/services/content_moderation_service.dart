class ContentModerationService {
  static final RegExp _blockedContent = RegExp(
    r'\b(?:kill\s+yourself|kys|n[i1]gg(?:er|a)|f[a@]gg?[o0]t|rape|child\s+porn)\b',
    caseSensitive: false,
  );

  static String validateAndNormalize(
    String value, {
    required String fieldName,
    required int maxLength,
  }) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      throw ArgumentError('$fieldName cannot be empty.');
    }
    if (normalized.length > maxLength) {
      throw ArgumentError('$fieldName must be $maxLength characters or fewer.');
    }
    if (_blockedContent.hasMatch(normalized)) {
      throw ArgumentError('$fieldName contains prohibited content.');
    }
    return normalized;
  }
}
