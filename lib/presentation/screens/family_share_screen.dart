import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/oracle_ui_system.dart';
import 'package:flutter/services.dart';
import '../../data/models/family_share_link.dart';

class FamilyShareScreen extends ConsumerStatefulWidget {
  const FamilyShareScreen({super.key});

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

  @override
  void initState() {
    super.initState();
    _startWatchingLinks();
    _expiryTimer = Timer.periodic(const Duration(seconds: 60), (_) => _checkAndCleanExpiredLinks());
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
    _linksSubscription = FirebaseFirestore.instance
        .collection('family_share_links')
        .where('touristId', isEqualTo: uid)
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
    }, onError: (e) {
      debugPrint("Error fetching share links: $e");
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
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // Unambiguous charset
    final random = Random.secure();
    return List.generate(8, (index) => chars[random.nextInt(chars.length)]).join();
  }

  void _generateLink() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("⚠️ Please enter a recipient name."),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.redAccent,
      ));
      return;
    }

    final token = _generateSecureToken();
    final now = DateTime.now();
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'current_user';
    final shareId = token;

    final newLink = FamilyShareLink(
      shareId: shareId,
      touristId: uid,
      sessionId: 'session_active',
      recipientName: name,
      shareToken: token,
      expiresAt: now.add(Duration(hours: _selectedHours)),
      permissions: Map<String, bool>.from(_permissions),
    );

    // Persist to Firestore
    FirebaseFirestore.instance
        .collection('family_share_links')
        .doc(shareId)
        .set(newLink.toJson());

    setState(() {
      if (!_activeLinks.any((l) => l.shareId == newLink.shareId)) {
        _activeLinks.insert(0, newLink);
      }
    });

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text("✅ Mission link generated for \"$name\"!"),
      behavior: SnackBarBehavior.floating,
      backgroundColor: const Color(0xFF00E676),
    ));

    _nameController.clear();
    _selectedHours = 4;
    _permissions.updateAll((key, value) => true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: OracleUI.auraBackground(
        child: CustomScrollView(
          slivers: [
            _buildAppBar(),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHero(),
                    const SizedBox(height: 48),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("ACTIVE LINKS", style: GoogleFonts.inter(color: AppTheme.textSecondary(context), fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 2)),
                        TextButton.icon(
                          onPressed: _showCreateLinkSheet,
                          icon: const Icon(Icons.add_rounded, color: Color(0xFF00E676)),
                          label: Text("NEW", style: GoogleFonts.inter(color: const Color(0xFF00E676), fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_activeLinks.isEmpty) _buildEmptyState() else ..._activeLinks.map((l) => _buildLinkCard(l)),
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

  Widget _buildAppBar() {
    return SliverAppBar(
      floating: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: OracleUI.neonText(
        "COORDINATION HUB",
        style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 4, color: AppTheme.textPrimary(context)),
      ),
    );
  }

  Widget _buildHero() {
    return OracleUI.premiumGlassCard(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const Icon(Icons.hub_rounded, color: Color(0xFF00E676), size: 48),
          const SizedBox(height: 24),
          Text(
            "Share your mission status with trusted contacts.",
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(color: AppTheme.textPrimary(context), fontSize: 18, fontWeight: FontWeight.bold, height: 1.4),
          ),
          const SizedBox(height: 12),
          Text(
            "Family and friends can track your live location, guide status, and safety signals through a secure link.",
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: AppTheme.textSecondary(context), fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return OracleUI.glassContainer(
      padding: const EdgeInsets.all(48),
      borderRadius: BorderRadius.circular(32),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.link_off_rounded, color: AppTheme.textSecondary(context).withValues(alpha: 0.3), size: 48),
            const SizedBox(height: 24),
            Text("No active sharing links found.", style: GoogleFonts.inter(color: AppTheme.textSecondary(context), fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildLinkCard(FamilyShareLink link) {
    final isExpired = link.isExpired || !link.isActive;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Opacity(
        opacity: isExpired ? 0.5 : 1.0,
        child: OracleUI.glassContainer(
          padding: const EdgeInsets.all(24),
          borderRadius: BorderRadius.circular(24),
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
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: Colors.redAccent.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.redAccent)),
                            child: Text("EXPIRED", style: GoogleFonts.inter(color: Colors.redAccent, fontSize: 9, fontWeight: FontWeight.bold)),
                          ),
                        ] else if (link.viewCount > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: const Color(0xFF00E676).withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFF00E676))),
                            child: Text("VIEWED ${link.viewCount}X", style: GoogleFonts.inter(color: const Color(0xFF00E676), fontSize: 9, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(isExpired ? "Status: No longer valid" : "Expires: ${link.expiresAt.hour}:${link.expiresAt.minute.toString().padLeft(2, '0')}", style: GoogleFonts.inter(color: AppTheme.textSecondary(context).withValues(alpha: 0.7), fontSize: 11)),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.copy_rounded, color: isExpired ? AppTheme.textSecondary(context).withValues(alpha: 0.3) : AppTheme.textSecondary(context)),
                onPressed: isExpired ? null : () {
                  Clipboard.setData(ClipboardData(
                    text: 'Family Share Code: ${link.shareToken}\nJoin link: https://hiddengems.lk/join/${link.shareToken}',
                  ));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text("📋 Invite code copied to clipboard!"),
                    behavior: SnackBarBehavior.floating,
                  ));
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: Theme.of(context).cardColor,
                      title: Text("Remove Link?",
                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppTheme.textPrimary(context))),
                      content: Text("This will revoke \"${link.recipientName}\"'s shared access.",
                          style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary(context))),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: Text("Cancel", style: TextStyle(color: AppTheme.textSecondary(context))),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            FirebaseFirestore.instance
                                .collection('family_share_links')
                                .doc(link.shareId)
                                .delete().catchError((_) {});
                            setState(() => _activeLinks.remove(link));
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text("Link for \"${link.recipientName}\" removed."),
                              behavior: SnackBarBehavior.floating,
                            ));
                          },
                          child: const Text("Remove", style: TextStyle(color: Colors.redAccent)),
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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: OracleUI.glassContainer(
            padding: const EdgeInsets.all(32),
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(40), topRight: Radius.circular(40)),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  OracleUI.neonText(
                    "CREATE SHARE LINK",
                    style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 4, color: AppTheme.textPrimary(context)),
                  ),
                  const SizedBox(height: 32),
                  _buildTextField("RECIPIENT NAME", "E.g. Mom, Dad, Home Office", _nameController),
                  const SizedBox(height: 24),
                  Text("EXPIRY", style: GoogleFonts.inter(color: AppTheme.textSecondary(context), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildTimeOption("4 HOURS", _selectedHours == 4, () => setSheetState(() => _selectedHours = 4)),
                      const SizedBox(width: 12),
                      _buildTimeOption("12 HOURS", _selectedHours == 12, () => setSheetState(() => _selectedHours = 12)),
                      const SizedBox(width: 12),
                      _buildTimeOption("24 HOURS", _selectedHours == 24, () => setSheetState(() => _selectedHours = 24)),
                    ],
                  ),
                  const SizedBox(height: 32),
                  _buildPermissionRow("SHARE LIVE STATUS", _permissions['show_status']!, (v) => setSheetState(() => _permissions['show_status'] = v)),
                  _buildPermissionRow("SHARE GUIDE IDENTITY", _permissions['show_identity']!, (v) => setSheetState(() => _permissions['show_identity'] = v)),
                  _buildPermissionRow("SHARE MEETING POINT", _permissions['show_meeting_point']!, (v) => setSheetState(() => _permissions['show_meeting_point'] = v)),
                  _buildPermissionRow("SHARE EMERGENCY ALERTS", _permissions['show_emergency']!, (v) => setSheetState(() => _permissions['show_emergency'] = v)),
                  const SizedBox(height: 48),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _generateLink,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00E676),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: Text("GENERATE MISSION LINK", style: GoogleFonts.outfit(fontWeight: FontWeight.w900, letterSpacing: 2)),
                    ),
                  ),
                  const SizedBox(height: 40),
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
        Text(label, style: GoogleFonts.inter(color: AppTheme.textSecondary(context), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
        const SizedBox(height: 12),
        OracleUI.glassContainer(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          borderRadius: BorderRadius.circular(16),
          child: TextField(
            controller: controller,
            style: TextStyle(color: AppTheme.textPrimary(context)),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.inter(color: AppTheme.textSecondary(context).withValues(alpha: 0.5), fontSize: 13),
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
          height: 50,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF00E676).withValues(alpha: 0.1) : AppTheme.borderColor(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isSelected ? const Color(0xFF00E676) : AppTheme.borderColor(context)),
          ),
          child: Text(label, style: GoogleFonts.inter(color: isSelected ? AppTheme.textPrimary(context) : AppTheme.textSecondary(context), fontSize: 11, fontWeight: FontWeight.bold)),
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
          Text(label, style: GoogleFonts.inter(color: AppTheme.textPrimary(context), fontSize: 14)),
          Switch(
            value: value,
            activeThumbColor: const Color(0xFF00E676),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

