import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/web3_passport_service.dart';
import '../../data/models/passport_model.dart';
import '../widgets/skeleton_loaders.dart';

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
      padding: EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: AppTheme.textSecondary(context)),
            onPressed: () => Navigator.pop(context),
          ),
          Column(
            children: [
              Text(
                "HERITAGE PASSPORT",
                style: GoogleFonts.outfit(
                  color: AppTheme.textPrimary(context), fontWeight: FontWeight.w900,
                  letterSpacing: 4, fontSize: 14,
                ),
              ),
              SizedBox(height: 4),
              Text(
                "VERIFIABLE EXPLORER ARCHIVE",
                style: GoogleFonts.inter(
                  color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w900,
                  fontSize: 10, letterSpacing: 2,
                ),
              ),
            ],
          ),
          SizedBox(width: 48),
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
              border: Border.all(color: AppTheme.secondaryBorder(context)),
              color: Colors.white,
              boxShadow: [
                 BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Icon(Icons.auto_awesome_motion_rounded, color: AppPalette.rust.withValues(alpha: 0.5), size: 64)
                .animate(onPlay: (c) => c.repeat())
                .shimmer(duration: 3.seconds),
          ),
          SizedBox(height: 32),
          Text(
            "Passport Empty",
            style: GoogleFonts.outfit(color: AppTheme.textPrimary(context), fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1),
          ),
          SizedBox(height: 12),
          Text(
            "Explore historical gems to\nclaim your unique digital stamps.",
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
    Color rarityColor = AppTheme.textSecondary(context);
    if (stamp.rarity == 'Rare') rarityColor = AppPalette.rust;
    if (stamp.rarity == 'Mythic') rarityColor = const Color(0xFFD4AF37);

    return GestureDetector(
      onTap: () => _showStampDetail(stamp),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: rarityColor.withValues(alpha: 0.3)),
          boxShadow: [
             BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          children: [
            Expanded(
              child: Container(
                margin: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  image: DecorationImage(image: NetworkImage(stamp.imageUrl), fit: BoxFit.cover),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter, end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withValues(alpha: 0.6)],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Column(
                children: [
                  Text(
                    stamp.placeName.toUpperCase(),
                    style: GoogleFonts.outfit(color: AppTheme.textPrimary(context), fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                    textAlign: TextAlign.center,
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: rarityColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: rarityColor.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      stamp.rarity.toUpperCase(), 
                      style: GoogleFonts.inter(color: rarityColor, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.95, 0.95)),
    );
  }

  void _showStampDetail(HeritageStamp stamp) {
    Color rarityColor = AppTheme.textSecondary(context);
    if (stamp.rarity == 'Rare') rarityColor = AppPalette.rust;
    if (stamp.rarity == 'Mythic') rarityColor = const Color(0xFFD4AF37); // Gold

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.fromLTRB(32, 20, 32, 40),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
          border: Border.all(color: rarityColor.withValues(alpha: 0.2)),
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
                borderRadius: BorderRadius.circular(80),
                border: Border.all(color: rarityColor.withValues(alpha: 0.3)),
                color: Colors.white,
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
            Text(stamp.placeName, style: GoogleFonts.outfit(color: AppTheme.textPrimary(context), fontSize: 26, fontWeight: FontWeight.w900)),
            SizedBox(height: 8),
            Text(
              "CLAIMED ON ${stamp.claimDate.toString().split(' ')[0]}", 
              style: GoogleFonts.inter(color: AppTheme.textSecondary(context), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 2)
            ),
            Divider(color: AppTheme.secondaryBorder(context), height: 48),
            Text(
              "VERIFIABLE HASH", 
              style: GoogleFonts.outfit(color: rarityColor, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white, 
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.secondaryBorder(context)),
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
              height: 60,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: rarityColor.withValues(alpha: 0.2),
                  foregroundColor: rarityColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: rarityColor.withValues(alpha: 0.3)),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.share_rounded, size: 20),
                    SizedBox(width: 12),
                    Text(
                      "SHARE COLLECTIBLE", 
                      style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1),
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
