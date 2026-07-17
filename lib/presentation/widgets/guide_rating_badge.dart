import 'package:hidden_gems_sl/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../l10n/app_localizations.dart';

class GuideRatingBadge extends StatelessWidget {
  final double rating;
  final int reviewCount;

  const GuideRatingBadge({
    super.key,
    required this.rating,
    required this.reviewCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.star_rounded, color: AppTheme.colors.amber, size: 18),
        const SizedBox(width: 4),
        Text(
          rating.toStringAsFixed(1),
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: AppTheme.textPrimary(context),
          ),
        ),
        Text(
          AppLocalizations.of(context)!.reviewCountSuffix(reviewCount),
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppTheme.textSecondary(context),
          ),
        ),
      ],
    );
  }
}
