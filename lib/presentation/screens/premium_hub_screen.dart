import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../data/datasources/premium_service.dart';
import '../../data/datasources/user_preference_service.dart';

class PremiumHubScreen extends ConsumerStatefulWidget {
  const PremiumHubScreen({super.key});

  @override
  ConsumerState<PremiumHubScreen> createState() => _PremiumHubScreenState();
}

class _PremiumHubScreenState extends ConsumerState<PremiumHubScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPremium = ref.watch(premiumNotifierProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 100),
            _buildModernHeader(isPremium),
            SizedBox(height: 40),
            _buildBenefitList(),
            SizedBox(height: 60),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: _buildPricingCard(isPremium),
            ),
            SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildModernHeader(bool isPremium) {
    const goldColor = AppPalette.rust;
    return Column(
      children: [
        Container(
          width: 140, height: 140,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(70),
            border: Border.all(color: goldColor.withValues(alpha: 0.3)),
            color: Colors.white,
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Container(
            margin: EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: goldColor.withValues(alpha: 0.1),
            ),
            child: Icon(Icons.stars_rounded, color: goldColor, size: 64),
          ),
        )
        .animate(onPlay: (c) => c.repeat())
        .shimmer(duration: 3.seconds)
        .scale(duration: 2.seconds, begin: const Offset(0.95, 0.95), end: const Offset(1.05, 1.05), curve: Curves.easeInOut),
        SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isPremium) Icon(Icons.workspace_premium_rounded, color: goldColor, size: 28),
            if (isPremium) SizedBox(width: 12),
            Text(
              "UNLEASH THE ORACLE",
              style: GoogleFonts.outfit(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Text(
          "Elevate your Sri Lankan journey to Premium",
          style: GoogleFonts.inter(
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ).animate().fadeIn(duration: 800.ms).slideY(begin: 0.1);
  }

  Widget _buildBenefitList() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          _benefitRow(
            Icons.view_in_ar_rounded,
            "Heritage AR Mode",
            "See ancient ruins reconstructed in 1:1 scale with historical audio guides.",
          ),
          _benefitRow(
            Icons.auto_awesome_rounded,
            "Oracle AI Trip Intelligence",
            "Unlimited hyper-personalized itineraries powered by the Oracle engine.",
          ),
          _benefitRow(
            Icons.map_outlined,
            "Offline Digital Twins",
            "Download high-res maps and 100+ points of interest for low-signal areas.",
          ),
          _benefitRow(
            Icons.local_offer_outlined,
            "Exclusive Curator Deals",
            "Access to member-only discounts at handpicked boutique stays.",
          ),
        ],
      ),
    );
  }

  Widget _benefitRow(IconData icon, String title, String desc) {
    const goldColor = AppPalette.rust;
    return Padding(
      padding: EdgeInsets.only(bottom: 24),
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.secondaryBorder(context)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: goldColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: goldColor.withValues(alpha: 0.2)),
              ),
              child: Icon(icon, color: goldColor, size: 24),
            ),
            SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    desc,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                      height: 1.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.05);
  }

  Widget _buildPricingCard(bool isPremium) {
    final profile = ref.watch(premiumNotifierProvider.select((_) => UserPreferenceService.getProfile()));
    const goldColor = AppPalette.rust;

    return Column(
      children: [
        if (isPremium) ...[
          Container(
            padding: EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: AppTheme.secondaryBorder(context)),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              children: [
                Icon(Icons.verified_user_rounded, color: goldColor, size: 64)
                    .animate(onPlay: (c) => c.repeat())
                    .shimmer(duration: 4.seconds),
                SizedBox(height: 24),
                Text(
                  "${(profile.premiumPlan ?? 'PREMIUM').toUpperCase()} ACTIVE",
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Theme.of(context).colorScheme.onSurface,
                    letterSpacing: 2,
                  ),
                ),
                if (profile.premiumExpiresAt != null)
                  Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: Text(
                      "Renewing on ${profile.premiumExpiresAt!.day}/${profile.premiumExpiresAt!.month}/${profile.premiumExpiresAt!.year}",
                      style: GoogleFonts.inter(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4), fontWeight: FontWeight.w900),
                    ),
                  ),
                SizedBox(height: 32),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05)),
                  ),
                  child: Text(
                    "ARCHIVED VIA ${profile.premiumSource?.replaceAll('_', ' ').toUpperCase() ?? 'STORE'}",
                    style: GoogleFonts.inter(fontSize: 9, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5), fontWeight: FontWeight.w900, letterSpacing: 1),
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          _buildTierOption(
            context: context,
            title: "Smart Traveler",
            priceStr: "Rs. 499",
            billingCycle: "Billed monthly",
            features: ["20 AI Itineraries/mo", "Selected AR Places", "Offline Maps (Basic)"],
            color: const Color(0xFF64B5F6),
            onPressed: () => ref.read(premiumNotifierProvider.notifier).buyPremium(productId: PremiumNotifier.explorerId),
          ),
          SizedBox(height: 20),
          _buildTierOption(
            context: context,
            title: "Heritage Premium",
            priceStr: "Rs. 999",
            billingCycle: "Billed monthly",
            features: ["Unlimited AI Itineraries", "Full Heritage AR Access", "All Offline Features"],
            color: goldColor,
            isRecommended: true,
            onPressed: () => ref.read(premiumNotifierProvider.notifier).buyPremium(productId: PremiumNotifier.premiumId),
          ),
          SizedBox(height: 20),
          _buildTierOption(
            context: context,
            title: "Ultra Explorer",
            priceStr: "Waitlist",
            billingCycle: "Next-Gen Experience",
            features: ["VR Mode Support", "Historical Timelines", "Personal AI Curator"],
            color: const Color(0xFFE1BEE7),
            isLocked: true,
            onPressed: () {},
          ),
          SizedBox(height: 40),
          TextButton(
            onPressed: () => ref.read(premiumNotifierProvider.notifier).restorePurchases(),
            child: Text(
              "RESTORE PREVIOUS ARCHIVES",
              style: GoogleFonts.inter(
                fontSize: 12,
                color: goldColor,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
          ),
          SizedBox(height: 12),
          Text(
            "Terms of Service  •  Privacy Policy",
            style: GoogleFonts.inter(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2), fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 24),
          if (kDebugMode)
            _buildMockButton(),
        ],
      ],
    );
  }

  Widget _buildMockButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: TextButton.icon(
        icon: Icon(Icons.bug_report, color: Colors.redAccent, size: 16),
        label: Text("TEST BUY (DEV ONLY)", 
          style: GoogleFonts.inter(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold)),
        onPressed: () {
          ref.read(premiumNotifierProvider.notifier).simulateMockPurchase();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("🚀 Mock Purchase Simulated. Refreshing...")),
          );
        },
      ),
    );
  }

  Widget _buildTierOption({
    required BuildContext context,
    required String title,
    required String priceStr,
    required String billingCycle,
    required List<String> features,
    required Color color,
    required VoidCallback onPressed,
    bool isRecommended = false,
    bool isLocked = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: isRecommended ? color.withValues(alpha: 0.4) : AppTheme.secondaryBorder(context)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      padding: EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    color: color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isRecommended) ...[
                SizedBox(width: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: color.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    "MOST POPULAR",
                    style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.w900, color: color, letterSpacing: 1),
                  ),
                ),
              ],
              if (isLocked)
                Text(
                   "LOCKED",
                  style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2), letterSpacing: 2),
                ),
            ],
          ),
          SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                priceStr,
                style: GoogleFonts.outfit(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  color: Theme.of(context).colorScheme.onSurface,
                  letterSpacing: -1,
                ),
              ),
              SizedBox(width: 8),
              Padding(
                padding: EdgeInsets.only(bottom: 6),
                child: Text(
                  "/ month",
                  style: GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3), fontSize: 13, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          SizedBox(height: 24),
          ...features.map((f) => Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Icon(Icons.check_circle_rounded, size: 18, color: color.withValues(alpha: 0.6)),
                SizedBox(width: 12),
                Text(f, style: GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
          )),
          SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: isLocked ? null : onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: isLocked ? Colors.white.withValues(alpha: 0.05) : color,
                foregroundColor: isLocked ? Colors.white10 : Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 0,
              ),
              child: Text(
                isLocked ? "COMING SOON" : "UPGRADE NOW",
                style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).scale(begin: const Offset(0.98, 0.98));
  }
}
