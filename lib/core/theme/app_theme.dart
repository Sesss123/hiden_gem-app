import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Central color-name proxy so the rest of the app can write
/// `AppTheme.colors.X` instead of importing `Colors` everywhere.
/// All fields are `final` and set via a `const` constructor (NOT getters),
/// which is required so they can be used inside other `static const`
/// declarations (e.g. AppPalette below) and other constant-expression call
/// sites throughout the app.
class AppThemeColors {
  // --- Brand ---
  final Color primary;

  // --- Base ---
  final Color white;
  final Color black;
  final Color transparent;

  // --- White opacity variants ---
  final Color white10;
  final Color white12;
  final Color white24;
  final Color white30;
  final Color white38;
  final Color white54;
  final Color white60;
  final Color white70;

  // --- Black opacity variants ---
  final Color black12;
  final Color black26;
  final Color black38;
  final Color black45;
  final Color black54;
  final Color black87;

  // --- Material swatches (support .shadeXXX and [shade] indexing) ---
  final MaterialColor red;
  final MaterialColor grey;
  final MaterialColor blueGrey;
  final MaterialColor green;
  final MaterialColor blue;
  final MaterialColor amber;
  final MaterialColor teal;
  final MaterialColor orange;
  final MaterialColor purple;
  final MaterialColor pink;
  final MaterialColor brown;

  // --- Accent colors ---
  final MaterialAccentColor redAccent;
  final MaterialAccentColor greenAccent;
  final MaterialAccentColor blueAccent;
  final MaterialAccentColor amberAccent;
  final MaterialAccentColor orangeAccent;
  final MaterialAccentColor purpleAccent;
  final MaterialAccentColor deepPurpleAccent;
  final MaterialAccentColor pinkAccent;
  final MaterialAccentColor cyanAccent;
  final MaterialAccentColor tealAccent;
  final MaterialAccentColor indigoAccent;

  const AppThemeColors({
    this.primary = const Color(0xFFC1440E), // brand rust/ochre
    this.white = Colors.white,
    this.black = Colors.black,
    this.transparent = Colors.transparent,
    this.white10 = Colors.white10,
    this.white12 = Colors.white12,
    this.white24 = Colors.white24,
    this.white30 = Colors.white30,
    this.white38 = Colors.white38,
    this.white54 = Colors.white54,
    this.white60 = Colors.white60,
    this.white70 = Colors.white70,
    this.black12 = Colors.black12,
    this.black26 = Colors.black26,
    this.black38 = Colors.black38,
    this.black45 = Colors.black45,
    this.black54 = Colors.black54,
    this.black87 = Colors.black87,
    this.red = Colors.red,
    this.grey = Colors.grey,
    this.blueGrey = Colors.blueGrey,
    this.green = Colors.green,
    this.blue = Colors.blue,
    this.amber = Colors.amber,
    this.teal = Colors.teal,
    this.orange = Colors.orange,
    this.purple = Colors.purple,
    this.pink = Colors.pink,
    this.brown = Colors.brown,
    this.redAccent = Colors.redAccent,
    this.greenAccent = Colors.greenAccent,
    this.blueAccent = Colors.blueAccent,
    this.amberAccent = Colors.amberAccent,
    this.orangeAccent = Colors.orangeAccent,
    this.purpleAccent = Colors.purpleAccent,
    this.deepPurpleAccent = Colors.deepPurpleAccent,
    this.pinkAccent = Colors.pinkAccent,
    this.cyanAccent = Colors.cyanAccent,
    this.tealAccent = Colors.tealAccent,
    this.indigoAccent = Colors.indigoAccent,
  });
}

class AppPalette {
  // --- Tropical / Earthy Modern (Light UI / "Breeze") ---
  // Matches "Hidden Gems SL - UI Refresh.dc.html" refresh mockups exactly.
  static const Color bg = Color(0xFFFFFDF8);
  static const Color bg2 = Color(0xFFF3E9D8);
  static const Color surface = Color(0xFFFFFFFF);
  // Muted surface used for input fields, filter chips (unselected), stat tiles.
  static const Color surfaceMuted = Color(0xFFF3ECE0);
  // Secondary/caption text tone used across refresh mockups.
  static const Color textMuted = Color(0xFF8C7A6A);

