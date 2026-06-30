import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/mocks/arcore_flutter_plugin.dart';
import 'package:video_player/video_player.dart';
import 'package:just_audio/just_audio.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../features/ar_video/screens/ar_video_library_screen.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/ar_video_service.dart';
import '../../data/models/ar_place_data.dart';
import '../widgets/oracle_orb.dart';

class ARVideoScreen extends StatefulWidget {
  final ARPlaceData arData;
  final String placeName;

  const ARVideoScreen({
    super.key,
    required this.arData,
    required this.placeName,
  });

  @override
  State<ARVideoScreen> createState() => _ARVideoScreenState();
}

class _ARVideoScreenState extends State<ARVideoScreen> with SingleTickerProviderStateMixin {
  late ArCoreController _arCoreController;
  final ARVideoService _videoService = ARVideoService();
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  bool _portalOpened = false;

  late AnimationController _portalAnimController;
  late Animation<double> _portalScale;

  @override
  void initState() {
    super.initState();
    _portalAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _portalScale = CurvedAnimation(parent: _portalAnimController, curve: Curves.elasticOut);

    _initSystems();
  }

  Future<void> _initSystems() async {
    final videoUrl = widget.arData.fallbackVideoUrl.isNotEmpty 
        ? widget.arData.fallbackVideoUrl 
        : "https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4"; // Fallback demo
    
    await _videoService.init(videoUrl);
    
    final audioUrl = widget.arData.audioUrlSi;
    if (audioUrl.isNotEmpty) {
      await _audioPlayer.setUrl(audioUrl);
    }
    
    _videoService.syncWithNarration(_audioPlayer);
  }

  void _onArCoreViewCreated(ArCoreController controller) {
    _arCoreController = controller;
    _arCoreController.onPlaneTap = _handlePlaneTap;
  }

  void _handlePlaneTap(List<ArCoreHitTestResult> hits) {
    if (_portalOpened || hits.isEmpty) return;

    setState(() {
      _portalOpened = true;
    });

    _portalAnimController.forward();
    _audioPlayer.play();
    _videoService.play();
  }

  @override
  void dispose() {
    _arCoreController.dispose();
    _videoService.dispose();
    _audioPlayer.dispose();
    _portalAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          ArCoreView(
            onArCoreViewCreated: _onArCoreViewCreated,
            enableTapRecognizer: true,
            enablePlaneRenderer: true,
          ),

          // Portal Display Logic
          if (_portalOpened && _videoService.controller != null && _videoService.controller!.value.isInitialized)
            Center(
              child: ScaleTransition(
                scale: _portalScale,
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.85,
                  height: MediaQuery.of(context).size.height * 0.5,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.sigiriyaOchre(context).withValues(alpha: 0.5),
                        blurRadius: 30,
                        spreadRadius: 5,
                      )
                    ],
                    border: Border.all(color: AppTheme.sigiriyaOchre(context), width: 2),
                  ),
                  child: ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: (_videoService.controller != null && _videoService.controller!.value.isInitialized)
                          ? AspectRatio(
                              aspectRatio: _videoService.controller!.value.aspectRatio,
                              child: VideoPlayer(_videoService.controller!),
                            )
                          : const Center(child: CircularProgressIndicator(color: AppPalette.rust)),
                  ),
                ),
              ),
            ),

          // UI Overlays
          _buildTopBar(),
          if (!_portalOpened) _buildScanningUI(),
          _buildOracleSyncUI(),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: 50, left: 20, right: 20,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          Text(
            "AR TIME TRAVEL",
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 3,
              fontSize: 18,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.video_library, color: Colors.white),
            onPressed: () => Navigator.pushReplacement(
              context, 
              MaterialPageRoute(builder: (_) => const ARVideoLibraryScreen())
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanningUI() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.center_focus_strong, color: Colors.white54, size: 64),
          const SizedBox(height: 16),
          Text(
            "SCAN GROUND TO OPEN PORTAL",
            style: GoogleFonts.inter(color: Colors.white70, fontSize: 12, letterSpacing: 1),
          ),
        ],
      ),
    );
  }

  Widget _buildOracleSyncUI() {
    return Positioned(
      bottom: 40, left: 0, right: 0,
      child: Column(
        children: [
          const OracleOrb(),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: StreamBuilder<Duration>(
              stream: _audioPlayer.positionStream,
              builder: (context, snapshot) {
                return Text(
                  _getNarrationSubtitle(snapshot.data?.inSeconds ?? 0),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 14,
                    height: 1.5,
                    fontStyle: FontStyle.italic,
                    shadows: [const Shadow(blurRadius: 10, color: Colors.black)],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _getNarrationSubtitle(int seconds) {
    // In a real app, this would come from a model.
    if (seconds < 5) return "Step into the portal to see ${widget.placeName} in its prime.";
    if (seconds < 15) return "Behold the golden age of the 5th century...";
    return "The Oracle reveals the hidden history of this sacred stone.";
  }
}
