import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_theme.dart';

/// The Aethereal Oracle Design System (Oracle V2)
/// Provides premium, high-fidelity UI components with glassmorphism and neon aesthetics.
class OracleUI {
  // --- Standard Gradient Tokens ---
  static LinearGradient glassGradient(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return LinearGradient(
      colors: isDark 
          ? [Colors.white.withValues(alpha: 0.1), Colors.white.withValues(alpha: 0.05), Colors.transparent]
          : [const Color(0xFF0F172A).withValues(alpha: 0.04), const Color(0xFF0F172A).withValues(alpha: 0.01), Colors.transparent],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  static const LinearGradient premiumBorderGradient = LinearGradient(
    colors: [Color(0xFF00E676), Color(0xFFC19A6B), Color(0xFF00E676)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient neonAccentGradient = LinearGradient(
    colors: [Color(0xFF00E676), Color(0xFFC19A6B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient deepAuraGradient = RadialGradient(
    colors: [Color(0xFF141A21), Color(0xFF0A0D11)],
    center: Alignment.center,
    radius: 1.5,
  );

  // --- Premium Widgets ---

  /// A high-fidelity Frosted Glass Container with dynamic borders and shadows.
  static Widget glassContainer({
    required Widget child,
    double blur = 20,
    double opacity = 0.08,
    BorderRadius? radius,
    BorderRadius? borderRadius,
    EdgeInsets? padding,
    EdgeInsets? margin,
    Color? borderColor,
    Gradient? borderGradient,
    DecorationImage? image,
    double? width,
    double? height,
    bool showGlow = false,
    Color? glowColor,
  }) {
    final effectiveRadius = radius ?? borderRadius ?? BorderRadius.circular(24);
    
    return Builder(builder: (context) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      
      final glass = ClipRRect(
        borderRadius: effectiveRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            width: width,
            height: height,
            padding: padding ?? const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: (isDark ? AppPalette.nightCard : const Color(0xFF0F172A)).withValues(alpha: opacity),
              borderRadius: effectiveRadius,
              image: image,
              border: borderGradient != null 
                ? Border.fromBorderSide(BorderSide.none) // Border.all conflicts with gradients in some contexts
                : Border.all(
                    color: borderColor ?? AppTheme.secondaryBorder(context),
                    width: 0.5,
                  ),
              gradient: glassGradient(context),
            ),
            child: borderGradient != null
                ? CustomPaint(
                    painter: _GradientBorderPainter(
                      gradient: borderGradient,
                      radius: effectiveRadius,
                      strokeWidth: 1.5,
                    ),
                    child: child,
                  )
                : child,
          ),
        ),
      );

      return Container(
        width: width,
        height: height,
        margin: margin,
        decoration: BoxDecoration(
          borderRadius: effectiveRadius,
          boxShadow: showGlow ? [
            BoxShadow(
              color: (glowColor ?? Theme.of(context).colorScheme.primary).withValues(alpha: 0.25),
              blurRadius: 30,
              spreadRadius: 2,
            )
          ] : null,
        ),
        child: RepaintBoundary(
          child: glass.animate(target: showGlow ? 1 : 0).shimmer(
            duration: 3.seconds,
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
          ),
        ),
      );
    });
  }

  /// A higher-tier glass container with an animated gradient border.
  static Widget premiumGlassCard({
    required Widget child,
    double blur = 30,
    double opacity = 0.1,
    BorderRadius? radius,
    EdgeInsets? padding,
    EdgeInsets? margin,
    bool showGlow = true,
  }) {
    final effectiveRadius = radius ?? BorderRadius.circular(24);
    
    return Builder(builder: (context) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final primaryColor = Theme.of(context).colorScheme.primary;
      
      return Container(
        margin: margin,
        decoration: BoxDecoration(
          borderRadius: effectiveRadius,
          boxShadow: showGlow ? [
            BoxShadow(
              color: primaryColor.withValues(alpha: 0.15),
              blurRadius: 30,
              spreadRadius: 2,
            )
          ] : null,
        ),
        child: ClipRRect(
          borderRadius: effectiveRadius,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
            child: CustomPaint(
              painter: _GradientBorderPainter(
                radius: effectiveRadius,
                gradient: premiumBorderGradient,
                strokeWidth: 1.5,
              ),
              child: Container(
                padding: padding ?? const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: (isDark ? AppPalette.nightCard : const Color(0xFF0F172A)).withValues(alpha: opacity),
                  borderRadius: effectiveRadius,
                ),
                child: child,
              ),
            ),
          ),
        ).animate(onPlay: (c) => c.repeat(reverse: true))
         .shimmer(duration: 4.seconds, color: isDark ? Colors.white10 : Colors.black12),
      );
    });
  }

