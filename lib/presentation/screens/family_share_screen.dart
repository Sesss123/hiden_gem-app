import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/oracle_ui_system.dart';
import 'package:flutter/services.dart';
import '../../data/models/family_share_link.dart';
import '../../data/repositories/tour_session_repository.dart';
import '../../core/config/app_config.dart';
import '../../core/services/family_share_sync_service.dart';
import 'package:hidden_gems_sl/core/utils/secure_logger.dart';
import '../../l10n/app_localizations.dart';

class FamilyShareScreen extends ConsumerStatefulWidget {
  final String? sessionId;
  const FamilyShareScreen({super.key, this.sessionId});

  @override
  ConsumerState<FamilyShareScreen> createState() => _FamilyShareScreenState();
}

class _FamilyShareScreenState extends ConsumerState<FamilyShareScreen> {
  final List<FamilyShareLink> _activeLinks = [];
  final TextEditingController _nameController = TextEditingController();
  int _selectedHours = 4;
  final Map<String, bool> _permissions = {
    'show_status': true,
    'show_identity': true,
    'show_meeting_point': true,
    'show_emergency': true,
  };

  Timer? _expiryTimer;
  StreamSubscription? _linksSubscription;
  String? _resolvedSessionId;
  bool _resolvingSession = false;

  @override
  void initState() {
    super.initState();
    _resolvedSessionId = widget.sessionId;
    if (_resolvedSessionId == null) {
      _resolveActiveSession();
    }
    _startWatchingLinks();
    _expiryTimer = Timer.periodic(const Duration(seconds: 60), (_) => _checkAndCleanExpiredLinks());
  }

