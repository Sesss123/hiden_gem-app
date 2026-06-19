import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppPalette {
  // --- Modern & Eco (The "Zen" Light Palette) ---
  static const Color zenGreen = Color(0xFF2E7D32);
  static const Color zenBlue = Color(0xFF1976D2);
  static const Color zenSurface = Color(0xFFFCFDFF);
  static const Color zenCard = Color(0xFFFFFFFF);
  static const Color zenTextPrimary = Color(0xFF0F172A);
  static const Color zenTextSecondary = Color(0xFF64748B);
  static const Color zenBorder = Color(0xFFE2E8F0);

  // --- Deep Night (The "Figma" Dark Palette) ---
  static const Color nightScaffold = Color(0xFF0A0D11); // Deep Charcoal
  static const Color nightSurface = Color(0xFF141A21);  // Slightly lighter
  static const Color nightCard = Color(0xFF141A21);     
  static const Color nightAccentGold = Color(0xFFC19A6B); // Gold
  static const Color nightAccentGreen = Color(0xFF10B981); // Emerald
  static const Color nightAccentBlue = Color(0xFF3B82F6);  // Bright Blue
  static const Color nightTextPrimary = Color(0xFFFFFFFF); 
  static const Color nightTextSecondary = Color(0x99FFFFFF); // 60% White
  static const Color nightBorder = Color(0x1AFFFFFF);    // 10% White

  // --- Legacy & Brand Anchors ---
  static const Color ceylonBlue = Color(0xFF003B5C);
  static const Color sigiriyaOchre = Color(0xFFC19A6B);
  static const Color modernBlue = Color(0xFF1976D2);
  static const Color modernGreen = Color(0xFF2E7D32);

  // --- Semantic (Dynamic/Contextual) ---
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);

  // --- AR Mode Vibe ---
  static const Color arHeritage = Color(0xFFFFB300); // Gold/Amber
  static const Color arExplore = Color(0xFF29B6F6);  // Sky Blue
  static const Color arStory = Color(0xFF66BB6A);    // Soft Green
}

class AppTheme {
  // --- Standard Static Constants (For Backward Compatibility) ---
  // --- Standard Accessors (Theme Aware) ---
  static Color glassBorder(BuildContext context) => Theme.of(context).brightness == Brightness.dark 
      ? Colors.white.withValues(alpha: 0.1) 
      : const Color(0xFF0F172A).withValues(alpha: 0.1);

  static Color modernBlue(BuildContext context) => Theme.of(context).colorScheme.secondary;
  static Color ceylonBlue(BuildContext context) => Theme.of(context).scaffoldBackgroundColor;
  static Color sigiriyaOchre(BuildContext context) => Theme.of(context).colorScheme.secondary;
  static Color accentOchre(BuildContext context) => Theme.of(context).colorScheme.secondary;
  
  // Legacy Static Fallbacks (Deprecated - prefer dynamic methods above)
  static const Color legacyModernGreen = AppPalette.nightAccentGreen;
  static const Color legacySigiriyaOchre = AppPalette.nightAccentGold;
  
  // Missing Aliases found in audit
  static Color deepSlate(BuildContext context) => Theme.of(context).scaffoldBackgroundColor;
  static Color softSlate(BuildContext context) => Theme.of(context).colorScheme.surface;
  static Color darkSurface(BuildContext context) => Theme.of(context).colorScheme.surface;
  
