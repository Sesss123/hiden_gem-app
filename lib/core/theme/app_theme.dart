import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppPalette {
  // --- Tropical / Earthy Modern (Light UI) ---
  static const Color bg = Color(0xFFF7F5F2);
  static const Color bg2 = Color(0xFFEFEDE9);
  static const Color surface = Color(0xFFFFFFFF);
  
  static const Color rust = Color(0xFFC0580A);
  static const Color rustDim = Color(0xFFA04508);
  
  // Hero Gradient
  static const Color heroCream = Color(0xFFFDEBD8);
  static const Color heroOchre = Color(0xFFECC89A);
  
  static const Color earth = Color(0xFF7C6A55);
  static const Color sand = Color(0xFFD9C9B0);
  static const Color sand2 = Color(0xFFEDE3D6);
  
  static const Color ink = Color(0xFF1A1512);
  
  static const Color success = Color(0xFF2E7D32);
  static const Color error = Color(0xFFC62828);
  static const Color warning = Color(0xFFF59E0B);
  
  // Legacy mappings to prevent breaking changes while we migrate
  static const Color ceylonBlue = earth;
  static const Color sigiriyaOchre = rust;
  static const Color modernBlue = earth;
  static const Color modernGreen = rust;
}

class AppPaletteDark {
  static const Color bg = Color(0xFF080B0F);
  static const Color surface = Color(0xFF0F1419);
  static const Color card = Color(0xFF141C24);
  
  static const Color gem = Color(0xFF22C55E);
  static const Color gemDim = Color(0xFF16A34A);
  
  static const Color gold = Color(0xFFC19A6B);
  static const Color blue = Color(0xFF3B82F6);
  
  static const Color text = Color(0xFFF8FAFC);
  static const Color textSub = Color(0x8CF8FAFC); // 0.55 opacity F8FAFC
}

class AppTheme {
  // --- Dynamic Accessors (Theme Aware) ---
  static Color cardColor(BuildContext context) => Theme.of(context).cardColor;
  static Color borderColor(BuildContext context) => Theme.of(context).brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.07) : AppPalette.ink.withValues(alpha: 0.12);
  static Color textPrimary(BuildContext context) => Theme.of(context).brightness == Brightness.dark ? AppPaletteDark.text : AppPalette.ink;
  static Color textSecondary(BuildContext context) => Theme.of(context).brightness == Brightness.dark ? AppPaletteDark.textSub : AppPalette.ink.withValues(alpha: 0.55);
  static Color scaffoldColor(BuildContext context) => Theme.of(context).scaffoldBackgroundColor;

  // Semantic Aliases
  static Color primaryBlue(BuildContext context) => Theme.of(context).colorScheme.secondary;
  static Color pureWhite(BuildContext context) => Theme.of(context).colorScheme.surface;
  
  static Color primaryBorder(BuildContext context) => AppPalette.ink.withValues(alpha: 0.07);
  static Color secondaryBorder(BuildContext context) => AppPalette.ink.withValues(alpha: 0.12);
  
  static Color translucentOverlay(BuildContext context) => Colors.black.withValues(alpha: 0.3);
  
  // Hardcoded
  static const Color successGreen = AppPalette.success;
  static const Color warningAmber = AppPalette.warning;
  static const Color errorRed = AppPalette.error;

  // --- Premium Shadows ---
  static List<BoxShadow> get premiumShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 16,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
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
    color: AppPalette.ink,
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
    color: AppPalette.rust,
  );

  static TextStyle bodyStyle(BuildContext context) => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppPalette.ink.withValues(alpha: 0.55),
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
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      error: AppPalette.error,
    ),
    textTheme: GoogleFonts.interTextTheme().copyWith(
      displayLarge: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.w800, color: AppPalette.ink),
      displayMedium: GoogleFonts.outfit(fontSize: 26, fontWeight: FontWeight.w700, color: AppPalette.ink),
      headlineMedium: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w600, color: AppPalette.ink),
      titleLarge: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600, color: AppPalette.ink),
      bodyLarge: GoogleFonts.inter(fontSize: 16, color: AppPalette.ink),
      bodyMedium: GoogleFonts.inter(fontSize: 14, color: AppPalette.ink.withValues(alpha: 0.55)),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: AppPalette.ink),
      iconTheme: const IconThemeData(color: AppPalette.ink),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppPalette.rust,
        foregroundColor: Colors.white,
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
      foregroundColor: Colors.white,
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
      onPrimary: Colors.black,
      onSecondary: Colors.white,
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
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: AppPaletteDark.text),
      iconTheme: const IconThemeData(color: AppPaletteDark.text),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppPaletteDark.gem,
        foregroundColor: Colors.black,
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
        side: BorderSide(color: Colors.white.withValues(alpha: 0.07), width: 1),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppPaletteDark.gem,
      foregroundColor: Colors.black,
    ),
    dividerColor: Colors.white.withValues(alpha: 0.07),
  );

  static ThemeData get breezeTheme => lightTheme;
  static ThemeData get abyssTheme => darkTheme;

  // --- Legacy Compatibility Getters ---
  static Color sigiriyaOchre(BuildContext context) => AppPalette.rust;
  static Color modernGreen(BuildContext context) => AppPalette.rust;
  static Color modernBlue(BuildContext context) => AppPalette.earth;
  static Color accentOchre(BuildContext context) => AppPalette.rust;
  static Color darkText(BuildContext context) => AppPalette.ink;
  static Color getDynamicOverlay() => Colors.transparent;
  static Color glassBackground(BuildContext context) => AppPalette.surface;
  static Color glassBorder(BuildContext context) => AppPalette.ink.withValues(alpha: 0.12);

  static LinearGradient modernGradient(BuildContext context) => const LinearGradient(
    colors: [AppPalette.heroCream, AppPalette.heroOchre],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static ButtonStyle primaryButtonStyle(BuildContext context) => ElevatedButton.styleFrom(
    backgroundColor: AppPalette.rust,
    foregroundColor: Colors.white,
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
      color: (color ?? AppPalette.surface).withValues(alpha: opacity),
      borderRadius: shape == BoxShape.circle ? null : (radius ?? BorderRadius.circular(22)),
      shape: shape,
      boxShadow: AppTheme.premiumShadow,
    );
  }
}
