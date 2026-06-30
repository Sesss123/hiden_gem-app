import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/oracle_ui_system.dart';
import 'package:flutter/services.dart';
import '../../data/models/family_share_link.dart';

class FamilyShareScreen extends ConsumerStatefulWidget {
  const FamilyShareScreen({super.key});

  @override
  ConsumerState<FamilyShareScreen> createState() => _FamilyShareScreenState();
}

class _FamilyShareScreenState extends ConsumerState<FamilyShareScreen> {
  final List<FamilyShareLink> _activeLinks = []; // In prod, fetch from Firestore

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
                        Text("ACTIVE LINKS", style: GoogleFonts.inter(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 2)),
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
        style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 4, color: Colors.white),
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
            style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, height: 1.4),
          ),
          const SizedBox(height: 12),
          Text(
            "Family and friends can track your live location, guide status, and safety signals through a secure link.",
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: Colors.white38, fontSize: 13, height: 1.5),
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
            const Icon(Icons.link_off_rounded, color: Colors.white12, size: 48),
            const SizedBox(height: 24),
            Text("No active sharing links found.", style: GoogleFonts.inter(color: Colors.white24, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildLinkCard(FamilyShareLink link) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: OracleUI.glassContainer(
        padding: const EdgeInsets.all(24),
        borderRadius: BorderRadius.circular(24),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(link.recipientName, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  Text("Expires: ${link.expiresAt.hour}:${link.expiresAt.minute}", style: GoogleFonts.inter(color: Colors.white24, fontSize: 11)),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.copy_rounded, color: Colors.white38),
              onPressed: () {
                // Copy invite code to clipboard (Bug #33)
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
                // Delete confirmation (Bug #33)
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text("Remove Link?",
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                    content: Text("This will revoke \"${link.recipientName}\"'s shared access.",
                        style: GoogleFonts.inter(fontSize: 13)),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text("Cancel"),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(ctx);
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
    ).animate().fadeIn().slideY(begin: 0.1);
  }

  void _showCreateLinkSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => OracleUI.glassContainer(
        padding: const EdgeInsets.all(32),
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(40), topRight: Radius.circular(40)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            OracleUI.neonText(
              "CREATE SHARE LINK",
              style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 4, color: Colors.white),
            ),
            const SizedBox(height: 32),
            _buildTextField("RECIPIENT NAME", "E.g. Mom, Dad, Home Office"),
            const SizedBox(height: 24),
            Text("EXPIRY", style: GoogleFonts.inter(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildTimeOption("4 HOURS", true),
                const SizedBox(width: 12),
                _buildTimeOption("12 HOURS", false),
                const SizedBox(width: 12),
                _buildTimeOption("24 HOURS", false),
              ],
            ),
            const SizedBox(height: 32),
            _buildPermissionRow("SHARE LIVE STATUS", true),
            _buildPermissionRow("SHARE GUIDE IDENTITY", true),
            _buildPermissionRow("SHARE MEETING POINT", true),
            _buildPermissionRow("SHARE EMERGENCY ALERTS", true),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
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
    );
  }

  Widget _buildTextField(String label, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
        const SizedBox(height: 12),
        OracleUI.glassContainer(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          borderRadius: BorderRadius.circular(16),
          child: TextField(
            style: const TextStyle(color: Colors.white70),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.inter(color: Colors.white10, fontSize: 13),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeOption(String label, bool isSelected) {
    return Expanded(
      child: Container(
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00E676).withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? const Color(0xFF00E676) : Colors.white.withValues(alpha: 0.05)),
        ),
        child: Text(label, style: GoogleFonts.inter(color: isSelected ? Colors.white : Colors.white38, fontSize: 11, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildPermissionRow(String label, bool value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(color: Colors.white70, fontSize: 14)),
          Switch(
            value: value,
            activeThumbColor: const Color(0xFF00E676),
            onChanged: (v) {},
          ),
        ],
      ),
    );
  }
}
