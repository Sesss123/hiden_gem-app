import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';

/// Shown wherever an AR entry point (place details, Discovery filter/picks,
/// map markers, saved-plan cards) would otherwise launch AR content —
/// AppConfig.arFeatureEnabled is false until real trained AR assets ship, so
/// every one of those entry points routes here instead of ARViewerScreen.
class ARComingSoonScreen extends StatelessWidget {
  final String placeName;

  const ARComingSoonScreen({super.key, required this.placeName});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppTheme.scaffoldColor(context),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  icon: Icon(Icons.close, color: AppTheme.textPrimary(context)),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              const Spacer(),
              Icon(Icons.view_in_ar_outlined, size: 72, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 24),
              Text(
                l10n.arComingSoonTitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary(context),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.arComingSoonMessage(placeName),
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  height: 1.5,
                  color: AppTheme.textSecondary(context),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                  ),
                  child: Text(l10n.okButton),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
