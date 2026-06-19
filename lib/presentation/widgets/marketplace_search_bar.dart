import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/marketplace_search_controller.dart';
import '../../core/utils/debouncer.dart';

/// [MarketplaceSearchBar] — UX-hardened search input widget.
///
/// Integrates with [MarketplaceSearchController] via Riverpod.
///
/// Built-in features:
/// ✅ 500ms debounce (no query on every keystroke)
/// ✅ 2-char minimum guard (shows hint instead of querying)
/// ✅ Rate-limit cooldown UI (countdown badge + disabled state)
/// ✅ Clear button (cancels any in-flight request)
/// ✅ Visual loading indicator
///
/// Usage:
/// ```dart
/// MarketplaceSearchBar(
///   onCooldownMessage: (msg) => ScaffoldMessenger.of(context).showSnackBar(...),
/// )
/// ```
class MarketplaceSearchBar extends ConsumerStatefulWidget {
  final void Function(String message)? onCooldownMessage;
  final String? hintText;

  const MarketplaceSearchBar({
    super.key,
    this.onCooldownMessage,
    this.hintText,
  });

  @override
  ConsumerState<MarketplaceSearchBar> createState() =>
      _MarketplaceSearchBarState();
}

class _MarketplaceSearchBarState
    extends ConsumerState<MarketplaceSearchBar> {
  final _controller = TextEditingController();
  final _debouncer = Debouncer(milliseconds: 500);
  bool _wasInCooldown = false;

  @override
  void dispose() {
    _controller.dispose();
    _debouncer.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    final state = ref.read(marketplaceSearchControllerProvider);

    // If in cooldown, notify user and don't fire
    if (state.isCooldown) {
      _showCooldownMessage(state.cooldownSeconds);
      return;
    }

    _debouncer.run(() {
      if (!mounted) return;
      ref
          .read(marketplaceSearchControllerProvider.notifier)
          .search(value);
    });
  }

  void _onClear() {
    _controller.clear();
    _debouncer.cancel();
    ref.read(marketplaceSearchControllerProvider.notifier).clear();
  }

  void _showCooldownMessage(int seconds) {
    final msg = 'Please wait $seconds seconds before searching again.';
    widget.onCooldownMessage?.call(msg);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(marketplaceSearchControllerProvider);

    // Show snackbar when cooldown starts
    ref.listen(marketplaceSearchControllerProvider, (prev, next) {
      if (!_wasInCooldown && next.isCooldown) {
        _wasInCooldown = true;
        _showCooldownMessage(next.cooldownSeconds);
      }
      if (_wasInCooldown && !next.isCooldown) {
        _wasInCooldown = false;
      }
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _SearchInputField(
          controller: _controller,
          hintText: widget.hintText ?? 'Search guides, regions…',
          isLoading: state.isLoading,
          isCooldown: state.isCooldown,
          cooldownSeconds: state.cooldownSeconds,
          onChanged: _onChanged,
          onClear: _onClear,
        ),

        // Empty state hint
        if (state.normalizedQuery.isNotEmpty &&
            state.normalizedQuery.length < 2 &&
            !state.isLoading)
          const _MinCharsHint(),

        // Rate-limit cooldown bar
        if (state.isCooldown)
          _CooldownBar(seconds: state.cooldownSeconds),
      ],
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _SearchInputField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool isLoading;
  final bool isCooldown;
  final int cooldownSeconds;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchInputField({
    required this.controller,
    required this.hintText,
    required this.isLoading,
    required this.isCooldown,
    required this.cooldownSeconds,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.08)
            : Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCooldown
              ? Colors.orange.withOpacity(0.6)
              : theme.colorScheme.outline.withOpacity(0.2),
          width: isCooldown ? 1.5 : 1.0,
        ),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        enabled: !isCooldown,
        style: theme.textTheme.bodyMedium,
        decoration: InputDecoration(
          hintText: isCooldown
              ? 'Wait ${cooldownSeconds}s...'
              : hintText,
          hintStyle: TextStyle(
            color: isCooldown
                ? Colors.orange.withOpacity(0.8)
                : theme.colorScheme.onSurface.withOpacity(0.4),
          ),
          prefixIcon: isLoading
              ? const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : Icon(
                  isCooldown ? Icons.timer_outlined : Icons.search_rounded,
                  color: isCooldown
                      ? Colors.orange
                      : theme.colorScheme.onSurface.withOpacity(0.5),
                ),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: onClear,
                  tooltip: 'Clear search',
                )
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}

class _MinCharsHint extends StatelessWidget {
  const _MinCharsHint();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, left: 16),
      child: Text(
        'Type at least 2 characters to search',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
      ),
    );
  }
}

class _CooldownBar extends StatelessWidget {
  final int seconds;
  const _CooldownBar({required this.seconds});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, left: 4, right: 4),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              size: 14, color: Colors.orange),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Too many searches. Please wait ${seconds}s.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.orange,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A small widget showing live search metrics in debug mode.
/// Add to your dev drawer or debug overlay only.
class SearchMetricsDebugBadge extends ConsumerWidget {
  const SearchMetricsDebugBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metrics =
        ref.watch(marketplaceSearchControllerProvider).metrics;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '🔍 ${metrics.totalSearches} searches | '
        '⚡ ${metrics.cacheHitRate.toStringAsFixed(0)}% cache | '
        '📄 ${metrics.avgDocsPerSearch.toStringAsFixed(1)} docs/search | '
        '🚫 ${metrics.canceledRequests} canceled | '
        '⏱ ${metrics.rateLimitHits} rate-limited',
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 10,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}