  Future<void> _resolveActiveSession() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    setState(() => _resolvingSession = true);
    try {
      final session = await TourSessionRepository().getActiveSessionForTourist(uid);
      if (mounted) {
        setState(() {
          _resolvedSessionId = session?.sessionId;
          _resolvingSession = false;
        });
      }
    } catch (e, st) {
      SecureLogger.error("Failed to resolve active session", e, st, "FamilyShare");
      if (mounted) setState(() => _resolvingSession = false);
    }
  }

  @override
  void dispose() {
    _expiryTimer?.cancel();
    _linksSubscription?.cancel();
    _nameController.dispose();
    super.dispose();
  }

  void _startWatchingLinks() {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'current_user';
    // Firestore cost fix: capped — a tourist realistically has a handful of
    // active share links at once (also enforced client-side by
    // _maxActiveLinks), not an unbounded history; this listener doesn't
    // need to re-deliver every link ever created.
    _linksSubscription = FirebaseFirestore.instance
        .collection('family_share_links')
        .where('touristId', isEqualTo: uid)
        .limit(50)
        .snapshots()
        .listen((snapshot) {
      final links = snapshot.docs
          .map((doc) => FamilyShareLink.fromJson(doc.data()))
          .toList();
      links.sort((a, b) => b.expiresAt.compareTo(a.expiresAt));
      if (mounted) {
        setState(() {
          _activeLinks
            ..clear()
            ..addAll(links);
        });
        _checkAndCleanExpiredLinks();
      }
    }, onError: (e, st) {
      SecureLogger.error("Error fetching share links", e, st, "FamilyShare");
    });
  }

  void _checkAndCleanExpiredLinks() {
    final now = DateTime.now();
    final toRemove = <FamilyShareLink>[];
    bool needsSetState = false;

    for (final link in _activeLinks) {
      if (link.isExpired) {
        needsSetState = true;
        // 1. If still marked active in Firestore, set isActive to false immediately
        if (link.isActive) {
          FirebaseFirestore.instance
              .collection('family_share_links')
              .doc(link.shareId)
              .update({'isActive': false}).catchError((_) {});
        }
        // 2. If expired more than 5 minutes ago (grace period), remove and delete from Firestore
        if (now.difference(link.expiresAt).inMinutes >= 5) {
          toRemove.add(link);
          FirebaseFirestore.instance
              .collection('family_share_links')
              .doc(link.shareId)
              .delete().catchError((_) {});
          const FlutterSecureStorage()
              .delete(key: 'family_share_key_${link.shareId}')
              .catchError((_) {});
          FamilyShareSyncService.instance.unwatchLink(link.shareId);
        }
      }
    }

    if (toRemove.isNotEmpty) {
      _activeLinks.removeWhere((l) => toRemove.contains(l));
      needsSetState = true;
    }

    if (needsSetState && mounted) {
      setState(() {});
    }
  }

  String _generateSecureToken() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // Unambiguous charset, 33 symbols
    final random = Random.secure();
    // 26 chars * log2(33) =~ 131 bits of entropy -- this token doubles as
    // the Firestore doc ID and the public /join/{token} URL slug, so it
    // must be strong enough to resist brute-force guessing/enumeration.
    return List.generate(26, (index) => chars[random.nextInt(chars.length)]).join();
  }

  /// Per-link symmetric key for E2EE of the shared status blob (see
  /// _generateLink). 32 raw random bytes, base64url-encoded so it survives
  /// unescaped in a URL fragment and decodes unambiguously on both the Dart
  /// and browser (WebCrypto) sides.
  String _generateLinkKey() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64Url.encode(bytes);
  }

  // Prevents unbounded link spam (each link is a public, anonymously
  // readable tracking token while active — see firestore.rules) — a normal
  // tourist sharing with a few family members never needs more than this
  // many simultaneously active links.
  static const int _maxActiveLinks = 10;

  void _generateLink() async {
    final l10n = AppLocalizations.of(context)!;
    final name = _nameController.text.trim();
    if (_activeLinks.where((l) => !l.isExpired).length >= _maxActiveLinks) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(l10n.familyShareLinkLimitReached(_maxActiveLinks)),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppTheme.colors.redAccent,
      ));
      return;
    }
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(l10n.familyShareRecipientNameRequired),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppTheme.colors.redAccent,
      ));
      return;
    }
    if (_resolvedSessionId == null || _resolvedSessionId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(l10n.familyShareNoActiveSessionError),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppTheme.colors.redAccent,
      ));
      return;
    }

    final token = _generateSecureToken();
    final now = DateTime.now();
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'current_user';
    final shareId = token;
    final permissions = Map<String, bool>.from(_permissions);

    final newLink = FamilyShareLink(
      shareId: shareId,
      touristId: uid,
      sessionId: _resolvedSessionId ?? '',
      recipientName: name,
      shareToken: token,
      expiresAt: now.add(Duration(hours: _selectedHours)),
      permissions: permissions,
    );

    // E2EE: this key is only ever kept on the tourist's device (secure
    // storage) and embedded in the share URL's fragment -- it must never be
    // written to Firestore or seen by the Laravel join-page backend.
    final linkKey = _generateLinkKey();
    await const FlutterSecureStorage().write(
      key: 'family_share_key_$shareId',
      value: linkKey,
    );

    final doc = newLink.toJson();
    doc['encryptedStatus'] = await FamilyShareSyncService.instance
        .buildEncryptedStatus(sessionId: newLink.sessionId, permissions: permissions, linkKey: linkKey);

    // Persist to Firestore
    FirebaseFirestore.instance
        .collection('family_share_links')
        .doc(shareId)
        .set(doc);

    // Make sure the live sync loop picks up this link immediately (it
    // otherwise only re-scans on its own family_share_links listener tick).
    FamilyShareSyncService.instance.watchLink(newLink.copyWith(permissions: permissions));

    if (!mounted) return;
    setState(() {
      if (!_activeLinks.any((l) => l.shareId == newLink.shareId)) {
        _activeLinks.insert(0, newLink);
      }
    });

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(l10n.familyShareLinkGeneratedSuccess(name)),
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppTheme.colors.primary,
    ));

    _nameController.clear();
    _selectedHours = 4;
    _permissions.updateAll((key, value) => true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppTheme.colors.transparent,
      body: OracleUI.auraBackground(
        child: CustomScrollView(
          slivers: [
            _buildAppBar(l10n),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHero(l10n),
                    if (!_resolvingSession && _resolvedSessionId == null) ...[
                      const SizedBox(height: 16),
                      _buildNoActiveSessionNotice(l10n),
                    ],
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(l10n.familyShareActiveLinksTitle, style: GoogleFonts.inter(color: AppTheme.textPrimary(context), fontSize: 14, fontWeight: FontWeight.w700)),
                        GestureDetector(
                          onTap: _showCreateLinkSheet,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Text(l10n.familyShareNewLinkButton, style: GoogleFonts.inter(color: AppTheme.colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_activeLinks.isEmpty) _buildEmptyState(l10n) else ..._activeLinks.map((l) => _buildLinkCard(l, l10n)),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(AppLocalizations l10n) {
    return SliverAppBar(
      floating: true,
      backgroundColor: AppTheme.colors.transparent,
      elevation: 0,
      title: Text(
        l10n.familyShareAppBarTitle,
        style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.5, color: AppTheme.textPrimary(context)),
      ),
    );
  }

  Widget _buildHero(AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary,
            AppPalette.rustDim,
          ],
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.hub_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.familyShareHeroSubtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: AppTheme.colors.white, fontSize: 14, fontWeight: FontWeight.w600, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildNoActiveSessionNotice(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.colors.amberAccent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.colors.amberAccent.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: AppTheme.colors.amberAccent, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l10n.familyShareNoActiveSessionNotice,
              style: GoogleFonts.inter(color: AppTheme.textSecondary(context), fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: AppTheme.colors.black.withValues(alpha: 0.05), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.link_off_rounded, color: AppTheme.textSecondary(context).withValues(alpha: 0.4), size: 40),
            const SizedBox(height: 20),
            Text(l10n.familyShareEmptyStateMessage, style: GoogleFonts.inter(color: AppTheme.textSecondary(context), fontSize: 13, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildLinkCard(FamilyShareLink link, AppLocalizations l10n) {
    final isExpired = link.isExpired || !link.isActive;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Opacity(
        opacity: isExpired ? 0.5 : 1.0,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(color: AppTheme.colors.black.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, 6)),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(link.recipientName, style: GoogleFonts.outfit(color: isExpired ? AppTheme.textSecondary(context) : AppTheme.textPrimary(context), fontWeight: FontWeight.bold, fontSize: 16)),
                        if (isExpired) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: AppTheme.colors.redAccent, borderRadius: BorderRadius.circular(100)),
                            child: Text(l10n.familyShareExpiredBadge, style: GoogleFonts.inter(color: AppTheme.colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
                          ),
                        ] else if (link.viewCount > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, borderRadius: BorderRadius.circular(100)),
                            child: Text(l10n.familyShareViewedCountBadge(link.viewCount), style: GoogleFonts.inter(color: AppTheme.colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(isExpired ? l10n.familyShareLinkNoLongerValid : l10n.familyShareLinkExpiresAt('${link.expiresAt.hour}:${link.expiresAt.minute.toString().padLeft(2, '0')}'), style: GoogleFonts.inter(color: AppTheme.textSecondary(context), fontSize: 11, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.copy_rounded, color: isExpired ? AppTheme.textSecondary(context).withValues(alpha: 0.3) : AppTheme.textSecondary(context)),
                onPressed: isExpired ? null : () async {
                  // linkKey never lives on FamilyShareLink/Firestore -- it's
                  // looked up from secure storage and only ever leaves the
                  // device inside the URL fragment (which browsers never
                  // send to a server), so the decryption key stays out of
                  // reach of Firestore, Laravel, and any DB leak.
                  final linkKey = await const FlutterSecureStorage()
                      .read(key: 'family_share_key_${link.shareId}');
                  final url = linkKey != null
                      ? '${AppConfig.webBaseUrl}/join/${link.shareToken}#k=$linkKey'
                      : '${AppConfig.webBaseUrl}/join/${link.shareToken}';
                  Clipboard.setData(ClipboardData(text: 'Track my trip live: $url'));
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(l10n.familyShareCopyLinkSnackbar),
                    behavior: SnackBarBehavior.floating,
                  ));
                },
              ),
              IconButton(
                icon: Icon(Icons.delete_outline_rounded, color: AppTheme.colors.redAccent),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: Theme.of(context).cardColor,
                      title: Text(l10n.familyShareRemoveLinkDialogTitle,
                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppTheme.textPrimary(context))),
                      content: Text(l10n.familyShareRemoveLinkDialogBody(link.recipientName),
                          style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary(context))),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: Text(l10n.cancel, style: TextStyle(color: AppTheme.textSecondary(context))),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            FirebaseFirestore.instance
                                .collection('family_share_links')
                                .doc(link.shareId)
                                .delete().catchError((_) {});
                            const FlutterSecureStorage()
                                .delete(key: 'family_share_key_${link.shareId}')
                                .catchError((_) {});
                            FamilyShareSyncService.instance.unwatchLink(link.shareId);
                            setState(() => _activeLinks.remove(link));
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(l10n.familyShareLinkRemovedSnackbar(link.recipientName)),
                              behavior: SnackBarBehavior.floating,
                            ));
                          },
                          child: Text(l10n.familyShareRemoveButton, style: TextStyle(color: AppTheme.colors.redAccent)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }

  void _showCreateLinkSheet() {
    _nameController.clear();
    _selectedHours = 4;
    _permissions.updateAll((key, value) => true);
    final l10n = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.familyShareCreateSheetTitle,
                    style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.5, color: AppTheme.textPrimary(context)),
                  ),
                  const SizedBox(height: 28),
                  _buildTextField(l10n.familyShareRecipientNameLabel, l10n.familyShareRecipientNameHint, _nameController),
                  const SizedBox(height: 24),
                  Text(l10n.familyShareExpiryLabel, style: GoogleFonts.inter(color: AppTheme.textPrimary(context), fontSize: 12, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildTimeOption(l10n.familyShareDuration4Hours, _selectedHours == 4, () => setSheetState(() => _selectedHours = 4)),
                      const SizedBox(width: 12),
                      _buildTimeOption(l10n.familyShareDuration12Hours, _selectedHours == 12, () => setSheetState(() => _selectedHours = 12)),
                      const SizedBox(width: 12),
                      _buildTimeOption(l10n.familyShareDuration24Hours, _selectedHours == 24, () => setSheetState(() => _selectedHours = 24)),
                    ],
                  ),
                  const SizedBox(height: 28),
                  _buildPermissionRow(l10n.familyShareToggleStatusLabel, _permissions['show_status']!, (v) => setSheetState(() => _permissions['show_status'] = v)),
                  _buildPermissionRow(l10n.familyShareToggleIdentityLabel, _permissions['show_identity']!, (v) => setSheetState(() => _permissions['show_identity'] = v)),
                  _buildPermissionRow(l10n.familyShareToggleMeetingPointLabel, _permissions['show_meeting_point']!, (v) => setSheetState(() => _permissions['show_meeting_point'] = v)),
                  _buildPermissionRow(l10n.familyShareToggleEmergencyLabel, _permissions['show_emergency']!, (v) => setSheetState(() => _permissions['show_emergency'] = v)),
                  const SizedBox(height: 36),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _generateLink,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: AppTheme.colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                      ),
                      child: Text(l10n.familyShareGenerateLinkButton, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14)),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, String hint, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(color: AppTheme.textPrimary(context), fontSize: 12, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            color: AppTheme.surfaceMuted(context),
            borderRadius: BorderRadius.circular(14),
          ),
          child: TextField(
            controller: controller,
            style: TextStyle(color: AppTheme.textPrimary(context)),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.inter(color: AppTheme.textSecondary(context), fontSize: 13),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeOption(String label, bool isSelected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? Theme.of(context).colorScheme.primary : AppTheme.surfaceMuted(context),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(label, style: GoogleFonts.inter(color: isSelected ? AppTheme.colors.white : AppTheme.textSecondary(context), fontSize: 12, fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }

  Widget _buildPermissionRow(String label, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(color: AppTheme.textPrimary(context), fontSize: 13, fontWeight: FontWeight.w500)),
          Switch(
            value: value,
            activeThumbColor: Theme.of(context).colorScheme.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