  /// A background providing a deep, ethereal aura effect using radial gradients.
  static Widget auraBackground({
    Widget child = const SizedBox.shrink(),
    bool isVisible = true,
    Color? baseColor,
  }) {
    return Builder(builder: (context) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark 
                ? [const Color(0xFF0A0D11), const Color(0xFF080A0E)]
                : [const Color(0xFFF8F9FA), const Color(0xFFE9ECEF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            // Dynamic Aurora Particles
            ...List.generate(3, (index) => _buildAuroraParticle(context, index)),
            child,
          ],
        ),
      );
    });
  }

  static Widget _buildAuroraParticle(BuildContext context, int index) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = [
      AppTheme.modernGreen(context).withValues(alpha: isDark ? 0.05 : 0.08),
      AppTheme.modernBlue(context).withValues(alpha: isDark ? 0.04 : 0.06),
      const Color(0xFF3B82F6).withValues(alpha: isDark ? 0.03 : 0.05),
    ];
    
    return Positioned(
      top: index == 0 ? -100 : (index == 1 ? 400 : -200),
      right: index == 0 ? -100 : (index == 2 ? 300 : -50),
      left: index == 1 ? -150 : null,
      child: Container(
        width: 400 + (index * 100).toDouble(),
        height: 400 + (index * 100).toDouble(),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: colors[index % colors.length],
        ),
      ).animate(onPlay: (c) => c.repeat(reverse: true))
       .blur(begin: const Offset(60, 60), end: const Offset(120, 120), duration: (5 + index * 2).seconds)
       .move(begin: const Offset(-20, -20), end: const Offset(40, 40), duration: (7 + index * 3).seconds),
    );
  }

  /// A neon-styled text with a subtle outer glow.
  static Widget neonText(String text, {
    TextStyle? style,
    Color glowColor = const Color(0xFF00E676),
    TextAlign? textAlign,
  }) {
    return Text(
      text,
      textAlign: textAlign,
      style: (style ?? GoogleFonts.outfit(fontWeight: FontWeight.bold)).copyWith(
        shadows: [
          Shadow(
            color: glowColor.withValues(alpha: 0.5),
            blurRadius: 10,
          ),
        ],
      ),
    );
  }

  /// Staggered entrance animation for lists or columns.
  static Widget staggeredEntrance({
    required Widget child,
    required int index,
    Duration delay = const Duration(milliseconds: 100),
  }) {
    return child.animate()
        .fadeIn(duration: 600.ms, delay: delay * index)
        .slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic);
  }

  /// Premium Chip used for categories or tags.
  static Widget glassChip({
    required BuildContext context,
    required String label,
    required bool isSelected,
    VoidCallback? onTap,
    IconData? icon,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = AppTheme.modernGreen(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: 300.ms,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? primary.withValues(alpha: 0.15) 
              : (isDark ? Colors.white : const Color(0xFF0F172A)).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected 
                ? primary.withValues(alpha: 0.5) 
                : AppTheme.secondaryBorder(context),
            width: 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: primary.withValues(alpha: 0.1),
              blurRadius: 15,
              spreadRadius: 1,
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
                color: isSelected ? primary : AppTheme.textSecondary(context)
              ),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected 
                    ? AppTheme.textPrimary(context) 
                    : AppTheme.textSecondary(context).withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// A card designed for the Kinetic Itinerary, supporting time-aware gradients.
  static Widget kineticCard({
    required BuildContext context,
    required Widget child,
    required bool isEvening,
    double opacity = 0.12,
  }) {
    final primaryColor = isEvening ? AppTheme.accentOchre(context) : AppTheme.modernGreen(context);
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.05),
            blurRadius: 40,
            spreadRadius: -10,
          )
        ],
      ),
      child: glassContainer(
        padding: const EdgeInsets.all(24),
        borderRadius: BorderRadius.circular(32),
        opacity: opacity,
        borderColor: primaryColor.withValues(alpha: 0.2),
        child: child,
      ),
    );
  }

  /// A node for the vertical timeline with neon pulsing effects.
  static Widget timelineNode({
    required BuildContext context,
    required bool isActive,
    required bool isLast,
    Color? color,
  }) {
    final primary = color ?? AppTheme.modernGreen(context);
    
    return Column(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? primary : AppTheme.glassBorder(context),
            boxShadow: isActive ? [
              BoxShadow(
                color: primary.withValues(alpha: 0.5),
                blurRadius: 10,
                spreadRadius: 2,
              )
            ] : null,
          ),
        ).animate(target: isActive ? 1 : 0).shimmer(duration: 2.seconds),
        if (!isLast)
          Container(
            width: 2,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  isActive ? primary : AppTheme.glassBorder(context),
                  AppTheme.glassBorder(context).withValues(alpha: 0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
      ],
    );
  }

  /// Helper to allow passing context to glassContainer easily
  static Widget glassContainerWithContext({
    required BuildContext context,
    required Widget child,
    double blur = 20,
    double opacity = 0.08,
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
      borderGradient: borderGradient,
    );
  }

  /// A pulsing concentrated ring indicator for 'Live' states.
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
            color: color.withValues(alpha: 0.6),
            blurRadius: size,
            spreadRadius: size / 2,
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

  /// A card with a neon border glow for important highlights.
  static Widget neonCard({
    required BuildContext context,
    required Widget child,
    Color? neonColor,
  }) {
    final color = neonColor ?? AppTheme.modernGreen(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.15),
            blurRadius: 30,
            spreadRadius: -10,
          )
        ],
      ),
      child: glassContainer(
        borderRadius: BorderRadius.circular(24),
        borderColor: color.withValues(alpha: 0.3),
        borderGradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.5),
            color.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        child: child,
      ),
    );
  }
}

