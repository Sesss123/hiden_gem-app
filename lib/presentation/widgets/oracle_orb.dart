import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/oracle_ui_system.dart';
import '../../core/services/voice_assistant_service.dart';

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
      setState(() => _isListening = false);
    } else {
      setState(() {
        _isListening = true;
        _words = "Oracle is listening...";
      });
      
      await VoiceAssistantService.startListening(
        onResult: (words) => setState(() => _words = words),
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
        width: 76,
        height: 76,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppTheme.modernGreen(context).withValues(alpha: _isListening ? 0.6 : 0.2),
              blurRadius: 30,
              spreadRadius: 5,
            )
          ],
          gradient: RadialGradient(
            colors: [
              Colors.white,
              AppTheme.modernGreen(context).withValues(alpha: 0.8),
              AppTheme.scaffoldColor(context).withValues(alpha: 0.6),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: Icon(
          _isListening ? Icons.mic_rounded : Icons.auto_awesome_rounded,
          color: _isListening ? (Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white) : Colors.white,
          size: 36,
        ),
      )
      .animate(onPlay: (c) => c.repeat(reverse: true))
      .scale(begin: const Offset(0.92, 0.92), end: const Offset(1.08, 1.08), duration: 2.seconds, curve: Curves.easeInOut)
      .shimmer(duration: 3.seconds, color: Colors.white24),
    );
  }
}
