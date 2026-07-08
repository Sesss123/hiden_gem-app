import 'package:hidden_gems_sl/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/oracle_ui_system.dart';
import '../../data/services/subscription_service.dart';
import '../../data/models/subscription_record.dart';
import 'billing_history_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:hidden_gems_sl/core/utils/secure_logger.dart';


class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  bool _isProcessing = false;

  Future<void> _subscribe(String planId, String price) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() => _isProcessing = true);
    
    try {
      // Use the new RevenueCat powered purchase flow
      await ref.read(subscriptionServiceProvider).purchasePlan(planId, user.uid, 'guide');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("✅ Subscribed to \"${planId.toUpperCase()}\" plan!"),
          backgroundColor: AppTheme.colors.primary.withValues(alpha: 0.2),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Subscription failed: $e"),
          backgroundColor: AppTheme.colors.redAccent.withValues(alpha: 0.2),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _restorePurchases() async {
    setState(() => _isProcessing = true);
    try {
      await Purchases.restorePurchases();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text("✅ Purchases restored successfully."),
          backgroundColor: AppTheme.colors.primary.withValues(alpha: 0.2),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
       if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Restore failed: $e"),
          backgroundColor: AppTheme.colors.redAccent.withValues(alpha: 0.2),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
       if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Scaffold(body: Center(child: Text("Access Denied")));

    final activeSubFuture = ref.watch(subscriptionServiceProvider).getActiveSubscription(user.uid);

    return Scaffold(
      backgroundColor: AppTheme.colors.transparent,
      body: OracleUI.auraBackground(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildAppBar(),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCurrentStatusSection(activeSubFuture),
                    const SizedBox(height: 32),
                    Text(
                      "Service tiers",
                      style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary(context)),
                    ),
                    const SizedBox(height: 16),
                    _buildPlanCard(
                      title: "Free tier",
                      price: "0",
                      planId: "free",
                      description: "Essential tour tools for verified guides.",
                      features: ["Basic Operations", "Verified Badge", "Standard SOS"],
                      isPopular: false,
                    ),
                    _buildPlanCard(
                      title: "Pro Commander",
                      price: "29",
                      planId: "pro",
                      description: "Elevate your visibility and tools.",
                      features: ["Featured Listings", "Advanced Analytics", "Client Analytics", "Priority SOS"],
                      isPopular: true,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    _buildPlanCard(
                      title: "Elite Agency",
                      price: "89",
                      planId: "elite",
                      description: "Full fleet and company management.",
                      features: ["Team Management", "Operator Dashboard", "White-label Branding", "Family Share Pro"],
                      isPopular: false,
                      color: AppTheme.colors.amberAccent,
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      floating: true,
      backgroundColor: AppTheme.colors.transparent,
      elevation: 0,
      title: Text(
        "Fleet plans",
        style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary(context)),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.history, color: AppTheme.textSecondary(context), size: 20),
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const BillingHistoryScreen()));
          },
        ),
        TextButton.icon(
          onPressed: _isProcessing ? null : _restorePurchases,
          icon: Icon(Icons.restore, color: AppTheme.textSecondary(context), size: 16),
          label: Text("Restore", style: GoogleFonts.inter(color: AppTheme.textSecondary(context), fontSize: 12, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  Widget _buildCurrentStatusSection(Future<SubscriptionRecord?> future) {
    return FutureBuilder<SubscriptionRecord?>(
      future: future,
      builder: (context, snapshot) {
        final sub = snapshot.data;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceMuted(context),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(shape: BoxShape.circle, color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12)),
                child: Icon(Icons.verified_user_rounded, color: Theme.of(context).colorScheme.primary, size: 18),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Current plan", style: GoogleFonts.inter(color: AppTheme.textSecondary(context), fontSize: 10, fontWeight: FontWeight.w600)),
                    Text(
                      sub?.planId != null ? _sentenceCase(sub!.planId) : "Free tier",
                      style: GoogleFonts.outfit(color: AppTheme.textPrimary(context), fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    if (sub != null)
                      Text("Expires: ${sub.expiresAt.day}/${sub.expiresAt.month}/${sub.expiresAt.year}", style: GoogleFonts.inter(color: AppTheme.textSecondary(context), fontSize: 11)),
                  ],
                ),
              ),
              if (sub == null)
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: TextButton(
                    onPressed: _isProcessing ? null : () => _subscribe('pro', '29'),
                    style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6)),
                    child: Text("Upgrade", style: GoogleFonts.inter(color: Theme.of(context).colorScheme.onPrimary, fontWeight: FontWeight.w700, fontSize: 12)))
                )
              else
                TextButton(
                  onPressed: () => _manageSubscription(context),
                  child: Text("Manage", style: GoogleFonts.inter(color: AppTheme.textSecondary(context), fontWeight: FontWeight.w600))),
            ],
          ),
        );
      },
    );
  }

  Future<void> _manageSubscription(BuildContext context) async {
    // Both iOS and Android require users to manage/cancel subscriptions in their respective app stores.
    // RevenueCat provides showInAppMessages for iOS, but url_launcher is the universal fallback.
    try {
      if (Theme.of(context).platform == TargetPlatform.iOS) {
        final url = Uri.parse("https://apps.apple.com/account/subscriptions");
        if (await canLaunchUrl(url)) await launchUrl(url);
      } else {
        final url = Uri.parse("https://play.google.com/store/account/subscriptions");
        if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (e, st) {
      SecureLogger.error("Could not launch store", e, st, "SubscriptionScreen");
    }
  }

  String _sentenceCase(String label) {
    if (label.isEmpty) return label;
    return label[0].toUpperCase() + label.substring(1).toLowerCase();
  }

  Widget _buildPlanCard({
    required String title,
    required String price,
    required String planId,
    required String description,
    required List<String> features,
    bool isPopular = false,
    Color? color,
  }) {
    final primary = Theme.of(context).colorScheme.primary;
    final actualColor = color ?? AppTheme.textSecondary(context);
    final titleColor = isPopular ? AppTheme.colors.white : AppTheme.textPrimary(context);
    final priceColor = isPopular ? AppTheme.colors.white : AppTheme.textPrimary(context);
    final descColor = isPopular ? AppTheme.colors.white.withValues(alpha: 0.85) : AppTheme.textSecondary(context);
    final featureColor = isPopular ? AppTheme.colors.white.withValues(alpha: 0.85) : AppTheme.textSecondary(context);
    final checkColor = isPopular ? AppTheme.colors.white : actualColor;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: isPopular
              ? LinearGradient(colors: [primary, AppPalette.rustDim], begin: Alignment.topLeft, end: Alignment.bottomRight)
              : null,
          color: isPopular ? null : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: isPopular ? null : [
            BoxShadow(color: AppTheme.colors.black.withValues(alpha: 0.05), blurRadius: 16, offset: const Offset(0, 6)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isPopular)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(color: AppTheme.colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(100)),
                child: Text("Most popular", style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, color: AppTheme.colors.white)),
              ),
            Text(title, style: GoogleFonts.outfit(color: titleColor, fontSize: 14, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Row(
              textBaseline: TextBaseline.alphabetic,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              children: [
                Text("\$$price", style: GoogleFonts.outfit(color: priceColor, fontSize: 28, fontWeight: FontWeight.w800)),
                const SizedBox(width: 4),
                Text("/month", style: GoogleFonts.inter(color: descColor, fontSize: 11, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 12),
            Text(description, style: GoogleFonts.inter(color: descColor, fontSize: 12)),
            const SizedBox(height: 20),
            ...features.map((f) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: checkColor, size: 16),
                  const SizedBox(width: 10),
                  Expanded(child: Text(f, style: GoogleFonts.inter(color: featureColor, fontSize: 12))),
                ],
              ),
            )),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: planId == 'free' || _isProcessing ? null : () => _subscribe(planId, price),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isPopular ? AppTheme.colors.white : AppTheme.surfaceMuted(context),
                  foregroundColor: isPopular ? primary : AppTheme.textSecondary(context),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                  elevation: 0,
                ),
                child: _isProcessing
                    ? SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: primary))
                    : Text(
                        planId == 'free' ? "Current plan" : "Select this plan",
                        style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12)),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.1);
  }
}
