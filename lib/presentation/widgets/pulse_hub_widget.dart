import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/oracle_ui_system.dart';
import '../../core/theme/app_theme.dart';

class PulseHubWidget extends StatelessWidget {
  final String currentStatus;
  final String nextStop;
  final double guideProximity; // 0.0 to 1.0

  const PulseHubWidget({
    super.key,
    this.currentStatus = "En-route to Sigiriya",
    this.nextStop = "Lunch at Heritance Kandalama",
    this.guideProximity = 0.8,
  });

  @override
  Widget build(BuildContext context) {
    return OracleUI.neonCard(
      context: context,
      neonColor: AppTheme.modernGreen(context),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                OracleUI.pulseOracle(
                  context: context, 
                  color: AppTheme.modernGreen(context),
                  size: 10,
                ),
                const SizedBox(width: 12),
                Text(
                  "PULSE HUB: LIVE",
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    color: AppTheme.modernGreen(context),
                  ),
                ),
                const Spacer(),
                Icon(Icons.gps_fixed, size: 14, color: AppTheme.textSecondary(context).withValues(alpha: 0.5)),
              ],
            ),
            const SizedBox(height: 20),
            
            // Status Section
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "CURRENT STATE",
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textSecondary(context),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        currentStatus,
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary(context),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.modernGreen(context).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.directions_car_filled, color: AppTheme.modernGreen(context)),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            const Divider(height: 1),
            const SizedBox(height: 20),
            
            // Guide Proximity
            Row(
              children: [
                Text(
                  "GUIDE PROXIMITY",
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textSecondary(context),
                  ),
                ),
                const Spacer(),
                Text(
                  "${(guideProximity * 100).toInt()}% READY",
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.modernGreen(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: guideProximity,
                backgroundColor: AppTheme.glassBorder(context),
                valueColor: AlwaysStoppedAnimation(AppTheme.modernGreen(context)),
                minHeight: 4,
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Next Stop Highlight
            OracleUI.glassContainer(
              padding: const EdgeInsets.all(12),
              borderRadius: BorderRadius.circular(16),
              opacity: 0.05,
              child: Row(
                children: [
                  Icon(Icons.upcoming, size: 16, color: AppTheme.accentOchre(context)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "UPCOMING ZENITH",
                          style: GoogleFonts.inter(
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.accentOchre(context),
                          ),
                        ),
                        Text(
                          nextStop,
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary(context),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn().slideY(begin: 0.05);
  }
}
