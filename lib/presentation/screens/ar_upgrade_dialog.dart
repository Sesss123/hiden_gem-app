import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';

/// Shows the AR Premium upgrade bottom sheet dialog.
/// Call via: ARUpgradeDialog.show(context, onPreview: ..., onUpgrade: ...)
class ARUpgradeDialog extends StatelessWidget {
  final VoidCallback onUpgrade;
  final VoidCallback onPreview;
  final VoidCallback? onWatchAd;

  const ARUpgradeDialog({
    super.key,
    required this.onUpgrade,
    required this.onPreview,
    this.onWatchAd,
  });

  static Future<void> show(
    BuildContext context, {
    required VoidCallback onUpgrade,
    required VoidCallback onPreview,
    VoidCallback? onWatchAd,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.colors.transparent,
      builder: (_) => ARUpgradeDialog(
        onUpgrade: onUpgrade,
        onPreview: onPreview,
        onWatchAd: onWatchAd,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 28,
        right: 28,
        top: 28,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      decoration: BoxDecoration(
        color: AppTheme.colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(color: AppPalette.rust.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppTheme.colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 28),

          // Icon with gold glow
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppPalette.rust.withValues(alpha: 0.1),
              border: Border.all(color: AppPalette.rust.withValues(alpha: 0.4)),
              boxShadow: [
                BoxShadow(
                  color: AppPalette.rust.withValues(alpha: 0.15),
                  blurRadius: 30,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: const Center(
              child: Text('🏛', style: TextStyle(fontSize: 36)),
            ),
          ),
          const SizedBox(height: 20),

          // Title
          Text(
            AppLocalizations.of(context)!.unlockArHeritageModeTitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              color: AppTheme.textPrimary(context),
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          // Subtitle
          Text(
            AppLocalizations.of(context)!.arHeritageModeSubtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: AppTheme.textSecondary(context),
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),

          // Feature list
          _featureRow('🏺', AppLocalizations.of(context)!.featureAncient3dReconstruction),
          const SizedBox(height: 12),
          _featureRow('🎧', AppLocalizations.of(context)!.featureAudioNarrationBilingual),
          const SizedBox(height: 12),
          _featureRow('📸', AppLocalizations.of(context)!.featureArPhotoCapture),
          const SizedBox(height: 28),

          // Pricing
          Text(
            AppLocalizations.of(context)!.pricingTrialLabel,
            style: GoogleFonts.inter(
              color: AppPalette.rust,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),

          // Upgrade button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                onUpgrade();
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: AppTheme.colors.transparent,
                shadowColor: AppTheme.colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ).copyWith(
                backgroundColor: WidgetStateProperty.all(AppTheme.colors.transparent),
              ),
              child: Ink(
                decoration: BoxDecoration(
                  color: AppPalette.rust,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    AppLocalizations.of(context)!.upgradeToPremiumButton,
                    style: GoogleFonts.outfit(
                      color: AppTheme.colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Preview button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                Navigator.pop(context);
                onPreview();
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: AppPalette.rust, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                AppLocalizations.of(context)!.watch10SecPreviewButton,
                style: GoogleFonts.outfit(
                  color: AppPalette.rust,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          if (onWatchAd != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  onWatchAd!();
                },
                icon: Icon(Icons.play_circle_fill, color: AppTheme.colors.white, size: 20),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppPalette.rust,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                label: Text(
                  AppLocalizations.of(context)!.watchAdUnlockSessionButton,
                  style: GoogleFonts.outfit(
                    color: AppTheme.colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),

          // Not now
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppLocalizations.of(context)!.notNowButtonLabel,
              style: GoogleFonts.inter(color: AppTheme.textSecondary(context), fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _featureRow(String emoji, String text) {
    return Row(
      children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: AppPalette.rust.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppPalette.rust.withValues(alpha: 0.2)),
          ),
          child: Center(child: Text(emoji, style: const TextStyle(fontSize: 16))),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(color: AppPalette.ink, fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}
