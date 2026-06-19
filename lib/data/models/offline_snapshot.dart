import '../models/tour_session.dart';
import '../models/broadcast_message.dart';

class OfflineSnapshot {
  final TourSession lastSession;
  final List<BroadcastMessage> recentBroadcasts;
  final DateTime updatedAt;
  final String? networkStatus;

  OfflineSnapshot({
    required this.lastSession,
    this.recentBroadcasts = const [],
    required this.updatedAt,
    this.networkStatus,
  });

  Map<String, dynamic> toJson() => {
    'lastSession': lastSession.toJson(),
    'recentBroadcasts': recentBroadcasts.map((b) => b.toJson()).toList(),
    'updatedAt': updatedAt.toIso8601String(),
    'networkStatus': networkStatus,
  };

  factory OfflineSnapshot.fromJson(Map<String, dynamic> json) => OfflineSnapshot(
    lastSession: TourSession.fromJson(json['lastSession']),
    recentBroadcasts: (json['recentBroadcasts'] as List)
        .map((b) => BroadcastMessage.fromJson(b))
        .toList(),
    updatedAt: DateTime.parse(json['updatedAt']),
    networkStatus: json['networkStatus'],
  );
}
