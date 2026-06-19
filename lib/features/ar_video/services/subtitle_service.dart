import '../models/ar_video_content.dart';

enum NarrationLang { english, sinhala }

/// Provides the correct subtitle for the current video position.
/// Keeps track of language preference independently of playback state,
/// so switching language never interrupts the video.
class SubtitleService {
  final List<SyncPoint> _syncPoints;
  NarrationLang _lang;

  SubtitleService({
    required List<SyncPoint> syncPoints,
    NarrationLang initialLang = NarrationLang.english,
  })  : _syncPoints = syncPoints,
        _lang = initialLang;

  NarrationLang get currentLang => _lang;

  /// Toggle between English and Sinhala — does NOT touch the video controller.
  void toggleLang() {
    _lang = _lang == NarrationLang.english
        ? NarrationLang.sinhala
        : NarrationLang.english;
  }

  void setLang(NarrationLang lang) => _lang = lang;

  /// Returns the active subtitle text for [position].
  /// Returns the most recent cue whose [SyncPoint.timeSeconds] <= position.
  String subtitleAt(Duration position) {
    final seconds = position.inSeconds;
    SyncPoint? active;
    for (final sp in _syncPoints) {
      if (sp.timeSeconds <= seconds) {
        active = sp;
      } else {
        break;
      }
    }
    if (active == null) return '';
    return _lang == NarrationLang.english ? active.textEn : active.textSi;
  }

  /// Streams subtitle changes based on a position stream (e.g. from video controller).
  Stream<String> subtitleStream(Stream<Duration> positionStream) =>
      positionStream.map(subtitleAt);
}
