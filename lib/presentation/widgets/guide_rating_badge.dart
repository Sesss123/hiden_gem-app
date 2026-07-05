import 'package:hidden_gems_sl/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GuideRatingBadge extends StatelessWidget {
  final double rating;
  final int reviewCount;
  final bool isVerified;
  
  const GuideRatingBadge({
    super.key,
    required this.rating,
    required this.reviewCount,
    this.isVerified = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.colors.amber.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.colors.amber.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.star_rounded, color: AppTheme.colors.amber, size: 16),
              const SizedBox(width: 4),
              Text(
                rating.toStringAsFixed(1),
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: AppTheme.colors.amber.shade700,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                "($reviewCount)",
                style: GoogleFonts.inter(
                  color: AppTheme.colors.grey,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
        if (isVerified) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified_rounded, color: AppTheme.colors.blue, size: 14),
                const SizedBox(width: 4),
                Text(
                  "Verified",
                  style: GoogleFonts.outfit(
                    color: AppTheme.colors.blue,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
