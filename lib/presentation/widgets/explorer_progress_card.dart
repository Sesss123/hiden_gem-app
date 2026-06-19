import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/services/explorer_progress_service.dart';
import '../../core/theme/app_theme.dart';

/// 📊 ExplorerProgressCard
///
/// A cinematic, glassmorphic progress dashboard widget for the user's
/// exploration journey across Hidden Gems SL.
///
/// Shows:
/// - Explorer level badge (with emoji + title)
/// - Animated overall progress arc or bar
/// - Per-category breakdown: Sites / AR Sessions / Badges
/// - "X / Y sites explored" motivation text
///
/// Usage:
/// ```dart
/// ExplorerProgressCard(service: ExplorerProgressService())
/// ```
class ExplorerProgressCard extends StatefulWidget {
  final ExplorerProgressService service;
  final bool compact; // If true, shows a condensed version for profile header

  const ExplorerProgressCard({
    super.key,
    required this.service,
    this.compact = false,
  });

  @override
  State<ExplorerProgressCard> createState() => _ExplorerProgressCardState();
}

class _ExplorerProgressCardState extends State<ExplorerProgressCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _progressAnim;

  double _targetProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _progressAnim = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _listenAndAnimate();

    // Listen to any progress updates
    widget.service.visitedSites.addListener(_listenAndAnimate);
    widget.service.arSessionCount.addListener(_listenAndAnimate);
    widget.service.badgeCount.addListener(_listenAndAnimate);
  }

  void _listenAndAnimate() {
    final newTarget = widget.service.overallProgress;
    if (newTarget == _targetProgress) return;
    _progressAnim = Tween<double>(begin: _targetProgress, end: newTarget).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _targetProgress = newTarget;
    _animController.forward(from: 0);
  }

  @override
  void dispose() {
    widget.service.visitedSites.removeListener(_listenAndAnimate);
    widget.service.arSessionCount.removeListener(_listenAndAnimate);
    widget.service.badgeCount.removeListener(_listenAndAnimate);
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.compact
        ? _buildCompact()
        : _buildFull();
  }

  // ── Full Card (Heritage Passport / Progress Screen) ──────────────────────

  Widget _buildFull() {
    final level = widget.service.currentLevel;
    return AnimatedBuilder(
      animation: _progressAnim,
      builder: (context, _) {
        final progress = _progressAnim.value;
        final pct = (progress * 100).round();

        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: AppTheme.glassDecoration(
            context,
            opacity: isDark ? 0.15 : 0.85,
            color: Theme.of(context).cardColor,
          ).copyWith(
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: _levelColor(level).withValues(alpha: isDark ? 0.3 : 0.5),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: _levelColor(level).withValues(alpha: 0.12),
                blurRadius: 40,
                spreadRadius: 8,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Level Badge ───────────────────────────────────────────────
              Row(
                children: [
                  _LevelBadge(level: level),
                  const Spacer(),
                  Text(
                    '$pct%',
                    style: GoogleFonts.outfit(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textPrimary(context),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 6),
              Text(
                level.subtitle,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppTheme.textSecondary(context),
                  letterSpacing: 0.3,
                ),
              ),

              const SizedBox(height: 20),

              // ── Overall Progress Bar ──────────────────────────────────────
              _AnimatedProgressBar(
                progress: progress,
                color: _levelColor(level),
                label: 'OVERALL EXPLORER PROGRESS',
              ),

              // ── Level-within-level progress ───────────────────────────────
              if (level != ExplorerLevel.master) ...[
                const SizedBox(height: 6),
                Text(
                  'Next: ${ExplorerLevel.values[level.index + 1].title} ${ExplorerLevel.values[level.index + 1].emoji}',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: AppTheme.textSecondary(context).withValues(alpha: 0.6),
                    letterSpacing: 0.5,
                  ),
                ),
              ],

              const SizedBox(height: 28),

              // ── Category Breakdown ────────────────────────────────────────
              Text(
                'EXPLORATION BREAKDOWN',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: AppTheme.textSecondary(context).withValues(alpha: 0.6),
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              _CategoryRow(
                icon: Icons.place_rounded,
                label: 'Sri Lanka Sites',
                current: widget.service.visitedSites.value,
                total: ExplorerProgressService.totalSites,
                progress: widget.service.sitesProgress,
                color: const Color(0xFFFFB300), // Sites: Gold
              ),
              const SizedBox(height: 14),
              _CategoryRow(
                icon: Icons.view_in_ar_rounded,
                label: 'AR Sessions',
                current: widget.service.arSessionCount.value,
                total: ExplorerProgressService.totalArSessions,
                progress: widget.service.arProgress,
                color: AppTheme.modernGreen(context), // AR: Green
              ),
              const SizedBox(height: 14),
              _CategoryRow(
                icon: Icons.military_tech_rounded,
                label: 'Badges Earned',
                current: widget.service.badgeCount.value,
                total: ExplorerProgressService.totalBadges,
                progress: widget.service.badgesProgress,
                color: const Color(0xFF7C4DFF), // Badges: Purple
              ),

              const SizedBox(height: 24),

              // ── Motivation Footer ─────────────────────────────────────────
              _MotivationBanner(
                visited: widget.service.visitedSites.value,
                total: ExplorerProgressService.totalSites,
                level: level,
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Compact Version (Profile Screen Banner) ───────────────────────────────

  Widget _buildCompact() {
    final level = widget.service.currentLevel;
    return AnimatedBuilder(
      animation: _progressAnim,
      builder: (context, _) {
        final progress = _progressAnim.value;
        final pct = (progress * 100).round();

        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: AppTheme.glassDecoration(context, opacity: isDark ? 0.08 : 0.85, blur: 20, color: Theme.of(context).cardColor).copyWith(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _levelColor(level).withValues(alpha: isDark ? 0.3 : 0.5)),
          ),
          child: Row(
            children: [
              // Level emoji in circle
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _levelColor(level).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: _levelColor(level).withValues(alpha: 0.4)),
                ),
                child: Center(
                  child: Text(level.emoji, style: const TextStyle(fontSize: 22)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          level.title,
                          style: GoogleFonts.outfit(
                            color: AppTheme.textPrimary(context),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          '$pct%',
                          style: GoogleFonts.outfit(
                            color: _levelColor(level),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(_levelColor(level)),
                        minHeight: 5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${widget.service.visitedSites.value} / ${ExplorerProgressService.totalSites} sites explored in Sri Lanka',
                      style: GoogleFonts.inter(
                        fontSize: 10.5,
                        color: AppTheme.textSecondary(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _levelColor(ExplorerLevel level) {
    switch (level) {
      case ExplorerLevel.beginner:    return const Color(0xFF66BB6A); // Green
      case ExplorerLevel.discoverer:  return const Color(0xFF29B6F6); // Blue
      case ExplorerLevel.hunter:      return const Color(0xFFFFB300); // Gold
      case ExplorerLevel.master:      return const Color(0xFFE040FB); // Violet
    }
  }
}

// ─── Sub-Widgets ──────────────────────────────────────────────────────────────

class _LevelBadge extends StatelessWidget {
  final ExplorerLevel level;
  const _LevelBadge({required this.level});

  Color get _color {
    switch (level) {
      case ExplorerLevel.beginner:    return const Color(0xFF66BB6A);
      case ExplorerLevel.discoverer:  return const Color(0xFF29B6F6);
      case ExplorerLevel.hunter:      return const Color(0xFFFFB300);
      case ExplorerLevel.master:      return const Color(0xFFE040FB);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(level.emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Text(
            level.title.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: _color,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedProgressBar extends StatelessWidget {
  final double progress;
  final Color color;
  final String label;

  const _AnimatedProgressBar({
    required this.progress,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 9,
              color: AppTheme.textSecondary(context).withValues(alpha: 0.6),
              letterSpacing: 1.2,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Stack(
          children: [
            // Background track
            Container(
              height: 10,
              decoration: BoxDecoration(
                color: (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black).withValues(alpha: isDark ? 0.1 : 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            // Filled portion
            FractionallySizedBox(
              widthFactor: progress.clamp(0.0, 1.0),
              child: Container(
                height: 10,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color.withValues(alpha: 0.7), color],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 8),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final int current;
  final int total;
  final double progress;
  final Color color;

  const _CategoryRow({
    required this.icon,
    required this.label,
    required this.current,
    required this.total,
    required this.progress,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppTheme.textPrimary(context),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '$current / $total',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black).withValues(alpha: isDark ? 0.08 : 0.12),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MotivationBanner extends StatelessWidget {
  final int visited;
  final int total;
  final ExplorerLevel level;

  const _MotivationBanner({
    required this.visited,
    required this.total,
    required this.level,
  });

  String get _message {
    final remaining = total - visited;
    if (remaining <= 0) return 'You have explored every Hidden Gem in Sri Lanka! 👑';
    if (visited == 0) return 'Begin your AR journey to unlock explorer progress!';
    return 'Explore $remaining more ${remaining == 1 ? "site" : "sites"} to ${_nextLevelName()}';
  }

  String _nextLevelName() {
    if (level == ExplorerLevel.master) return 'maintain your legendary status';
    return 'become a ${ExplorerLevel.values[level.index + 1].title}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.borderColor(context).withValues(alpha: isDark ? 0.1 : 0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderColor(context).withValues(alpha: isDark ? 0.2 : 0.25)),
      ),
      child: Row(
        children: [
          const Text('🗺️', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _message,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppTheme.textSecondary(context),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
