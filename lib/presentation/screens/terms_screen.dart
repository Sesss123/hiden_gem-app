import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/oracle_ui_system.dart';
import '../../data/datasources/user_preference_service.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class TermsScreen extends StatefulWidget {
  const TermsScreen({super.key});

  @override
  State<TermsScreen> createState() => _TermsScreenState();
}

class _TermsScreenState extends State<TermsScreen> {
  bool _agreedToTerms = false;
  bool _agreedToAiPolicy = false;

  void _completeOnboarding() async {
    if (_agreedToTerms && _agreedToAiPolicy) {
      await UserPreferenceService.updateTermsAgreement(true);
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      if (FirebaseAuth.instance.currentUser != null) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
      } else {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.black,
      body: OracleUI.auraBackground(
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                child: Column(
                  children: [
                    OracleUI.neonText(
                      "TERMS & PRIVACY",
                      style: GoogleFonts.outfit(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "GOVERNANCE PROTOCOLS v2.0",
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: primaryColor.withValues(alpha: 0.5),
                        letterSpacing: 3,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 800.ms).slideY(begin: -0.1),
              
              Expanded(
                child: OracleUI.premiumGlassCard(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.all(28),
                  radius: BorderRadius.circular(40),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionTitle("I. DATA ARCHIVAL & SOVEREIGNTY"),
                        _sectionBody("The Oracle respects your digital footprint. We securely archive your profile frequencies and saved journeys within a secure local vault. Your neural data remains under your absolute control."),
                        const SizedBox(height: 32),
                        _sectionTitle("II. AI ORACLE PREDICTIVE PROTOCOLS"),
                        _sectionBody("The AI Oracle is a predictive engine. While we strive for absolute precision in our transmissions, its revelations may diverge from real-time physical realities. You must verify critical information independently.\n\nBy engaging the Oracle, you agree:\n• To use results for enlightenment, not malice.\n• To never attempt a recursive prompt exploitation.\n• To accept all insights as hypothetical transmissions."),
                        const SizedBox(height: 32),
                        _sectionTitle("III. EXPLORER CONDUCT MATRIX"),
                        _sectionBody("You agree to traverse the application with respect, ensuring the stability of the collective infrastructure and the sanctity of other explorers' journeys."),
                        const SizedBox(height: 48),
                      ],
                    ),
                  ),
                ).animate().fadeIn(duration: 800.ms, delay: 200.ms).slideY(begin: 0.05),
              ),
              
              Padding(
                padding: const EdgeInsets.all(28.0),
                child: Column(
                  children: [
                    _buildCheckbox(
                      value: _agreedToTerms,
                      label: "I accept the Privacy Protocol & Terms of Service",
                      onChanged: (val) => setState(() => _agreedToTerms = val ?? false),
                    ),
                    const SizedBox(height: 16),
                    _buildCheckbox(
                      value: _agreedToAiPolicy,
                      label: "I acknowledge the Oracle Protocols and limitations",
                      onChanged: (val) => setState(() => _agreedToAiPolicy = val ?? false),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 64,
                      child: ElevatedButton(
                        onPressed: (_agreedToTerms && _agreedToAiPolicy) ? _completeOnboarding : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          disabledBackgroundColor: Colors.white.withValues(alpha: 0.05),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          elevation: 0,
                          shadowColor: primaryColor.withValues(alpha: 0.4),
                        ),
                        child: OracleUI.neonText(
                          "INITIATE LINK",
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: (_agreedToTerms && _agreedToAiPolicy) 
                                ? Colors.black 
                                : Colors.white24,
                            letterSpacing: 2,
                          ),
                          glowColor: (_agreedToTerms && _agreedToAiPolicy) ? Colors.white38 : Colors.transparent,
                        ),
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 600.ms, duration: 800.ms),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OracleUI.neonText(
          title,
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: Theme.of(context).colorScheme.primary,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 24,
          height: 2,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }

  Widget _sectionBody(String body) {
    return Padding(
      padding: const EdgeInsets.only(top: 12.0),
      child: Text(
        body,
        style: GoogleFonts.inter(
          fontSize: 13,
          color: Colors.white.withValues(alpha: 0.5),
          height: 1.7,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildCheckbox({required bool value, required String label, required Function(bool?) onChanged}) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onChanged(!value);
      },
      behavior: HitTestBehavior.opaque,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedContainer(
            duration: 300.ms,
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: value ? primaryColor : Colors.white10,
                width: 1.5,
              ),
              color: value ? primaryColor.withValues(alpha: 0.1) : Colors.transparent,
              boxShadow: value ? [
                BoxShadow(color: primaryColor.withValues(alpha: 0.2), blurRadius: 8)
              ] : null,
            ),
            child: value ? Icon(Icons.check_rounded, color: primaryColor, size: 18) : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: value ? Colors.white : Colors.white38,
                  fontWeight: value ? FontWeight.w700 : FontWeight.w500,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
