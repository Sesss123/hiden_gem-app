import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme/app_theme.dart';

class ModernTracerShimmer extends StatelessWidget {
  final Widget child;
  final bool enabled;

  const ModernTracerShimmer({
    super.key,
    required this.child,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Shimmer.fromColors(
      baseColor: isDark ? const Color(0xFF262B2A) : Colors.grey[300]!,
      highlightColor: isDark 
          ? AppTheme.modernGreen(context).withValues(alpha: 0.2)
          : Colors.grey[100]!,
      period: const Duration(milliseconds: 1500),
      child: child,
    );
  }

  static Widget box(
    BuildContext context, {
    double? width,
    double height = 20,
    double borderRadius = 8,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isDark ? AppTheme.borderColor(context).withValues(alpha: 0.3) : Colors.grey[200],
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }

  /// A circular skeleton (e.g. for profile pics)
  static Widget circle(BuildContext context, {double size = 40}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isDark ? AppTheme.borderColor(context).withValues(alpha: 0.3) : Colors.grey[200],
        shape: BoxShape.circle,
      ),
    );
  }
}

/// A premium skeleton for discovery cards
class DiscoveryCardSkeleton extends StatelessWidget {
  const DiscoveryCardSkeleton({super.key});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ModernTracerShimmer(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        height: 200,
        decoration: AppTheme.glassDecoration(context, opacity: isDark ? 0.05 : 0.1),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ModernTracerShimmer.box(context, width: 150, height: 24),
              const SizedBox(height: 8),
              ModernTracerShimmer.box(context, width: 100, height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

/// A skeleton for the Heritage Passport grid
class PassportSkeleton extends StatelessWidget {
  const PassportSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: 6,
      itemBuilder: (context, index) => Container(
        decoration: AppTheme.glassDecoration(context, opacity: 0.05),
        child: Column(
          children: [
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.cardColor(context).withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  ModernTracerShimmer.box(context, width: 80, height: 12),
                  const SizedBox(height: 8),
                  ModernTracerShimmer.box(context, width: 40, height: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A skeleton for the Results screen itinerary
class ResultsTabSkeleton extends StatelessWidget {
  const ResultsTabSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: 3,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 80,
              decoration: AppTheme.glassDecoration(context, opacity: 0.05),
            ),
            const SizedBox(height: 20),
            ...List.generate(2, (i) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  Container(width: 40, height: 40, decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.borderColor(context).withValues(alpha: 0.2))),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ModernTracerShimmer.box(context, width: 150, height: 16),
                        const SizedBox(height: 8),
                        ModernTracerShimmer.box(context, width: 250, height: 12),
                      ],
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}