class _GradientBorderPainter extends CustomPainter {
  final BorderRadius radius;
  final Gradient gradient;
  final double strokeWidth;

  _GradientBorderPainter({required this.radius, required this.gradient, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    var rect = Offset.zero & size;
    var paint = Paint()
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..shader = gradient.createShader(rect);

    var rrect = radius.toRRect(rect);
    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

/// Structured exception for Oracle system failures.
class OracleException implements Exception {
  final String message;
  final String? code;
  final dynamic technicalDetails;

  OracleException(this.message, {this.code, this.technicalDetails});

  @override
  String toString() => message;
}

/// Global manager for Zenith UI notifications to prevent persistent leaks.
class OracleNotification {
  static OverlayEntry? _currentOverlay;
  static bool _isDisplaying = false;
  static String? _lastMessage;

  static void show(BuildContext context, String text, {bool isError = false, Duration duration = const Duration(seconds: 4)}) {
    // Suppression Logic: Don't show the exact same message if it's already being displayed
    if (_isDisplaying && _lastMessage == text) return;

    // If a notification is already displayed, remove it before showing the next one
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
                _lastMessage = null; // Important: Clear message so it can re-trigger
              }
            },
            child: OracleUI.glassContainer(
              showGlow: true,
              glowColor: isError ? Colors.redAccent : AppTheme.modernGreen(context),
              borderColor: isError ? Colors.redAccent.withValues(alpha: 0.3) : AppTheme.modernGreen(context).withValues(alpha: 0.3),
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(
                    isError ? Icons.warning_amber_rounded : Icons.auto_awesome_rounded,
                    color: isError ? Colors.redAccent : AppTheme.modernGreen(context),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        OracleUI.neonText(
                          isError ? "SYSTEM ALERT" : "ORACLE INSIGHT",
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: isError ? Colors.redAccent : AppTheme.modernGreen(context),
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
            ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.95, 0.95), curve: Curves.easeOutBack),
          ),
        ),
      ),
    );

    _currentOverlay = overlayEntry;
    _isDisplaying = true;
    overlay.insert(overlayEntry);

    // Auto-dismiss logic with safety check
    Future.delayed(duration, () {
      if (overlayEntry.mounted && _currentOverlay == overlayEntry) {
        overlayEntry.remove();
        _isDisplaying = false;
        _currentOverlay = null;
        _lastMessage = null; // Reset message on dismissal
      }
    });
  }
}

