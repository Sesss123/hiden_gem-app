import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/oracle_ui_system.dart';
import '../../data/models/trip_plan_model.dart';

class KineticTimelineView extends StatelessWidget {
  final List<ItineraryDay> days;

  const KineticTimelineView({super.key, required this.days});

  @override
  Widget build(BuildContext context) {
    // Flatten days for a continuous timeline flow
    final allItems = <({ItineraryItem item, int dayNum, bool isLastItemOfDay})>[];
    for (int i = 0; i < days.length; i++) {
      final day = days[i];
      for (int j = 0; j < day.items.length; j++) {
        allItems.add((
          item: day.items[j], 
          dayNum: day.day, 
          isLastItemOfDay: j == day.items.length - 1
        ));
      }
    }

    return ListView.builder(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: allItems.length,
      itemBuilder: (context, index) {
        final entry = allItems[index];
        final item = entry.item;
        final isLast = index == allItems.length - 1;
        
        // Determine evening/night theme based on time or index (simulated for demo)
        final bool isEvening = index > 2; 

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timeline Column
            SizedBox(
              width: 50,
              child: Column(
                children: [
                  if (index == 0 || entry.dayNum != allItems[index - 1].dayNum)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12, top: 12),
                      child: OracleUI.neonText(
                        "D${entry.dayNum}",
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.modernGreen(context).withValues(alpha: 0.8),
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  OracleUI.timelineNode(
                    context: context,
                    isActive: index == 1, // Simulate current node in journey
                    isLast: isLast,
                    color: isEvening ? AppTheme.accentOchre(context) : null,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            
            // Card Column
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 28),
                child: OracleUI.kineticCard(
                  context: context,
                  isEvening: isEvening,
                  opacity: 0.1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          OracleUI.neonText(
                            item.time,
                            style: GoogleFonts.outfit(
                              color: isEvening 
                                  ? AppTheme.accentOchre(context) 
                                  : AppTheme.modernGreen(context),
                              fontWeight: FontWeight.w900,
                              fontSize: 11,
                              letterSpacing: 3,
                            ),
                          ),
                          if (index == 1)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppTheme.modernGreen(context).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppTheme.modernGreen(context).withValues(alpha: 0.3)),
                              ),
                              child: OracleUI.neonText(
                                "ACTIVE NODE",
                                style: GoogleFonts.outfit(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.modernGreen(context),
                                  letterSpacing: 1,
                                ),
                              ),
                            ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 2.seconds),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        item.title.toUpperCase(),
                        style: GoogleFonts.outfit(
                          color: AppTheme.textPrimary(context),
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                      if (item.notes.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          item.notes,
                          style: GoogleFonts.inter(
                            color: AppTheme.textSecondary(context).withValues(alpha: 0.8),
                            fontSize: 13,
                            height: 1.6,
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          OracleUI.glassChip(
                            context: context, 
                            label: "${item.durationMin} MINS",
                            isSelected: false,
                            icon: Icons.timer_outlined,
                          ),
                          if (item.costLkr > 0)
                            OracleUI.glassChip(
                              context: context, 
                              label: "LKR ${item.costLkr}",
                              isSelected: false,
                              icon: Icons.payments_outlined,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ).animate().fadeIn(delay: (index * 100).ms, duration: 600.ms).slideY(begin: 0.1, curve: Curves.easeOutCubic);
      },
    );
  }
}
