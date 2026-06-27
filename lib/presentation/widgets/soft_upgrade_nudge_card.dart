import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/datasources/user_preference_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/oracle_ui_system.dart';
import '../screens/premium_hub_screen.dart';
import '../screens/subscription_screen.dart';

class SoftUpgradeNudgeCard extends StatelessWidget {
  final String featureName;
  final VoidCallback? onDismiss;

  const SoftUpgradeNudgeCard({
    super.key,
    required this.featureName,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final profile = UserPreferenceService.getProfile();
    final isGuide = profile.role.startsWith('guide') || profile.isGuideApproved;

    // Only show to free tier users
    if (profile.isPremium) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: OracleUI.glassContainer(
        padding: const EdgeInsets.all(18),
        borderRadius: BorderRadius.circular(20),
        borderColor: AppTheme.warningAmber.withValues(alpha: 0.25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.stars_rounded, color: AppTheme.warningAmber, size: 20),
                const SizedBox(width: 8),
                Text(
                  'UPGRADE RECOMENDED',
                  style: GoogleFonts.outfit(
                    color: AppTheme.warningAmber,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const Spacer(),
                if (onDismiss != null)
                  GestureDetector(
                    onTap: onDismiss,
                    child: const Icon(Icons.close, color: Colors.white30, size: 16),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Approaching your limit for $featureName. Unlock unlimited AI travel plans, offline map caching, and verified guide support.',
              style: GoogleFonts.inter(
                color: Colors.white70,
                fontSize: 12,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => isGuide ? const SubscriptionScreen() : const PremiumHubScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.warningAmber,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    child: Text(
                      'Upgrade Plan',
                      style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                if (onDismiss != null) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onDismiss,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white24),
                        foregroundColor: Colors.white70,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(
                        'Not Now',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
