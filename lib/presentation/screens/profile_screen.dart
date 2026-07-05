import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../core/utils/secure_logger.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/providers/screenshot_provider.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hidden_gems_sl/data/models/user_profile.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../core/localization/locale_provider.dart';
import '../../core/services/explorer_progress_service.dart';
import '../../data/datasources/premium_service.dart';
import '../../data/datasources/user_preference_service.dart';
import '../../data/datasources/auth_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:hidden_gems_sl/l10n/app_localizations.dart';
import '../widgets/explorer_progress_card.dart';
import '../widgets/cached_image.dart';
import 'guide_dashboard_screen.dart';
import 'emergency_kit_screen.dart';
import 'premium_hub_screen.dart';
import '../widgets/usage_meter_widget.dart';
import 'qr_scanner_screen.dart';
import 'heritage_passport_screen.dart';
import 'budget_concierge_screen.dart';
import 'login_screen.dart';
import 'guide_listing_editor_screen.dart';
import 'booking_inbox_screen.dart';
import 'guide_earnings_screen.dart';
import '../../core/services/ethical_travel_service.dart';
import '../../core/rating/rating_service.dart';
import '../../core/notifications/notification_service.dart';
import 'guide_enrollment_screen.dart';
import '../../data/repositories/guide_application_repository.dart';
import 'package:hidden_gems_sl/data/models/guide_status.dart';
import 'package:hidden_gems_sl/presentation/screens/family_share_screen.dart';
import 'package:hidden_gems_sl/presentation/screens/privacy_policy_screen.dart';
import 'package:hidden_gems_sl/presentation/screens/terms_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  late var profile = UserPreferenceService.getProfile();
  StreamSubscription? _userSub;
  StreamSubscription? _appSub;

  @override
  void initState() {
    super.initState();
    _startWatchingRole();
  }

  void _startWatchingRole() {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        NotificationService().startWatchingUserNotifications(user.uid);
        GuideApplicationRepository().getMyApplication().catchError((_) => null);
        _userSub = FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots().listen((doc) async {
          if (doc.exists && doc.data() != null && mounted) {
            final data = doc.data()!;
            bool changed = false;
            if (data['role'] != null && profile.role != data['role']) {
              profile.role = data['role'];
              if (profile.role == 'guide_approved') {
                profile.guideStatus = GuideStatus.approved;
                profile.isGuideApproved = true;
              }
              changed = true;
            }
            if (data['guideStatus'] != null) {
              final statusStr = data['guideStatus'] as String;
              try {
                final newStatus = GuideStatus.values.byName(statusStr);
                if (profile.guideStatus != newStatus) {
                  profile.guideStatus = newStatus;
                  changed = true;
                }
              } catch (e, st) { SecureLogger.error("Exception caught", e, st); }
            }
            if (changed) {
              await UserPreferenceService.saveProfile(profile);
              if (mounted) setState(() {});
            }
          }
        });

        _appSub = FirebaseFirestore.instance.collection('guide_applications').doc(user.uid).snapshots().listen((doc) async {
          if (doc.exists && doc.data() != null && mounted) {
            final data = doc.data()!;
            final statusStr = data['status'] as String?;
            if (statusStr != null) {
              try {
                final newStatus = GuideStatus.values.byName(statusStr);
                bool changed = false;
                if (newStatus == GuideStatus.approved && profile.guideStatus != GuideStatus.approved) {
                  profile.guideStatus = GuideStatus.approved;
                  profile.role = 'guide_approved';
                  profile.isGuideApproved = true;
                  changed = true;
                } else if (newStatus == GuideStatus.rejected && profile.guideStatus != GuideStatus.rejected) {
                  profile.guideStatus = GuideStatus.rejected;
                  changed = true;
                } else if (newStatus == GuideStatus.pending && profile.guideStatus != GuideStatus.pending) {
                  profile.guideStatus = GuideStatus.pending;
                  changed = true;
                }
                if (changed) {
                  await UserPreferenceService.saveProfile(profile);
                  if (mounted) setState(() {});
                }
              } catch (e, st) { SecureLogger.error("Exception caught", e, st); }
            }
          }
        });
      }
    } catch (e) {
      debugPrint("Error syncing role: $e");
    }
  }

  @override
  void dispose() {
    _userSub?.cancel();
    _appSub?.cancel();
    super.dispose();
  }

  // ── Language Picker ─────────────────────────────────────────────────────────
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
      builder: (context) => _BottomSheet(
        title: AppLocalizations.of(context)!.selectLanguage.toUpperCase(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: languages.map((lang) {
            return ListTile(
              leading: Text(lang['flag']!, style: const TextStyle(fontSize: 24)),
              title: Text(
                lang['name']!,
                style: GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurface),
              ),
              onTap: () {
                ref.read(localeProvider.notifier).setLocale(Locale(lang['code']!));
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  // ── Profile Image Loading ────────────────────────────────────────────────────
  Widget _buildProfileImage(UserProfile profile, bool isPremium) {
    if (profile.profileImagePath == null || profile.profileImagePath!.isEmpty) {
      return _defaultAvatar(isPremium);
    }
    if (profile.profileImagePath!.startsWith('http')) {
      return CachedImage(
        url: profile.profileImagePath!,
        fit: BoxFit.cover,
        errorWidget: _defaultAvatar(isPremium),
        placeholder: _defaultAvatar(isPremium),
      );
    }
    if (kIsWeb) {
      return Image.network(
        profile.profileImagePath!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _defaultAvatar(isPremium),
      );
    }
    try {
      final file = File(profile.profileImagePath!);
      if (!file.existsSync()) return _defaultAvatar(isPremium);
      return Image.file(file, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _defaultAvatar(isPremium));
    } catch (_) {
      return _defaultAvatar(isPremium);
    }
  }

  Widget _defaultAvatar(bool isPremium) {
    return Container(
      color: AppPalette.heroCream,
      child: Icon(
        isPremium ? Icons.stars_rounded : Icons.person_rounded,
        color: AppPalette.rust.withValues(alpha: 0.4),
        size: 48,
      ),
    );
  }

  // ── Image Picker ─────────────────────────────────────────────────────────────
  Future<void> _pickImage(AppLocalizations l10n) async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _BottomSheet(
        title: "PROFILE PHOTO",
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _photoOption(Icons.camera_alt_outlined, "CAMERA", ImageSource.camera),
                _photoOption(Icons.photo_library_outlined, "GALLERY", ImageSource.gallery),
              ],
            ),
            if (profile.profileImagePath != null) ...[
              const SizedBox(height: 16),
              TextButton.icon(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                label: Text("REMOVE PHOTO",
                    style: GoogleFonts.inter(
                        color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold)),
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
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppPalette.heroCream,
              shape: BoxShape.circle,
              border: Border.all(color: AppPalette.sand),
            ),
            child: Icon(icon, color: AppPalette.rust, size: 26),
          ),
          const SizedBox(height: 10),
          Text(label,
              style: GoogleFonts.outfit(
                  color: AppPalette.earth, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        ],
      ),
    );
  }

  // ── Main Build ───────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    super.build(context);
    try {
      final isPremium = ref.watch(premiumProvider);
      final l10n = AppLocalizations.of(context);
      final isDark = Theme.of(context).brightness == Brightness.dark;

      if (l10n == null) {
        return const Scaffold(
          body: Center(child: Text("Localization error", style: TextStyle(color: Colors.red))),
        );
      }

      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Hero App Bar ───────────────────────────────────────────────
            _buildHeroAppBar(isPremium, l10n, isDark),

            // ── Body ───────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                // BUG-053: Wrap in SingleChildScrollView to prevent overflow on small screens
                child: SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(), // parent CustomScrollView handles scroll
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 28),

                      // Guide Command Hub (Option 1 - Quick Access at the very top!)
                      if (profile.guideStatus == GuideStatus.approved || profile.role == 'guide_approved' || profile.isGuideApproved || profile.role == 'admin') ...[
                        _buildGuideCommandHub(),
                        const SizedBox(height: 24),
                      ],

                      // Stats Row
                      _buildStatsCard(),
                      const SizedBox(height: 20),

                      // Explorer Progress
                      ExplorerProgressCard(
                        service: ExplorerProgressService(),
                        compact: true,
                      ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.1),
                      const SizedBox(height: 20),

                      // Premium / AR Status
                      _buildPremiumCard(isPremium),
                      const SizedBox(height: 20),

                      // Usage Meter
                      const UsageMeterWidget(),
                      const SizedBox(height: 28),

                      // Theme Toggle
                      _sectionLabel("APPEARANCE"),
                      const SizedBox(height: 12),
                      _buildThemeToggle(),
                      const SizedBox(height: 28),

                      // Heritage Hub
                      _buildHeritageHub(),
                      const SizedBox(height: 28),

                      // Settings
                      _sectionLabel("SETTINGS"),
                      const SizedBox(height: 12),
                      _buildSettingsSection(l10n),
                    ],
                  ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.05),
                ),
              ),
            ),
          ],
        ),
      );
    } catch (e, stack) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Text("PROFILE ERROR:\n$e\n\n$stack",
                style: const TextStyle(color: Colors.red, fontSize: 11)),
          ),
        ),
      );
    }
  }

  // ── Hero App Bar ─────────────────────────────────────────────────────────────
  Widget _buildHeroAppBar(bool isPremium, AppLocalizations l10n, bool isDark) {
    final accentColor = isPremium ? AppPalette.rust : AppPalette.rust;

    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Background gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF0F1419), const Color(0xFF141C24).withValues(alpha: 0)]
                      : [AppPalette.heroOchre.withValues(alpha: 0.35), AppPalette.bg.withValues(alpha: 0)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),

            // Content
            SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 16),

                  // Avatar with pulsing ring
                  GestureDetector(
                    onTap: () => _pickImage(l10n),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer glow ring
                        Container(
                          width: 112,
                          height: 112,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: accentColor.withValues(alpha: 0.25), width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: accentColor.withValues(alpha: 0.2),
                                blurRadius: 24,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                        ),
                        // Avatar
                        Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: accentColor, width: 2.5),
                          ),
                          child: ClipOval(child: _buildProfileImage(profile, isPremium)),
                        ),
                        // Edit badge
                        Positioned(
                          right: 2,
                          bottom: 2,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: accentColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: Theme.of(context).scaffoldBackgroundColor, width: 2),
                            ),
                            child: Icon(
                              isPremium ? Icons.verified_rounded : Icons.camera_alt_rounded,
                              color: Colors.white,
                              size: 12,
                            ),
                          ),
                        ),
                      ],
                    ).animate(onPlay: (c) => c.repeat()).shimmer(
                        duration: 3.seconds, delay: 2.seconds, color: accentColor.withValues(alpha: 0.3)),
                  ),

                  const SizedBox(height: 16),

                  // Name / title
                  Text(
                    isPremium ? "PREMIUM TRAVELER" : "ORACLE TRAVELER",
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textPrimary(context),
                      letterSpacing: 2.5,
                    ),
                  ),

                  const SizedBox(height: 4),

                  // Level badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: accentColor.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      ExplorerProgressService().currentLevel.title.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: accentColor,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Stats Card ───────────────────────────────────────────────────────────────
  Widget _buildStatsCard() {
    return _Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _statItem(profile.totalTripsGenerated.toString(), "TRIPS", Icons.route_rounded),
            _divider(),
            _statItem(profile.visitedPlaces.length.toString(), "PLACES", Icons.place_rounded),
            _divider(),
            _statItem("1", "LEVEL", Icons.workspace_premium_rounded),
          ],
        ),
      ),
    );
  }

  Widget _statItem(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppPalette.rust, size: 20),
        const SizedBox(height: 6),
        Text(value,
            style: GoogleFonts.outfit(
                fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textPrimary(context))),
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 9,
                color: AppTheme.textSecondary(context),
                fontWeight: FontWeight.bold,
                letterSpacing: 1)),
      ],
    );
  }

  Widget _divider() =>
      Container(height: 36, width: 1, color: AppTheme.borderColor(context).withValues(alpha: 0.5));

  // ── Premium Card ─────────────────────────────────────────────────────────────
  Widget _buildPremiumCard(bool isPremium) {
    return _Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isPremium
                    ? AppPalette.rust.withValues(alpha: 0.12)
                    : AppTheme.borderColor(context).withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isPremium ? Icons.view_in_ar_rounded : Icons.lock_outline_rounded,
                color: isPremium ? AppPalette.rust : AppTheme.textSecondary(context),
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isPremium ? "ORACLE EXPLORER" : "INITIATE",
                    style: GoogleFonts.outfit(
                        color: isPremium ? AppPalette.rust : AppTheme.textPrimary(context),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isPremium ? "Full AR & AI access granted" : "Upgrade to unlock all features",
                    style: GoogleFonts.inter(color: AppTheme.textSecondary(context), fontSize: 11),
                  ),
                ],
              ),
            ),
            if (!isPremium)
              GestureDetector(
                onTap: () => Navigator.push(
                    context, MaterialPageRoute(builder: (_) => const PremiumHubScreen())),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppPalette.rust,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text("UPGRADE",
                      style: GoogleFonts.outfit(
                          color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Theme Toggle ─────────────────────────────────────────────────────────────
  Widget _buildThemeToggle() {
    final themeMode = ref.watch(themeModeProvider);
    return _Card(
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            Expanded(
              child: _themeOption(
                "☀️  LIGHT",
                themeMode == ThemeMode.light,
                () => ref.read(themeModeProvider.notifier).setMode(ThemeMode.light),
              ),
            ),
            Expanded(
              child: _themeOption(
                "🌙  DARK",
                themeMode == ThemeMode.dark,
                () => ref.read(themeModeProvider.notifier).setMode(ThemeMode.dark),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _themeOption(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: isSelected ? AppPalette.rust : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : AppTheme.textSecondary(context),
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  // ── Heritage Hub ─────────────────────────────────────────────────────────────
  Widget _buildHeritageHub() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel("JOURNEY HUB"),
        const SizedBox(height: 12),
        _Card(
          child: Column(
            children: [
              _hubItem(Icons.account_balance_wallet_outlined, "AI Budget Concierge",
                  "Smart expense advisor", AppPalette.rust,
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BudgetConciergeScreen()))),
              _hubDivider(),
              _hubItem(Icons.workspace_premium_outlined, "Heritage Passport",
                  "Verifiable visit collection", const Color(0xFF8B6914),
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HeritagePassportScreen()))),
              _hubDivider(),
              FutureBuilder<int>(
                future: EthicalTravelService.getScore(),
                builder: (context, snapshot) {
                  final score = snapshot.data ?? 0;
                  final rank = EthicalTravelService.getRank(score);
                  return _hubItem(Icons.eco_outlined, "Ethical Travel Meter",
                      "Rank: $rank • Score: $score", const Color(0xFF2E7D32), () => _showEthicalMeterDialog(context, score, rank));
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showEthicalMeterDialog(BuildContext context, int score, String rank) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
          border: Border.all(color: const Color(0xFF2E7D32).withValues(alpha: 0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.eco_rounded, color: Color(0xFF2E7D32), size: 40),
            ),
            const SizedBox(height: 16),
            Text(
              "ETHICAL TRAVEL METER",
              style: GoogleFonts.outfit(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Rank: $rank • Score: $score Pts",
              style: GoogleFonts.inter(
                color: const Color(0xFF2E7D32),
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Your ethical travel score measures your positive impact on local communities and heritage preservation across Sri Lanka.",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "HOW TO EARN POINTS:",
                style: GoogleFonts.outfit(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 12),
            _ecoPointTile("✍️ Leave Place Reviews", "+10 Pts", "Support local guides and travelers"),
            _ecoPointTile("🍛 Sample Local Food", "+15 Pts", "Empower authentic local eateries"),
            _ecoPointTile("🏛️ Visit Heritage Sites", "+20 Pts", "Promote cultural preservation"),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "🎁 REWARDS & PERKS YOU UNLOCK:",
                style: GoogleFonts.outfit(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 12),
            _rewardTile("🌟 Eco Guardian Badge", "Stand out on leaderboards & reviews"),
            _rewardTile("☕ Partner Discounts", "5%-15% off at verified eco-stays & cafes"),
            _rewardTile("🔓 Free Premium Perks", "Unlock AR guides & offline maps with points"),
            _rewardTile("🌳 Real-World Impact", "Reach 500 Pts & we plant a tree in SL for you!"),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(
                  "GOT IT, KEEP EXPLORING",
                  style: GoogleFonts.inter(fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 13),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _rewardTile(String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF2E7D32).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2E7D32).withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          const Icon(Icons.card_giftcard_rounded, color: Color(0xFF2E7D32), size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 12)),
                Text(subtitle, style: GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _ecoPointTile(String title, String points, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 2),
                Text(subtitle, style: GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 11)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF2E7D32).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(points, style: GoogleFonts.outfit(color: const Color(0xFF2E7D32), fontWeight: FontWeight.w900, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _hubItem(IconData icon, String title, String subtitle, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.inter(
                          color: AppTheme.textPrimary(context),
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                  Text(subtitle,
                      style: GoogleFonts.inter(
                          color: AppTheme.textSecondary(context), fontSize: 11)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                color: AppTheme.textSecondary(context).withValues(alpha: 0.35), size: 13),
          ],
        ),
      ),
    );
  }

  Widget _hubDivider() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 18),
    child: Divider(height: 1, color: AppTheme.borderColor(context).withValues(alpha: 0.5)),
  );

  // ── Guide Command Hub (Option 1 - Redesigned for High Contrast & Luxury) ────
  Widget _buildGuideCommandHub() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E1810), const Color(0xFF141A20)]
              : [const Color(0xFFFFF8E7), const Color(0xFFFFECC4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.amber.withValues(alpha: 0.5) : const Color(0xFFD4AF37),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.amber.withValues(alpha: 0.08)
                : const Color(0xFFD4AF37).withValues(alpha: 0.2),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? Colors.amber.withValues(alpha: 0.2) : const Color(0xFFFFD700).withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.explore, color: isDark ? Colors.amber[700] : const Color(0xFFB8860B), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "GUIDE COMMAND HUB",
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: isDark ? Colors.white : const Color(0xFF1A1512),
                      ),
                    ),
                    Text(
                      "Quick access to your guide tools",
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: isDark ? Colors.white70 : const Color(0xFF5A4A3A),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.greenAccent, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Colors.greenAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "ACTIVE",
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.greenAccent,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _buildGuideHubButton(
                  Icons.explore_outlined,
                  "Tour Dashboard",
                  "Active tour & QR",
                  isDark ? Colors.amber[700]! : const Color(0xFFD4AF37),
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GuideDashboardScreen())),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildGuideHubButton(
                  Icons.inbox_rounded,
                  "Bookings",
                  "Tour requests",
                  isDark ? Colors.blueAccent : const Color(0xFF2563EB),
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BookingInboxScreen())),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildGuideHubButton(
                  Icons.account_balance_wallet_outlined,
                  "Earnings",
                  "Payouts & stats",
                  isDark ? Colors.greenAccent[400]! : const Color(0xFF16A34A),
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GuideEarningsScreen())),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildGuideHubButton(
                  Icons.edit_document,
                  "My Listing",
                  "Profile & vehicle",
                  isDark ? Colors.orangeAccent : const Color(0xFFEA580C),
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GuideListingEditorScreen())),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, curve: Curves.easeOutQuad);
  }

  Widget _buildGuideHubButton(IconData icon, String title, String subtitle, Color color, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F2937) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? color.withValues(alpha: 0.4) : color,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black.withValues(alpha: 0.3) : color.withValues(alpha: 0.15),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const Spacer(),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 12,
                  color: isDark ? Colors.white38 : const Color(0xFF9CA3AF),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF111827),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 10,
                color: isDark ? Colors.white70 : const Color(0xFF4B5563),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ── Settings Section ─────────────────────────────────────────────────────────
  Widget _buildSettingsSection(AppLocalizations l10n) {
    return Column(
      children: [
        // Guide Enrollment (only for non-guides)
        if (profile.guideStatus != GuideStatus.approved && profile.role != 'guide_approved' && !profile.isGuideApproved && profile.role != 'admin') ...[
          _tile(Icons.badge_outlined, "Become a Guide",
              onTap: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const GuideEnrollmentScreen()))),
        ],

        _tile(Icons.family_restroom_outlined, "Family Sharing",
            iconColor: Colors.blue[400],
            onTap: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const FamilyShareScreen()))),

        _tile(Icons.privacy_tip_outlined, l10n.privacyPolicy,
            iconColor: Colors.teal[400],
            onTap: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()))),

        _tile(Icons.description_outlined, l10n.termsOfService,
            iconColor: Colors.amber[600],
            onTap: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const TermsScreen()))),

        _tile(Icons.qr_code_scanner_rounded, "Scan Guide QR",
            onTap: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const QRScannerScreen()))),

        _tile(Icons.camera_alt_outlined, "Oracle Lens",
            trailing: Switch(
              value: ref.watch(screenshotProvider),
              onChanged: (val) =>
                  ref.read(screenshotProvider.notifier).toggleVisibility(val),
              activeThumbColor: AppPalette.rust,
            )),

        _tile(Icons.language_outlined, l10n.language,
            onTap: () => _showLanguagePicker(context)),

        _tile(Icons.translate_rounded, "Bilingual (EN/SI)",
            trailing: Switch(
              value: ref.watch(localeProvider)?.languageCode == 'si',
              onChanged: (_) {
                HapticFeedback.selectionClick();
                ref.read(localeProvider.notifier).toggleBilingual();
              },
              activeThumbColor: AppPalette.rust,
            )),

        _tile(Icons.emergency_outlined, "Emergency Protocol",
            iconColor: Colors.red[600],
            onTap: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const EmergencyKitScreen()))),

        _tile(Icons.star_rate_rounded, "Rate the App",
            onTap: () => RatingService().forceRequestReview()),

        _tile(Icons.help_outline_rounded, "Support",
            onTap: () async {
              final uri = Uri(
                  scheme: 'mailto',
                  path: 'support@hiddengems.lk',
                  query: 'subject=Support%20Request');
              if (await canLaunchUrl(uri)) await launchUrl(uri);
            }),

        _tile(Icons.share_rounded, l10n.inviteFriends,
            onTap: () {
              SharePlus.instance.share(ShareParams(
                text: "Join Hidden Gems SL! 🌍 https://hiddengems.lk",
                subject: "Join me on Hidden Gems SL!",
              ));
            }),

        if (kDebugMode)
          _tile(Icons.bug_report_rounded, "Simulate Crash (Debug)",
              textColor: Colors.orange,
              iconColor: Colors.orange,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Crash in 2s...")));
                Future.delayed(const Duration(seconds: 2),
                    () => throw Exception("Test Crash for Firebase Crashlytics"));
              }),

        const SizedBox(height: 8),

        // Delete account
        _tile(Icons.delete_forever_rounded, l10n.deleteAccount,
            textColor: Colors.redAccent,
            iconColor: Colors.redAccent,
            onTap: _confirmDeleteAccount),

        // Logout
        _tile(Icons.logout_rounded, "Sign Out",
            textColor: Colors.redAccent,
            iconColor: Colors.redAccent,
            onTap: _confirmSignOut),
      ],
    );
  }

  // ── Confirm Delete ────────────────────────────────────────────────────────────
  Future<void> _confirmDeleteAccount() async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await _showConfirmDialog(
      icon: Icons.warning_amber_rounded,
      iconColor: Colors.redAccent,
      title: "DELETE ACCOUNT",
      message: l10n.confirmDeleteMessage,
      confirmLabel: "DELETE",
      confirmColor: Colors.redAccent,
    );
    if (confirm != true) return;
    if (!mounted) return;
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => Center(child: CircularProgressIndicator(color: AppPalette.rust)));
    try {
      await AuthService().deleteAccount();
      if (!mounted) return;
      Navigator.pop(context);
      Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  // ── Confirm Sign Out ──────────────────────────────────────────────────────────
  Future<void> _confirmSignOut() async {
    final confirm = await _showConfirmDialog(
      icon: Icons.logout_rounded,
      iconColor: AppPalette.rust,
      title: "SIGN OUT",
      message: "Are you sure you want to sign out?",
      confirmLabel: "SIGN OUT",
      confirmColor: AppPalette.rust,
    );
    if (confirm != true) return;
    await AuthService().signOut();
    if (mounted) Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
  }

  Future<bool?> _showConfirmDialog({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String message,
    required String confirmLabel,
    required Color confirmColor,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppTheme.borderColor(context)),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 24)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: Icon(icon, color: iconColor, size: 32),
              ),
              const SizedBox(height: 16),
              Text(title,
                  style: GoogleFonts.outfit(
                      color: AppTheme.textPrimary(context),
                      fontWeight: FontWeight.bold,
                      fontSize: 17)),
              const SizedBox(height: 10),
              Text(message,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                      color: AppTheme.textSecondary(context), fontSize: 13)),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppTheme.borderColor(context)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text("CANCEL",
                          style: GoogleFonts.outfit(
                              color: AppTheme.textSecondary(context),
                              fontWeight: FontWeight.bold,
                              fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: confirmColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                      ),
                      child: Text(confirmLabel,
                          style: GoogleFonts.outfit(
                              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Settings Tile ─────────────────────────────────────────────────────────────
  Widget _tile(IconData icon, String title,
      {VoidCallback? onTap, Widget? trailing, Color? textColor, Color? iconColor}) {
    final effectiveIconColor = iconColor ?? AppPalette.rust;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderColor(context)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))
        ],
      ),
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          leading: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: effectiveIconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: effectiveIconColor, size: 18),
          ),
          title: Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textColor ?? AppTheme.textPrimary(context),
            ),
          ),
          trailing: trailing ??
              Icon(Icons.arrow_forward_ios_rounded,
                  size: 13, color: AppTheme.textSecondary(context).withValues(alpha: 0.35)),
          onTap: onTap ?? () => HapticFeedback.selectionClick(),
        ),
      ),
    );
  }

  // ── Section Label ─────────────────────────────────────────────────────────────
  Widget _sectionLabel(String label) => Text(
    label,
    style: GoogleFonts.outfit(
      fontSize: 11,
      fontWeight: FontWeight.w900,
      color: AppPalette.rust,
      letterSpacing: 3,
    ),
  );
}

