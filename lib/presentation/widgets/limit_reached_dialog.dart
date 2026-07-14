import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../screens/premium_hub_screen.dart';

class LimitReachedDialog extends StatelessWidget {
  final String featureName;
  final VoidCallback? onWatchAd;

  /// The concrete value the user unlocks by upgrading — shown as bullet points
  /// so the upsell sells a specific outcome, not a vague "upgrade your plan".
  /// Defaults to the Heritage Premium value prop.
  final List<String> perks;

  /// Headline plan + price shown on the upgrade button's subtitle. Defaults to
  /// the recommended tier. This is the price anchor at the exact moment of
  /// highest intent (the user just hit a wall wanting to do the thing).
  final String planName;
  final String planPrice;

  const LimitReachedDialog({
    super.key,
    required this.featureName,
    this.onWatchAd,
    this.perks = const [
      '50 AI trip plans every month',
      'Unlimited AR heritage experiences',
      'Unlimited offline maps',
      'No ads, ever',
    ],
    this.planName = 'Heritage Premium',
    this.planPrice = 'Rs. 999/mo',
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: AppTheme.glassDecoration(
          context,
          color: Theme.of(context).cardColor,
          opacity: 0.9,
          blur: 20,
        ).copyWith(
          border: Border.all(color: AppTheme.warningAmber.withValues(alpha: 0.5)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.warningAmber.withValues(alpha: 0.1),
              ),
              child: const Icon(Icons.stars_rounded, size: 48, color: AppTheme.warningAmber),
            ),
            const SizedBox(height: 16),
            Text(
              "Usage Limit Reached",
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              "You've used all your $featureName for this month. Go unlimited with $planName:",
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            // Concrete value props — this is what turns "Maybe Later" into a tap.
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppTheme.warningAmber.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: perks
                    .map((perk) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle_rounded, size: 17, color: AppTheme.warningAmber),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  perk,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.85),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 24),
            // Primary CTA: the paid upgrade, with the price anchored right on
            // the button at the moment of highest intent.
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PremiumHubScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.warningAmber,
                  foregroundColor: AppTheme.colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Get $planName",
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      planPrice,
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            if (onWatchAd != null) ...[
              const SizedBox(height: 12),
              // Secondary free path — doubles as a conversion funnel (a user who
              // keeps watching ads for "one more" is a warm premium prospect).
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    onWatchAd!();
                  },
                  icon: Icon(Icons.play_circle_outline_rounded, size: 18, color: Theme.of(context).colorScheme.primary),
                  label: Text(
                    "Watch an ad for one more",
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 13, color: Theme.of(context).colorScheme.primary),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Maybe Later",
                style: GoogleFonts.inter(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
