import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../data/datasources/user_preference_service.dart';
import '../../data/datasources/auth_service.dart';
import '../../l10n/app_localizations.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'privacy_policy_screen.dart';

class TermsScreen extends ConsumerStatefulWidget {
  const TermsScreen({super.key});

  @override
  ConsumerState<TermsScreen> createState() => _TermsScreenState();
}

class _TermsScreenState extends ConsumerState<TermsScreen> {
  bool _agreedToTerms = false;
  bool _agreedToAiPolicy = false;

  void _completeOnboarding() async {
    if (_agreedToTerms && _agreedToAiPolicy) {
      await UserPreferenceService.updateTermsAgreement(true);
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      if ((ref.read(authStateProvider).value ?? FirebaseAuth.instance.currentUser) != null) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
      } else {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(authStateProvider);
    final primaryColor = Theme.of(context).colorScheme.primary;
    final l10n = AppLocalizations.of(context)!;

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
                    l10n.termsAndPrivacyTitle,
                    style: GoogleFonts.outfit(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary(context),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.reviewBeforeContinuing,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textSecondary(context),
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
                      _sectionCard(
                        color: AppTheme.successGreen,
                        title: l10n.dataPrivacySectionTitle,
                        body: l10n.dataPrivacySectionBody,
                      ),
                      const SizedBox(height: 12),
                      _sectionCard(
                        color: AppTheme.warningAmber,
                        title: l10n.aiPlanningSectionTitle,
                        body: l10n.aiPlanningSectionBody,
                      ),
                      const SizedBox(height: 12),
                      _sectionCard(
                        color: Theme.of(context).colorScheme.primary,
                        title: l10n.communityConductSectionTitle,
                        body: l10n.communityConductSectionBody,
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ).animate().fadeIn(duration: 800.ms, delay: 200.ms).slideY(begin: 0.05),
            ),
            
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                border: Border(top: BorderSide(color: AppTheme.secondaryBorder(context))),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
                        );
                      },
                      style: TextButton.styleFrom(padding: EdgeInsets.zero, alignment: Alignment.centerLeft),
                      child: Text(
                        l10n.readFullPrivacyPolicy,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: primaryColor,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildCheckbox(
                    value: _agreedToTerms,
                    label: l10n.acceptTermsCheckbox,
                    onChanged: (val) => setState(() => _agreedToTerms = val ?? false),
                  ),
                  const SizedBox(height: 12),
                  _buildCheckbox(
                    value: _agreedToAiPolicy,
                    label: l10n.acceptAiPolicyCheckbox,
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
                        disabledBackgroundColor: AppTheme.colors.black12,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                        elevation: 0,
                      ),
                      child: Text(
                        l10n.continueLabel,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.colors.white,
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

  Widget _sectionCard({required Color color, required String title, required String body}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceMuted(context),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
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
              color: value ? primaryColor.withValues(alpha: 0.1) : AppTheme.colors.transparent,
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
