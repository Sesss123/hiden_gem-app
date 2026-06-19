import 'dart:async';
import 'package:arcore_flutter_plugin/arcore_flutter_plugin.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:video_player/video_player.dart';

import '../models/ar_video_content.dart';
import '../services/ar_video_service.dart';
import '../services/ar_sync_service.dart';
import '../services/subtitle_service.dart';
import '../services/video_cache_service.dart';
import '../../../../core/theme/app_theme.dart';

class ARVideoScreen extends StatefulWidget {
  final ARVideoContent content;

  const ARVideoScreen({super.key, required this.content});

  @override
  State<ARVideoScreen> createState() => _ARVideoScreenState();
}

class _ARVideoScreenState extends State<ARVideoScreen>
    with TickerProviderStateMixin {

  // ── Services ───────────────────────────────────────────────────────────────
  late final ARVideoService _videoService;
  late final AudioPlayer _audioPlayer;
  late ARSyncService _syncService;
  late SubtitleService _subtitleService;

  // ── AR ─────────────────────────────────────────────────────────────────────
  ArCoreController? _arController;
  bool _surfaceDetected = false;
  bool _videoPlaced = false;

  // ── UI state ───────────────────────────────────────────────────────────────
  bool _isReady = false;
  bool _hasError = false;
  String _errorMsg = '';
  NarrationLang _lang = NarrationLang.english;
  String _subtitle = '';

  // ── Animations ─────────────────────────────────────────────────────────────
  late AnimationController _portalController;
  late Animation<double> _portalScale;
  late Animation<double> _portalOpacity;

  late AnimationController _pulseController;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _videoService = ARVideoService();
    _audioPlayer = AudioPlayer();

    _subtitleService = SubtitleService(
      syncPoints: widget.content.syncPoints,
      initialLang: NarrationLang.english,
    );

    // Portal entry animation
    _portalController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1200),
    );
    _portalScale = CurvedAnimation(parent: _portalController, curve: Curves.elasticOut);
    _portalOpacity = CurvedAnimation(parent: _portalController, curve: Curves.easeIn);

    // Scan pulse
    _pulseController = AnimationController(
      vsync: this, duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Pre-cache, then init video
    VideoCacheService.preload(widget.content.videoUrl).then((_) => _initVideo());
  }

  Future<void> _initVideo() async {
    await _videoService.init(widget.content.videoUrl);

    if (!_videoService.isReady) {
      if (mounted) setState(() { _hasError = true; _errorMsg = _videoService.error ?? 'Unknown error'; });
      return;
    }

    _syncService = ARSyncService(
      videoService: _videoService,
      audioPlayer: _audioPlayer,
      syncPoints: widget.content.syncPoints,
      onSyncPoint: (sp) {
        if (mounted) setState(() => _subtitle = _lang == NarrationLang.english ? sp.textEn : sp.textSi);
      },
    );

    // Update subtitle from video position continuously
    _videoService.controller?.addListener(_onVideoTick);

    if (mounted) setState(() => _isReady = true);
  }

  void _onVideoTick() {
    final pos = _videoService.position;
    final newSub = _subtitleService.subtitleAt(pos);
    if (newSub != _subtitle && mounted) setState(() => _subtitle = newSub);
  }

  // ── AR ─────────────────────────────────────────────────────────────────────
  void _onArCoreViewCreated(ArCoreController controller) {
    _arController = controller;
    _arController!.onPlaneTap = _handlePlaneTap;
    setState(() => _surfaceDetected = true);
  }

  void _handlePlaneTap(List<ArCoreHitTestResult> hits) async {
    if (_videoPlaced || !_isReady || hits.isEmpty) return;
    setState(() => _videoPlaced = true);
    _portalController.forward();

    final narUrl = _lang == NarrationLang.english
        ? widget.content.narrationUrlEn
        : widget.content.narrationUrlSi;
    await _syncService.start(narrationUrl: narUrl);
  }

  // ── Language toggle ─────────────────────────────────────────────────────────
  Future<void> _toggleLang() async {
    _subtitleService.toggleLang();
    setState(() => _lang = _subtitleService.currentLang);

    final newUrl = _lang == NarrationLang.english
        ? widget.content.narrationUrlEn
        : widget.content.narrationUrlSi;
    if (newUrl.isNotEmpty) {
      await _syncService.switchNarration(newUrl);
    }

    HapticFeedback.selectionClick();
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _videoService.controller?.removeListener(_onVideoTick);
    _syncService.dispose();
    _videoService.dispose();
    _arController?.dispose();
    _portalController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  // ── BUILD ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // AR Camera background
          ArCoreView(
            onArCoreViewCreated: _onArCoreViewCreated,
            enableTapRecognizer: true,
            enablePlaneRenderer: true,
          ),

          // Cinematic video portal overlay
          if (_videoPlaced && _isReady) _buildVideoPortal(),

          // Loading overlay
          if (!_isReady && !_hasError) _buildLoadingOverlay(),

          // Error overlay
          if (_hasError) _buildErrorOverlay(),

          // Scan hint (before tap)
          if (_surfaceDetected && !_videoPlaced && _isReady) _buildScanHint(),

          // Top control bar
          _buildTopBar(),

          // Language toggle + playback
          if (_videoPlaced) _buildControlBar(),

          // Subtitle bar
          if (_videoPlaced && _subtitle.isNotEmpty) _buildSubtitleBar(),
        ],
      ),
    );
  }

  Widget _buildVideoPortal() {
    return Center(
      child: ScaleTransition(
        scale: _portalScale,
        child: FadeTransition(
          opacity: _portalOpacity,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.88,
            constraints: const BoxConstraints(maxHeight: 420),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: AppTheme.sigiriyaOchre(context).withValues(alpha: 0.7), width: 2),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.sigiriyaOchre(context).withValues(alpha: 0.4),
                  blurRadius: 40, spreadRadius: 5,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: AspectRatio(
                aspectRatio: _videoService.controller!.value.aspectRatio,
                child: VideoPlayer(_videoService.controller!),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black87,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Color(0xFFFFB300)),
            const SizedBox(height: 20),
            Text(
              'Preparing time portal…',
              style: GoogleFonts.outfit(color: Colors.white70, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black87,
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 56),
          const SizedBox(height: 16),
          Text('Video unavailable', style: GoogleFonts.outfit(color: Colors.white, fontSize: 18)),
          const SizedBox(height: 8),
          Text(_errorMsg, style: GoogleFonts.inter(color: Colors.white38, fontSize: 12), textAlign: TextAlign.center),
          const SizedBox(height: 24),
          TextButton(
            onPressed: () { setState(() { _hasError = false; }); _initVideo(); },
            child: const Text('Retry', style: TextStyle(color: Color(0xFFFFB300))),
          ),
        ]),
      ),
    );
  }

  Widget _buildScanHint() {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        ScaleTransition(
          scale: _pulse,
          child: const Icon(Icons.touch_app, color: Colors.white54, size: 72),
        ),
        const SizedBox(height: 16),
        Text(
          'Tap the ground to open the portal',
          style: GoogleFonts.inter(color: Colors.white70, fontSize: 14, letterSpacing: 0.8),
        ),
      ]),
    );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: 0, left: 0, right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              _glassBtn(Icons.arrow_back_ios_rounded, () => Navigator.pop(context)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.sigiriyaOchre(context).withValues(alpha: 0.4)),
                ),
                child: Text(
                  widget.content.name.toUpperCase(),
                  style: GoogleFonts.outfit(
                    color: AppTheme.sigiriyaOchre(context),
                    fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 2,
                  ),
                ),
              ),
              const Spacer(),
              _glassBtn(Icons.info_outline, () {}),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlBar() {
    return Positioned(
      bottom: 90, left: 24, right: 24,
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        _glassBtn(
          _videoService.state == ARVideoState.playing ? Icons.pause : Icons.play_arrow,
          () {
            _videoService.state == ARVideoState.playing
                ? _syncService.pause()
                : _syncService.resume();
            setState(() {});
          },
        ),
        const SizedBox(width: 16),
        GestureDetector(
          onTap: _toggleLang,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white24),
            ),
            child: Text(
              _lang == NarrationLang.english ? 'EN | 🇬🇧' : 'SI | 🇱🇰',
              style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildSubtitleBar() {
    return Positioned(
      bottom: 30, left: 24, right: 24,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          _subtitle,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 14, height: 1.5,
            shadows: [const Shadow(blurRadius: 8, color: Colors.black)],
          ),
        ),
      ),
    );
  }

  Widget _glassBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          color: Colors.black54, shape: BoxShape.circle,
          border: Border.all(color: Colors.white24),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}
