import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';
import 'video_cache_service.dart';

enum ARVideoState { idle, loading, buffering, playing, paused, error }

/// Wraps [VideoPlayerController] with a clean public API for the AR engine.
/// Handles caching, buffering events, and error recovery.
class ARVideoService extends ChangeNotifier {
  VideoPlayerController? _controller;
  ARVideoState _state = ARVideoState.idle;
  String? _errorMessage;

  VideoPlayerController? get controller => _controller;
  ARVideoState get state => _state;
  String? get error => _errorMessage;
  bool get isReady => _controller != null && _controller!.value.isInitialized;

  Duration get position => _controller?.value.position ?? Duration.zero;
  Duration get duration => _controller?.value.duration ?? Duration.zero;

  /// Loads and initialises the video.
  /// Tries the local cache first, falls back to network.
  Future<void> init(String url) async {
    _setState(ARVideoState.loading);
    try {
      File cachedFile;
      try {
        cachedFile = await VideoCacheService.getVideo(url);
        _controller = VideoPlayerController.file(cachedFile);
      } catch (_) {
        // Cache fail — stream direct from network
        debugPrint('[ARVideoService] Cache miss, streaming from: $url');
        _controller = VideoPlayerController.networkUrl(Uri.parse(url));
      }

      await _controller!.initialize();
      _controller!.setLooping(true);

      // Forward buffering states
      _controller!.addListener(_onControllerUpdate);

      _setState(ARVideoState.paused);
    } catch (e) {
      _errorMessage = e.toString();
      _setState(ARVideoState.error);
      debugPrint('[ARVideoService] Init error: $e');
    }
  }

  void _onControllerUpdate() {
    if (_controller == null) return;
    final v = _controller!.value;
    if (v.isBuffering) {
      _setState(ARVideoState.buffering);
    } else if (v.isPlaying) {
      _setState(ARVideoState.playing);
    } else if (v.isInitialized && !v.isPlaying) {
      _setState(ARVideoState.paused);
    }
  }

  void play() {
    _controller?.play();
  }

  void pause() {
    _controller?.pause();
  }

  Future<void> seekTo(Duration position) async {
    await _controller?.seekTo(position);
  }

  void _setState(ARVideoState s) {
    if (_state == s) return;
    _state = s;
    notifyListeners();
  }

  @override
  Future<void> dispose() async {
    _controller?.removeListener(_onControllerUpdate);
    await _controller?.dispose();
    _controller = null;
    super.dispose();
  }
}
