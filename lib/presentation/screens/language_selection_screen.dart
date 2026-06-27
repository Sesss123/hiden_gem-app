import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/oracle_ui_system.dart';
import '../../core/localization/locale_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../l10n/app_localizations.dart';

class LanguageSelectionScreen extends ConsumerWidget {
  const LanguageSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.black, // Dark foundation for the aura
      body: OracleUI.auraBackground(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Container(
            width: double.infinity,
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 60),
                // Ethereal Logo
                Hero(
                  tag: 'app_logo',
                  child: Container(
                    height: 140,
                    width: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                          blurRadius: 40,
                          spreadRadius: 5,
                        )
                      ],
                    ),
                    child: OracleUI.glassContainer(
                      borderRadius: BorderRadius.circular(70),
                      borderColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                      child: Icon(
                        Icons.translate_rounded,
                        size: 64,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 4.seconds, color: Colors.white10),
                
                const SizedBox(height: 48),
                
                // Title with Kinetic Glow
                OracleUI.neonText(
                  "TRIPME.AI",
                  style: GoogleFonts.outfit(
                    fontSize: 44,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -1,
                  ),
                ).animate().fadeIn(duration: 800.ms).slideY(begin: 0.2, curve: Curves.easeOutBack),
                
                const SizedBox(height: 12),
                
                // Subtitle with Oracle Insight styling
                Text(
                  l10n.selectOracleLanguage.toUpperCase(),
                  style: GoogleFonts.inter(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4,
                  ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(duration: 800.ms, delay: 300.ms),
                
                const SizedBox(height: 60),
                
                // Language Matrix
                _buildLanguageOption(
                  ref: ref,
                  label: "ENGLISH",
                  subLabel: "Global Oracle Standard",
                  locale: const Locale('en'),
                  delay: 500.ms,
                ),
                const SizedBox(height: 16),
                
                _buildLanguageOption(
                  ref: ref,
                  label: "සිංහල",
                  subLabel: "දේශීය අත්දැකීම",
                  locale: const Locale('si'),
                  delay: 700.ms,
                ),
                const SizedBox(height: 16),
                
                _buildLanguageOption(
                  ref: ref,
                  label: "தமிழ்",
                  subLabel: "உள்ளூர் அனுபவம்",
                  locale: const Locale('ta'),
                  delay: 900.ms,
                ),
                
                const SizedBox(height: 40),
                
                TextButton(
                  onPressed: () async {
                    await ref.read(localeNotifierProvider.notifier).setLocale(const Locale('en'));
                  },
                  child: Text(
                    l10n.skipForNow.toUpperCase(),
                    style: GoogleFonts.inter(
                      color: Colors.white24,
                      fontWeight: FontWeight.w900,
                      fontSize: 10,
                      letterSpacing: 2,
                    ),
                  ),
                ).animate().fadeIn(delay: 1200.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageOption({
    required WidgetRef ref,
    required String label,
    required String subLabel,
    required Locale locale,
    required Duration delay,
  }) {
    return OracleUI.premiumGlassCard(
      padding: EdgeInsets.zero,
      margin: EdgeInsets.zero,
      radius: BorderRadius.circular(20),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            HapticFeedback.mediumImpact();
            await ref.read(localeNotifierProvider.notifier).setLocale(locale);
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      OracleUI.neonText(
                        label,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: Colors.white,
                          letterSpacing: 1.5,
                        ),
                        glowColor: Colors.white10,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subLabel,
                        style: GoogleFonts.inter(
                          color: Colors.white38,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white24,
                  size: 14,
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: delay).slideX(begin: -0.1, curve: Curves.easeOut);
  }
}

