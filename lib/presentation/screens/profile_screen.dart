import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hidden_gems_sl/core/theme/theme_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:hidden_gems_sl/l10n/app_localizations.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/oracle_ui_system.dart';
import '../../core/theme/app_theme.dart';
import '../../core/localization/locale_provider.dart';
import '../../core/providers/screenshot_provider.dart';
import '../../core/services/explorer_progress_service.dart';
import '../../data/datasources/premium_service.dart';
import '../../data/datasources/user_preference_service.dart';
import '../../data/datasources/auth_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/explorer_progress_card.dart';
import 'emergency_kit_screen.dart';
import 'premium_hub_screen.dart';
import 'heritage_passport_screen.dart';
import 'budget_concierge_screen.dart';
import 'login_screen.dart';
import '../../core/services/ethical_travel_service.dart';
import '../../core/rating/rating_service.dart';
import 'guide_enrollment_screen.dart';
import 'guide_dashboard_screen.dart';
import 'qr_scanner_screen.dart';
import 'package:hidden_gems_sl/data/models/guide_status.dart';
import 'package:hidden_gems_sl/presentation/screens/guide_reviews_screen.dart';
import 'package:hidden_gems_sl/presentation/screens/incident_center_screen.dart';
import 'package:hidden_gems_sl/presentation/screens/operator_dashboard_screen.dart';
import 'package:hidden_gems_sl/presentation/screens/subscription_screen.dart';
import 'package:hidden_gems_sl/presentation/screens/family_share_screen.dart';
import 'package:hidden_gems_sl/presentation/screens/smart_match_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late var profile = UserPreferenceService.getProfile();

  void _showLanguagePicker(BuildContext context) {
    final languages = [
      {'name': 'English', 'code': 'en', 'flag': '🇺🇸'},
      {'name': 'සිංහල', 'code': 'si', 'flag': '🇱🇰'},
      {'name': 'தமிழ்', 'code': 'ta', 'flag': '🇱🇰'},
      {'name': '日本語', 'code': 'ja', 'flag': '🇯🇵'},
      {'name': 'Русский', 'code': 'ru', 'flag': '🇷🇺'},
      {'name': '한국어', 'code': 'ko', 'flag': '🇰🇷'},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => OracleUI.glassContainer(
        margin: EdgeInsets.all(16),
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            OracleUI.neonText(
              AppLocalizations.of(context)!.selectLanguage.toUpperCase(),
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
                letterSpacing: 2,
              ),
            ),
            SizedBox(height: 16),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: languages.length,
                itemBuilder: (context, index) {
                  final lang = languages[index];
                  return ListTile(
                    leading: Text(lang['flag']!, style: TextStyle(fontSize: 24)),
                    title: Text(
                      lang['name']!,
                      style: GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurface),
                    ),
                    onTap: () {
                      ref.read(localeNotifierProvider.notifier).setLocale(Locale(lang['code']!));
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(AppLocalizations l10n) async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => OracleUI.glassContainer(
        margin: EdgeInsets.all(16),
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            OracleUI.neonText(
              "MANIFEST AVATAR",
              style: GoogleFonts.outfit(color: Theme.of(context).colorScheme.primary, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 2)
            ),
            SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _photoOption(Icons.camera_alt_outlined, "CAMERA", ImageSource.camera),
                _photoOption(Icons.photo_library_outlined, "ARCHIVE", ImageSource.gallery),
              ],
            ),
            if (profile.profileImagePath != null) ...[
              SizedBox(height: 24),
              TextButton.icon(
                icon: Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                label: Text("EXTINGUISH PHOTO", style: GoogleFonts.inter(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                onPressed: () async {
                  await UserPreferenceService.updateProfileImagePath(null);
                  if (!context.mounted) return;
                  setState(() => profile = UserPreferenceService.getProfile());
                  Navigator.pop(context);
                },
              ),
            ],
          ],
        ),
      ),
    );

    if (source != null) {
      final XFile? image = await picker.pickImage(source: source, maxWidth: 800);
      if (image != null) {
        await UserPreferenceService.updateProfileImagePath(image.path);
        if (mounted) setState(() => profile = UserPreferenceService.getProfile());
      }
    }
  }

  Widget _photoOption(IconData icon, String label, ImageSource source) {
    return GestureDetector(
      onTap: () => Navigator.pop(context, source),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
              shape: BoxShape.circle,
              border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
            ),
            child: Icon(icon, color: Theme.of(context).colorScheme.onSurface, size: 28),
          ),
          SizedBox(height: 12),
          Text(label, style: GoogleFonts.outfit(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPremium = ref.watch(premiumNotifierProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: OracleUI.auraBackground(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildAppBar(isPremium, l10n),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    OracleUI.neonText(
                      "ASCENSION STATUS",
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: Theme.of(context).colorScheme.secondary,
                        letterSpacing: 4,
                      ),
                    ),
                    SizedBox(height: 24),
                    _buildStatsRow(),
                    SizedBox(height: 24),
                    ExplorerProgressCard(
                      service: ExplorerProgressService(),
                      compact: true,
                    ).animate().fadeIn(delay: 200.ms).slideX(),
                    SizedBox(height: 32),
                    _buildThemeModeToggle(),
                    SizedBox(height: 32),
                    _buildVibeSelector(),
                    SizedBox(height: 32),
                    _buildPremiumARStatus(isPremium),
                    SizedBox(height: 32),
                    _buildHeritageHub(),
                    SizedBox(height: 40),
                    _buildSettingsSection(l10n),
                    SizedBox(height: 120),
                  ],
                ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(bool isPremium, AppLocalizations l10n) {
    return SliverAppBar(
      expandedHeight: 320,
      pinned: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black, Theme.of(context).scaffoldBackgroundColor],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 40),
                GestureDetector(
                  onTap: () => _pickImage(l10n),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isPremium ? Theme.of(context).colorScheme.secondary : Theme.of(context).colorScheme.primary,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (isPremium ? Theme.of(context).colorScheme.secondary : Theme.of(context).colorScheme.primary).withValues(alpha: 0.3),
                              blurRadius: 20,
                              spreadRadius: 5,
                            )
                          ],
                        ),
                        child: Hero(
                          tag: 'profile_pic',
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(shape: BoxShape.circle),
                            child: ClipOval(
                              child: profile.profileImagePath != null && (kIsWeb || File(profile.profileImagePath!).existsSync())
                                ? (kIsWeb
                                    ? Image.network(
                                        profile.profileImagePath!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => _defaultAvatar(isPremium),
                                      )
                                    : Image.file(
                                        File(profile.profileImagePath!),
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => _defaultAvatar(isPremium),
                                      ))
                                : _defaultAvatar(isPremium),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 4,
                        bottom: 4,
                        child: Container(
                          padding: EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: isPremium ? Theme.of(context).colorScheme.secondary : Theme.of(context).colorScheme.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 2),
                          ),
                          child: Icon(isPremium ? Icons.verified : Icons.edit, color: Theme.of(context).scaffoldBackgroundColor, size: 14),
                        ),
                      ),
                    ],
                  ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 3.seconds, delay: 2.seconds),
                ),
                SizedBox(height: 20),
                OracleUI.neonText(
                  isPremium ? "PREMIUM TRAVELER" : "ORACLE TRAVELER",
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Theme.of(context).colorScheme.onSurface,
                    letterSpacing: 3,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  ExplorerProgressService().currentLevel.title.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: Theme.of(context).colorScheme.secondary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.5,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _defaultAvatar(bool isPremium) {
    return Container(
      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
      child: Icon(
        isPremium ? Icons.stars_rounded : Icons.person_rounded,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
        size: 50,
      ),
    );
  }

  Widget _buildStatsRow() {
    return OracleUI.glassContainer(
      padding: EdgeInsets.symmetric(vertical: 24),
      showGlow: true,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem(profile.totalTripsGenerated.toString(), "TRIPS"),
          _verticalDivider(),
          _statItem(profile.visitedPlaces.length.toString(), "NODES"),
          _verticalDivider(),
          _statItem("1", "LEVEL"),
        ],
      ),
    );
  }

  Widget _statItem(String val, String label) {
    return Column(
      children: [
        Text(
          val,
          style: GoogleFonts.outfit(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _verticalDivider() {
    return Container(height: 30, width: 1, color: Theme.of(context).dividerColor.withValues(alpha: 0.2));
  }

  Widget _buildVibeSelector() {
    final vibes = ["explorer", "luxury", "photographer", "budget"];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OracleUI.neonText(
          "DESTINY VIBE",
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 3,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: vibes.map((v) => _vibeChip(v)).toList(),
        ),
      ],
    );
  }

  Widget _vibeChip(String v) {
    final isSelected = profile.vibe == v;
    return GestureDetector(
      onTap: () async {
        HapticFeedback.selectionClick();
        await UserPreferenceService.updateVibe(v);
        setState(() {
          profile = UserPreferenceService.getProfile();
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).dividerColor.withValues(alpha: 0.1),
            width: 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
              blurRadius: 15,
            )
          ] : null,
        ),
        child: Text(
          v.toUpperCase(),
          style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isSelected ? Theme.of(context).scaffoldBackgroundColor : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildThemeModeToggle() {
    final themeMode = ref.watch(themeModeProvider);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OracleUI.neonText(
          "LUMINANCE GRID", 
          style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 4, color: Theme.of(context).colorScheme.primary)
        ),
        SizedBox(height: 16),
        Container(
          padding: EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              Expanded(
                child: _modeOption(
                  "ZEN LIGHT",
                  Icons.wb_sunny_outlined,
                  themeMode == ThemeMode.light,
                  () => ref.read(themeModeProvider.notifier).setMode(ThemeMode.light),
                ),
              ),
              Expanded(
                child: _modeOption(
                  "MIDNIGHT",
                  Icons.nightlight_round_outlined,
                  themeMode == ThemeMode.dark,
                  () => ref.read(themeModeProvider.notifier).setMode(ThemeMode.dark),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _modeOption(String label, IconData icon, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon, 
              size: 16, 
              color: isSelected ? Theme.of(context).scaffoldBackgroundColor : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            SizedBox(width: 10),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isSelected ? Theme.of(context).scaffoldBackgroundColor : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection(AppLocalizations l10n) {
    return Column(
      children: [
        if (profile.guideStatus == GuideStatus.approved || profile.role == 'admin') ...[
          _settingsTile(
            Icons.business_center_outlined, 
            "OPERATOR DASHBOARD",
            iconColor: Colors.cyanAccent,
            onTap: () async {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => const Center(child: CircularProgressIndicator()),
              );
              try {
                final user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
                  if (doc.exists) {
                    final data = doc.data() as Map<String, dynamic>? ?? {};
                    final role = data['role'] ?? 'user';
                    final guideStatus = data['guideStatus'] ?? 'none';
                    if (role == 'admin' || guideStatus == 'approved') {
                      if (context.mounted) Navigator.pop(context); // Close loader
                      if (context.mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const OperatorDashboardScreen()),
                        );
                      }
                      return;
                    }
                  }
                }
                if (context.mounted) Navigator.pop(context); // Close loader
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Unauthorized: Access restricted to operators/admins.")),
                  );
                }
              } catch (e) {
                if (context.mounted) Navigator.pop(context);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Verification failed: $e")),
                  );
                }
              }
            },
          ),
          _settingsTile(
            Icons.card_membership_outlined, 
            "GUIDE SUBSCRIPTION",
            iconColor: Colors.amberAccent,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SubscriptionScreen()),
              );
            },
          ),
          _settingsTile(
            Icons.star_outline_rounded, 
            "REPUTATION LOG",
            iconColor: Colors.amberAccent,
            onTap: () {
              final uid = AuthService().currentUser?.uid;
              if (uid != null) {
                Navigator.push(
                  context, 
                  MaterialPageRoute(builder: (context) => GuideReviewsScreen(guideId: uid))
                );
              }
            },
          ),
          _settingsTile(
            Icons.shield_outlined, 
            "SAFETY CONSOLE",
            iconColor: Colors.redAccent,
            onTap: () => Navigator.push(
              context, 
              MaterialPageRoute(builder: (context) => const IncidentCenterScreen())
            ),
          ),
        ] else ...[
          _settingsTile(
            Icons.badge_outlined, 
            "BECOME A GUIDE",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const GuideEnrollmentScreen()),
              );
            },
          ),
        ],
        _settingsTile(
          Icons.family_restroom_outlined, 
          "FAMILY SHARING",
          iconColor: Colors.blueAccent,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const FamilyShareScreen()),
            );
          },
        ),
        _settingsTile(
          Icons.auto_awesome_mosaic_outlined, 
          "SMART MATCHING",
          iconColor: Colors.purpleAccent,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SmartMatchScreen()),
            );
          },
        ),
        _settingsTile(
          Icons.qr_code_scanner_rounded, 
          "SCAN GUIDE QR",
          iconColor: Theme.of(context).colorScheme.primary,
          onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const QRScannerScreen()),
              );
            },
          ),
        _settingsTile(
          Icons.camera_alt_outlined, 
          "ORACLE LENS (SCREENSHOT)",
          trailing: Switch(
            value: ref.watch(screenshotNotifierProvider),
            onChanged: (val) => ref.read(screenshotNotifierProvider.notifier).toggleVisibility(val),
            activeThumbColor: Theme.of(context).colorScheme.primary,
          ),
        ),
        _settingsTile(Icons.notifications_active_outlined, "VOICE NODES"),
        _settingsTile(
          Icons.language_outlined, 
          l10n.language,
          onTap: () => _showLanguagePicker(context),
        ),
        _settingsTile(
          Icons.translate_rounded, 
          "BILINGUAL FLOW (EN/SI)",
          trailing: Switch(
            value: ref.watch(localeNotifierProvider)?.languageCode == 'si',
            onChanged: (val) {
              HapticFeedback.selectionClick();
              ref.read(localeNotifierProvider.notifier).toggleBilingual();
            },
            activeThumbColor: Theme.of(context).colorScheme.secondary,
          ),
        ),
        _settingsTile(
          Icons.emergency_outlined,
          "EMERGENCY PROTOCOL",
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const EmergencyKitScreen()),
          ),
        ),
        _settingsTile(
          Icons.privacy_tip_outlined, 
          l10n.privacyPolicy,
          onTap: () async {
            final url = Uri.parse("https://tripme-ai.web.app/privacy");
            if (await canLaunchUrl(url)) {
              await launchUrl(url, mode: LaunchMode.externalApplication);
            }
          },
        ),
        _settingsTile(
          Icons.description_outlined, 
          l10n.termsOfService,
          onTap: () async {
            final url = Uri.parse("https://tripme-ai.web.app/terms");
            if (await canLaunchUrl(url)) {
              await launchUrl(url, mode: LaunchMode.externalApplication);
            }
          },
        ),
        _settingsTile(
          Icons.star_rate_rounded, 
          "ORACLE RATING", 
          onTap: () => RatingService().forceRequestReview(),
        ),
        _settingsTile(
          Icons.help_outline_rounded, 
          "SUPPORT SIGNAL",
          onTap: () async {
            final Uri emailLaunchUri = Uri(
              scheme: 'mailto',
              path: 'support@tripme.ai',
              query: 'subject=Support%20Request%20-%20Oracle%20Traveler',
            );
            if (await canLaunchUrl(emailLaunchUri)) {
              await launchUrl(emailLaunchUri);
            }
          },
        ),
        _settingsTile(
          Icons.share_rounded, 
          l10n.inviteFriends,
          onTap: () {
            Share.share(
              "Join the Aethereal Oracle on TripMe! 🌍 Download now: https://tripme-ai.web.app",
              subject: "Join me on TripMe!",
            );
          },
        ),
        if (kDebugMode)
          _settingsTile(
            Icons.bug_report_rounded, 
            "SIMULATE CRASH (DEBUG)",
            textColor: Colors.orangeAccent,
            iconColor: Colors.orangeAccent,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Oracle will reset in 2 cycles... Check Firebase!")),
              );
              Future.delayed(const Duration(seconds: 2), () {
                throw Exception("Test Crash for Firebase Crashlytics");
              });
            },
          ),
        _settingsTile(
          Icons.delete_forever_rounded, 
          l10n.deleteAccount,
          textColor: Colors.redAccent.withValues(alpha: 0.7),
          iconColor: Colors.redAccent.withValues(alpha: 0.7),
          onTap: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (context) => OracleUI.glassContainer(
                margin: EdgeInsets.symmetric(horizontal: 40, vertical: 240),
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 48),
                    SizedBox(height: 20),
                    OracleUI.neonText("PERMANENT ERASE", style: GoogleFonts.outfit(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 18)),
                    SizedBox(height: 16),
                    Text(
                      l10n.confirmDeleteMessage,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 13),
                    ),
                    SizedBox(height: 32),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text("CANCEL", style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4))),
                          ),
                        ),
                        Expanded(
                          child: ElevatedButton(
                             style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                             onPressed: () => Navigator.pop(context, true),
                             child: Text("ERASE", style: TextStyle(color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );

            if (confirm == true) {
              if (!mounted) return;
              try {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary)),
                );
                
                await AuthService().deleteAccount();
                
                if (!mounted) return;
                Navigator.pop(context); 
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              } catch (e) {
                if (!mounted) return;
                Navigator.pop(context); 
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Manifestation error: $e")),
                );
              }
            }
          },
        ),
        SizedBox(height: 16),
        _settingsTile(
          Icons.logout_rounded, 
          "EXPEL SESSION",
          textColor: Colors.redAccent,
          iconColor: Colors.redAccent,
          onTap: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (context) => OracleUI.glassContainer(
                 margin: EdgeInsets.symmetric(horizontal: 40, vertical: 260),
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("EXPEL SESSION?", style: GoogleFonts.outfit(color: AppTheme.textPrimary(context), fontWeight: FontWeight.bold, fontSize: 18)),
                    SizedBox(height: 32),
                    Row(
                      children: [
                        Expanded(child: TextButton(onPressed: () => Navigator.pop(context, false), child: Text("REMAIN"))),
                        Expanded(child: ElevatedButton(onPressed: () => Navigator.pop(context, true), child: Text("EXIT"))),
                      ],
                    ),
                  ],
                ),
              ),
            );

            if (confirm == true) {
              await AuthService().signOut();
              if (mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
              }
            }
          },
        ),
      ],
    );
  }

  Widget _settingsTile(IconData icon, String title, {VoidCallback? onTap, Widget? trailing, Color? textColor, Color? iconColor}) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: OracleUI.glassContainer(
        padding: EdgeInsets.zero,
        borderRadius: BorderRadius.circular(20),
        child: ListTile(
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          leading: Container(
            width: 42,
            height: 42,
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (iconColor ?? Theme.of(context).colorScheme.primary).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor ?? Theme.of(context).colorScheme.primary, size: 20),
          ),
          title: Text(
            title.toUpperCase(),
            style: GoogleFonts.outfit(
              fontSize: 11, 
              fontWeight: FontWeight.w900, 
              color: textColor ?? AppTheme.textPrimary(context).withValues(alpha: 0.8), 
              letterSpacing: 2
            ),
          ),
          trailing: trailing ?? Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.textSecondary(context).withValues(alpha: 0.3)),
          onTap: onTap ?? () {
              HapticFeedback.selectionClick();
          },
        ),
      ),
    );
  }


  Widget _buildPremiumARStatus(bool isPremium) {
    return OracleUI.glassContainer(
      padding: EdgeInsets.all(20),
      showGlow: isPremium,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (isPremium ? Theme.of(context).colorScheme.secondary : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1)).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isPremium ? Icons.view_in_ar_rounded : Icons.lock_outline,
                  color: isPremium ? Theme.of(context).colorScheme.secondary : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
                  size: 20,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isPremium ? "ORACLE EXPLORER" : "INITIATE",
                      style: GoogleFonts.outfit(
                        color: isPremium ? Theme.of(context).colorScheme.secondary : AppTheme.textPrimary(context).withValues(alpha: 0.6),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      isPremium ? "Full AR access granted" : "Upgrade to unlock AR",
                      style: GoogleFonts.inter(color: AppTheme.textSecondary(context).withValues(alpha: 0.6), fontSize: 11),
                    ),
                  ],
                ),
              ),
              if (!isPremium)
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const PremiumHubScreen()),
                    );
                  },
                  child: Text(
                    profile.trialUsed ? "Renew" : "Upgrade", 
                    style: TextStyle(color: Color(0xFFFFB300)),
                  ),
                ),
            ],
          ),
          if (isPremium) ...[
            SizedBox(height: 20),
            Container(height: 1, color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _miniStat("AI TRIPS", "${profile.aiTripsUsedThisMonth} USED"),
                _miniStat("AR SESSIONS", "${profile.arSessionsUsedThisMonth} USED"),
                if (profile.usageResetDate != null)
                  _miniStat("RESETS IN", "${profile.usageResetDate!.difference(DateTime.now()).inDays} DAYS"),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            letterSpacing: 1,
          ),
        ),
        SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildHeritageHub() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
            OracleUI.neonText(
          "FUTURE HORIZONS HUB",
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: AppTheme.sigiriyaOchre(context),
            letterSpacing: 4,
          ),
        ),
        SizedBox(height: 24),
        OracleUI.glassContainer(
          padding: EdgeInsets.all(24),
          borderRadius: BorderRadius.circular(32),
          showGlow: true,
          glowColor: AppTheme.sigiriyaOchre(context),
          child: Column(
            children: [
              _buildHubItem(
                Icons.account_balance_wallet_outlined, 
                "AI Budget Concierge", 
                "Smart expense advisor",
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BudgetConciergeScreen())),
              ),
              Divider(color: Theme.of(context).dividerColor.withValues(alpha: 0.1), height: 24),
              _buildHubItem(
                Icons.workspace_premium_outlined, 
                "Heritage Passport", 
                "Verifiable visit collection",
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HeritagePassportScreen())),
              ),
              Divider(color: Theme.of(context).dividerColor.withValues(alpha: 0.1), height: 24),
              FutureBuilder<int>(
                future: EthicalTravelService.getScore(),
                builder: (context, snapshot) {
                  final score = snapshot.data ?? 0;
                  final rank = EthicalTravelService.getRank(score);
                  return _buildHubItem(
                    Icons.eco_outlined, 
                    "Ethical Travel Meter", 
                    "Rank: $rank • Score: $score",
                    () {},
                    color: AppTheme.modernGreen(context),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHubItem(IconData icon, String title, String subtitle, VoidCallback onTap, {Color? color}) {
    final effectiveColor = color ?? AppTheme.textPrimary(context).withValues(alpha: 0.4);
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: effectiveColor, size: 24),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(color: AppTheme.textPrimary(context), fontWeight: FontWeight.bold, fontSize: 13)),
                Text(subtitle, style: GoogleFonts.inter(color: AppTheme.textSecondary(context).withValues(alpha: 0.7), fontSize: 10)),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios, color: AppTheme.textSecondary(context).withValues(alpha: 0.3), size: 14),
        ],
      ),
    );
  }
}

class _GlowingProfileRing extends StatefulWidget {
  final Widget child;
  const _GlowingProfileRing({required this.child});

  @override
  State<_GlowingProfileRing> createState() => _GlowingProfileRingState();
}

class _GlowingProfileRingState extends State<_GlowingProfileRing> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // Replicates a smooth, infinite "Smart Animate" style pulse from Figma
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: 114 + (_controller.value * 12), // Subtle pulsing expansion
          height: 114 + (_controller.value * 12),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppTheme.modernGreen(context).withValues(alpha: 0.3 + (_controller.value * 0.5)),
              width: 1.5 + (_controller.value * 2.0),
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.modernGreen(context).withValues(alpha: 0.1 + (_controller.value * 0.3)),
                blurRadius: 15 + (_controller.value * 20),
                spreadRadius: 2 + (_controller.value * 8),
              )
            ],
          ),
          child: Center(child: widget.child),
        );
      },
    );
  }
}
