import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'app_theme.dart';

class Haptics {
  static void light() => HapticFeedback.lightImpact();
  static void medium() => HapticFeedback.mediumImpact();
  static void heavy() => HapticFeedback.heavyImpact();
}

/// The Aethereal Oracle Design System (Light UI Edition)
/// Provides clean, earthy modern UI components (solid surfaces, subtle borders, soft shadows).
class OracleUI {
  
  // --- Legacy Gradients ---
  static const LinearGradient premiumBorderGradient = LinearGradient(
    colors: [AppPalette.rust, AppPalette.earth],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient neonAccentGradient = LinearGradient(
    colors: [AppPalette.rust, AppPalette.earth],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // --- Modern UI Widgets ---

  /// A modern solid container replacing the old glass effect. 
  /// Uses a white surface with a soft border and subtle shadow.
  static Widget glassContainer({
    required Widget child,
    double blur = 20, // Ignored in Light UI, kept for compatibility
    double opacity = 1.0,
    BorderRadius? radius,
    BorderRadius? borderRadius,
    EdgeInsets? padding,
    EdgeInsets? margin,
    Color? borderColor,
    Gradient? borderGradient, // Ignored in Light UI
    DecorationImage? image,
    double? width,
    double? height,
    bool showGlow = false,
    Color? glowColor,
  }) {
    final effectiveRadius = radius ?? borderRadius ?? BorderRadius.circular(22); // Figma r-lg is 22px
    
    return Builder(builder: (context) {
      return Container(
        width: width,
        height: height,
        margin: margin,
        padding: padding ?? const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: (Theme.of(context).brightness == Brightness.dark ? AppPaletteDark.card : AppPalette.surface).withValues(alpha: opacity),
          borderRadius: effectiveRadius,
          image: image,
          border: Border.all(
            color: borderColor ?? AppTheme.borderColor(context),
            width: 1.0,
          ),
          boxShadow: showGlow ? [
            BoxShadow(
              color: (glowColor ?? Theme.of(context).primaryColor).withValues(alpha: 0.15),
              blurRadius: 20,
              spreadRadius: 0,
              offset: const Offset(0, 4),
            )
          ] : AppTheme.softShadow,
        ),
        child: child,
      );
    });
  }

  /// A premium elevated card (replaces premiumGlassCard).
  static Widget premiumGlassCard({
    required Widget child,
    double blur = 30, // Ignored
    double opacity = 1.0,
    BorderRadius? radius,
    EdgeInsets? padding,
    EdgeInsets? margin,
    bool showGlow = true,
  }) {
    final effectiveRadius = radius ?? BorderRadius.circular(22);
    
    return Builder(builder: (context) {
      return Container(
        margin: margin,
        padding: padding ?? const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark ? AppPaletteDark.card : AppPalette.surface,
          borderRadius: effectiveRadius,
          border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.15), width: 1.5),
          boxShadow: showGlow ? [
            BoxShadow(
              color: Theme.of(context).primaryColor.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.2 : 0.08),
              blurRadius: 24,
              offset: const Offset(0, 8),
            )
          ] : AppTheme.premiumShadow,
        ),
        child: child,
      );
    });
  }

  /// Base background for screens
  static Widget auraBackground({
    Widget child = const SizedBox.shrink(),
    bool isVisible = true,
    Color? baseColor,
  }) {
    return Builder(builder: (context) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: Theme.of(context).brightness == Brightness.dark 
              ? [AppPaletteDark.bg, AppPaletteDark.bg] 
              : [AppPalette.bg, AppPalette.bg2],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: child,
      );
    });
  }

  static Widget neonText(String text, {
    TextStyle? style,
    Color? glowColor,
    TextAlign? textAlign,
  }) {
    return Builder(builder: (context) {
      final effectiveColor = glowColor ?? Theme.of(context).primaryColor;
      return Text(
        text,
        textAlign: textAlign,
        style: (style ?? GoogleFonts.outfit(fontWeight: FontWeight.bold)).copyWith(
          color: effectiveColor,
          letterSpacing: 1.0,
        ),
      );
    });
  }

  /// Page Entrance: Cards fade in from below with 30px offset.
  static Widget pageEntrance({
    required Widget child,
    required int index,
    Duration stagger = const Duration(milliseconds: 80),
  }) {
    return child.animate()
        .fadeIn(duration: 500.ms, delay: stagger * index)
        .moveY(begin: 30, end: 0, duration: 500.ms, curve: Curves.easeOutCubic);
  }

  /// Alias for pageEntrance to prevent breaking existing screens
  static Widget staggeredEntrance({
    required Widget child,
    required int index,
    Duration stagger = const Duration(milliseconds: 80),
  }) => pageEntrance(child: child, index: index, stagger: stagger);

  /// Detail Stagger: Place Details sections reveal in sequence.
  static Widget detailStagger({
    required Widget child,
    required int index,
    Duration stagger = const Duration(milliseconds: 150),
  }) {
    return child.animate()
        .fadeIn(duration: 500.ms, delay: stagger * index)
        .moveX(begin: 20, end: 0, duration: 500.ms, curve: Curves.easeOutCubic);
  }

  /// FAB Breathe: Gently pulses the FAB.
  static Widget fabBreathe({required Widget child}) {
    return child.animate(onPlay: (c) => c.repeat(reverse: true))
        .scale(begin: const Offset(1.0, 1.0), end: const Offset(1.04, 1.04), duration: 1500.ms, curve: Curves.easeInOut);
  }

  /// Hero Crossfade: Warm 1200ms crossfade for backgrounds.
  static Widget heroCrossfade({required Widget child}) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 1200),
      child: child,
    );
  }

  /// Premium Chip used for categories or tags (replaces glassChip).
  static Widget glassChip({
    required BuildContext context,
    required String label,
    required bool isSelected,
    VoidCallback? onTap,
    IconData? icon,
  }) {
    final primary = Theme.of(context).primaryColor;
    final earth = Theme.of(context).colorScheme.secondary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: 300.ms,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? primary : Colors.transparent,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: isSelected ? primary : AppPalette.ink.withValues(alpha: 0.12),
            width: 1.5,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: primary.withValues(alpha: 0.22),
              blurRadius: 20,
              offset: const Offset(0, 4),
            )
          ] : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon, 
                size: 16, 
                color: isSelected ? Colors.white : earth,
              ),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isSelected ? (Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white) : AppTheme.textPrimary(context).withValues(alpha: 0.8),
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Kinetic Card for dynamic lists (with tap animation)
  static Widget kineticCard({
    required BuildContext context,
    required Widget child,
    required bool isEvening,
    double opacity = 1.0,
    VoidCallback? onTap,
  }) {
    return _KineticCardWidget(
      onTap: onTap,
      child: glassContainer(
        padding: const EdgeInsets.all(24),
        borderRadius: BorderRadius.circular(22),
        opacity: opacity,
        child: child,
      ),
    );
  }

  static Widget timelineNode({
    required BuildContext context,
    required bool isActive,
    required bool isLast,
    Color? color,
  }) {
    final primary = color ?? Theme.of(context).primaryColor;
    final secondary = Theme.of(context).colorScheme.secondary;
    
    return Column(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? primary : secondary,
            boxShadow: isActive ? [
              BoxShadow(
                color: primary.withValues(alpha: 0.3),
                blurRadius: 8,
                spreadRadius: 2,
              )
            ] : null,
          ),
        ).animate(target: isActive ? 1 : 0).scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1)),
        if (!isLast)
          Container(
            width: 2,
            height: 60,
            decoration: BoxDecoration(
              color: isActive ? primary.withValues(alpha: 0.3) : secondary.withValues(alpha: 0.5),
            ),
          ),
      ],
    );
  }

  /// Helper to allow passing context
  static Widget glassContainerWithContext({
    required BuildContext context,
    required Widget child,
    double blur = 20,
    double opacity = 1.0,
    BorderRadius? borderRadius,
    EdgeInsets? padding,
    Color? borderColor,
    Gradient? borderGradient,
  }) {
    return glassContainer(
      child: child,
      blur: blur,
      opacity: opacity,
      borderRadius: borderRadius,
      padding: padding,
      borderColor: borderColor,
    );
  }

  static Widget pulseOracle({
    required BuildContext context,
    required Color color,
    double size = 12,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: size,
            spreadRadius: size / 4,
          )
        ],
      ),
    ).animate(onPlay: (c) => c.repeat()).scale(
      duration: 1.seconds,
      begin: const Offset(0.8, 0.8),
      end: const Offset(1.2, 1.2),
      curve: Curves.easeInOut,
    ).then().scale(
      duration: 1.seconds,
      begin: const Offset(1.2, 1.2),
      end: const Offset(0.8, 0.8),
      curve: Curves.easeInOut,
    );
  }

  static Widget neonCard({
    required BuildContext context,
    required Widget child,
    Color? neonColor,
  }) {
    final color = neonColor ?? Theme.of(context).primaryColor;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: glassContainer(
        borderRadius: BorderRadius.circular(22),
        borderColor: color.withValues(alpha: 0.3),
        child: child,
      ),
    );
  }
}

