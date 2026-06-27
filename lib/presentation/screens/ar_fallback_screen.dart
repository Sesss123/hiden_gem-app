import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/analytics/analytics_service.dart';
import '../../data/models/ar_place_data.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/usage_limiter_service.dart';
import '../../data/datasources/monetization_service.dart';

class ARFallbackScreen extends StatefulWidget {
  final ARPlaceData arData;
  final String placeName;
  final String reason; // "unsupported" | "denied" | "failed"

  const ARFallbackScreen({
    super.key,
    required this.arData,
    required this.placeName,
    this.reason = "unsupported",
  });

  @override
  State<ARFallbackScreen> createState() => _ARFallbackScreenState();
}

class _ARFallbackScreenState extends State<ARFallbackScreen> {
  late VideoPlayerController _controller;
  bool _initialized = false;
  bool _hasError = false;
  String _activeMode = "video"; // "video" | "3d" | "story"

  @override
  void initState() {
    super.initState();
    AnalyticsService().logARSessionStarted(
        placeName: widget.placeName,
        tier: widget.arData.arTier,
        mode: 'fallback_${widget.reason}');
    // Default fallback video if URL is empty
    final videoUrl = widget.arData.fallbackVideoUrl.isNotEmpty 
        ? widget.arData.fallbackVideoUrl 
        : "https://assets.mixkit.co/videos/preview/mixkit-ancient-stone-walls-of-a-temple-41618-large.mp4";

    _controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
    _controller.initialize().then((_) {
      if (mounted) {
        setState(() {
          _initialized = true;
          _hasError = false;
        });
        _controller.setLooping(true);
        _controller.setVolume(0.0); // Muted by default as per requirement
        _controller.play();
      }
    }).catchError((e) {
      debugPrint("Video Player initialization error: $e");
      if (mounted) {
        setState(() {
          _initialized = false;
          _hasError = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldColor(context),
      body: Stack(
        children: [
          // Mode-specific content
          if (_activeMode == "video") _buildVideoBackground(),
          if (_activeMode == "3d") _build3DPlaceholder(),
          if (_activeMode == "story") _buildStoryMode(),

          // Gradient overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black54, 
                  _activeMode == "story" ? Colors.black87 : Colors.transparent, 
                  Colors.black87
                ],
              ),
            ),
          ),

          // Content
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      _circleBtn(Icons.close, () => Navigator.pop(context)),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.placeName, 
                            style: GoogleFonts.outfit(
                              color: AppTheme.textPrimary(context), 
                              fontSize: 20, 
                              fontWeight: FontWeight.bold
                            )
                          ),
                          Text(
                            widget.arData.historicalPeriod,
                            style: GoogleFonts.inter(
                              color: AppTheme.textSecondary(context),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      _buildModeSwitcher(),
                    ],
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: AppTheme.glassDecoration(
                      context,
                      opacity: 0.15, 
                      blur: 30, 
                      isDarkOverride: Theme.of(context).brightness == Brightness.dark,
                      radius: BorderRadius.circular(24),
                    ).copyWith(
                      border: Border.all(color: AppTheme.warningAmber.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          widget.reason == "denied" ? Icons.no_photography_outlined : Icons.videocam_outlined,
                          color: AppTheme.warningAmber,
                          size: 32,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _getTitle(),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            color: AppTheme.textPrimary(context), 
                            fontSize: 18, 
                            fontWeight: FontWeight.bold
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _getMessage(),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            color: AppTheme.textSecondary(context), 
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: AppTheme.warningAmber),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                foregroundColor: AppTheme.warningAmber,
                              ),
                              child: const Text("CLOSE VIEW"),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton.icon(
                              onPressed: () {
                                MonetizationService().showRewardedAd(
                                  context: context,
                                  onRewardEarned: (reward) async {
                                    await UsageLimiterService.provideBonusArSession();
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('✨ Oracle reward active! Fallback modes and premium content unlocked.'),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    }
                                  },
                                );
                              },
                              icon: const Icon(Icons.play_circle_fill, color: Colors.black, size: 16),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.warningAmber,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                foregroundColor: Colors.black,
                              ),
                              label: const Text("WATCH AD (UNLOCK)"),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                if (_activeMode == "video") _buildBottomInfoBar(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomInfoBar() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: AppTheme.warningAmber, size: 16),
          const SizedBox(width: 12),
          Text(
            "AR not available on this device · Showing 360° view",
            style: GoogleFonts.inter(color: AppTheme.textSecondary(context), fontSize: 11),
          ),
        ],
      ),
    ),
  );

  Widget _buildVideoBackground() {
    if (_hasError) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.video_library_outlined, color: Colors.white24, size: 48),
              const SizedBox(height: 16),
              Text(
                "Cinematic preview unavailable",
                style: GoogleFonts.inter(color: Colors.white38, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }
    if (!_initialized) return const Center(child: CircularProgressIndicator(color: Color(0xFFFFB300)));
    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _controller.value.size.width,
          height: _controller.value.size.height,
          child: VideoPlayer(_controller),
        ),
      ),
    );
  }

  Widget _build3DPlaceholder() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.threed_rotation, color: Color(0xFFFFB300), size: 80),
        const SizedBox(height: 24),
        Text(
          "Interactive 3D View",
          style: GoogleFonts.outfit(color: AppTheme.textPrimary(context), fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(
          "Touch to rotate monument",
          style: GoogleFonts.inter(color: AppTheme.textSecondary(context), fontSize: 13),
        ),
      ],
    ),
  );

  Widget _buildStoryMode() => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(24, 120, 24, 200),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "HISTORICAL STORY",
          style: GoogleFonts.inter(color: AppTheme.warningAmber, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 2),
        ),
        const SizedBox(height: 16),
        Text(
          "Unveiling the ${widget.arData.historicalPeriod}",
          style: GoogleFonts.outfit(color: AppTheme.textPrimary(context), fontSize: 32, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        Text(
          "Sri Lanka's heritage runs deep into the fabric of time. This site, dating back to the ${widget.arData.historicalPeriod}, was once the center of a thriving civilization that pioneered hydraulic engineering and spiritual architecture.\n\nThe stupa we see today was constructed using over 100 million sun-baked bricks, standing as a testament to the engineering marvels of ancient kings...",
          style: GoogleFonts.inter(color: AppTheme.textSecondary(context), fontSize: 16, height: 1.8),
        ),
        const SizedBox(height: 32),
        _buildAudioNarrationPill(),
        const SizedBox(height: 32),
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white.withValues(alpha: 0.05),
            border: Border.all(color: Colors.white10),
            image: const DecorationImage(
              image: NetworkImage("https://images.unsplash.com/photo-1588615467652-3fb374d08122?auto=format&fit=crop&w=800"),
              fit: BoxFit.cover,
              opacity: 0.6,
            ),
          ),
          child: const Center(
            child: Icon(Icons.palette_outlined, color: Color(0xFFFFB300), size: 32),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Illustration: Ancient Engineering (Concept Art)",
          style: GoogleFonts.inter(color: Colors.white38, fontSize: 12, fontStyle: FontStyle.italic),
        ),
      ],
    ),
  );

  Widget _buildAudioNarrationPill() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      color: AppTheme.warningAmber.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(30),
      border: Border.all(color: AppTheme.warningAmber.withValues(alpha: 0.3)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.play_circle_fill, color: Color(0xFFFFB300), size: 24),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("LISTEN TO NARRATION", style: GoogleFonts.inter(color: AppTheme.warningAmber, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
            Text("Sinhala & English available", style: GoogleFonts.inter(color: AppTheme.textSecondary(context), fontSize: 10)),
          ],
        ),
      ],
    ),
  );

  Widget _buildModeSwitcher() => Container(
    padding: const EdgeInsets.all(2),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        _modeBtn("video", Icons.videocam, "360°"),
        _modeBtn("3d", Icons.view_in_ar, "3D"),
        _modeBtn("story", Icons.menu_book, "Story"),
      ],
    ),
  );

  Widget _modeBtn(String mode, IconData icon, String label) {
    bool active = _activeMode == mode;
    return GestureDetector(
      onTap: () => setState(() => _activeMode = mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppTheme.warningAmber : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, color: active ? Colors.black : AppTheme.textSecondary(context), size: 14),
            const SizedBox(width: 4),
            Text(label, style: GoogleFonts.inter(color: active ? Colors.black : AppTheme.textSecondary(context), fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  String _getTitle() {
    if (_activeMode != "video") return "";
    if (widget.reason == "denied") return "Camera Permission Required";
    if (widget.reason == "unsupported") return "Device Not AR Ready";
    return "AR Loading Failed";
  }

  String _getMessage() {
    if (_activeMode != "video") return "";
    if (widget.reason == "denied") return "Camera access is needed for AR features. Enjoy this cinematic reconstruction video instead.";
    if (widget.reason == "unsupported") return "Your device doesn't support full ARCore/ARKit. Experience the historical era via this immersive cinematic view.";
    return "We couldn't load the historical 3D model. Showing the cinematic fallback view.";
  }

  Widget _circleBtn(IconData icon, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 40, height: 40,
      decoration: BoxDecoration(
        color: Colors.black45,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white24, width: 0.5)
      ),
      child: Icon(icon, color: AppTheme.textPrimary(context), size: 20)
    ),
  );
}
