import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_theme.dart';
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "TERMS & PRIVACY",
                    style: GoogleFonts.outfit(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textPrimary(context),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "GOVERNANCE PROTOCOLS v2.0",
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textSecondary(context),
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 800.ms).slideY(begin: -0.1),
            
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _sectionCard("I. DATA ARCHIVAL & SOVEREIGNTY", "The Oracle respects your digital footprint. We securely archive your profile frequencies and saved journeys within a secure local vault. Your neural data remains under your absolute control."),
                      const SizedBox(height: 12),
                      _sectionCard("II. AI ORACLE PREDICTIVE PROTOCOLS", "The AI Oracle is a predictive engine. While we strive for absolute precision in our transmissions, its revelations may diverge from real-time physical realities. You must verify critical information independently.\n\nBy engaging the Oracle, you agree:\n• To use results for enlightenment, not malice.\n• To never attempt a recursive prompt exploitation.\n• To accept all insights as hypothetical transmissions."),
                      const SizedBox(height: 12),
                      _sectionCard("III. EXPLORER CONDUCT MATRIX", "You agree to traverse the application with respect, ensuring the stability of the collective infrastructure and the sanctity of other explorers' journeys."),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ).animate().fadeIn(duration: 800.ms, delay: 200.ms).slideY(begin: 0.05),
            ),
            
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppTheme.secondaryBorder(context))),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Column(
                children: [
                  _buildCheckbox(
                    value: _agreedToTerms,
                    label: "I accept the Privacy Protocol & Terms of Service",
                    onChanged: (val) => setState(() => _agreedToTerms = val ?? false),
                  ),
                  const SizedBox(height: 12),
                  _buildCheckbox(
                    value: _agreedToAiPolicy,
                    label: "I acknowledge the Oracle Protocols and limitations",
                    onChanged: (val) => setState(() => _agreedToAiPolicy = val ?? false),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: (_agreedToTerms && _agreedToAiPolicy) ? _completeOnboarding : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        disabledBackgroundColor: Colors.black12,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: Text(
                        "INITIATE LINK",
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 600.ms, duration: 800.ms),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard(String title, String body) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.secondaryBorder(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppTheme.modernGreen(context),
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppTheme.textSecondary(context),
              height: 1.6,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
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
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: value ? primaryColor : AppTheme.textSecondary(context).withValues(alpha: 0.3),
                width: 1.5,
              ),
              color: value ? primaryColor.withValues(alpha: 0.1) : Colors.transparent,
            ),
            child: value ? Icon(Icons.check_rounded, color: primaryColor, size: 16) : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2.0),
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: value ? AppTheme.textPrimary(context) : AppTheme.textSecondary(context),
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