  static const Color rust = Color(0xFFC1440E);
  static const Color rustDim = Color(0xFF8C3009);

  // Hero Gradient
  static const Color heroCream = Color(0xFFF7E9CF);
  static const Color heroOchre = Color(0xFFE0A93A);

  static const Color earth = Color(0xFF6B4226);
  static const Color sand = Color(0xFFE3CBA5);
  static const Color sand2 = Color(0xFFD8B888);

  static const Color ink = Color(0xFF2B211A);

  static const Color success = Color(0xFF2E7D32);
  static const Color error = Color(0xFFC62828);
  static const Color warning = Color(0xFFE0A93A);

  // Legacy mappings to prevent breaking changes while we migrate
  static const Color ceylonBlue = earth;
  static const Color sigiriyaOchre = rust;
  static const Color modernBlue = earth;
  static const Color modernGreen = rust;
}

class AppPaletteDark {
  static const Color bg = Color(0xFF14100D);
  static const Color surface = Color(0xFF1F1911);
  static const Color card = Color(0xFF241D15);

  // Brand rust/ochre in the dark theme too — no green anywhere in the app.
  static const Color gem = Color(0xFFC1440E);
  static const Color gemDim = Color(0xFF8C3009);

  static const Color gold = Color(0xFFE0A93A);
  static const Color blue = Color(0xFF3B82F6);

  static const Color text = Color(0xFFF8FAFC);
  static const Color textSub = Color(0xA6F8FAFC); // 0.65 opacity F8FAFC
}

class AppTheme {
  // --- Color name proxy (AppTheme.colors.red, .white, .amber[700], etc.) ---
  static const AppThemeColors colors = AppThemeColors();

  // --- Dynamic Accessors (Theme Aware) ---
  static Color cardColor(BuildContext context) => Theme.of(context).cardColor;
  static Color borderColor(BuildContext context) => Theme.of(context).brightness == Brightness.dark ? AppTheme.colors.white.withValues(alpha: 0.07) : AppPalette.ink.withValues(alpha: 0.12);
  static Color textPrimary(BuildContext context) => Theme.of(context).brightness == Brightness.dark ? AppPaletteDark.text : AppPalette.ink;
  static Color textSecondary(BuildContext context) => Theme.of(context).brightness == Brightness.dark ? AppPaletteDark.textSub : AppPalette.textMuted;
  static Color scaffoldColor(BuildContext context) => Theme.of(context).scaffoldBackgroundColor;
  // Muted surface for inputs, unselected chips, stat tiles (Breeze: #F3ECE0, Abyss: card color).
  static Color surfaceMuted(BuildContext context) => Theme.of(context).brightness == Brightness.dark ? AppPaletteDark.card : AppPalette.surfaceMuted;

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
    colorScheme: ColorScheme.light(
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
    floatingActionButtonTheme: FloatingActionButtonThemeData(
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
    colorScheme: ColorScheme.dark(
      primary: AppPaletteDark.gem,
      secondary: AppPaletteDark.gold,
      surface: AppPaletteDark.surface,
      onSurface: AppPaletteDark.text,
      onPrimary: AppTheme.colors.white,
      onSecondary: AppTheme.colors.black,
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
        foregroundColor: AppTheme.colors.white,
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
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppPaletteDark.gem,
      foregroundColor: AppTheme.colors.white,
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
    backgroundColor: Theme.of(context).colorScheme.primary,
    foregroundColor: Theme.of(context).colorScheme.onPrimary,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
  );

  /// Button label style used by the refresh: sentence case, modest tracking
  /// (the old style forced ALL CAPS with 1.2px tracking on every button).
  static TextStyle buttonLabelStyle(BuildContext context) => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.2,
    color: Theme.of(context).colorScheme.onPrimary,
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