// ── Reusable Card ─────────────────────────────────────────────────────────────
class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.borderColor(context)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 3))
        ],
      ),
      child: child,
    );
  }
}

// ── Bottom Sheet wrapper ──────────────────────────────────────────────────────
class _BottomSheet extends StatelessWidget {
  final String title;
  final Widget child;
  const _BottomSheet({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppTheme.borderColor(context)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 16)],
      ),
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.borderColor(context),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 18),
          Text(title,
              style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppPalette.rust,
                  letterSpacing: 1.5)),
          const SizedBox(height: 20),
          child,
        ],
      ),
    )));
  }
}

// ── Glowing Profile Ring (kept for potential future use) ──────────────────────
class _GlowingProfileRing extends StatefulWidget {
  final Widget child;
  const _GlowingProfileRing({required this.child});

  @override
  State<_GlowingProfileRing> createState() => _GlowingProfileRingState();
}

class _GlowingProfileRingState extends State<_GlowingProfileRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))
          ..repeat(reverse: true);
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
          width: 114 + (_controller.value * 12),
          height: 114 + (_controller.value * 12),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppPalette.rust.withValues(alpha: 0.3 + (_controller.value * 0.5)),
              width: 1.5 + (_controller.value * 2.0),
            ),
            boxShadow: [
              BoxShadow(
                color: AppPalette.rust.withValues(alpha: 0.1 + (_controller.value * 0.3)),
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
