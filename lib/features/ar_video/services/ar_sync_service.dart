import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'ar_video_service.dart';
import '../models/ar_video_content.dart';

/// Orchestrates synchronisation between the video engine and the Oracle narration.
/// ─ Keeps audio-video drift < 100 ms.
/// ─ Fires [onSyncPoint] callbacks so the UI can react to story beats.
class ARSyncService {
  final ARVideoService _videoService;
  final AudioPlayer _audioPlayer;
  final List<SyncPoint> _syncPoints;
  final void Function(SyncPoint)? onSyncPoint;

  StreamSubscription<Duration>? _audioPosSub;
  Timer? _driftTimer;

  int _lastFiredIndex = -1;

  ARSyncService({
    required ARVideoService videoService,
    required AudioPlayer audioPlayer,
    required List<SyncPoint> syncPoints,
    this.onSyncPoint,
  })  : _videoService = videoService,
        _audioPlayer = audioPlayer,
        _syncPoints = syncPoints;

  /// Begin synchronisation. Call after both video and audio are initialised.
  Future<void> start({
    required String narrationUrl,
  }) async {
    if (narrationUrl.isNotEmpty) {
      await _audioPlayer.setUrl(narrationUrl);
    }

    // ── Audio → Video drift correction via 100ms periodic timer ──────────
    _driftTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!_videoService.isReady) return;
      final audioPos = _audioPlayer.position;
      final videoPos = _videoService.position;
      final driftMs = (audioPos.inMilliseconds - videoPos.inMilliseconds).abs();
      if (driftMs > 100) {
        _videoService.seekTo(audioPos);
        debugPrint('[ARSyncService] Corrected drift: ${driftMs}ms');
      }

      // ── Sync-point event firing ────────────────────────────────────────
      _checkSyncPoints(videoPos);
    });

    // Listen to audio for play state cross-reference
    _audioPosSub = _audioPlayer.positionStream.listen((_) {});

    // Start playing both
    _audioPlayer.play();
    _videoService.play();
  }

  void _checkSyncPoints(Duration position) {
    final seconds = position.inSeconds;
    for (int i = _lastFiredIndex + 1; i < _syncPoints.length; i++) {
      if (_syncPoints[i].timeSeconds <= seconds) {
        _lastFiredIndex = i;
        onSyncPoint?.call(_syncPoints[i]);
        debugPrint('[ARSyncService] SyncPoint fired @ ${_syncPoints[i].timeSeconds}s');
      } else {
        break;
      }
    }
  }

  /// Pause both video and audio together.
  void pause() {
    _audioPlayer.pause();
    _videoService.pause();
  }

  /// Resume both together.
  void resume() {
    _audioPlayer.play();
    _videoService.play();
  }

  /// Hot-swap narration URL (e.g., language switch) without restarting video.
  Future<void> switchNarration(String newUrl) async {
    final currentPos = _audioPlayer.position;
    pause();
    await _audioPlayer.setUrl(newUrl);
    await _audioPlayer.seek(currentPos);
    resume();
  }

  Future<void> dispose() async {
    _driftTimer?.cancel();
    await _audioPosSub?.cancel();
    await _audioPlayer.dispose();
  }
}
