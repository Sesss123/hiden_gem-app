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
  String? _loadingUrl;

  VideoPlayerController? get controller => _controller;
  ARVideoState get state => _state;
  String? get error => _errorMessage;
  bool get isReady => _controller != null && _controller!.value.isInitialized;

  Duration get position => _controller?.value.position ?? Duration.zero;
  Duration get duration => _controller?.value.duration ?? Duration.zero;

  /// Loads and initialises the video.
  /// Tries the local cache first, falls back to network.
  Future<void> init(String url) async {
    _loadingUrl = url;
    if (_controller != null) {
      _controller!.removeListener(_onControllerUpdate);
      await _controller!.dispose();
      _controller = null;
    }
    _setState(ARVideoState.loading);
    VideoPlayerController? tempController;
    try {
      try {
        final cachedFile = await VideoCacheService.getVideo(url);
        if (_disposed || _loadingUrl != url) {
          return;
        }
        tempController = VideoPlayerController.file(cachedFile);
        await tempController.initialize();
      } catch (e) {
        if (tempController != null) {
          await tempController.dispose();
          tempController = null;
        }
        if (_disposed || _loadingUrl != url) return;
        debugPrint('[ARVideoService] Cache miss or corrupted file ($e), falling back to network: $url');
        tempController = VideoPlayerController.networkUrl(Uri.parse(url));
        await tempController.initialize();
      }

      if (_disposed || _loadingUrl != url) {
        await tempController.dispose();
        tempController = null;
        return;
      }

      _controller = tempController;
      tempController = null;
      _controller!.setLooping(true);
      _controller!.addListener(_onControllerUpdate);

      _setState(ARVideoState.paused);
    } catch (e) {
      // Whatever controller we were in the middle of building must not leak.
      if (tempController != null) {
        await tempController.dispose();
        tempController = null;
      }
      if (_disposed || _loadingUrl != url) return;
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

  bool _disposed = false;

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
    if (_disposed) return;
    if (_state == s) return;
    _state = s;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _controller?.removeListener(_onControllerUpdate);
    _controller?.dispose();
    _controller = null;
    super.dispose();
  }
}
