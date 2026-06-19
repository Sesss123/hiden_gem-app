import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';

/// A reusable, branded error/empty state widget.
/// Use it wherever something goes wrong or there's no content to show.
class GracefulErrorWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? buttonLabel;
  final VoidCallback? onRetry;
  final Color? iconColor;

  const GracefulErrorWidget({
    super.key,
    this.icon = Icons.cloud_off_rounded,
    required this.title,
    required this.subtitle,
    this.buttonLabel,
    this.onRetry,
    this.iconColor,
  });

  /// Preset: No Internet
  factory GracefulErrorWidget.noInternet({VoidCallback? onRetry}) {
    return GracefulErrorWidget(
      icon: Icons.signal_wifi_connected_no_internet_4_rounded,
      title: "No Connection",
      subtitle: "Check your internet and try again.\nYour saved plans are still available offline.",
      buttonLabel: "Try Again",
      onRetry: onRetry,
      iconColor: AppTheme.warningAmber,
    );
  }

  /// Preset: AI Timeout / Error
  factory GracefulErrorWidget.aiError({VoidCallback? onRetry}) {
    return GracefulErrorWidget(
      icon: Icons.psychology_outlined,
      title: "Oracle Unreachable",
      subtitle: "The AI couldn't complete your request.\nPlease check your connection or try again.",
      buttonLabel: "Retry",
      onRetry: onRetry,
      iconColor: AppTheme.errorRed,
    );
  }

  /// Preset: Empty results
  factory GracefulErrorWidget.empty({String subtitle = "Nothing to show here yet."}) {
    return GracefulErrorWidget(
      icon: Icons.search_off_rounded,
      title: "Nothing Found",
      subtitle: subtitle,
      iconColor: null, // Let build method handle the theme-aware default
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = iconColor ?? AppTheme.modernGreen(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.1),
                border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
              ),
              child: Icon(icon, color: color, size: 40),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary(context),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppTheme.textSecondary(context),
                height: 1.6,
              ),
            ),
            if (onRetry != null && buttonLabel != null) ...[
              const SizedBox(height: 32),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: Text(buttonLabel!),
                style: OutlinedButton.styleFrom(
                  foregroundColor: color,
                  side: BorderSide(color: color.withValues(alpha: 0.6)),
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
