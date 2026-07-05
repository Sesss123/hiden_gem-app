import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppPalette {
  // --- Tropical / Earthy Modern (Light UI) ---
  static const Color bg = AppTheme.colors.primary;
  static const Color bg2 = AppTheme.colors.primary;
  static const Color surface = AppTheme.colors.primary;
  
  static const Color rust = AppTheme.colors.primary;
  static const Color rustDim = AppTheme.colors.primary;
  
  // Hero Gradient
  static const Color heroCream = AppTheme.colors.primary;
  static const Color heroOchre = AppTheme.colors.primary;
  
  static const Color earth = AppTheme.colors.primary;
  static const Color sand = AppTheme.colors.primary;
  static const Color sand2 = AppTheme.colors.primary;
  
  static const Color ink = AppTheme.colors.primary;
  
  static const Color success = AppTheme.colors.primary;
  static const Color error = AppTheme.colors.primary;
  static const Color warning = AppTheme.colors.primary;
  
  // Legacy mappings to prevent breaking changes while we migrate
  static const Color ceylonBlue = earth;
  static const Color sigiriyaOchre = rust;
  static const Color modernBlue = earth;
  static const Color modernGreen = rust;
}

class AppPaletteDark {
  static const Color bg = AppTheme.colors.primary;
  static const Color surface = AppTheme.colors.primary;
  static const Color card = AppTheme.colors.primary;
  
  static const Color gem = AppTheme.colors.primary;
  static const Color gemDim = AppTheme.colors.primary;
  
  static const Color gold = AppTheme.colors.primary;
  static const Color blue = AppTheme.colors.primary;
  
  static const Color text = AppTheme.colors.primary;
  static const Color textSub = AppTheme.colors.primary; // 0.65 opacity F8FAFC
}

class AppTheme {
  // --- Dynamic Accessors (Theme Aware) ---
  static Color cardColor(BuildContext context) => Theme.of(context).cardColor;
  static Color borderColor(BuildContext context) => Theme.of(context).brightness == Brightness.dark ? AppTheme.colors.white.withValues(alpha: 0.07) : AppPalette.ink.withValues(alpha: 0.12);
  static Color textPrimary(BuildContext context) => Theme.of(context).brightness == Brightness.dark ? AppPaletteDark.text : AppPalette.ink;
  static Color textSecondary(BuildContext context) => Theme.of(context).brightness == Brightness.dark ? AppPaletteDark.textSub : AppPalette.ink.withValues(alpha: 0.65);
  static Color scaffoldColor(BuildContext context) => Theme.of(context).scaffoldBackgroundColor;

  // Semantic Aliases
  static Color primaryBlue(BuildContext context) => Theme.of(context).colorScheme.secondary;
  static Color pureWhite(BuildContext context) => Theme.of(context).colorScheme.surface;
  
  static Color primaryBorder(BuildContext context) => AppPalette.ink.withValues(alpha: 0.07);
  static Color secondaryBorder(BuildContext context) => AppPalette.ink.withValues(alpha: 0.12);
  
  static Color translucentOverlay(BuildContext context) => AppTheme.colors.black.withValues(alpha: 0.3);
  
  // Hardcoded
  static const Color successGreen = AppPalette.success;
  static const Color warningAmber = AppPalette.warning;
  static const Color errorRed = AppPalette.error;

