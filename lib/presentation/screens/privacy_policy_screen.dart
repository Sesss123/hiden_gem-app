import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/oracle_ui_system.dart';

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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Could not open email client. Please email support@hiddengems.lk"),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: OracleUI.auraBackground(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              floating: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: OracleUI.neonText(
                "PRIVACY POLICY & LEGAL",
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
                    _buildHeader(),
                    const SizedBox(height: 24),
                    _buildContactButton(primaryColor),
                    const SizedBox(height: 32),
                    _buildSectionCard(
                      index: 0,
                      title: "1. DATA WE COLLECT",
                      icon: Icons.data_usage_rounded,
                      content: "Hidden Gems Sri Lanka collects personal information voluntarily provided when using our services:\n\n"
                          "• Account Information: Display name, email address, phone number, and profile picture (via Firebase Auth / Google Sign-In).\n"
                          "• Precise & Live Location: We request location data to enable location-based Discovery, Local Gems, and live tracking features. When using Family Sharing, your real-time coordinates are processed to update authorized recipients.\n"
                          "• Family Sharing Recipient Data: Recipient names, contact identifiers, and temporary share tokens generated during coordination sessions.\n"
                          "• Guide Profile & Verification Data: Licensing status, identification credentials, languages spoken, and bio details submitted during guide enrollment.\n"
                          "• In-App Messages & Bookings: Communications between tourists and guides, itinerary data, and session logs.\n"
                          "• Device & Analytics Data: Crash diagnostics, performance metrics, and device metadata via Firebase Analytics and Crashlytics.\n"
                          "• Payment Data: If applicable, financial transactions are processed exclusively by PCI-DSS compliant third-party payment gateways. Hidden Gems Sri Lanka never stores raw credit card numbers or banking data on our servers.",
                    ),
                    const SizedBox(height: 16),
                    _buildSectionCard(
                      index: 1,
                      title: "2. FAMILY SHARING FEATURE SPECIFICALLY",
                      icon: Icons.family_restroom_rounded,
                      content: "Our 'Family Sharing' and coordination hub allows explorers to share live status, guide identity, meeting points, and emergency alerts with trusted personal contacts:\n\n"
                          "• Opt-In & Revocable: Sharing is strictly opt-in and controlled entirely by the user. You may revoke access or delete active sharing links at any time in the app.\n"
                          "• Time-Limited: Shared mission links automatically expire after your selected duration (e.g., 4, 12, or 24 hours). Once expired, location transmission ceases immediately.\n"
                          "• Zero Content Monitoring: Hidden Gems Sri Lanka is not a party to and does not monitor or inspect the personal communications or shared status between you and your chosen recipients beyond what is technically necessary to operate the feature and deliver encrypted telemetry.",
                    ),
                    const SizedBox(height: 16),
                    _buildSectionCard(
                      index: 2,
                      title: "3. LEGAL BASIS & SRI LANKA COMPLIANCE",
                      icon: Icons.gavel_rounded,
                      content: "Our data practices strictly adhere to Sri Lankan regulatory frameworks and international best practices:\n\n"
                          "• Governing Data Law: This policy is governed by the Personal Data Protection Act, No. 9 of 2022 (Sri Lanka). Hidden Gems Sri Lanka (Pvt) Ltd / TripMe.ai acts as the Data Controller and commits to the core statutory principles of data minimization, purpose limitation, lawful processing, and mandatory breach notification.\n"
                          "• Tourism Act & SLTDA Regulations: In compliance with the Tourism Act, No. 38 of 2005 and Sri Lanka Tourism Development Authority (SLTDA) guidelines, guide verification credentials displayed in app profiles are self-reported or verified against SLTDA registries where available. The company provides this information for transparency but does not guarantee licensing status beyond what is displayed.\n"
                          "• Cross-Border Data Transfers: For international tourists visiting Sri Lanka, using this application involves transferring data across borders to global cloud infrastructure (including Google Firebase and AWS servers). By utilizing the app, you explicitly consent to these international data transfers for the performance of the service.",
                    ),
                    const SizedBox(height: 16),
                    _buildSectionCard(
                      index: 3,
                      title: "4. LIABILITY LIMITATION & DISCLAIMERS",
                      icon: Icons.warning_amber_rounded,
                      content: "To the maximum extent permitted by applicable law, your use of the app is subject to the following limitations:\n\n"
                          "• Connective Platform Role: Hidden Gems Sri Lanka operates as an informational and connective platform connecting tourists with independent local guides and services. We are not liable for the conduct, safety, licensing validity, or actions of any guide, driver, or third-party service connected through the app.\n"
                          "• Emergency & Location Feature Limitations: Location-sharing, 'Family Sharing', and emergency alert signals are provided on a best-effort technical basis. THEY ARE NOT A SUBSTITUTE FOR OFFICIAL EMERGENCY SERVICES. In an emergency, always contact Sri Lanka Police (119), Tourist Police (+94 11 242 1052), or Suwaseriya Ambulance (1990). The company assumes no liability for network delays, GPS inaccuracies, or notification delivery failures.\n"
                          "• Independent Verification: Users remain solely responsible for verifying guide credentials, vehicle safety, and personal security independently prior to travel.\n"
                          "• Statutory Liability Cap: Under Sri Lankan law, any liability of Hidden Gems Sri Lanka (Pvt) Ltd arising out of or related to your use of the platform is strictly limited to the total fees paid by you to the company for the specific service in dispute.",
                    ),
                    const SizedBox(height: 16),
                    _buildSectionCard(
                      index: 4,
                      title: "5. USER RIGHTS & DATA CONTROL",
                      icon: Icons.admin_panel_settings_rounded,
                      content: "Under the Personal Data Protection Act No. 9 of 2022, you hold fundamental rights regarding your personal data:\n\n"
                          "• Right of Access & Correction: You may review, download, or edit your account information and profile data directly within the app's Profile Screen.\n"
                          "• Withdrawal of Consent: You may withdraw consent for location tracking or data processing at any time by disabling location permissions in device settings or revoking active Family Sharing links.\n"
                          "• Right to Deletion (Right to be Forgotten): You can request permanent account deletion directly via Profile > Privacy > Account Deletion, or by emailing our data protection officer at support@hiddengems.lk.",
                    ),
                    const SizedBox(height: 16),
                    _buildSectionCard(
                      index: 5,
                      title: "6. DATA RETENTION & PURGATION",
                      icon: Icons.auto_delete_rounded,
                      content: "We retain personal data only for as long as necessary to fulfill the purposes outlined in this policy:\n\n"
                          "• Family Sharing & Location Data: Temporary share links and associated live location history are automatically purged from active databases upon link expiration or manual revocation.\n"
                          "• Account Data: Upon submitting an account deletion request, your profile, saved wishlists, and personal identifiers are permanently scrubbed from our production servers within 30 days, retaining only anonymized statistical data required for regulatory audit trails.",
                    ),
                    const SizedBox(height: 16),
                    _buildSectionCard(
                      index: 6,
                      title: "7. CHILDREN'S PRIVACY PROTECTION",
                      icon: Icons.child_care_rounded,
                      content: "Hidden Gems Sri Lanka is designed for adult travelers and independent tourism professionals. The application is not directed at children under the age of 18. We do not knowingly solicit, collect, or process personal data from minors. If we discover that an underage user has provided personal data without verified parental consent, we will immediately purge such data from our infrastructure.",
                    ),
                    const SizedBox(height: 16),
                    _buildSectionCard(
                      index: 7,
                      title: "8. CHANGES TO THIS POLICY",
                      icon: Icons.update_rounded,
                      content: "We may update this Privacy Policy periodically to reflect technological advancements, new app features, or evolving Sri Lankan legal requirements. When material changes occur, we will notify users via prominent in-app banners and update the persistent 'Last Updated' timestamp at the top of this document. Continued use of the platform constitutes acceptance of the revised terms.",
                    ),
                    const SizedBox(height: 16),
                    _buildSectionCard(
                      index: 8,
                      title: "9. CLOSING LEGAL DISCLAIMER",
                      icon: Icons.policy_rounded,
                      content: "This policy is provided for general informational purposes and does not constitute formal legal advice. Hidden Gems Sri Lanka (Pvt) Ltd / TripMe.ai recommends that users and tourism stakeholders seek independent legal counsel in Sri Lanka to confirm full compliance with the Personal Data Protection Act No. 9 of 2022, the Tourism Act No. 38 of 2005, and any other applicable statutory regulations.",
                    ),
                    const SizedBox(height: 48),
                    _buildFooter(),
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

  Widget _buildHeader() {
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
                      "DATA PROTECTION PROTOCOL",
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
                        "LAST UPDATED: JULY 5, 2026",
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
            "We value your privacy and data sovereignty. This document outlines how Hidden Gems Sri Lanka (Pvt) Ltd collects, protects, and governs your personal information under Sri Lankan law.",
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

  Widget _buildContactButton(Color primaryColor) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _contactSupport,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 4,
          shadowColor: primaryColor.withValues(alpha: 0.4),
        ),
        icon: const Icon(Icons.mail_outline_rounded, size: 22),
        label: Text(
          "CONTACT US ABOUT YOUR DATA",
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

  Widget _buildFooter() {
    return Center(
      child: Column(
        children: [
          Text(
            "HIDDEN GEMS SRI LANKA (PVT) LTD",
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppTheme.textSecondary(context),
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Registered Office: Colombo, Sri Lanka • support@hiddengems.lk",
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
