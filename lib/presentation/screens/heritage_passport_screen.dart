import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/web3_passport_service.dart';
import '../../data/models/passport_model.dart';
import '../widgets/skeleton_loaders.dart';
import '../../l10n/app_localizations.dart';

class HeritagePassportScreen extends StatefulWidget {
  const HeritagePassportScreen({super.key});

  @override
  State<HeritagePassportScreen> createState() => _HeritagePassportScreenState();
}

class _HeritagePassportScreenState extends State<HeritagePassportScreen> {
  List<HeritageStamp> _collection = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCollection();
  }

  Future<void> _loadCollection() async {
    final collection = await Web3PassportService.getCollection();
    if (mounted) {
      setState(() {
        _collection = collection;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
            children: [
              _buildTopBar(),
              _isLoading 
                ? Expanded(child: PassportSkeleton())
                : Expanded(
                    child: _collection.isEmpty 
                      ? _buildEmptyState()
                      : _buildGrid(),
                  ),
            ],
          ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: AppTheme.textSecondary(context)),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.passportTitle,
                  style: GoogleFonts.outfit(
                    color: AppTheme.textPrimary(context),
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    fontSize: 22,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  AppLocalizations.of(context)!.verifiedVisitCollectionSubtitle,
                  style: GoogleFonts.inter(
                    color: AppTheme.textSecondary(context),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(32),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(50),
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                 BoxShadow(color: AppTheme.colors.black.withValues(alpha: 0.06), blurRadius: 20, offset: const Offset(0, 8)),
              ],
            ),
            child: Icon(Icons.auto_awesome_motion_rounded, color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.6), size: 64)
                .animate(onPlay: (c) => c.repeat())
                .shimmer(duration: 3.seconds),
          ),
          SizedBox(height: 32),
          Text(
            AppLocalizations.of(context)!.passportIsEmptyTitle,
            style: GoogleFonts.outfit(color: AppTheme.textPrimary(context), fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -0.3),
          ),
          SizedBox(height: 12),
          Text(
            AppLocalizations.of(context)!.exploreHistoricalGemsMessage,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: AppTheme.textSecondary(context), fontSize: 13, height: 1.5, fontWeight: FontWeight.w600),
          ),
        ],
      ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1),
    );
  }

  Widget _buildGrid() {
    return GridView.builder(
      padding: EdgeInsets.all(24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 20,
        crossAxisSpacing: 20,
        childAspectRatio: 0.8,
      ),
      itemCount: _collection.length,
      itemBuilder: (context, index) => _buildStampCard(_collection[index]),
    );
  }

  Widget _buildStampCard(HeritageStamp stamp) {
    final isRare = stamp.rarity == 'Rare' || stamp.rarity == 'Mythic';
    Color badgeColor = AppTheme.textSecondary(context);
    if (stamp.rarity == 'Rare') badgeColor = Theme.of(context).colorScheme.primary;
    if (stamp.rarity == 'Mythic') badgeColor = Theme.of(context).colorScheme.secondary;

    return GestureDetector(
      onTap: () => _showStampDetail(stamp),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
             BoxShadow(color: AppTheme.colors.black.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 10)),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      image: DecorationImage(image: NetworkImage(stamp.imageUrl), fit: BoxFit.cover),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter, end: Alignment.bottomCenter,
                          colors: [AppTheme.colors.transparent, AppTheme.colors.black.withValues(alpha: 0.5)],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isRare ? badgeColor : AppTheme.textSecondary(context),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        _rarityLabel(stamp.rarity, AppLocalizations.of(context)!),
                        style: GoogleFonts.inter(color: AppTheme.colors.white, fontSize: 9, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Text(
                stamp.placeName,
                style: GoogleFonts.outfit(color: AppTheme.textPrimary(context), fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: -0.2),
                textAlign: TextAlign.center,
                maxLines: 1, overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.95, 0.95)),
    );
  }

  String _rarityLabel(String rarity, AppLocalizations l10n) {
    switch (rarity) {
      case 'Rare':
        return l10n.stampRarityRare;
      case 'Mythic':
        return l10n.stampRarityMythic;
      default:
        return l10n.stampRarityCommon;
    }
  }

  void _showStampDetail(HeritageStamp stamp) {
    Color rarityColor = AppTheme.textSecondary(context);
    if (stamp.rarity == 'Rare') rarityColor = Theme.of(context).colorScheme.primary;
    if (stamp.rarity == 'Mythic') rarityColor = Theme.of(context).colorScheme.secondary;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.fromLTRB(32, 20, 32, 40),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [
            BoxShadow(color: AppTheme.colors.black.withValues(alpha: 0.15), blurRadius: 30, offset: const Offset(0, -8)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: AppTheme.secondaryBorder(context), borderRadius: BorderRadius.circular(2)),
            ),
            SizedBox(height: 32),
            Container(
              width: 160, height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [
                  BoxShadow(color: AppTheme.colors.black.withValues(alpha: 0.08), blurRadius: 24, offset: const Offset(0, 10)),
                ],
              ),
              child: Container(
                margin: EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(image: NetworkImage(stamp.imageUrl), fit: BoxFit.cover),
                ),
              ),
            ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 4.seconds),
            SizedBox(height: 32),
            Text(stamp.placeName, style: GoogleFonts.outfit(color: AppTheme.textPrimary(context), fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: -0.5)),
            SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.claimedOnLabel(stamp.claimDate.toString().split(' ')[0]),
              style: GoogleFonts.inter(color: AppTheme.textSecondary(context), fontSize: 12, fontWeight: FontWeight.w600)
            ),
            Divider(color: AppTheme.secondaryBorder(context), height: 48),
            Text(
              AppLocalizations.of(context)!.verifiableHashLabel,
              style: GoogleFonts.outfit(color: rarityColor, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: -0.2)
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceMuted(context),
                borderRadius: BorderRadius.circular(16),
              ),
              child: SelectableText(
                stamp.hash,
                style: GoogleFonts.robotoMono(color: AppTheme.textSecondary(context), fontSize: 9, height: 1.5),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: rarityColor,
                  foregroundColor: AppTheme.colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.share_rounded, size: 18),
                    SizedBox(width: 10),
                    Text(
                      AppLocalizations.of(context)!.shareCollectibleButton,
                      style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
