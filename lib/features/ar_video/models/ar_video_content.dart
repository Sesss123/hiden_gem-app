/// A single timed narration cue — maps a video timestamp to bilingual text.
class SyncPoint {
  final int timeSeconds;
  final String textEn;
  final String textSi;

  const SyncPoint({
    required this.timeSeconds,
    required this.textEn,
    required this.textSi,
  });

  factory SyncPoint.fromMap(Map<String, dynamic> map) => SyncPoint(
        timeSeconds: map['time'] as int? ?? 0,
        textEn: map['text_en'] as String? ?? '',
        textSi: map['text_si'] as String? ?? '',
      );

  Map<String, dynamic> toMap() => {
        'time': timeSeconds,
        'text_en': textEn,
        'text_si': textSi,
      };
}

/// Full AR video content descriptor for one heritage location.
class ARVideoContent {
  final String locationId;
  final String name;
  final String videoUrl;       // CDN URL (H.264 / 720p)
  final String narrationUrlEn; // TTS audio — English
  final String narrationUrlSi; // TTS audio — Sinhala
  final List<SyncPoint> syncPoints;

  const ARVideoContent({
    required this.locationId,
    required this.name,
    required this.videoUrl,
    this.narrationUrlEn = '',
    this.narrationUrlSi = '',
    this.syncPoints = const [],
  });

  factory ARVideoContent.fromMap(String id, Map<String, dynamic> map) =>
      ARVideoContent(
        locationId: id,
        name: map['name'] as String? ?? '',
        videoUrl: map['videoUrl'] as String? ?? '',
        narrationUrlEn: map['narrationUrlEn'] as String? ?? '',
        narrationUrlSi: map['narrationUrlSi'] as String? ?? '',
        syncPoints: (map['syncPoints'] as List<dynamic>? ?? [])
            .map((e) => SyncPoint.fromMap(e as Map<String, dynamic>))
            .toList(),
      );

  // ── Demo content used when Firestore is unavailable ───────────────────────
  static ARVideoContent sigiriyaDemo() => const ARVideoContent(
        locationId: 'sigiriya',
        name: 'Sigiriya',
        videoUrl:
            'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
        narrationUrlEn: '',
        narrationUrlSi: '',
        syncPoints: [
          SyncPoint(timeSeconds: 0,  textEn: 'Welcome to Sigiriya — the Lion Rock.', textSi: 'සීගිරිය — සිංහ ගලට සාදරයෙන් පිළිගනිමු.'),
          SyncPoint(timeSeconds: 5,  textEn: 'Built in the 5th century by King Kashyapa.', textSi: '5 වන සියවසේ රජ කාශ්‍යප විසින් ඉදිකරන ලදී.'),
          SyncPoint(timeSeconds: 12, textEn: 'The palace once rose 200 metres above the plains.', textSi: 'මාළිගාව එකල තලාවෙන් මීටර් 200ක් ඉහළ විය.'),
          SyncPoint(timeSeconds: 20, textEn: 'Marvel at the frescoes that survived 1600 years.', textSi: 'වසර 1600 ක් ඉතිරි වූ ෆ්‍රෙස්කෝ පින්තූරවලට පන දෙමු.'),
        ],
      );
}
