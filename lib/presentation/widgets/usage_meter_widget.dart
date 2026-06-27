import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/services/usage_limiter_service.dart';
import '../../data/datasources/user_preference_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/oracle_ui_system.dart';
import '../screens/premium_hub_screen.dart';
import '../screens/subscription_screen.dart';

class UsageMeterWidget extends StatefulWidget {
  const UsageMeterWidget({super.key});

  @override
  State<UsageMeterWidget> createState() => _UsageMeterWidgetState();
}

class _UsageMeterWidgetState extends State<UsageMeterWidget> {
  int _aiLimit = 3;
  int _arLimit = 1;
  int _offlineLimit = 2;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLimits();
  }

  Future<void> _loadLimits() async {
    final profile = UserPreferenceService.getProfile();
    try {
      // Mock retrieve using key limit mappings
      await UsageLimiterService.canGenerateAiTrip(); // basic validation
      setState(() {
        // Fallback limits based on plan
        if (profile.isPremium) {
          final plan = profile.premiumPlan ?? 'premium';
          if (plan == 'explorer') {
            _aiLimit = 20;
            _arLimit = 3;
            _offlineLimit = 10;
          } else {
            _aiLimit = 50;
            _arLimit = 9999;
            _offlineLimit = 9999;
          }
        } else {
          _aiLimit = 3;
          _arLimit = 1;
          _offlineLimit = 2;
        }
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator(color: Color(0xFFFFB300))),
      );
    }

    final profile = UserPreferenceService.getProfile();
    final isGuide = profile.role.startsWith('guide') || profile.isGuideApproved;

    // AI Trips
    final aiUsed = profile.aiTripsUsedThisMonth;
    final aiPercent = _aiLimit > 0 ? (aiUsed / _aiLimit).clamp(0.0, 1.0) : 0.0;
    final isAiHigh = aiPercent >= 0.8 && _aiLimit < 100;

    // AR Sessions
    final arUsed = profile.arSessionsUsedThisMonth;
    final arPercent = _arLimit > 0 && _arLimit < 9999 ? (arUsed / _arLimit).clamp(0.0, 1.0) : 0.0;
    final isArHigh = arPercent >= 0.8 && _arLimit < 100;

    // Offline Downloads
    final offlineUsed = profile.offlineDownloadsUsed;
    final offlinePercent = _offlineLimit > 0 && _offlineLimit < 9999 ? (offlineUsed / _offlineLimit).clamp(0.0, 1.0) : 0.0;
    final isOfflineHigh = offlinePercent >= 0.8 && _offlineLimit < 100;

    final hasWarning = isAiHigh || isArHigh || isOfflineHigh;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: OracleUI.glassContainer(
        padding: const EdgeInsets.all(20),
        borderRadius: BorderRadius.circular(24),
        borderColor: hasWarning 
            ? AppTheme.warningAmber.withValues(alpha: 0.3) 
            : Colors.white.withValues(alpha: 0.05),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PLAN USAGE METERS',
                      style: GoogleFonts.outfit(
                        color: AppTheme.warningAmber,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      profile.isPremium 
                          ? '${(profile.premiumPlan ?? "Premium").toUpperCase()} PLAN ACTIVE'
                          : 'FREE EXPLORER TIER',
                      style: GoogleFonts.inter(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                if (!profile.isPremium)
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => isGuide ? const SubscriptionScreen() : const PremiumHubScreen(),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.warningAmber,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'UPGRADE',
                        style: GoogleFonts.outfit(
                          color: Colors.black,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            if (hasWarning) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.warningAmber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.warningAmber.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: AppTheme.warningAmber, size: 14),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Approaching monthly feature limit. Upgrade to maintain full access.',
                        style: GoogleFonts.inter(color: AppTheme.warningAmber, fontSize: 10, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),

            // AI Plans Progress Bar
            _buildProgressBar(
              title: 'AI Travel Plans',
              used: aiUsed,
              limit: _aiLimit,
              percent: aiPercent,
              isHigh: isAiHigh,
            ),
            const SizedBox(height: 14),

            // AR Sessions Progress Bar
            _buildProgressBar(
              title: 'AR 3D Portal Sessions',
              used: arUsed,
              limit: _arLimit,
              percent: arPercent,
              isHigh: isArHigh,
              isUnlimited: _arLimit >= 9999,
            ),
            const SizedBox(height: 14),

            // Offline Downloads Progress Bar
            _buildProgressBar(
              title: 'Offline Island Guides',
              used: offlineUsed,
              limit: _offlineLimit,
              percent: offlinePercent,
              isHigh: isOfflineHigh,
              isUnlimited: _offlineLimit >= 9999,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar({
    required String title,
    required int used,
    required int limit,
    required double percent,
    required bool isHigh,
    bool isUnlimited = false,
  }) {
    final color = isUnlimited
        ? Colors.greenAccent
        : (isHigh ? Colors.redAccent : AppTheme.warningAmber);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
            ),
            Text(
              isUnlimited ? 'Unlimited' : '$used / $limit used',
              style: GoogleFonts.inter(
                color: isHigh ? Colors.redAccent : Colors.white38,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: isUnlimited ? 1.0 : percent,
            minHeight: 6,
            backgroundColor: Colors.white10,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