  // --- Premium Shadows ---
  static List<BoxShadow> get premiumShadow => [
        BoxShadow(
          color: AppTheme.colors.black.withValues(alpha: 0.04),
          blurRadius: 16,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: AppTheme.colors.black.withValues(alpha: 0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

  // --- Backgrounds ---
  static LinearGradient appBackground(BuildContext context) {
    return const LinearGradient(
      colors: [AppPalette.bg, AppPalette.bg2],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );
  }

  // --- Advanced Text Styles ---
  static TextStyle oracleBrandHeading(BuildContext context) => GoogleFonts.outfit(
    fontSize: 28,
    fontWeight: FontWeight.w900,
    color: textPrimary(context),
    letterSpacing: -1,
  );

  static TextStyle get budgetEmphasis => GoogleFonts.outfit(
    fontSize: 24,
    fontWeight: FontWeight.w800,
    color: AppPalette.rust,
  );

  static TextStyle labelStyle(BuildContext context) => GoogleFonts.outfit(
    fontSize: 10,
    fontWeight: FontWeight.bold,
    letterSpacing: 2.0,
    color: Theme.of(context).colorScheme.primary,
  );

  static TextStyle bodyStyle(BuildContext context) => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: textSecondary(context),
    height: 1.7,
  );

  // --- ThemeData: Light UI (Tropical Modern) ---
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: AppPalette.rust,
    scaffoldBackgroundColor: AppPalette.bg,
    colorScheme: const ColorScheme.light(
      primary: AppPalette.rust,
      secondary: AppPalette.earth,
      surface: AppPalette.surface,
      onSurface: AppPalette.ink,
      onPrimary: AppTheme.colors.white,
      onSecondary: AppTheme.colors.white,
      error: AppPalette.error,
    ),
    textTheme: GoogleFonts.interTextTheme().copyWith(
      displayLarge: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.w800, color: AppPalette.ink),
      displayMedium: GoogleFonts.outfit(fontSize: 26, fontWeight: FontWeight.w700, color: AppPalette.ink),
      headlineMedium: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w600, color: AppPalette.ink),
      titleLarge: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600, color: AppPalette.ink),
      bodyLarge: GoogleFonts.inter(fontSize: 16, color: AppPalette.ink),
      bodyMedium: GoogleFonts.inter(fontSize: 14, color: AppPalette.ink.withValues(alpha: 0.65)),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppTheme.colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: AppPalette.ink),
      iconTheme: const IconThemeData(color: AppPalette.ink),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppPalette.rust,
        foregroundColor: AppTheme.colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
        textStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.2),
        elevation: 0,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppPalette.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: AppPalette.ink.withValues(alpha: 0.07), width: 1),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppPalette.rust,
      foregroundColor: AppTheme.colors.white,
    ),
    dividerColor: AppPalette.sand,
  );

  // --- ThemeData: Dark UI ---
  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: AppPaletteDark.gem,
    scaffoldBackgroundColor: AppPaletteDark.bg,
    colorScheme: const ColorScheme.dark(
      primary: AppPaletteDark.gem,
      secondary: AppPaletteDark.gold,
      surface: AppPaletteDark.surface,
      onSurface: AppPaletteDark.text,
      onPrimary: AppTheme.colors.black,
      onSecondary: AppTheme.colors.white,
      error: AppPalette.error,
    ),
    textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
      displayLarge: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.w800, color: AppPaletteDark.text),
      displayMedium: GoogleFonts.outfit(fontSize: 26, fontWeight: FontWeight.w700, color: AppPaletteDark.text),
      headlineMedium: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w600, color: AppPaletteDark.text),
      titleLarge: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600, color: AppPaletteDark.text),
      bodyLarge: GoogleFonts.inter(fontSize: 16, color: AppPaletteDark.text),
      bodyMedium: GoogleFonts.inter(fontSize: 14, color: AppPaletteDark.textSub),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppTheme.colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: AppPaletteDark.text),
      iconTheme: const IconThemeData(color: AppPaletteDark.text),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppPaletteDark.gem,
        foregroundColor: AppTheme.colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
        textStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.2),
        elevation: 0,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppPaletteDark.card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: AppTheme.colors.white.withValues(alpha: 0.07), width: 1),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppPaletteDark.gem,
      foregroundColor: AppTheme.colors.black,
    ),
    dividerColor: AppTheme.colors.white.withValues(alpha: 0.07),
  );

  static ThemeData get breezeTheme => lightTheme;
  static ThemeData get abyssTheme => darkTheme;

  // --- Legacy Compatibility Getters ---
  static Color sigiriyaOchre(BuildContext context) => Theme.of(context).colorScheme.primary;
  static Color modernGreen(BuildContext context) => Theme.of(context).colorScheme.primary;
  static Color modernBlue(BuildContext context) => Theme.of(context).colorScheme.secondary;
  static Color accentOchre(BuildContext context) => Theme.of(context).colorScheme.primary;
  static Color darkText(BuildContext context) => textPrimary(context);
  static Color getDynamicOverlay() => AppTheme.colors.transparent;
  static Color glassBackground(BuildContext context) => cardColor(context);
  static Color glassBorder(BuildContext context) => borderColor(context);

  static LinearGradient modernGradient(BuildContext context) => const LinearGradient(
    colors: [AppPalette.heroCream, AppPalette.heroOchre],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static ButtonStyle primaryButtonStyle(BuildContext context) => ElevatedButton.styleFrom(
    backgroundColor: AppPalette.rust,
    foregroundColor: AppTheme.colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
  );

  static BoxDecoration glassDecoration(BuildContext context, {
    double opacity = 1.0, 
    double blur = 20,
    BorderRadius? radius,
    Color? color,
    BoxShape shape = BoxShape.rectangle,
    bool? isDarkOverride,
  }) {
    return BoxDecoration(
      color: (color ?? cardColor(context)).withValues(alpha: opacity),
      borderRadius: shape == BoxShape.circle ? null : (radius ?? BorderRadius.circular(22)),
      shape: shape,
      boxShadow: AppTheme.premiumShadow,
    );
  }
}
