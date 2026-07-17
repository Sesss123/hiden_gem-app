import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hidden_gems_sl/core/utils/secure_logger.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/providers/screenshot_provider.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
import '../../core/notifications/notification_service.dart';
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
import 'budget_tracker_screen.dart';
import '../../data/datasources/trip_cache_service.dart';
import 'login_screen.dart';
import 'booking_inbox_screen.dart';
import 'guide_earnings_screen.dart';
import 'operator_dashboard_screen.dart';
import 'guide_clients_screen.dart';
import 'guide_packages_screen.dart';
import 'my_bookings_screen.dart';
import 'subscription_screen.dart';
import '../../data/services/subscription_service.dart';
import '../../core/services/ethical_travel_service.dart';
import '../../core/rating/rating_service.dart';
import 'guide_enrollment_screen.dart';
import '../../data/repositories/guide_application_repository.dart';
import 'package:hidden_gems_sl/data/models/guide_status.dart';
import 'package:hidden_gems_sl/presentation/screens/family_share_screen.dart';
import 'package:hidden_gems_sl/presentation/screens/privacy_policy_screen.dart';
import 'package:hidden_gems_sl/presentation/screens/terms_screen.dart';
import '../../core/services/secure_entitlements.dart';
import 'admin_guide_verification_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  late var profile = UserPreferenceService.getProfile();

  Timer? _pendingGuideStatusPoll;

  @override
  void initState() {
    super.initState();
    _refreshRoleOnce();
  }

  @override
  void dispose() {
    _pendingGuideStatusPoll?.cancel();
    super.dispose();
  }

  static const String _lastRoleCheckPrefsKey = 'profile_last_role_check_at';
  static const Duration _roleCheckWindow = Duration(hours: 2);

  /// Role/guideStatus sync, run once when the profile tab first mounts.
  /// Previously this ran as two persistent Firestore listeners (users/{uid}
  /// + guide_applications/{uid}) held open for the entire app session via
  /// AutomaticKeepAliveClientMixin — but role/guideStatus only ever change
  /// on a rare admin/approval action, so a live listener wasn't buying any
  /// real freshness, just cost. That was already fixed to a one-shot .get(),
  /// but since this tab re-mounts once per session, that's still 1 Firestore
  /// read per session. Round 3: the users/{uid} .get() is now also gated
  /// behind a time window (not risk-tiered like the premium check — there's
  /// no fraud-race-condition rationale here, this is a display-only sync,
  /// not a security gate; actual privilege checks happen fresh via Firestore
  /// rules and SecurityOrchestrator regardless of what this screen shows).
  Future<void> _refreshRoleOnce() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      NotificationService().startWatchingUserNotifications(user.uid);

      // Laravel/MySQL-backed — zero Firestore cost. Already syncs
      // guideStatus/isGuideApproved on approval/rejection server-side.
      // Always runs (free) — only the Firestore .get() below is time-gated.
      final app = await GuideApplicationRepository().getMyApplication().catchError((_) => null);
      if (app != null && mounted) {
        bool changed = false;
        if (app.status != profile.guideStatus &&
            (app.status == GuideStatus.approved || app.status == GuideStatus.rejected || app.status == GuideStatus.pending)) {
          profile.applyGuideStatus(app.status);
          changed = true;
        }
        if (changed) {
          await UserPreferenceService.saveProfile(profile);
          if (mounted) setState(() {});
        }

        // BUG-8 FIX: The timer callback previously called _refreshRoleOnce()
        // directly — a recursive pattern where _refreshRoleOnce() sets up a
        // timer that calls _refreshRoleOnce() again. Under heavy load or rapid
        // re-mounts, this could let a second timer spawn before ??= blocks it.
        // Now the timer calls a dedicated lightweight poll (_pollGuideStatus)
        // that only runs the guide-application check, not the full Firestore
        // role sync — which already only runs once per _roleCheckWindow anyway.
        if (app.status == GuideStatus.pending) {
          _pendingGuideStatusPoll ??= Timer.periodic(
            const Duration(seconds: 30),
            (_) => _pollGuideStatus(),
          );
        } else {
          _pendingGuideStatusPoll?.cancel();
          _pendingGuideStatusPoll = null;
        }
      }

      final prefs = await SharedPreferences.getInstance();
      final lastCheckMs = prefs.getInt(_lastRoleCheckPrefsKey);
      if (lastCheckMs != null) {
        final elapsed = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(lastCheckMs));
        if (elapsed < _roleCheckWindow) return; // Still fresh — skip the Firestore read.
      }
      await prefs.setInt(_lastRoleCheckPrefsKey, DateTime.now().millisecondsSinceEpoch);

      // One-shot read (not a listener) — also catches role changes outside
      // the guide-application flow (e.g. admin ban/promotion).
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
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
          } catch (e, st) { SecureLogger.error("Exception caught: $e\n$st"); }
        }
        if (changed) {
          await UserPreferenceService.saveProfile(profile);
          if (mounted) setState(() {});
        }
      }
    } catch (e, st) {
      SecureLogger.error("Error syncing role", e, st, "ProfileScreen");
    }
  }

  /// Lightweight guide-status poll used by the periodic timer.
  /// BUG-8 FIX: This is intentionally separate from _refreshRoleOnce() to
  /// break the recursive timer pattern. It only checks the guide application
  /// status (free Laravel call) and updates local state \u2014 it does NOT set up
  /// another timer, keeping the call chain strictly one level deep.
  Future<void> _pollGuideStatus() async {
    if (!mounted) return;
    try {
      final app = await GuideApplicationRepository().getMyApplication().catchError((_) => null);
      if (app == null || !mounted) return;

      bool changed = false;
      if (app.status == GuideStatus.approved && profile.guideStatus != GuideStatus.approved) {
        profile.applyGuideStatus(GuideStatus.approved);
        changed = true;
      } else if (app.status == GuideStatus.rejected && profile.guideStatus != GuideStatus.rejected) {
        profile.applyGuideStatus(GuideStatus.rejected);
        changed = true;
        // Stop polling once a terminal state is reached.
        _pendingGuideStatusPoll?.cancel();
        _pendingGuideStatusPoll = null;
      }
      if (changed) {
        await UserPreferenceService.saveProfile(profile);
        if (mounted) setState(() {});
      }
    } catch (e, st) {
      SecureLogger.error("Error in guide status poll", e, st, "ProfileScreen");
    }
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
      backgroundColor: AppTheme.colors.transparent,
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
      backgroundColor: AppTheme.colors.transparent,
      builder: (context) => _BottomSheet(
        title: l10n.profilePhoto,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _photoOption(Icons.camera_alt_outlined, l10n.camera, ImageSource.camera),
                _photoOption(Icons.photo_library_outlined, l10n.gallery, ImageSource.gallery),
              ],
            ),
            if (profile.profileImagePath != null) ...[
              const SizedBox(height: 16),
              TextButton.icon(
                icon: Icon(Icons.delete_outline, color: AppTheme.colors.redAccent, size: 18),
                label: Text(l10n.removePhoto,
                    style: GoogleFonts.inter(
                        color: AppTheme.colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold)),
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
        return Scaffold(
          body: Center(child: Text('Loading...', style: TextStyle(color: AppTheme.colors.red))),
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
                      _sectionLabel(l10n.appearance),
                      const SizedBox(height: 12),
                      _buildThemeToggle(),
                      const SizedBox(height: 28),

                      // Heritage Hub
                      _buildHeritageHub(),
                      const SizedBox(height: 28),

                      // Settings
                      _sectionLabel(l10n.settingsSectionLabel),
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
      SecureLogger.error("ProfileScreen crash boundary", e, stack);
      final fallbackL10n = AppLocalizations.of(context);
      return Scaffold(
        backgroundColor: AppTheme.colors.black,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                fallbackL10n?.somethingWentWrong ?? 'Something went wrong. Please restart the app.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.colors.white, fontSize: 14),
              ),
            ),
          ),
        ),
      );
    }
  }

  // ── Hero App Bar ─────────────────────────────────────────────────────────────
  Widget _buildHeroAppBar(bool isPremium, AppLocalizations l10n, bool isDark) {
    final primary = Theme.of(context).colorScheme.primary;
    final secondary = Theme.of(context).colorScheme.secondary;

    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      elevation: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primary, secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(36),
              bottomRight: Radius.circular(36),
            ),
          ),
          // BUG-6 FIX: Listen to ExplorerProgressService.visitedSites so
          // the level badge and Level stat tile rebuild the instant Firestore
          // data syncs — previously the hero read a stale index-0 snapshot
          // computed at build time and never refreshed until the user scrolled
          // to the ExplorerProgressCard which called init() on its own.
          child: ValueListenableBuilder<int>(
            valueListenable: ExplorerProgressService().visitedSites,
            builder: (context, _, __) {
              final svc = ExplorerProgressService();
              final levelNumber = svc.currentLevel.index + 1;
              return SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 12, 22, 16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Avatar, centered
                      GestureDetector(
                        onTap: () => _pickImage(l10n),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 88,
                              height: 88,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: AppTheme.colors.white.withValues(alpha: 0.55), width: 2.5),
                              ),
                              child: ClipOval(child: _buildProfileImage(profile, isPremium)),
                            ),
                            Positioned(
                              right: -2,
                              bottom: -2,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppPalette.heroOchre,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: primary, width: 2),
                                ),
                                child: Icon(
                                  isPremium ? Icons.verified_rounded : Icons.camera_alt_rounded,
                                  color: AppPalette.ink,
                                  size: 14,
                                ),
                              ),
                            ),
                          ],
                        ).animate(onPlay: (c) => c.repeat()).shimmer(
                            duration: 3.seconds, delay: 2.seconds, color: AppTheme.colors.white.withValues(alpha: 0.3)),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        isPremium ? l10n.premiumTraveler : l10n.oracleTraveler,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          l10n.levelBadgeLabel(svc.currentLevel.title, levelNumber),
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: AppTheme.colors.white,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(height: 1, color: AppTheme.colors.white.withValues(alpha: 0.15)),
                      const SizedBox(height: 12),
                      // Stats, embedded directly in the hero card
                      Row(
                        children: [
                          Expanded(child: _heroStatTile(profile.totalTripsGenerated.toString(), l10n.statLabelTrips)),
                          Container(width: 1, height: 32, color: AppTheme.colors.white.withValues(alpha: 0.15)),
                          Expanded(child: _heroStatTile(profile.visitedPlaces.length.toString(), l10n.statLabelPlaces)),
                          Container(width: 1, height: 32, color: AppTheme.colors.white.withValues(alpha: 0.15)),
                          Expanded(child: _heroStatTile(levelNumber.toString(), l10n.statLabelLevel)),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }


  Widget _heroStatTile(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.colors.white),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 10, color: AppTheme.colors.white.withValues(alpha: 0.75), fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  // ── Premium Card ─────────────────────────────────────────────────────────────
  Widget _buildPremiumCard(bool isPremium) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppPaletteDark.card : AppPalette.ink;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppPalette.heroOchre.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isPremium ? Icons.view_in_ar_rounded : Icons.lock_outline_rounded,
              color: AppPalette.heroOchre,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isPremium ? l10n.oracleExplorer : l10n.goPremium,
                  style: GoogleFonts.outfit(
                      color: AppTheme.colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  isPremium ? l10n.fullArAiAccessGranted : l10n.unlockArAiFeatures,
                  style: GoogleFonts.inter(color: AppTheme.colors.white.withValues(alpha: 0.6), fontSize: 11),
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
                  color: AppPalette.heroOchre,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(l10n.upgrade,
                    style: GoogleFonts.inter(
                        color: AppPalette.ink, fontSize: 11, fontWeight: FontWeight.w700)),
              ),
            ),
        ],
      ),
    );
  }

  // ── Theme Toggle ─────────────────────────────────────────────────────────────
  Widget _buildThemeToggle() {
    final l10n = AppLocalizations.of(context)!;
    final themeMode = ref.watch(themeModeProvider);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceMuted(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: _themeOption(
              Icons.light_mode_rounded,
              l10n.themeLight,
              themeMode == ThemeMode.light,
              () => ref.read(themeModeProvider.notifier).setMode(ThemeMode.light),
            ),
          ),
          Expanded(
            child: _themeOption(
              Icons.dark_mode_rounded,
              l10n.themeDark,
              themeMode == ThemeMode.dark,
              () => ref.read(themeModeProvider.notifier).setMode(ThemeMode.dark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _themeOption(IconData icon, String label, bool isSelected, VoidCallback onTap) {
    final color = isSelected ? AppTheme.textPrimary(context) : AppTheme.textSecondary(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).colorScheme.surface : AppTheme.colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [BoxShadow(color: AppTheme.colors.black.withValues(alpha: 0.12), blurRadius: 10, offset: const Offset(0, 4))]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 7),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Heritage Hub ─────────────────────────────────────────────────────────────
  Widget _buildHeritageHub() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel(l10n.journeyHub),
        const SizedBox(height: 10),
        _hubCard(
          Icons.account_balance_wallet_outlined,
          l10n.aiBudgetConcierge,
          l10n.smartExpenseAdvisor,
          AppPalette.rust,
          _openBudgetHub,
        ),
        const SizedBox(height: 8),
        _hubCard(
          Icons.workspace_premium_outlined,
          l10n.heritagePassport,
          l10n.verifiableVisitCollection,
          AppPalette.heroOchre,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HeritagePassportScreen())),
        ),
        const SizedBox(height: 8),
        FutureBuilder<int>(
          future: EthicalTravelService.getScore(),
          builder: (context, snapshot) {
            final score = snapshot.data ?? 0;
            final rank = EthicalTravelService.getRank(score);
            return _hubCard(Icons.eco_outlined, l10n.ethicalTravelMeter,
                l10n.ethicalRankScore(rank, score), Theme.of(context).colorScheme.secondary, () => _showEthicalMeterDialog(context, score, rank));
          },
        ),
      ],
    );
  }

  /// Routes to the trip-linked BudgetTrackerScreen (real budget-vs-spend
  /// tracking against the user's most recent trip plan) when one exists,
  /// falling back to the generic, trip-independent BudgetConciergeScreen
  /// otherwise. TripCacheService.getAllTrips() is sorted newest-first, so
  /// .first is the user's most recently generated/cached trip.
  void _openBudgetHub() {
    final trips = TripCacheService.getAllTrips();
    if (trips.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => BudgetTrackerScreen(plan: trips.first)),
      );
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const BudgetConciergeScreen()));
    }
  }

  Widget _hubCard(IconData icon, String title, String subtitle, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: AppTheme.colors.black.withValues(alpha: 0.05), blurRadius: 16, offset: const Offset(0, 6)),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(11)),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: GoogleFonts.inter(color: AppTheme.textPrimary(context), fontWeight: FontWeight.w600, fontSize: 12)),
                    Text(subtitle,
                        style: GoogleFonts.inter(color: AppTheme.textSecondary(context), fontSize: 10)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.textSecondary(context).withValues(alpha: 0.5), size: 12),
            ],
          ),
        ),
      ),
    );
  }

  void _showEthicalMeterDialog(BuildContext context, int score, String rank) {
    HapticFeedback.selectionClick();
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
          border: Border.all(color: AppTheme.colors.primary.withValues(alpha: 0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppTheme.colors.black.withValues(alpha: 0.2),
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
                color: AppTheme.colors.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.eco_rounded, color: AppTheme.colors.primary, size: 40),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.ethicalTravelMeterDialogTitle,
              style: GoogleFonts.outfit(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.ethicalRankScorePoints(rank, score),
              style: GoogleFonts.inter(
                color: AppTheme.colors.primary,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.ethicalScoreDescription,
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
                l10n.howToEarnPointsHeading,
                style: GoogleFonts.outfit(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 12),
            _ecoPointTile(Icons.rate_review_rounded, l10n.earnPointsReviewsTitle, l10n.earnPointsReviewsAmount, l10n.earnPointsReviewsSubtitle),
            _ecoPointTile(Icons.restaurant_rounded, l10n.earnPointsFoodTitle, l10n.earnPointsFoodAmount, l10n.earnPointsFoodSubtitle),
            _ecoPointTile(Icons.account_balance_rounded, l10n.earnPointsHeritageTitle, l10n.earnPointsHeritageAmount, l10n.earnPointsHeritageSubtitle),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                l10n.rewardsPerksHeading,
                style: GoogleFonts.outfit(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 12),
            _rewardTile(Icons.workspace_premium_rounded, l10n.rewardEcoGuardianBadgeTitle, l10n.rewardEcoGuardianBadgeSubtitle),
            _rewardTile(Icons.local_cafe_rounded, l10n.rewardPartnerDiscountsTitle, l10n.rewardPartnerDiscountsSubtitle),
            _rewardTile(Icons.lock_open_rounded, l10n.rewardFreePremiumPerksTitle, l10n.rewardFreePremiumPerksSubtitle),
            _rewardTile(Icons.park_rounded, l10n.rewardRealWorldImpactTitle, l10n.rewardRealWorldImpactSubtitle),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.colors.primary,
                  foregroundColor: AppTheme.colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(
                  l10n.gotItKeepExploring,
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

  Widget _rewardTile(IconData icon, String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.colors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.colors.primary.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.colors.primary, size: 18),
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

  Widget _ecoPointTile(IconData icon, String title, String points, String subtitle) {
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
          Icon(icon, color: AppTheme.colors.primary, size: 20),
          const SizedBox(width: 12),
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
              color: AppTheme.colors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(points, style: GoogleFonts.outfit(color: AppTheme.colors.primary, fontWeight: FontWeight.w900, fontSize: 12)),
          ),
        ],
      ),
    );
  }


  // ── Guide Command Hub (Option 1 - Redesigned for High Contrast & Luxury) ────
  Widget _buildGuideCommandHub() {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [AppTheme.colors.primary, AppTheme.colors.primary]
              : [AppTheme.colors.primary, AppTheme.colors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? AppTheme.colors.amber.withValues(alpha: 0.5) : AppTheme.colors.primary,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? AppTheme.colors.amber.withValues(alpha: 0.08)
                : AppTheme.colors.primary.withValues(alpha: 0.2),
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
                  color: isDark ? AppTheme.colors.amber.withValues(alpha: 0.2) : AppTheme.colors.primary.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.explore, color: isDark ? AppTheme.colors.amber[700] : AppTheme.colors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.guideCommandHub,
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: isDark ? AppTheme.colors.white : AppTheme.colors.primary,
                      ),
                    ),
                    Text(
                      l10n.guideCommandHubSubtitle,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: isDark ? AppTheme.colors.white70 : AppTheme.colors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.colors.greenAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.colors.greenAccent, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: AppTheme.colors.greenAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      l10n.activeStatusBadge,
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.colors.greenAccent,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _buildGuideHubButton(
            Icons.explore_outlined,
            l10n.tourDashboard,
            l10n.tourDashboardSubtitle,
            isDark ? AppTheme.colors.amber[700]! : AppTheme.colors.primary,
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GuideDashboardScreen())),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildBookingsEntry(isDark)),
              const SizedBox(width: 12),
              Expanded(
                child: _buildGuideHubButton(
                  Icons.account_balance_wallet_outlined,
                  l10n.earnings,
                  l10n.earningsSubtitle,
                  isDark ? AppTheme.colors.greenAccent[400]! : AppTheme.colors.primary,
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GuideEarningsScreen())),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildGuideHubButton(
                  Icons.people_outline_rounded,
                  l10n.clients,
                  l10n.clientsSubtitle,
                  isDark ? AppTheme.colors.purpleAccent : AppTheme.colors.primary,
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GuideClientsScreen())),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: _buildPackagesEntry(isDark)),
            ],
          ),
          _buildOperatorDashboardEntry(isDark),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, curve: Curves.easeOutQuad);
  }

  Widget _buildBookingsEntry(bool isDark) {
    final l10n = AppLocalizations.of(context)!;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return _buildGuideHubButton(
        Icons.inbox_rounded,
        l10n.bookings,
        l10n.tourRequests,
        isDark ? AppTheme.colors.blueAccent : AppTheme.colors.primary,
        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BookingInboxScreen())),
      );
    }

    // Firestore cost fix: this used to run its OWN second, separate
    // `user_notifications` listener just for this badge — a raw duplicate
    // of the query NotificationService already runs app-wide the moment a
    // user logs in (and ProfileScreen is a bottom-nav tab kept alive for
    // the whole session, so this listener used to stay open the entire
    // time). Reusing NotificationService's in-memory count means zero extra
    // Firestore reads for this badge.
    return ValueListenableBuilder<int>(
      valueListenable: NotificationService().unreadBookingCount,
      builder: (context, unreadCount, _) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            _buildGuideHubButton(
              Icons.inbox_rounded,
              l10n.bookings,
              unreadCount > 0 ? l10n.unreadRequestsCount(unreadCount) : l10n.tourRequests,
              isDark ? AppTheme.colors.blueAccent : AppTheme.colors.primary,
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BookingInboxScreen())),
            ),
            if (unreadCount > 0)
              Positioned(
                top: -6, right: -6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppPalette.rust,
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 2),
                  ),
                  child: Text(
                    unreadCount > 9 ? '9+' : '$unreadCount',
                    style: GoogleFonts.outfit(color: AppTheme.colors.white, fontSize: 11, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildPackagesEntry(bool isDark) {
    final l10n = AppLocalizations.of(context)!;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const SizedBox.shrink();

    return FutureBuilder<bool>(
      future: SubscriptionService().hasEntitlement(uid, 'customPackages'),
      builder: (context, snapshot) {
        final unlocked = snapshot.data ?? false;
        return _buildGuideHubButton(
          unlocked ? Icons.local_offer_outlined : Icons.lock_outline_rounded,
          l10n.packages,
          unlocked ? l10n.customTourPricingSubtitle : l10n.upgradeToPro,
          isDark ? AppTheme.colors.orangeAccent : AppTheme.colors.primary,
          () {
            if (unlocked) {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const GuidePackagesScreen()));
            } else {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionScreen()));
            }
          },
        );
      },
    );
  }

  Widget _buildOperatorDashboardEntry(bool isDark) {
    final l10n = AppLocalizations.of(context)!;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const SizedBox.shrink();

    return FutureBuilder<bool>(
      future: SubscriptionService().hasEntitlement(uid, 'operatorDashboard'),
      builder: (context, snapshot) {
        if (snapshot.data != true) return const SizedBox.shrink();
        return Column(
          children: [
            const SizedBox(height: 12),
            _buildGuideHubButton(
              Icons.groups_2_outlined,
              l10n.manageTeam,
              l10n.manageTeamSubtitle,
              isDark ? AppTheme.colors.amber[700]! : AppTheme.colors.primary,
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OperatorDashboardScreen())),
            ),
          ],
        );
      },
    );
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
          color: isDark ? AppTheme.colors.primary : AppTheme.colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? color.withValues(alpha: 0.4) : color,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark ? AppTheme.colors.black.withValues(alpha: 0.3) : color.withValues(alpha: 0.15),
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
                  color: isDark ? AppTheme.colors.white38 : AppTheme.colors.primary,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDark ? AppTheme.colors.white : AppTheme.colors.primary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 10,
                color: isDark ? AppTheme.colors.white70 : AppTheme.colors.primary,
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
          _tile(Icons.badge_outlined, l10n.becomeAGuide,
              onTap: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const GuideEnrollmentScreen()))),
        ],

        _tile(Icons.event_note_outlined, l10n.myBookings,
            iconColor: AppPalette.rust,
            onTap: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const MyBookingsScreen()))),

        _tile(Icons.family_restroom_outlined, l10n.familySharing,
            iconColor: AppTheme.colors.blue[400],
            onTap: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const FamilyShareScreen()))),

        _tile(Icons.privacy_tip_outlined, l10n.privacyPolicy,
            iconColor: AppTheme.colors.teal[400],
            onTap: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()))),

        _tile(Icons.description_outlined, l10n.termsOfService,
            iconColor: AppTheme.colors.amber[600],
            onTap: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const TermsScreen()))),

        _tile(Icons.qr_code_scanner_rounded, l10n.scanGuideQr,
            onTap: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const QRScannerScreen()))),

        // Admin-only: local check is UX polish, verifyAdmin() on tap is the real gate.
        if (profile.role == 'admin')
          _tile(Icons.verified_user_rounded, l10n.adminGuideVerificationTile,
              iconColor: AppTheme.colors.blue[600],
              onTap: () async {
                final isAdmin = await SecureEntitlements().verifyAdmin();
                if (!mounted) return;
                if (!isAdmin) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.accessDeniedMessage)),
                  );
                  return;
                }
                if (!mounted) return;
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const AdminGuideVerificationScreen()));
              }),

        _tile(Icons.camera_alt_outlined, l10n.oracleLens,
            trailing: Switch(
              value: ref.watch(screenshotProvider),
              onChanged: (val) =>
                  ref.read(screenshotProvider.notifier).toggleVisibility(val),
              activeThumbColor: AppPalette.rust,
            )),

        _tile(Icons.language_outlined, l10n.language,
            onTap: () => _showLanguagePicker(context)),

        _tile(Icons.translate_rounded, l10n.bilingualToggle,
            trailing: Switch(
              value: ref.watch(localeProvider)?.languageCode == 'si',
              onChanged: (_) {
                HapticFeedback.selectionClick();
                ref.read(localeProvider.notifier).toggleBilingual();
              },
              activeThumbColor: AppPalette.rust,
            )),

        _tile(Icons.emergency_outlined, l10n.emergencyProtocol,
            iconColor: AppTheme.colors.red[600],
            onTap: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const EmergencyKitScreen()))),

        _tile(Icons.star_rate_rounded, l10n.rateTheApp,
            onTap: () => RatingService().forceRequestReview()),

        _tile(Icons.help_outline_rounded, l10n.support,
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
                text: l10n.shareAppMessage,
                subject: l10n.shareAppSubject,
              ));
            }),

        if (kDebugMode)
          _tile(Icons.bug_report_rounded, "Simulate Crash (Debug)",
              textColor: AppTheme.colors.orange,
              iconColor: AppTheme.colors.orange,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Crash in 2s...")));
                Future.delayed(const Duration(seconds: 2),
                    () => throw Exception("Test Crash for Firebase Crashlytics"));
              }),

        const SizedBox(height: 8),

        // Delete account
        _tile(Icons.delete_forever_rounded, l10n.deleteAccount,
            textColor: AppTheme.colors.redAccent,
            iconColor: AppTheme.colors.redAccent,
            onTap: _confirmDeleteAccount),

        // Logout
        _tile(Icons.logout_rounded, l10n.signOut,
            textColor: AppTheme.colors.redAccent,
            iconColor: AppTheme.colors.redAccent,
            onTap: _confirmSignOut),
      ],
    );
  }

  // ── Confirm Delete ────────────────────────────────────────────────────────────
  Future<void> _confirmDeleteAccount() async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await _showConfirmDialog(
      icon: Icons.warning_amber_rounded,
      iconColor: AppTheme.colors.redAccent,
      title: l10n.deleteAccountDialogTitle,
      message: l10n.confirmDeleteMessage,
      confirmLabel: l10n.deleteButtonLabel,
      confirmColor: AppTheme.colors.redAccent,
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.genericErrorWithDetails(e.toString()))));
    }
  }

  // ── Confirm Sign Out ──────────────────────────────────────────────────────────
  Future<void> _confirmSignOut() async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await _showConfirmDialog(
      icon: Icons.logout_rounded,
      iconColor: AppPalette.rust,
      title: l10n.signOutDialogTitle,
      message: l10n.confirmSignOutMessage,
      confirmLabel: l10n.signOutDialogTitle,
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
        backgroundColor: AppTheme.colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppTheme.borderColor(context)),
            boxShadow: [BoxShadow(color: AppTheme.colors.black.withValues(alpha: 0.08), blurRadius: 24)],
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
                      child: Text(AppLocalizations.of(context)!.cancel.toUpperCase(),
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
                              color: AppTheme.colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
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
              color: AppTheme.colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))
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
      fontSize: 13,
      fontWeight: FontWeight.w700,
      color: AppTheme.textPrimary(context),
    ),
  );
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
        boxShadow: [BoxShadow(color: AppTheme.colors.black.withValues(alpha: 0.06), blurRadius: 16)],
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
