import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/oracle_ui_system.dart';
import '../../core/services/voice_assistant_service.dart';
import '../../core/services/usage_limiter_service.dart';
import '../../data/datasources/monetization_service.dart';
import '../../l10n/app_localizations.dart';
import 'limit_reached_dialog.dart';

class OracleOrb extends StatefulWidget {
  const OracleOrb({super.key});

  @override
  State<OracleOrb> createState() => _OracleOrbState();
}

class _OracleOrbState extends State<OracleOrb> {
  bool _isListening = false;
  String _words = "Listening...";

  void _toggleOracle() async {
    if (_isListening) {
      await VoiceAssistantService.stopListening();
      if (!mounted) return;
      setState(() => _isListening = false);
      return;
    }

    // Gate every new query on the monthly Oracle-chat quota — mirrors the
    // check-then-consume pattern used for AR sessions (place_details_screen)
    // so a rapid double-tap can't slip past the check before it's consumed.
    final canAccess = await UsageLimiterService.canAccessOracleChat();
    if (!mounted) return;
    if (!canAccess) {
      _showLimitReachedDialog();
      return;
    }
    final claimed = await UsageLimiterService.incrementOracleChat();
    if (!mounted) return;
    if (!claimed) {
      _showLimitReachedDialog();
      return;
    }

    setState(() {
      _isListening = true;
      _words = "Oracle is listening...";
    });

    await VoiceAssistantService.startListening(
      onResult: (words) {
        if (!mounted) return;
        setState(() => _words = words);
      },
      onDone: () async {
        final position = await VoiceAssistantService.getCurrentPosition();
        final contextLoc = position != null
            ? "${position.latitude}, ${position.longitude}"
            : "Mystical Coordinates";

        final reply = await VoiceAssistantService.getOracleLogic(_words, contextLoc, position: position);
        await VoiceAssistantService.speak(reply);

        if (mounted) {
          setState(() {
            _isListening = false;
            _words = reply;
          });
          _showCinematicReply(context, reply);
        }
      },
    );
  }

  void _showLimitReachedDialog() {
    showDialog(
      context: context,
      builder: (_) => LimitReachedDialog(
        featureName: AppLocalizations.of(context)!.featureNameOracleQueries,
        onWatchAd: () {
          MonetizationService().showRewardedAd(
            onRewardEarned: (reward) async {
              await UsageLimiterService.provideBonusOracleChat();
            },
          );
        },
      ),
    );
  }

  void _showCinematicReply(BuildContext context, String text) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: 150,
        left: 20,
        right: 20,
        child: OracleUI.glassContainer(
          showGlow: true,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(Icons.auto_awesome_rounded, color: AppTheme.modernGreen(context), size: 16),
                  const SizedBox(width: 8),
                  OracleUI.neonText(
                    "ORACLE SUPREME",
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.modernGreen(context),
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                text,
                style: GoogleFonts.inter(
                  color: AppTheme.textPrimary(context),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.9, 0.9), curve: Curves.easeOutBack),
      ),
    );

    overlay.insert(overlayEntry);
    Future.delayed(const Duration(seconds: 6), () => overlayEntry.remove());
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleOracle,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.secondary,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: _isListening ? 0.45 : 0.28),
              blurRadius: _isListening ? 30 : 18,
              spreadRadius: _isListening ? 8 : 0,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: Icon(
          _isListening ? Icons.graphic_eq_rounded : Icons.auto_awesome_rounded,
          color: AppTheme.colors.white,
          size: 32,
        ),
      )
      .animate(onPlay: (c) => c.repeat(reverse: true))
      .scale(begin: const Offset(0.95, 0.95), end: const Offset(1.05, 1.05), duration: 2.seconds, curve: Curves.easeInOut),
    );
  }
}
