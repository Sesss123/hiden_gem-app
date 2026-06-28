import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';

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
                      child: Text(
                        "D${entry.dayNum}",
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppPalette.rust,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  _buildTimelineNode(context, isLast: isLast),
                ],
              ),
            ),
            const SizedBox(width: 16),
            
            // Card Column
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: AppTheme.secondaryBorder(context)),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.time,
                        style: GoogleFonts.outfit(
                          color: AppPalette.rust,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.title,
                        style: GoogleFonts.outfit(
                          color: AppTheme.textPrimary(context),
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          height: 1.2,
                        ),
                      ),
                      if (item.notes.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          item.notes,
                          style: GoogleFonts.inter(
                            color: AppTheme.textSecondary(context),
                            fontSize: 13,
                            height: 1.5,
                          ),
                        ),
                      ],
                      if (item.durationMin > 0 || item.costLkr > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              if (item.durationMin > 0)
                                _buildChip(context, Icons.timer_outlined, "${item.durationMin} MINS"),
                              if (item.costLkr > 0)
                                _buildChip(context, Icons.payments_outlined, "LKR ${item.costLkr}"),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ).animate().fadeIn(delay: (index * 50).ms, duration: 400.ms).slideY(begin: 0.1, curve: Curves.easeOutCubic);
      },
    );
  }

  Widget _buildTimelineNode(BuildContext context, {required bool isLast}) {
    return Column(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: AppPalette.rust, width: 2),
          ),
        ),
        if (!isLast)
          Container(
            width: 2,
            height: 120, // Approximate height to connect to next card
            margin: const EdgeInsets.symmetric(vertical: 4),
            color: AppTheme.secondaryBorder(context),
          ),
      ],
    );
  }

  Widget _buildChip(BuildContext context, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border.all(color: AppTheme.secondaryBorder(context)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppTheme.textSecondary(context)),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppTheme.textSecondary(context),
            ),
          ),
        ],
      ),
    );
  }
}
