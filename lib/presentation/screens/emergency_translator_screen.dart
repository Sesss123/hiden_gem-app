import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/emergency_translator_service.dart';

/// Full-screen, hand-to-a-stranger emergency communicator. Opened right
/// after SOS is triggered: picks a situation type, translates it to
/// Sinhala, shows it in large high-contrast text, and speaks it aloud —
/// so a tourist can show/play this to a bystander, police officer, or
/// hospital staff and be understood immediately, without needing to type
/// or explain anything themselves.
class EmergencyTranslatorScreen extends StatefulWidget {
  final EmergencySituationType initialType;

  const EmergencyTranslatorScreen({super.key, this.initialType = EmergencySituationType.other});

  @override
  State<EmergencyTranslatorScreen> createState() => _EmergencyTranslatorScreenState();
}

class _EmergencyTranslatorScreenState extends State<EmergencyTranslatorScreen> {
  late EmergencySituationType _selectedType;
  Position? _position;
  bool _isTranslating = true;
  bool _isSpeaking = false;
  EmergencyTranslatorResult? _result;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType;
    _loadAndTranslate();
  }

  Future<void> _loadAndTranslate() async {
    setState(() => _isTranslating = true);
    try {
      _position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      ).timeout(const Duration(seconds: 8));
    } catch (_) {
      _position = null;
    }

    final result = await EmergencyTranslatorService.translateSituation(
      _selectedType,
      lat: _position?.latitude,
      lng: _position?.longitude,
    );

    if (!mounted) return;
    setState(() {
      _result = result;
      _isTranslating = false;
    });
    _speak();
  }

  Future<void> _speak() async {
    if (_result == null) return;
    setState(() => _isSpeaking = true);
    await EmergencyTranslatorService.speakSinhala(_result!.sinhalaText);
    if (mounted) setState(() => _isSpeaking = false);
  }

  void _selectType(EmergencySituationType type) {
    if (type == _selectedType) return;
    HapticFeedback.selectionClick();
    setState(() => _selectedType = type);
    _loadAndTranslate();
  }

  Future<void> _openMap() async {
    if (_position == null) return;
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=${_position!.latitude},${_position!.longitude}');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.colors.black,
      appBar: AppBar(
        backgroundColor: AppTheme.colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: AppTheme.colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Emergency Translator",
          style: GoogleFonts.outfit(color: AppTheme.colors.white, fontWeight: FontWeight.w800, fontSize: 17),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "Show this screen to a bystander, police officer, or hospital staff — it's speaking Sinhala for you.",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: AppTheme.colors.white70, fontSize: 12.5, height: 1.5),
              ),
              const SizedBox(height: 18),
              _buildTypeSelector(),
              const SizedBox(height: 20),
              Expanded(child: _buildSinhalaBanner()),
              const SizedBox(height: 16),
              _buildLocationRow(),
              const SizedBox(height: 16),
              _buildActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    final types = EmergencySituationType.values;
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: types.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final type = types[i];
          final isSelected = type == _selectedType;
          return GestureDetector(
            onTap: () => _selectType(type),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.errorRed : AppTheme.colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                type.englishLabel,
                style: GoogleFonts.inter(
                  color: AppTheme.colors.white,
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSinhalaBanner() {
    if (_isTranslating || _result == null) {
      return const Center(child: CircularProgressIndicator(color: AppPalette.rust));
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.errorRed, width: 2),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _result!.sinhalaText,
              textAlign: TextAlign.center,
              style: GoogleFonts.notoSansSinhala(
                color: AppPalette.ink,
                fontSize: 26,
                fontWeight: FontWeight.w700,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Divider(color: AppPalette.ink.withValues(alpha: 0.15)),
            const SizedBox(height: 12),
            Text(
              _result!.englishText,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: AppTheme.textSecondary(context), fontSize: 13, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationRow() {
    return GestureDetector(
      onTap: _position != null ? _openMap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(Icons.my_location_rounded, color: AppPalette.heroOchre, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _position != null
                    ? '${_position!.latitude.toStringAsFixed(5)}, ${_position!.longitude.toStringAsFixed(5)} — tap to open in Maps'
                    : 'Location unavailable',
                style: GoogleFonts.inter(color: AppTheme.colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
            if (_position != null) Icon(Icons.chevron_right_rounded, color: AppTheme.colors.white38, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildActions() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: (_isTranslating || _isSpeaking) ? null : _speak,
        icon: Icon(_isSpeaking ? Icons.volume_up_rounded : Icons.replay_rounded, color: AppTheme.colors.white),
        label: Text(
          _isSpeaking ? "Speaking…" : "Play again",
          style: GoogleFonts.inter(color: AppTheme.colors.white, fontWeight: FontWeight.w700, fontSize: 15),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppPalette.rust,
          disabledBackgroundColor: AppPalette.rust.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
        ),
      ),
    );
  }
}
