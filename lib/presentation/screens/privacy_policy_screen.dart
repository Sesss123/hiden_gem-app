import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/oracle_ui_system.dart';
import '../../l10n/app_localizations.dart';

class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  // Track expansion state for each section
  final Map<int, bool> _expandedSections = {
    0: true, // Expand first section by default
    1: false,
    2: false,
    3: false,
    4: false,
    5: false,
    6: false,
    7: false,
    8: false,
  };

  void _toggleSection(int index) {
    HapticFeedback.selectionClick();
    setState(() {
      _expandedSections[index] = !(_expandedSections[index] ?? false);
    });
  }

  Future<void> _contactSupport() async {
    HapticFeedback.mediumImpact();
    final uri = Uri(
      scheme: 'mailto',
      path: 'support@hiddengems.lk',
      query: 'subject=Privacy%20and%20Data%20Protection%20Request',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(AppLocalizations.of(context)!.couldNotOpenEmail),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppTheme.colors.transparent,
      body: OracleUI.auraBackground(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              floating: true,
              backgroundColor: AppTheme.colors.transparent,
              elevation: 0,
              title: OracleUI.neonText(
                l10n.privacyPolicyTitle,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                  color: AppTheme.textPrimary(context),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(l10n),
                    const SizedBox(height: 24),
                    _buildContactButton(primaryColor, l10n),
                    const SizedBox(height: 32),
                    _buildSectionCard(
                      index: 0,
                      title: l10n.privacySection1Title,
                      icon: Icons.data_usage_rounded,
                      content: l10n.privacySection1Body,
                    ),
                    const SizedBox(height: 16),
                    _buildSectionCard(
                      index: 1,
                      title: l10n.privacySection2Title,
                      icon: Icons.family_restroom_rounded,
                      content: l10n.privacySection2Body,
                    ),
                    const SizedBox(height: 16),
                    _buildSectionCard(
                      index: 2,
                      title: l10n.privacySection3Title,
                      icon: Icons.gavel_rounded,
                      content: l10n.privacySection3Body,
                    ),
                    const SizedBox(height: 16),
                    _buildSectionCard(
                      index: 3,
                      title: l10n.privacySection4Title,
                      icon: Icons.warning_amber_rounded,
                      content: l10n.privacySection4Body,
                    ),
                    const SizedBox(height: 16),
                    _buildSectionCard(
                      index: 4,
                      title: l10n.privacySection5Title,
                      icon: Icons.admin_panel_settings_rounded,
                      content: l10n.privacySection5Body,
                    ),
                    const SizedBox(height: 16),
                    _buildSectionCard(
                      index: 5,
                      title: l10n.privacySection6Title,
                      icon: Icons.auto_delete_rounded,
                      content: l10n.privacySection6Body,
                    ),
                    const SizedBox(height: 16),
                    _buildSectionCard(
                      index: 6,
                      title: l10n.privacySection7Title,
                      icon: Icons.child_care_rounded,
                      content: l10n.privacySection7Body,
                    ),
                    const SizedBox(height: 16),
                    _buildSectionCard(
                      index: 7,
                      title: l10n.privacySection8Title,
                      icon: Icons.update_rounded,
                      content: l10n.privacySection8Body,
                    ),
                    const SizedBox(height: 16),
                    _buildSectionCard(
                      index: 8,
                      title: l10n.privacySection9Title,
                      icon: Icons.policy_rounded,
                      content: l10n.privacySection9Body,
                    ),
                    const SizedBox(height: 48),
                    _buildFooter(l10n),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return OracleUI.premiumGlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.modernGreen(context).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.shield_rounded, color: AppTheme.modernGreen(context), size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.dataProtectionProtocol,
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.textPrimary(context),
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.modernGreen(context).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.modernGreen(context).withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        l10n.lastUpdatedDate,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.modernGreen(context),
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            l10n.privacyIntro,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppTheme.textSecondary(context),
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.05);
  }

  Widget _buildContactButton(Color primaryColor, AppLocalizations l10n) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _contactSupport,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: AppTheme.colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 4,
          shadowColor: primaryColor.withValues(alpha: 0.4),
        ),
        icon: const Icon(Icons.mail_outline_rounded, size: 22),
        label: Text(
          l10n.contactUsAboutData,
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
      ),
    ).animate().fadeIn(duration: 600.ms, delay: 100.ms);
  }

  Widget _buildSectionCard({
    required int index,
    required String title,
    required IconData icon,
    required String content,
  }) {
    final isExpanded = _expandedSections[index] ?? false;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return OracleUI.glassContainer(
      padding: const EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => _toggleSection(index),
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                Icon(icon, color: primaryColor, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary(context),
                      letterSpacing: 1,
                    ),
                  ),
                ),
                AnimatedRotation(
                  turns: isExpanded ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppTheme.textSecondary(context),
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity, height: 0),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Divider(color: AppTheme.secondaryBorder(context), height: 1),
                  const SizedBox(height: 16),
                  Text(
                    content,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppTheme.textSecondary(context),
                      height: 1.6,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
            sizeCurve: Curves.easeInOutCubic,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms, delay: (150 + index * 50).ms).slideY(begin: 0.05);
  }

  Widget _buildFooter(AppLocalizations l10n) {
    return Center(
      child: Column(
        children: [
          Text(
            l10n.privacyFooterCompany,
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppTheme.textSecondary(context),
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.privacyFooterAddress,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppTheme.textSecondary(context).withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}
