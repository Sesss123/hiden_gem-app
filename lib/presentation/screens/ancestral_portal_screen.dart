import 'package:flutter/material.dart';
import 'package:panorama/panorama.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/oracle_ui_system.dart';
import '../../data/models/portal_model.dart';

class AncestralPortalScreen extends StatefulWidget {
  final AncestralPortal portal;
  const AncestralPortalScreen({super.key, required this.portal});

  @override
  State<AncestralPortalScreen> createState() => _AncestralPortalScreenState();
}

class _AncestralPortalScreenState extends State<AncestralPortalScreen> {
  double _opacity = 0.0;
  bool _infoVisible = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _opacity = 1.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Panorama 360 Viewer
          Positioned.fill(
            child: Panorama(
              zoom: 1,
              child: Image.network(widget.portal.panoramaImageUrl),
            ),
          ),

          // Portal "Entrance" Effect
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedOpacity(
                duration: const Duration(seconds: 2),
                opacity: 1.0 - _opacity,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        Colors.transparent, 
                        Theme.of(context).colorScheme.primary.withValues(alpha: 0.3), 
                        Theme.of(context).scaffoldBackgroundColor
                      ],
                      stops: const [0.3, 0.7, 1.0],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // UI Overlays
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopBar(),
                const Spacer(),
                if (_infoVisible) _buildInfoPanel(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _circleIconBtn(Icons.close, () => Navigator.pop(context)),
          _circleIconBtn(
            _infoVisible ? Icons.info : Icons.info_outline, 
            () => setState(() => _infoVisible = !_infoVisible)
          ),
        ],
      ),
    );
  }

  Widget _circleIconBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: OracleUI.glassContainer(
        padding: EdgeInsets.all(12),
        borderRadius: BorderRadius.circular(30),
        borderColor: Colors.white.withValues(alpha: 0.1),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }

  Widget _buildInfoPanel() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 800),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 50),
            child: OracleUI.glassContainer(
              margin: EdgeInsets.all(24),
              padding: EdgeInsets.all(28),
              borderRadius: BorderRadius.circular(32),
              borderColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.history_edu, color: Theme.of(context).colorScheme.primary, size: 18),
                      SizedBox(width: 12),
                      Expanded(
                        child: OracleUI.neonText(
                          widget.portal.era.toUpperCase(),
                          style: GoogleFonts.outfit(
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
                            fontWeight: FontWeight.w900,
                            fontSize: 11,
                            letterSpacing: 2.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text(
                    widget.portal.locationName,
                    style: GoogleFonts.outfit(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    widget.portal.description,
                    style: GoogleFonts.inter(color: Colors.white70, fontSize: 13, height: 1.5),
                  ),
                  SizedBox(height: 16),
                  OracleUI.neonText(
                    "ANCIENT ARTIFACTS",
                    style: GoogleFonts.outfit(
                      color: Colors.white24, 
                      fontSize: 10, 
                      fontWeight: FontWeight.w900, 
                      letterSpacing: 2
                    ),
                  ),
                  SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: widget.portal.keyArtifacts.map((e) => _artifactChip(e)).toList(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _artifactChip(String label) {
    return OracleUI.glassContainer(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      borderRadius: BorderRadius.circular(10),
      borderColor: Colors.white.withValues(alpha: 0.05),
      child: Text(
        label, 
        style: GoogleFonts.inter(
          color: Colors.white38, 
          fontSize: 11,
          fontWeight: FontWeight.w600
        )
      ),
    );
  }
}