  // Theme-Aware Dynamic Accessors
  static Color cardColor(BuildContext context) => Theme.of(context).cardColor;
  static Color borderColor(BuildContext context) => Theme.of(context).dividerColor.withValues(alpha: 0.1);
  static Color textPrimary(BuildContext context) => Theme.of(context).colorScheme.onSurface;
  static Color textSecondary(BuildContext context) => Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);
  static Color scaffoldColor(BuildContext context) => Theme.of(context).scaffoldBackgroundColor;

  // Semantic Aliases (Previously static const, now dynamic)
  static Color darkCard(BuildContext context) => Theme.of(context).cardColor;
  static Color darkBorder(BuildContext context) => Theme.of(context).dividerColor.withValues(alpha: 0.1);
  static Color darkText(BuildContext context) => Theme.of(context).colorScheme.onSurface;
  static Color primaryBlue(BuildContext context) => Theme.of(context).colorScheme.secondary;
  static Color pureWhite(BuildContext context) => Theme.of(context).colorScheme.surface;
  static Color silkPearl(BuildContext context) => Theme.of(context).colorScheme.surface;

  static Color primaryBorder(BuildContext context) => Theme.of(context).brightness == Brightness.dark 
      ? Colors.white.withValues(alpha: 0.15) 
      : const Color(0xFF0F172A).withValues(alpha: 0.12);

  static Color modernGreen(BuildContext context) => Theme.of(context).colorScheme.primary;

  static Color secondaryBorder(BuildContext context) => Theme.of(context).brightness == Brightness.dark 
      ? Colors.white.withValues(alpha: 0.08) 
      : const Color(0xFF0F172A).withValues(alpha: 0.14);
  static Color translucentOverlay(BuildContext context) => Theme.of(context).brightness == Brightness.dark 
      ? Colors.black.withValues(alpha: 0.3) 
      : Colors.white.withValues(alpha: 0.5);
  static Color glassBackground(BuildContext context) => Theme.of(context).brightness == Brightness.dark 
      ? Colors.white.withValues(alpha: 0.05) 
      : Colors.black.withValues(alpha: 0.02);
  
  // Semantic Hardcoded (Static ok for these fixed status colors)
  static const Color successGreen = AppPalette.success;
  static const Color warningAmber = AppPalette.warning;
  static const Color errorRed = AppPalette.error;

  // --- Luxury Shadows ---
  static List<BoxShadow> get premiumShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.10),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  // --- Premium Gradients ---
  static LinearGradient modernGradient(BuildContext context) => LinearGradient(
    colors: [Theme.of(context).colorScheme.secondary, Theme.of(context).colorScheme.primary],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient oceanGradient = LinearGradient(
    colors: [AppPalette.ceylonBlue, Color(0xFF002844)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  /// The ONE background all screens should use — adapts to Breeze/Abyss
  static LinearGradient appBackground(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return LinearGradient(
      colors: isDark 
          ? [const Color(0xFF0A0D11), const Color(0xFF080A0E)]
          : [const Color(0xFFF8FAFC), const Color(0xFFF1F5F9)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  // --- Glassmorphism Optimized ---
  /// Creates a premium glassmorphic effect that adapts to theme brightness.
  static BoxDecoration glassDecoration(BuildContext context, {
    double opacity = 0.05, 
    double blur = 30,
    BorderRadius? radius,
    Color? color,
    BoxShape shape = BoxShape.rectangle,
    bool? isDarkOverride,
  }) {
    final isDark = isDarkOverride ?? (Theme.of(context).brightness == Brightness.dark);
    final bgColor = isDark 
        ? (color ?? AppPalette.nightCard)
        : (color ?? Colors.white);
        
    return BoxDecoration(
      color: bgColor.withValues(alpha: opacity),
      borderRadius: shape == BoxShape.circle ? null : (radius ?? BorderRadius.circular(20)),
      shape: shape,
      border: Border.all(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: isDark ? 0.15 : 0.3),
        width: 0.5, // Thinner, more premium border line
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
          blurRadius: blur,
          spreadRadius: -5,
          offset: const Offset(0, 8),
        )
      ],
    );
  }

  /// Specialized pill badge decoration for AR tiers
  static BoxDecoration arBadgeDecoration({required Color tierColor, double opacity = 0.15}) {
    return BoxDecoration(
      color: Colors.black.withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(30),
      border: Border.all(color: tierColor.withValues(alpha: 0.5), width: 1.5),
    );
  }

  /// Premium gold-to-amber gradient for AR buttons
  static const LinearGradient arButtonGradient = LinearGradient(
    colors: [Color(0xFFFFB300), Color(0xFFFF8F00)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  /// Dark blur overlay used for premium locked AR previews
  static BoxDecoration get arLockOverlay => BoxDecoration(
    color: Colors.black.withValues(alpha: 0.7),
    borderRadius: BorderRadius.circular(20),
  );

  // --- Dynamic Time-Aware Overlay ---
  static Color getDynamicOverlay() {
    final hour = DateTime.now().hour;
    return (hour >= 18 || hour < 6) ? Colors.black.withValues(alpha: 0.2) : Colors.transparent;
  }

  // --- Advanced Text Styles ---
  static TextStyle oracleBrandHeading(BuildContext context) => GoogleFonts.outfit(
    fontSize: 28,
    fontWeight: FontWeight.w900,
    color: Theme.of(context).colorScheme.secondary,
    letterSpacing: 1.5,
  );

  static TextStyle get budgetEmphasis => GoogleFonts.outfit(
    fontSize: 24,
    fontWeight: FontWeight.w900,
    color: AppPalette.sigiriyaOchre,
    letterSpacing: 1,
  );

  /// Consistent label style (section headers, tags)
  static TextStyle labelStyle(BuildContext context) => GoogleFonts.outfit(
    fontSize: 12,
    fontWeight: FontWeight.bold,
    letterSpacing: 1.5,
    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
  );

  /// Consistent body text style
  static TextStyle bodyStyle(BuildContext context) => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.9),
  );

  /// Ochre-accented left-border for cards — now theme-aware
  static BoxDecoration ochreCardDecoration(
    BuildContext context, {
    double borderRadius = 16,
    double opacity = 0.06,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: (isDark ? Colors.white : Colors.black).withValues(alpha: opacity),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border(
        left: BorderSide(color: AppPalette.sigiriyaOchre, width: 3),
        top: BorderSide(color: primaryBorder(context)),
        right: BorderSide(color: primaryBorder(context)),
        bottom: BorderSide(color: primaryBorder(context)),
      ),
    );
  }

  // --- ThemeData: Zen Light ---
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: AppPalette.zenGreen,
    scaffoldBackgroundColor: AppPalette.zenSurface,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppPalette.zenGreen,
      primary: AppPalette.zenGreen,
      secondary: AppPalette.zenBlue,
      surface: AppPalette.zenCard,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: AppPalette.zenTextPrimary,
      error: AppPalette.error,
    ),
    textTheme: GoogleFonts.outfitTextTheme().copyWith(
      displayLarge: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: AppPalette.zenTextPrimary),
      displayMedium: GoogleFonts.outfit(fontSize: 26, fontWeight: FontWeight.w700, color: AppPalette.zenTextPrimary),
      headlineMedium: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w600, color: AppPalette.zenTextPrimary),
      titleLarge: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600, color: AppPalette.zenTextPrimary),
      bodyLarge: GoogleFonts.inter(fontSize: 16, color: AppPalette.zenTextPrimary),
      bodyMedium: GoogleFonts.inter(fontSize: 14, color: AppPalette.zenTextSecondary),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: AppPalette.zenGreen),
      iconTheme: const IconThemeData(color: AppPalette.zenGreen),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppPalette.zenGreen,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    ),
    cardTheme: CardThemeData(
      color: AppPalette.zenCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: AppPalette.zenBorder, width: 1),
      ),
      shadowColor: Colors.black.withValues(alpha: 0.05),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppPalette.zenGreen,
      foregroundColor: Colors.white,
    ),
    chipTheme: ChipThemeData(
      selectedColor: AppPalette.zenGreen.withValues(alpha: 0.15),
      labelStyle: GoogleFonts.inter(fontSize: 12),
    ),
  );

  // --- ThemeData: Sigiriya Night (Premium Dark) ---
  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: AppPalette.nightAccentGreen,
    scaffoldBackgroundColor: AppPalette.nightScaffold,
    colorScheme: ColorScheme.dark(
      primary: AppPalette.nightAccentGreen,
      secondary: AppPalette.nightAccentBlue,
      surface: AppPalette.nightCard,
      onPrimary: AppPalette.nightScaffold,
      onSecondary: AppPalette.nightScaffold,
      onSurface: Colors.white,
      error: AppPalette.error,
    ),
    textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme).copyWith(
      displayLarge: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
      displayMedium: GoogleFonts.outfit(fontSize: 26, fontWeight: FontWeight.w700, color: Colors.white),
      headlineMedium: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
      titleLarge: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
      bodyLarge: GoogleFonts.inter(fontSize: 16, color: Colors.white),
      bodyMedium: GoogleFonts.inter(fontSize: 14, color: Colors.white70),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
      iconTheme: IconThemeData(color: Colors.white),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppPalette.nightAccentGreen,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    ),
    cardTheme: CardThemeData(
      color: AppPalette.nightCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: AppPalette.nightBorder, width: 1),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppPalette.nightAccentGreen,
      foregroundColor: AppPalette.nightScaffold,
    ),
    chipTheme: ChipThemeData(
      selectedColor: AppPalette.nightAccentGreen.withValues(alpha: 0.2),
      labelStyle: GoogleFonts.inter(fontSize: 12, color: Colors.white),
    ),
  );

  static ButtonStyle primaryButtonStyle(BuildContext context) {
    return ElevatedButton.styleFrom(
      backgroundColor: AppPalette.ceylonBlue,
      foregroundColor: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      textStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold),
    );
  }

  static InputDecoration glassInputDecoration(BuildContext context, String hint, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38),
      prefixIcon: Icon(icon, color: isDark ? Colors.white38 : Colors.black38, size: 20),
      filled: true,
      fillColor: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: secondaryBorder(context)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: sigiriyaOchre(context), width: 1.5),
      ),
    );
  }

  // --- Theme Engines ---
  
  static ThemeData get breezeTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppPalette.zenGreen,
      scaffoldBackgroundColor: AppPalette.zenSurface,
      colorScheme: const ColorScheme.light(
        primary: AppPalette.zenGreen,
        secondary: AppPalette.sigiriyaOchre,
        surface: AppPalette.zenCard,
        onSurface: AppPalette.zenTextPrimary,
        onPrimary: Colors.white,
      ),
      textTheme: GoogleFonts.outfitTextTheme().apply(
        bodyColor: AppPalette.zenTextPrimary,
        displayColor: AppPalette.zenTextPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: AppPalette.zenTextPrimary),
        titleTextStyle: TextStyle(color: AppPalette.zenTextPrimary, fontWeight: FontWeight.bold, fontSize: 18),
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: AppPalette.zenCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      dividerColor: const Color(0xFFE2E8F0),
    );
  }

  static ThemeData get abyssTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: AppPalette.nightAccentGreen,
      scaffoldBackgroundColor: AppPalette.nightScaffold,
      colorScheme: const ColorScheme.dark(
        primary: AppPalette.nightAccentGreen,
        secondary: AppPalette.nightAccentGold,
        surface: AppPalette.nightSurface,
        onSurface: Colors.white,
        onPrimary: AppPalette.nightScaffold,
      ),
      textTheme: GoogleFonts.outfitTextTheme().apply(
        bodyColor: AppPalette.nightTextPrimary,
        displayColor: AppPalette.nightTextPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: AppPalette.nightTextPrimary),
        titleTextStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: AppPalette.nightCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0x1AFFFFFF), width: 1),
        ),
      ),
      dividerColor: const Color(0x1AFFFFFF),
    );
  }
}

