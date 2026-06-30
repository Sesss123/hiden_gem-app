import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../core/localization/locale_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../l10n/app_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'terms_screen.dart';
import 'login_screen.dart';
import 'home_screen.dart';
import '../../data/datasources/user_preference_service.dart';

class LanguageSelectionScreen extends ConsumerWidget {
  const LanguageSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                
                // Lang Orb
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFDEBD8), Color(0xFFECC89A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(color: AppPalette.rust.withValues(alpha: 0.2)),
                  ),
                  child: const Icon(
                    Icons.translate_rounded,
                    size: 32,
                    color: AppPalette.rust,
                  ),
                ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
                
                const SizedBox(height: 24),
                
                // Title
                Text(
                  "Choose Your Path",
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textPrimary(context),
                  ),
                ).animate().fadeIn(duration: 800.ms).slideY(begin: 0.1),
                
                const SizedBox(height: 8),
                
                // Subtitle
                Text(
                  l10n.selectOracleLanguage,
                  style: GoogleFonts.inter(
                    color: AppTheme.textSecondary(context),
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(duration: 800.ms, delay: 200.ms),
                
                const SizedBox(height: 48),
                
                // Language List (Converted from Grid to List for mobile friendliness)
                Column(
                  children: [
                    _buildLanguageOption(
                      context: context,
                      ref: ref,
                      label: "ENGLISH",
                      subLabel: "Global Standard",
                      locale: const Locale('en'),
                      delay: 300.ms,
                    ),
                    const SizedBox(height: 12),
                    _buildLanguageOption(
                      context: context,
                      ref: ref,
                      label: "සිංහල",
                      subLabel: "දේශීය අත්දැකීම",
                      locale: const Locale('si'),
                      delay: 400.ms,
                    ),
                    const SizedBox(height: 12),
                    _buildLanguageOption(
                      context: context,
                      ref: ref,
                      label: "தமிழ்",
                      subLabel: "உள்ளூர் அனுபவம்",
                      locale: const Locale('ta'),
                      delay: 500.ms,
                    ),
                    const SizedBox(height: 12),
                    _buildLanguageOption(
                      context: context,
                      ref: ref,
                      label: "日本語",
                      subLabel: "日本の体験",
                      locale: const Locale('ja'),
                      delay: 600.ms,
                    ),
                    const SizedBox(height: 12),
                    _buildLanguageOption(
                      context: context,
                      ref: ref,
                      label: "Русский",
                      subLabel: "Русский опыт",
                      locale: const Locale('ru'),
                      delay: 700.ms,
                    ),
                    const SizedBox(height: 12),
                    _buildLanguageOption(
                      context: context,
                      ref: ref,
                      label: "한국어",
                      subLabel: "한국어 체험",
                      locale: const Locale('ko'),
                      delay: 800.ms,
                    ),
                  ],
                ),
                
                const SizedBox(height: 40),
                
                TextButton(
                  onPressed: () async {
                    await ref.read(localeNotifierProvider.notifier).setLocale(const Locale('en'));
                    if (context.mounted) {
                      _navigateNext(context);
                    }
                  },
                  child: Text(
                    l10n.skipForNow.toUpperCase(),
                    style: GoogleFonts.inter(
                      color: AppTheme.textSecondary(context).withValues(alpha: 0.5),
                      fontWeight: FontWeight.w800,
                      fontSize: 10,
                      letterSpacing: 2,
                    ),
                  ),
                ).animate().fadeIn(delay: 800.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateNext(BuildContext context) {
    final profile = UserPreferenceService.getProfile();
    Widget nextScreen;
    if (!profile.hasAgreedToTerms) {
      nextScreen = const TermsScreen();
    } else if (FirebaseAuth.instance.currentUser != null) {
      nextScreen = const HomeScreen();
    } else {
      nextScreen = const LoginScreen();
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => nextScreen),
    );
  }

  Widget _buildLanguageOption({
    required BuildContext context,
    required WidgetRef ref,
    required String label,
    required String subLabel,
    required Locale locale,
    required Duration delay,
  }) {
    return InkWell(
      onTap: () async {
        HapticFeedback.mediumImpact();
        await ref.read(localeNotifierProvider.notifier).setLocale(locale);
        if (context.mounted) {
          _navigateNext(context);
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.secondaryBorder(context)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: AppTheme.textPrimary(context),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subLabel,
                    style: GoogleFonts.inter(
                      color: AppTheme.textSecondary(context),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppTheme.textSecondary(context).withValues(alpha: 0.3),
              size: 16,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: delay).slideX(begin: -0.05, curve: Curves.easeOut);
  }
}