class OracleException implements Exception {
  final String message;
  final String? code;
  final dynamic technicalDetails;

  OracleException(this.message, {this.code, this.technicalDetails});

  @override
  String toString() => message;
}

class OracleNotification {
  static OverlayEntry? _currentOverlay;
  static bool _isDisplaying = false;
  static String? _lastMessage;

  static void show(BuildContext context, String text, {bool isError = false, Duration duration = const Duration(seconds: 4)}) {
    if (_isDisplaying && _lastMessage == text) return;

    if (_isDisplaying) {
      _currentOverlay?.remove();
      _isDisplaying = false;
      _currentOverlay = null;
    }

    _lastMessage = text;

    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;
    
    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: 100,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: Dismissible(
            key: UniqueKey(),
            direction: DismissDirection.horizontal,
            onDismissed: (_) {
              if (_currentOverlay == overlayEntry) {
                overlayEntry.remove();
                _isDisplaying = false;
                _currentOverlay = null;
                _lastMessage = null; 
              }
            },
            child: OracleUI.glassContainer(
              showGlow: true,
              glowColor: isError ? AppPalette.error : AppPalette.success,
              borderColor: isError ? AppPalette.error.withValues(alpha: 0.3) : AppPalette.success.withValues(alpha: 0.3),
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(
                    isError ? Icons.warning_amber_rounded : Icons.check_circle_rounded,
                    color: isError ? Theme.of(context).colorScheme.error : AppTheme.successGreen,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isError ? "SYSTEM ALERT" : "SUCCESS",
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: isError ? Theme.of(context).colorScheme.error : AppTheme.successGreen,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          text,
                          style: GoogleFonts.inter(
                            color: AppTheme.textPrimary(context),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0, curve: Curves.easeOutBack),
          ),
        ),
      ),
    );

    _currentOverlay = overlayEntry;
    _isDisplaying = true;
    overlay.insert(overlayEntry);

    Future.delayed(duration, () {
      if (overlayEntry.mounted && _currentOverlay == overlayEntry) {
        overlayEntry.remove();
        _isDisplaying = false;
        _currentOverlay = null;
        _lastMessage = null;
      }
    });
  }
}

class _KineticCardWidget extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _KineticCardWidget({required this.child, this.onTap});

  @override
  State<_KineticCardWidget> createState() => _KineticCardWidgetState();
}

class _KineticCardWidgetState extends State<_KineticCardWidget> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        Haptics.light();
        setState(() => _isPressed = true);
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        transform: Matrix4.identity()..scale(_isPressed ? 0.97 : 1.0, _isPressed ? 0.97 : 1.0),
        transformAlignment: Alignment.center,
        child: widget.child,
      ),
    );
  }
}
