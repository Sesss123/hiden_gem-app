import 'package:hidden_gems_sl/core/theme/app_theme.dart';
import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../data/models/discovery_place.dart';
import '../../core/theme/oracle_ui_system.dart';
import '../../core/services/asset_cache_service.dart';
import '../widgets/cached_image.dart';
import 'package:hidden_gems_sl/core/utils/secure_logger.dart';
import '../../l10n/app_localizations.dart';

class AudioGuideScreen extends StatefulWidget {
  final DiscoveryPlace place;
  const AudioGuideScreen({super.key, required this.place});

  @override
  State<AudioGuideScreen> createState() => _AudioGuideScreenState();
}

class _AudioGuideScreenState extends State<AudioGuideScreen> with SingleTickerProviderStateMixin {
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;
  bool _isLoading = false;
  bool _hasError = false;
  String _currentLang = 'si'; // Default to Sinhala
  late AnimationController _pulseController;
  StreamSubscription<PlayerState>? _playerStateSubscription;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    // Bug fix: previously registered inside _initAudio(), which is also
    // called from _switchLanguage() on every language switch — that stacked
    // a new playerStateStream listener each time without ever cancelling the
    // old ones, so setState() ran multiple times per state change and the
    // listeners accumulated for the lifetime of the screen. Register once
    // here and cancel it in dispose().
    _playerStateSubscription = _player.playerStateStream.listen((state) {
      if (mounted) {
        setState(() => _isPlaying = state.playing);
      }
    });
    _initAudio();
  }

  Future<void> _initAudio() async {
    final url = _currentLang == 'si' ? widget.place.audioUrlSi : widget.place.audioUrlEn;
    if (url.isEmpty) {
      if (mounted) setState(() { _hasError = true; _isLoading = false; });
      return;
    }

    setState(() { _isLoading = true; _hasError = false; });

    try {
      final localPath = await AssetCacheService.getLocalPath(url);
      if (!mounted) return;
      if (localPath != null) {
        await _player.setFilePath(localPath);
      } else {
        await _player.setUrl(url);
      }
      if (mounted) setState(() => _isLoading = false);
    } catch (e, st) {
      SecureLogger.error("Audio init error", e, st, "AudioGuide");
      if (mounted) setState(() { _hasError = true; _isLoading = false; });
    }
  }

  Future<void> _togglePlayback() async {
    if (_isLoading || _hasError) return;
    if (_player.playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  Future<void> _switchLanguage(String lang) async {
    if (_currentLang == lang) return;
    await _player.stop();
    if (!mounted) return;
    setState(() => _currentLang = lang);
    await _initAudio();
    if (!mounted || _hasError) return;
    await _player.play();
  }

  @override
  void dispose() {
    _playerStateSubscription?.cancel();
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
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.colors.white.withValues(alpha: 0.12),
              ),
              child: Icon(Icons.close, color: AppTheme.colors.white, size: 18),
            ),
          ),
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
                border: Border.all(color: AppTheme.colors.white.withValues(alpha: 0.2), width: 4),
              ),
            ),
          ],
        ),
        SizedBox(height: 48),
        Text(
          widget.place.name,
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurface,
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: 8),
        Text(
          "${widget.place.district} · ${AppLocalizations.of(context)!.audioGuideLabel}",
          style: GoogleFonts.inter(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            fontWeight: FontWeight.w600,
          ),
        ),
        if (_hasError) ...[
          SizedBox(height: 12),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              AppLocalizations.of(context)!.audioGuideUnavailable,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
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
                icon: Icon(Icons.replay_10_rounded, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), size: 32),
                onPressed: () => _player.seek(Duration(seconds: _player.position.inSeconds - 10)),
              ),
              SizedBox(width: 40),
              GestureDetector(
                onTap: _hasError ? _initAudio : _togglePlayback,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _hasError
                        ? Theme.of(context).colorScheme.error
                        : Theme.of(context).colorScheme.secondary,
                  ),
                  child: Center(
                    child: _isLoading
                        ? SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(strokeWidth: 2.5, color: AppPalette.ink),
                          )
                        : Icon(
                            _hasError
                                ? Icons.refresh_rounded
                                : (_isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
                            color: AppPalette.ink,
                            size: 40,
                          ),
                  ),
                ),
              ),
              SizedBox(width: 40),
              IconButton(
                icon: Icon(Icons.forward_10_rounded, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), size: 32),
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
      borderRadius: BorderRadius.circular(100),
      borderColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _langTab(AppLocalizations.of(context)!.sinhalaShortLabel, "si"),
          _langTab(AppLocalizations.of(context)!.englishShortLabel, "en"),
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
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: active ? Theme.of(context).colorScheme.secondary : AppTheme.colors.transparent,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: active ? AppPalette.ink : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            fontWeight: FontWeight.w700,
            fontSize: 12,
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
                    inactiveTrackColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.15),
                    thumbColor: Theme.of(context).colorScheme.primary,
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
                      Text(_formatDuration(position), style: GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 11, fontWeight: FontWeight.bold)),
                      Text(_formatDuration(duration), style: GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 11)),
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
