import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/business_discovery_service.dart';
import '../../core/services/secure_entitlements.dart';
import '../../data/models/business_partner.dart';
import '../widgets/cached_image.dart';
import 'premium_hub_screen.dart';

/// Premium-only benefit: member discounts at handpicked boutique
/// stays/cafes. Backed by the Firestore `partners` collection (managed via
/// the Laravel admin panel) — previously "Exclusive Curator Deals" was just
/// marketing copy on PremiumHubScreen with no feature behind it.
class CuratorDealsScreen extends StatefulWidget {
  const CuratorDealsScreen({super.key});

  @override
  State<CuratorDealsScreen> createState() => _CuratorDealsScreenState();
}

class _CuratorDealsScreenState extends State<CuratorDealsScreen> {
  List<BusinessPartner> _deals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _guardAndLoad();
  }

  // Security: this screen was previously only gated by PremiumHubScreen's
  // button being disabled for non-premium users — a tampered local/cached
  // premium state (or any other nav path here) got unrestricted access to
  // curator deals content with no server check at all. Verify on entry,
  // same pattern as EmergencyKitScreen's premium-gated navigation.
  Future<void> _guardAndLoad() async {
    final isPremium = await SecureEntitlements().verifyPremium();
    if (!mounted) return;
    if (!isPremium) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PremiumHubScreen()));
      return;
    }
    _load();
  }

  Future<void> _load() async {
    final deals = await BusinessDiscoveryService().getPremiumDeals();
    if (!mounted) return;
    setState(() {
      _deals = deals;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, size: 20, color: AppTheme.textPrimary(context)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Curator deals', style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 18, color: AppTheme.textPrimary(context))),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary))
          : _deals.isEmpty
              ? _buildEmptyState(context)
              : RefreshIndicator(
                  color: Theme.of(context).colorScheme.primary,
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                    itemCount: _deals.length,
                    itemBuilder: (context, index) => _buildDealCard(context, _deals[index]),
                  ),
                ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.local_offer_outlined, size: 56, color: AppTheme.textSecondary(context).withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text('No deals right now', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary(context))),
            const SizedBox(height: 8),
            Text(
              'New partner discounts are added regularly — check back soon.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary(context)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDealCard(BuildContext context, BusinessPartner partner) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppTheme.colors.black.withValues(alpha: 0.06), blurRadius: 18, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: CachedImage(url: partner.imageUrl, height: 140, width: double.infinity, fit: BoxFit.cover),
              ),
              Positioned(
                top: 12, left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: AppPalette.rust, borderRadius: BorderRadius.circular(100)),
                  child: Text(
                    '${partner.discountPercent}% OFF',
                    style: GoogleFonts.outfit(color: AppTheme.colors.white, fontSize: 12, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(partner.name, style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary(context)))),
                    Icon(Icons.star_rounded, color: AppTheme.colors.amber, size: 16),
                    const SizedBox(width: 2),
                    Text(partner.rating.toStringAsFixed(1), style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textPrimary(context))),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  partner.dealDescription.isNotEmpty ? partner.dealDescription : partner.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary(context), height: 1.4),
                ),
                if (partner.dealValidUntil != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Valid until ${partner.dealValidUntil!.day}/${partner.dealValidUntil!.month}/${partner.dealValidUntil!.year}',
                    style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary(context).withValues(alpha: 0.7), fontWeight: FontWeight.w600),
                  ),
                ],
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: partner.bookingUrl.isEmpty ? null : () => _openBooking(partner.bookingUrl),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                      elevation: 0,
                    ),
                    child: Text('Claim deal', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05);
  }

  Future<void> _openBooking(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
