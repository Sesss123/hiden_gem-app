import 'dart:async';
import 'package:video_player/video_player.dart';
import 'package:just_audio/just_audio.dart';
import '../utils/secure_logger.dart';

class ARVideoService {
  VideoPlayerController? _videoController;
  bool _isInitialized = false;

  VideoPlayerController? get controller => _videoController;
  bool get isInitialized => _isInitialized;

  /// Initializes the video engine with a remote URL.
  Future<void> init(String url) async {
    try {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(url));
      await _videoController!.initialize();
      _videoController!.setLooping(true);
      _isInitialized = true;
      SecureLogger.info('AR Video Engine Initialized: $url');
    } catch (e) {
      SecureLogger.error('AR Video Init Error: $e');
      _isInitialized = false;
    }
  }

  /// Synchronizes the video playback with the Oracle AI voice narration.
  /// This ensures that if the audio is paused or seeks, the video follows.
  void syncWithNarration(AudioPlayer oracle) {
    if (_videoController == null || !_isInitialized) return;

    // Listen to oracle position updates
    oracle.positionStream.listen((position) {
      final videoPos = _videoController!.value.position;
      final diff = (position.inMilliseconds - videoPos.inMilliseconds).abs();

      // If they drift by more than 200ms, force a seek on the video
      if (diff > 200) {
        _videoController!.seekTo(position);
      }
    });

    // Sync play/pause states
    oracle.playerStateStream.listen((state) {
      if (state.playing) {
        _videoController!.play();
      } else {
        _videoController!.pause();
      }
    });
  }

  void play() => _videoController?.play();
  void pause() => _videoController?.pause();

  Future<void> dispose() async {
    await _videoController?.dispose();
    _isInitialized = false;
  }
}
