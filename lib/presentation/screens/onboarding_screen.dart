import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/oracle_ui_system.dart';
import '../../data/datasources/user_preference_service.dart';
import 'login_screen.dart';
import 'language_selection_screen.dart';
import 'terms_screen.dart';

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
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _next() {
    HapticFeedback.lightImpact();
    if (_currentPage < 2) {
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
                    "SKIP", 
                    style: GoogleFonts.inter(
                      color: Colors.white24, 
                      fontSize: 10, 
                      fontWeight: FontWeight.bold, 
                      letterSpacing: 2
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
                  ],
                ),
              ),
              // Dots + Button
              _buildBottomControls(),
              SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // ── Slide 1: AI Planning ──────────────────────────────────
  Widget _buildSlide1() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          OracleUI.glassContainer(
            padding: EdgeInsets.all(32),
            borderRadius: BorderRadius.circular(50),
            borderColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
            child: Icon(Icons.auto_awesome_rounded, size: 64, color: Theme.of(context).colorScheme.primary),
          ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 3.seconds, color: Colors.white10),
          SizedBox(height: 60),
          OracleUI.neonText(
            "Plan Smarter with AI",
            style: GoogleFonts.outfit(
              fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white, height: 1.1,
            ),
          ),
          SizedBox(height: 24),
          Text(
            "Tell the Oracle where you want to go.\nGet a full personalized itinerary for Sri Lanka in seconds.",
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 16, color: Colors.white54, height: 1.6),
          ),
        ],
      ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1, end: 0),
    );
  }

  // ── Slide 2: Hidden Gems ──────────────────────────────────
  Widget _buildSlide2() {
    final gems = [
      (Icons.park_outlined, "Nature Trails"),
      (Icons.temple_buddhist_outlined, "Ancient Temples"),
      (Icons.waves_outlined, "Pristine Beaches"),
      (Icons.landscape_outlined, "Hill Country"),
    ];
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: gems.asMap().entries.map((e) => _gemBubble(e.value.$1, e.value.$2, e.key)).toList(),
          ),
          SizedBox(height: 60),
          OracleUI.neonText(
            "Discover Hidden Gems",
            style: GoogleFonts.outfit(
              fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white, height: 1.1,
            ),
          ),
          SizedBox(height: 24),
          Text(
            "Explore over 500 off-the-beaten-path locations curated by locals — places you won't find in any guidebook.",
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 16, color: Colors.white54, height: 1.6),
          ),
        ],
      ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1, end: 0),
    );
  }

  Widget _gemBubble(IconData icon, String label, int index) {
    return OracleUI.glassContainer(
      width: 120,
      padding: EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      borderRadius: BorderRadius.circular(20),
      borderColor: Colors.white.withValues(alpha: 0.05),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.8), size: 28),
          SizedBox(height: 12),
          Text(
            label, 
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w600, letterSpacing: 0.5)
          ),
        ],
      ),
    ).animate().fadeIn(delay: (200 * index).ms).scale(begin: const Offset(0.8, 0.8));
  }

  // ── Slide 3: Your Journey ─────────────────────────────────
  Widget _buildSlide3() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          OracleUI.glassContainer(
            padding: EdgeInsets.all(32),
            borderRadius: BorderRadius.circular(60),
            borderColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
            child: Text("🇱🇰", style: TextStyle(fontSize: 64)),
          ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 3.seconds, color: Colors.white10),
          SizedBox(height: 60),
          OracleUI.neonText(
            "Your Journey,\nYour Way",
            style: GoogleFonts.outfit(
              fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white, height: 1.1,
            ),
          ),
          SizedBox(height: 24),
          Text(
            "Sinhala, English, Tamil and more.\nOffline maps, SOS, and AI concierge — everything for the perfect adventure.",
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 16, color: Colors.white54, height: 1.6),
          ),
        ],
      ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1, end: 0),
    );
  }

  // ── Bottom Controls ───────────────────────────────────────
  Widget _buildBottomControls() {
    return Column(
      children: [
        // Page dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) => _dot(i)),
        ),
        SizedBox(height: 32),
        // CTA button
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 32),
          child: SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: _next,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.black,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: OracleUI.neonText(
                _currentPage == 2 ? "BEGIN JOURNEY 🚀" : "CONTINUE",
                style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 14, color: Colors.black, letterSpacing: 1),
                glowColor: Colors.white24,
              ),
            ),
          ),
        ).animate().fadeIn(duration: 600.ms, delay: 1000.ms),
      ],
    );
  }

  Widget _dot(int index) {
    final active = _currentPage == index;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: EdgeInsets.symmetric(horizontal: 4),
      width: active ? 28 : 8,
      height: 6,
      decoration: BoxDecoration(
        color: active ? Theme.of(context).colorScheme.primary : Colors.white10,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
