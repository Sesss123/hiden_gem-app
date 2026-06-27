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
  final String description;
  final String duration;
  final String guideName;

  const ARVideoContent({
    required this.locationId,
    required this.name,
    required this.videoUrl,
    this.narrationUrlEn = '',
    this.narrationUrlSi = '',
    this.syncPoints = const [],
    this.description = '',
    this.duration = '',
    this.guideName = '',
  });

  factory ARVideoContent.fromMap(String id, Map<String, dynamic> map) {
    final desc = map['description'] as String? ?? _getDefaultDescription(id);
    final dur = map['duration'] as String? ?? _getDefaultDuration(id);
    final guide = map['guideName'] as String? ?? _getDefaultGuide(id);

    return ARVideoContent(
      locationId: id,
      name: map['name'] as String? ?? '',
      videoUrl: map['videoUrl'] as String? ?? '',
      narrationUrlEn: map['narrationUrlEn'] as String? ?? '',
      narrationUrlSi: map['narrationUrlSi'] as String? ?? '',
      syncPoints: (map['syncPoints'] as List<dynamic>? ?? [])
          .map((e) => SyncPoint.fromMap(e as Map<String, dynamic>))
          .toList(),
      description: desc,
      duration: dur,
      guideName: guide,
    );
  }

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
        description: 'Explore the ancient fortress of Sigiriya, a stunning architectural marvel rising 200 meters above the forest canopy. Journey through the water gardens, view the centuries-old frescoes, and ascend to the summit palace built by King Kashyapa.',
        duration: '3m 45s',
        guideName: 'Prof. Senaka Bandaranaike',
      );

  static String _getDefaultDescription(String id) {
    switch (id.toLowerCase()) {
      case 'sigiriya':
        return 'Explore the ancient fortress of Sigiriya, a stunning architectural marvel rising 200 meters above the forest canopy. Journey through the water gardens, view the centuries-old frescoes, and ascend to the summit palace built by King Kashyapa.';
      case 'ella':
      case 'nine_arch':
        return 'Step into the misty highlands of Ella, where the iconic Nine Arch Bridge spans across lush tea fields, showcasing colonial engineering in harmony with nature.';
      case 'galle':
      case 'galle_fort':
        return 'Walk through the historic Galle Fort, a UNESCO World Heritage site where colonial Dutch architecture meets the Indian Ocean breeze.';
      case 'kandy':
      case 'kandy_lake':
        return 'Experience the sacred legacy of Kandy Lake and the Temple of the Tooth Relic, the spiritual capital of Sri Lanka.';
      case 'nuwara_eliya':
        return 'Traverse the picturesque tea estates of Nuwara Eliya, Sri Lanka\'s scenic "Little England" wrapped in cool mountain mist.';
      default:
        return 'Discover the rich history, breathtaking vistas, and hidden cultural secrets of this heritage site in Sri Lanka.';
    }
  }

  static String _getDefaultDuration(String id) {
    switch (id.toLowerCase()) {
      case 'sigiriya': return '3m 45s';
      case 'ella': case 'nine_arch': return '2m 15s';
      case 'galle': case 'galle_fort': return '4m 10s';
      case 'kandy': case 'kandy_lake': return '3m 05s';
      case 'nuwara_eliya': return '2m 45s';
      default: return '3m 00s';
    }
  }

  static String _getDefaultGuide(String id) {
    switch (id.toLowerCase()) {
      case 'sigiriya': return 'Prof. Senaka Bandaranaike';
      case 'ella': case 'nine_arch': return 'Devinda Rambukwelle';
      case 'galle': case 'galle_fort': return 'Anura De Silva';
      case 'kandy': case 'kandy_lake': return 'K. M. Jayaratne';
      case 'nuwara_eliya': return 'Suren Goonewardene';
      default: return 'National Heritage Guide';
    }
  }
}
