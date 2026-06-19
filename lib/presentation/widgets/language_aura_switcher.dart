import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/oracle_ui_system.dart';
import '../../core/localization/locale_provider.dart';
import '../../l10n/app_localizations.dart';

/// A premium, glassmorphic language switcher with aura animations.
class LanguageAuraSwitcher extends ConsumerWidget {
  const LanguageAuraSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final currentLocale = Localizations.localeOf(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: OracleUI.neonText(
            l10n.selectLanguage,
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _LanguageCard(
                label: "ENGLISH",
                subLabel: "Universal",
                isSelected: currentLocale.languageCode == 'en',
                onTap: () => _updateLocale(context, ref, const Locale('en')),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _LanguageCard(
                label: "සිංහල",
                subLabel: "දේශීය",
                isSelected: currentLocale.languageCode == 'si',
                onTap: () => _updateLocale(context, ref, const Locale('si')),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _updateLocale(BuildContext context, WidgetRef ref, Locale locale) {
    HapticFeedback.mediumImpact();
    
    // Connect to the real LocaleNotifier
    ref.read(localeNotifierProvider.notifier).setLocale(locale);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Oracle switching to ${locale.languageCode == 'si' ? 'Sinhala' : 'English'}..."),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
      ),
    );
  }
}

class _LanguageCard extends StatelessWidget {
  final String label;
  final String subLabel;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageCard({
    required this.label,
    required this.subLabel,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: OracleUI.glassContainer(
        padding: const EdgeInsets.all(16),
        borderRadius: BorderRadius.circular(20),
        borderColor: isSelected 
            ? Theme.of(context).colorScheme.primary 
            : Theme.of(context).dividerColor.withValues(alpha: 0.1),
        child: Stack(
          children: [
            if (isSelected)
              Positioned(
                right: -10,
                top: -10,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  ),
                ).animate(onPlay: (c) => c.repeat()).scale(
                  begin: const Offset(1, 1),
                  end: const Offset(2, 2),
                  duration: 2.seconds,
                  curve: Curves.easeOut,
                ).fadeOut(),
              ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isSelected 
                            ? Theme.of(context).colorScheme.primary 
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    if (isSelected)
                      Icon(
                        Icons.check_circle,
                        color: Theme.of(context).colorScheme.primary,
                        size: 16,
                      ).animate().scale().fadeIn(),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subLabel.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate(target: isSelected ? 1 : 0).scale(
      begin: const Offset(1, 1),
      end: const Offset(1.02, 1.02),
      duration: 200.ms,
    );
  }
}
