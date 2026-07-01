import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../data/models/discovery_place.dart';
import '../../core/theme/oracle_ui_system.dart';
import '../../core/services/asset_cache_service.dart';
import '../widgets/cached_image.dart';

class AudioGuideScreen extends StatefulWidget {
  final DiscoveryPlace place;
  const AudioGuideScreen({super.key, required this.place});

  @override
  State<AudioGuideScreen> createState() => _AudioGuideScreenState();
}

class _AudioGuideScreenState extends State<AudioGuideScreen> with SingleTickerProviderStateMixin {
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;
  String _currentLang = 'si'; // Default to Sinhala
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _initAudio();
  }

  Future<void> _initAudio() async {
    final url = _currentLang == 'si' ? widget.place.audioUrlSi : widget.place.audioUrlEn;
    if (url.isEmpty) return;

    try {
      final localPath = await AssetCacheService.getLocalPath(url);
      if (localPath != null) {
        await _player.setFilePath(localPath);
      } else {
        await _player.setUrl(url);
      }
    } catch (e) {
      debugPrint("Audio init error: $e");
    }

    _player.playerStateStream.listen((state) {
      if (mounted) {
        setState(() => _isPlaying = state.playing);
      }
    });
  }

  Future<void> _togglePlayback() async {
    if (_player.playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  Future<void> _switchLanguage(String lang) async {
    if (_currentLang == lang) return;
    await _player.stop();
    setState(() => _currentLang = lang);
    await _initAudio();
    await _player.play();
  }

  @override
  void dispose() {
    _player.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Background Image with Blur
          Positioned.fill(
            child: CachedImage(
              url: widget.place.imageUrl,
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
              child: Container(color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.8)),
            ),
          ),
          OracleUI.auraBackground(
            child: SafeArea(
              child: Column(
                children: [
                  _buildHeader(),
                  const Spacer(),
                  _buildVisualizer(),
                  const Spacer(),
                  _buildControls(),
                  SizedBox(height: 60),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.close, color: Colors.white, size: 28),
            onPressed: () => Navigator.pop(context),
          ),
          OracleUI.glassContainer(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            borderRadius: BorderRadius.circular(20),
            borderColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
            child: OracleUI.neonText(
              "AUDIO GUIDE",
              style: GoogleFonts.outfit(
                color: Theme.of(context).colorScheme.primary, 
                fontWeight: FontWeight.w900, 
                letterSpacing: 2, 
                fontSize: 10
              ),
              glowColor: Theme.of(context).colorScheme.primary,
            ),
          ),
          SizedBox(width: 48), // Placeholder for symmetry
        ],
      ),
    );
  }

  Widget _buildVisualizer() {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            OracleUI.glassContainer(
              width: 220,
              height: 220,
              borderRadius: BorderRadius.circular(110),
              borderColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              child: SizedBox(),
            ).animate(onPlay: (c) => c.repeat()).scale(
              begin: const Offset(1.0, 1.0),
              end: const Offset(1.2, 1.2),
              duration: 2000.ms,
              curve: Curves.easeInOut,
            ).fadeIn(duration: 1000.ms).fadeOut(delay: 1000.ms),
            Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: NetworkImage(widget.place.imageUrl),
                  fit: BoxFit.cover,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                    blurRadius: 40,
                    spreadRadius: 5,
                  )
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 48),
        OracleUI.neonText(
          widget.place.name.toUpperCase(),
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: 26, 
            fontWeight: FontWeight.w900, 
            color: Colors.white,
            letterSpacing: 1.5,
          ),
        ),
        SizedBox(height: 12),
        Text(
          widget.place.district.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 11, 
            color: Colors.white24, 
            letterSpacing: 3,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget _buildControls() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        children: [
          _buildLanguageSelector(),
          SizedBox(height: 30),
          _buildProgressSlider(),
          SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.replay_10_rounded, color: Colors.white30, size: 32),
                onPressed: () => _player.seek(Duration(seconds: _player.position.inSeconds - 10)),
              ),
              SizedBox(width: 40),
              GestureDetector(
                onTap: _togglePlayback,
                child: OracleUI.glassContainer(
                  width: 90,
                  height: 90,
                  borderRadius: BorderRadius.circular(45),
                  borderColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                  child: Center(
                    child: Icon(
                      _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, 
                      color: Theme.of(context).colorScheme.primary, 
                      size: 48
                    ),
                  ),
                ),
              ),
              SizedBox(width: 40),
              IconButton(
                icon: Icon(Icons.forward_10_rounded, color: Colors.white30, size: 32),
                onPressed: () => _player.seek(Duration(seconds: _player.position.inSeconds + 10)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSelector() {
    return OracleUI.glassContainer(
      padding: EdgeInsets.all(4),
      borderRadius: BorderRadius.circular(30),
      borderColor: Colors.white.withValues(alpha: 0.05),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _langTab("සිංහල", "si"),
          _langTab("ENGLISH", "en"),
        ],
      ),
    );
  }

  Widget _langTab(String label, String code) {
    bool active = _currentLang == code;
    return GestureDetector(
      onTap: () => _switchLanguage(code),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: active ? Theme.of(context).colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            color: active ? Colors.black : Colors.white24, 
            fontWeight: FontWeight.w900, 
            fontSize: 10,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildProgressSlider() {
    return StreamBuilder<Duration?>(
      stream: _player.durationStream,
      builder: (context, snapshot) {
        final duration = snapshot.data ?? Duration.zero;
        return StreamBuilder<Duration>(
          stream: _player.positionStream,
          builder: (context, snapshot) {
            var position = snapshot.data ?? Duration.zero;
            if (position > duration) position = duration;
            return Column(
              children: [
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: Theme.of(context).colorScheme.primary,
                    inactiveTrackColor: Colors.white.withValues(alpha: 0.05),
                    thumbColor: Colors.white,
                    overlayColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 0),
                  ),
                  child: Slider(
                    min: 0.0,
                    max: duration.inMilliseconds.toDouble(),
                    value: position.inMilliseconds.toDouble(),
                    onChanged: (value) {
                      _player.seek(Duration(milliseconds: value.toInt()));
                    },
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_formatDuration(position), style: GoogleFonts.inter(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
                      Text(_formatDuration(duration), style: GoogleFonts.inter(color: Colors.white38, fontSize: 11)),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }
}
