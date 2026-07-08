import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/oracle_ui_system.dart';
import '../../core/theme/app_theme.dart';
import '../../data/datasources/user_preference_service.dart';
import '../../l10n/app_localizations.dart';
import 'login_screen.dart';
import 'language_selection_screen.dart';
import 'terms_screen.dart';
import '../widgets/custom_buttons.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      final page = _pageController.page?.round() ?? 0;
      if (page != _currentPage) {
        setState(() {
          _currentPage = page;
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _next() {
    HapticFeedback.lightImpact();
    if (_currentPage < 4) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _finish();
    }
  }

  void _finish() async {
    await UserPreferenceService.updateOnboardingCompletion(true);
    final profile = UserPreferenceService.getProfile();
    Widget targetScreen;
    if (profile.languageCode == null) {
      targetScreen = const LanguageSelectionScreen();
    } else if (!profile.hasAgreedToTerms) {
      targetScreen = const TermsScreen();
    } else {
      targetScreen = const LoginScreen();
    }

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => targetScreen),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: OracleUI.auraBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Skip button
              Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: _finish,
                  child: Text(
                    l10n?.skipForNow ?? "Skip for now",
                    style: GoogleFonts.inter(
                      color: AppTheme.textSecondary(context),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    )
                  ),
                ),
              ),
              // Pages
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  children: [
                    _buildSlide1(),
                    _buildSlide2(),
                    _buildSlide3(),
                    _buildSlide4(),
                    _buildSlide5(),
                  ],
                ),
              ),
              // Dots + Button
              _buildBottomControls(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // ── Slide 1: Discover Hidden Gems ─────────────────────────
  Widget _buildSlide1() {
    final gems = [
      (Icons.park_outlined, "Nature Trails"),
      (Icons.temple_buddhist_outlined, "Ancient Temples"),
      (Icons.waves_outlined, "Pristine Beaches"),
      (Icons.landscape_outlined, "Hill Country"),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: gems.asMap().entries.map((e) => _gemBubble(e.value.$1, e.value.$2, e.key)).toList(),
          ),
          const SizedBox(height: 60),
          Text(
            "Discover hidden gems",
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 30, fontWeight: FontWeight.w800, color: AppTheme.textPrimary(context), height: 1.1, letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "Explore over 500 off-the-beaten-path locations curated by locals — places you won't find in any guidebook.",
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 15, color: AppTheme.textSecondary(context), height: 1.6),
          ),
        ],
      ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1, end: 0),
    );
  }

  Widget _gemBubble(IconData icon, String label, int index) {
    return OracleUI.glassContainer(
      width: 120,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      borderRadius: BorderRadius.circular(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary, size: 26),
          const SizedBox(height: 12),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary(context), fontWeight: FontWeight.w600)
          ),
        ],
      ),
    ).animate().fadeIn(delay: (200 * index).ms).scale(begin: const Offset(0.8, 0.8));
  }

  // ── Slide 2: AI Travel Planner ────────────────────────────
  Widget _buildSlide2() {
    return const _OnboardingSlide(
      icon: Icons.auto_awesome_rounded,
      title: "Plan Smarter with AI",
      description: "Tell the Oracle where you want to go.\nGet a full personalized itinerary for Sri Lanka in seconds.",
    );
  }

  // ── Slide 3: Immersive AR Viewer ──────────────────────────
  Widget _buildSlide3() {
    return const _OnboardingSlide(
      icon: Icons.view_in_ar_rounded,
      title: "Step Into History",
      description: "Unlock detailed 3D historical reconstructions of monuments. Watch past eras come alive in real-time.",
    );
  }

  // ── Slide 4: Guide Marketplace ────────────────────────────
  Widget _buildSlide4() {
    return const _OnboardingSlide(
      icon: Icons.person_pin_circle_rounded,
      title: "Verified Local Guides",
      description: "Connect with certified regional tour guides. Request custom bookings and secure narrative tours directly.",
    );
  }

  // ── Slide 5: Zenith Safety Shield ─────────────────────────
  Widget _buildSlide5() {
    return const _OnboardingSlide(
      icon: Icons.security_rounded,
      title: "Zenith Safety Shield",
      description: "Explore with peace of mind. Live local safety alerts, offline map backups, and one-tap emergency SOS broadcasts.",
    );
  }

  // ── Bottom Controls ───────────────────────────────────────
  Widget _buildBottomControls() {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        // Page dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (i) => _dot(i)),
        ),
        const SizedBox(height: 32),
        // CTA button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: PrimaryButton(
            label: _currentPage == 4 ? "Begin journey" : (l10n?.continueButton ?? "Continue"),
            onPressed: _next,
          ),
        ),
      ],
    );
  }

  Widget _dot(int index) {
    final active = _currentPage == index;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: active ? 28 : 8,
      height: 6,
      decoration: BoxDecoration(
        color: active ? Theme.of(context).colorScheme.primary : AppTheme.surfaceMuted(context),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class _OnboardingSlide extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _OnboardingSlide({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          OracleUI.glassContainer(
            padding: const EdgeInsets.all(32),
            borderRadius: BorderRadius.circular(50),
            borderColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
            child: Icon(icon, size: 64, color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(height: 60),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 30, fontWeight: FontWeight.w800, color: AppTheme.textPrimary(context), height: 1.1, letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            description,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 15, color: AppTheme.textSecondary(context), height: 1.6),
          ),
        ],
      ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1, end: 0),
    );
  }
}
