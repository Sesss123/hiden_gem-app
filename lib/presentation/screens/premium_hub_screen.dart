import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../data/datasources/premium_service.dart';
import '../../data/datasources/user_preference_service.dart';
import 'curator_deals_screen.dart';
import 'emergency_translator_screen.dart';
import '../../core/services/emergency_translator_service.dart';

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
    final isPremium = ref.watch(premiumProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: AppTheme.colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildModernHeader(isPremium),
            SizedBox(height: 32),
            _buildBenefitList(),
            SizedBox(height: 40),
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
    final goldColor = AppPalette.heroOchre;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 100, 24, 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark ? [AppPaletteDark.card, AppPaletteDark.bg] : [AppPalette.ink, const Color(0xFF4A2F1C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 88, height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: goldColor.withValues(alpha: 0.18),
            ),
            child: Icon(Icons.stars_rounded, color: goldColor, size: 40),
          )
          .animate(onPlay: (c) => c.repeat())
          .shimmer(duration: 3.seconds)
          .scale(duration: 2.seconds, begin: const Offset(0.95, 0.95), end: const Offset(1.05, 1.05), curve: Curves.easeInOut),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isPremium) Icon(Icons.workspace_premium_rounded, color: goldColor, size: 22),
              if (isPremium) SizedBox(width: 10),
              Flexible(
                child: Text(
                  "Go Premium",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.colors.white,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            "Full AR & unlimited AI trips",
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppTheme.colors.white.withValues(alpha: 0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 800.ms).slideY(begin: 0.1);
  }

  Widget _buildBenefitList() {
    final isPremium = ref.watch(premiumProvider);
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
            onTap: isPremium
                ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CuratorDealsScreen()))
                : null,
          ),
          _benefitRow(
            Icons.translate_rounded,
            "Guardian Emergency Translator",
            "Instantly explain your situation to Sri Lankan police or hospital staff in spoken Sinhala during an SOS.",
            onTap: isPremium
                ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EmergencyTranslatorScreen(initialType: EmergencySituationType.other)))
                : null,
          ),
        ],
      ),
    );
  }

  Widget _benefitRow(IconData icon, String title, String desc, {VoidCallback? onTap}) {
    final iconColor = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceMuted(context),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary(context),
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      desc,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppTheme.textSecondary(context),
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.textSecondary(context).withValues(alpha: 0.5)),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.05);
  }

  Widget _buildPricingCard(bool isPremium) {
    final profile = ref.watch(premiumProvider.select((_) => UserPreferenceService.getProfile()));
    const goldColor = AppPalette.rust;

    return Column(
      children: [
        if (isPremium) ...[
          Container(
            padding: EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppTheme.surfaceMuted(context),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              children: [
                Icon(Icons.verified_user_rounded, color: goldColor, size: 56)
                    .animate(onPlay: (c) => c.repeat())
                    .shimmer(duration: 4.seconds),
                SizedBox(height: 20),
                Text(
                  "${profile.premiumPlan ?? 'Premium'} active",
                  style: GoogleFonts.outfit(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary(context),
                  ),
                ),
                if (profile.premiumExpiresAt != null)
                  Padding(
                    padding: EdgeInsets.only(top: 10),
                    child: Text(
                      "Renewing on ${profile.premiumExpiresAt!.day}/${profile.premiumExpiresAt!.month}/${profile.premiumExpiresAt!.year}",
                      style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary(context), fontWeight: FontWeight.w600),
                    ),
                  ),
                SizedBox(height: 24),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    "Via ${profile.premiumSource?.replaceAll('_', ' ') ?? 'store'}",
                    style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textSecondary(context), fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          if (kDebugMode) ...[
            SizedBox(height: 16),
            TextButton.icon(
              icon: Icon(Icons.restart_alt_rounded, color: AppTheme.colors.redAccent, size: 16),
              label: Text("RESET PREMIUM (DEV ONLY)",
                style: GoogleFonts.inter(color: AppTheme.colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold)),
              onPressed: () {
                ref.read(premiumProvider.notifier).simulateMockCancel();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Premium reset. Pricing tiers are back.")),
                );
              },
            ),
          ],
        ] else ...[
          _buildTierOption(
            context: context,
            title: "Smart Traveler",
            priceStr: "Rs. 499",
            billingCycle: "Billed monthly",
            features: ["20 AI Itineraries/mo", "Selected AR Places", "Offline Maps (Basic)"],
            color: AppTheme.colors.primary,
            onPressed: () => ref.read(premiumProvider.notifier).buyPremium(productId: PremiumNotifier.explorerId),
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
            onPressed: () => ref.read(premiumProvider.notifier).buyPremium(productId: PremiumNotifier.premiumId),
          ),
          SizedBox(height: 20),
          _buildTierOption(
            context: context,
            title: "Ultra Explorer",
            priceStr: "Waitlist",
            billingCycle: "Next-Gen Experience",
            features: ["VR Mode Support", "Historical Timelines", "Personal AI Curator"],
            color: AppTheme.colors.primary,
            isLocked: true,
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text("🚀 Ultra Explorer is on the waitlist! We'll notify you when it launches."),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: AppTheme.colors.primary.withValues(alpha: 0.15),
                ),
              );
            },
          ),
          SizedBox(height: 32),
          TextButton(
            onPressed: () => ref.read(premiumProvider.notifier).restorePurchases(),
            child: Text(
              "Restore previous purchases",
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(height: 8),
          Text(
            "Terms of Service  •  Privacy Policy",
            style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary(context).withValues(alpha: 0.7), fontWeight: FontWeight.w600),
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
        color: AppTheme.colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.colors.red.withValues(alpha: 0.3)),
      ),
      child: TextButton.icon(
        icon: Icon(Icons.bug_report, color: AppTheme.colors.redAccent, size: 16),
        label: Text("TEST BUY (DEV ONLY)", 
          style: GoogleFonts.inter(color: AppTheme.colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold)),
        onPressed: () {
          ref.read(premiumProvider.notifier).simulateMockPurchase();
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Recommended tier gets the dark "premium" treatment (gold-on-charcoal);
    // other tiers stay as plain shadow cards.
    final cardBg = isRecommended ? AppPalette.ink : (isDark ? AppPaletteDark.card : Theme.of(context).colorScheme.surface);
    final titleColor = isRecommended ? AppPalette.heroOchre : AppTheme.textPrimary(context);
    final priceColor = isRecommended ? AppTheme.colors.white : AppTheme.textPrimary(context);
    final featureTextColor = isRecommended ? AppTheme.colors.white.withValues(alpha: 0.75) : AppTheme.textSecondary(context);
    final checkColor = isRecommended ? AppPalette.heroOchre : color;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        boxShadow: isRecommended ? null : [
          BoxShadow(color: AppTheme.colors.black.withValues(alpha: 0.05), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isRecommended) ...[
                SizedBox(width: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppPalette.heroOchre,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    "Popular",
                    style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, color: AppPalette.ink),
                  ),
                ),
              ],
              if (isLocked)
                Text(
                   "Locked",
                  style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.textSecondary(context).withValues(alpha: 0.6)),
                ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                priceStr,
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: priceColor,
                ),
              ),
              SizedBox(width: 6),
              Padding(
                padding: EdgeInsets.only(bottom: 5),
                child: Text(
                  "/ month",
                  style: GoogleFonts.inter(color: featureTextColor, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          SizedBox(height: 18),
          ...features.map((f) => Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Icon(Icons.check_circle_rounded, size: 16, color: checkColor),
                SizedBox(width: 10),
                Expanded(
                  child: Text(f, style: GoogleFonts.inter(color: featureTextColor, fontSize: 12, fontWeight: FontWeight.w500)),
                ),
              ],
            ),
          )),
          SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: isLocked ? null : onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: isLocked
                    ? AppTheme.surfaceMuted(context)
                    : (isRecommended ? AppPalette.heroOchre : color),
                foregroundColor: isLocked ? AppTheme.textSecondary(context) : AppPalette.ink,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                elevation: 0,
              ),
              child: Text(
                isLocked ? "Coming soon" : "Upgrade now",
                style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).scale(begin: const Offset(0.98, 0.98));
  }
}
