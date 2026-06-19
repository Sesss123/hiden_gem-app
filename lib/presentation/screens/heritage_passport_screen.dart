import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/oracle_ui_system.dart';
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
      body: OracleUI.auraBackground(
        child: SafeArea(
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
            icon: Icon(Icons.arrow_back_rounded, color: Colors.white70),
            onPressed: () => Navigator.pop(context),
          ),
          Column(
            children: [
              OracleUI.neonText(
                "HERITAGE PASSPORT",
                style: GoogleFonts.outfit(
                  color: Colors.white, fontWeight: FontWeight.w900,
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
          OracleUI.glassContainer(
            padding: EdgeInsets.all(32),
            borderRadius: BorderRadius.circular(50),
            borderColor: Colors.white.withValues(alpha: 0.1),
            child: Icon(Icons.auto_awesome_motion_rounded, color: Colors.white10, size: 64)
                .animate(onPlay: (c) => c.repeat())
                .shimmer(duration: 3.seconds),
          ),
          SizedBox(height: 32),
          OracleUI.neonText(
            "Passport Empty",
            style: GoogleFonts.outfit(color: Colors.white24, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1),
          ),
          SizedBox(height: 12),
          Text(
            "Explore historical gems to\nclaim your unique digital stamps.",
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: Colors.white12, fontSize: 13, height: 1.5, fontWeight: FontWeight.w600),
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
    Color rarityColor = Colors.white54;
    if (stamp.rarity == 'Rare') rarityColor = Theme.of(context).colorScheme.primary;
    if (stamp.rarity == 'Mythic') rarityColor = const Color(0xFFFFD700);

    return GestureDetector(
      onTap: () => _showStampDetail(stamp),
      child: OracleUI.glassContainer(
        borderRadius: BorderRadius.circular(24),
        borderColor: rarityColor.withValues(alpha: 0.2),
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
                    style: GoogleFonts.outfit(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                    textAlign: TextAlign.center,
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8),
                  OracleUI.glassContainer(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    borderRadius: BorderRadius.circular(8),
                    borderColor: rarityColor.withValues(alpha: 0.3),
                    child: OracleUI.neonText(
                      stamp.rarity.toUpperCase(), 
                      style: GoogleFonts.inter(color: rarityColor, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1),
                      glowColor: rarityColor.withValues(alpha: 0.1),
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
    Color rarityColor = Colors.white54;
    if (stamp.rarity == 'Rare') rarityColor = Theme.of(context).colorScheme.primary;
    if (stamp.rarity == 'Mythic') rarityColor = const Color(0xFFFFD700);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => OracleUI.glassContainer(
        padding: const EdgeInsets.fromLTRB(32, 20, 32, 40),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
        borderColor: rarityColor.withValues(alpha: 0.1),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(2)),
            ),
            SizedBox(height: 32),
            OracleUI.glassContainer(
              width: 160, height: 160,
              borderRadius: BorderRadius.circular(80),
              borderColor: rarityColor.withValues(alpha: 0.3),
              child: Container(
                margin: EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(image: NetworkImage(stamp.imageUrl), fit: BoxFit.cover),
                ),
              ),
            ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 4.seconds),
            SizedBox(height: 32),
            OracleUI.neonText(stamp.placeName, style: GoogleFonts.outfit(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
            SizedBox(height: 8),
            Text(
              "CLAIMED ON ${stamp.claimDate.toString().split(' ')[0]}", 
              style: GoogleFonts.inter(color: Colors.white24, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 2)
            ),
            const Divider(color: Colors.white10, height: 48),
            OracleUI.neonText(
              "VERIFIABLE ORACLE HASH", 
              style: GoogleFonts.outfit(color: rarityColor, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03), 
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: SelectableText(
                stamp.hash,
                style: GoogleFonts.robotoMono(color: Colors.white38, fontSize: 9, height: 1.5),
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
                    OracleUI.neonText(
                      "SHARE COLLECTIBLE", 
                      style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1),
                      glowColor: rarityColor.withValues(alpha: 0.1),
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
