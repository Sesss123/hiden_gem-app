import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/operator_account.dart';
import '../../data/repositories/operator_repository.dart';
import '../../data/repositories/marketplace_repository.dart';
import '../widgets/cached_image.dart';
import 'package:hidden_gems_sl/core/utils/secure_logger.dart';
import '../../l10n/app_localizations.dart';

/// Elite-tier "Manage team" screen — Team Management + Operator Dashboard +
/// White-label Branding folded into one screen with three tabs, reusing the
/// guide's own account as the operator (no separate account type). Lazily
/// creates the guide's OperatorAccount document on first open.
class OperatorDashboardScreen extends ConsumerStatefulWidget {
  const OperatorDashboardScreen({super.key});

  @override
  ConsumerState<OperatorDashboardScreen> createState() => _OperatorDashboardScreenState();
}

class _OperatorDashboardScreenState extends ConsumerState<OperatorDashboardScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  OperatorAccount? _operator;
  int _tabIndex = 0;

  final _inviteController = TextEditingController();
  final _companyNameController = TextEditingController();
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadOrCreateOperator();
  }

  @override
  void dispose() {
    _inviteController.dispose();
    _companyNameController.dispose();
    super.dispose();
  }

  Future<void> _loadOrCreateOperator() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final repo = OperatorRepository();
      var account = await repo.getOperatorByOwner(user.uid);
      account ??= await repo.createOperatorAccount(
        ownerId: user.uid,
        displayName: user.displayName ?? 'My tour company',
        supportEmail: user.email ?? '',
      );

      if (mounted) {
        setState(() {
          _operator = account;
          _companyNameController.text = account!.companyName;
        });
      }
    } catch (e, st) {
      SecureLogger.error("Error loading operator account", e, st, "OperatorDashboard");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _inviteGuide() async {
    final guideId = _inviteController.text.trim();
    if (guideId.isEmpty || _operator == null) return;

    setState(() => _isSaving = true);
    try {
      await OperatorRepository().inviteGuideToTeam(_operator!.operatorId, guideId);
      final refreshed = await OperatorRepository().getOperatorByOwner(_operator!.ownerUserId);
      if (mounted) {
        setState(() => _operator = refreshed);
        _inviteController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.guideAddedToTeamMessage), backgroundColor: AppTheme.colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.failedToInviteGuideMessage(e.toString())), backgroundColor: Theme.of(context).colorScheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _removeGuide(String guideId) async {
    if (_operator == null) return;
    setState(() => _isSaving = true);
    try {
      await OperatorRepository().removeGuideFromTeam(_operator!.operatorId, guideId);
      final refreshed = await OperatorRepository().getOperatorByOwner(_operator!.ownerUserId);
      if (mounted) setState(() => _operator = refreshed);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.failedToRemoveGuideMessage(e.toString())), backgroundColor: Theme.of(context).colorScheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _pickAndUploadLogo() async {
    if (_operator == null) return;
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 75);
      if (image == null) return;

      setState(() => _isSaving = true);
      final repo = ref.read(marketplaceRepositoryProvider);
      final url = await repo.uploadListingPhoto(file: image, photoType: 'logo');

      if (url != null && mounted) {
        await _updateLogoUrl(url);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.failedToUploadLogoMessage(e.toString())), backgroundColor: Theme.of(context).colorScheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _updateLogoUrl(String url) async {
    if (_operator == null) return;
    await OperatorRepository().updateLogoUrl(_operator!.operatorId, url);
    final refreshed = await OperatorRepository().getOperatorByOwner(_operator!.ownerUserId);
    if (mounted) setState(() => _operator = refreshed);
  }

  Future<void> _updatePrimaryColor(Color color) async {
    if (_operator == null) return;
    setState(() => _isSaving = true);
    try {
      final branding = Map<String, String>.from(_operator!.brandingAssets);
      branding['primaryColor'] = '#${color.toARGB32().toRadixString(16).substring(2)}';
      await OperatorRepository().updateBranding(_operator!.operatorId, branding);
      final refreshed = await OperatorRepository().getOperatorByOwner(_operator!.ownerUserId);
      if (mounted) setState(() => _operator = refreshed);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Color get _brandColor {
    final hex = _operator?.brandingAssets['primaryColor'];
    if (hex == null || hex.isEmpty) return Theme.of(context).colorScheme.primary;
    try {
      return Color(int.parse('FF${hex.replaceFirst('#', '')}', radix: 16));
    } catch (_) {
      return Theme.of(context).colorScheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary)),
      );
    }

    if (_operator == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(title: Text(AppLocalizations.of(context)!.manageTeamTitle)),
        body: Center(child: Text(AppLocalizations.of(context)!.signInToManageTeamMessage, style: TextStyle(color: AppTheme.textSecondary(context)))),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, size: 20, color: AppTheme.textPrimary(context)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          AppLocalizations.of(context)!.manageTeamTitle,
          style: GoogleFonts.outfit(fontWeight: FontWeight.w800, letterSpacing: -0.5, fontSize: 20, color: AppTheme.textPrimary(context)),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildTabBar(),
            Expanded(
              child: IndexedStack(
                index: _tabIndex,
                children: [
                  _buildOverviewTab(),
                  _buildTeamTab(),
                  _buildBrandingTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    final l10n = AppLocalizations.of(context)!;
    final tabs = [l10n.tabOverview, l10n.tabTeam, l10n.tabBranding];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final isSelected = _tabIndex == i;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() => _tabIndex = i);
              },
              child: Container(
                margin: EdgeInsets.only(right: i < tabs.length - 1 ? 8 : 0),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? Theme.of(context).colorScheme.primary : AppTheme.surfaceMuted(context),
                  borderRadius: BorderRadius.circular(100),
                ),
                alignment: Alignment.center,
                child: Text(
                  tabs[i],
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Theme.of(context).colorScheme.onPrimary : AppTheme.textSecondary(context),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildOverviewTab() {
    final op = _operator!;
    final l10n = AppLocalizations.of(context)!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
      physics: const BouncingScrollPhysics(),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_brandColor, AppPalette.rustDim],
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(op.companyName, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.colors.white)),
              const SizedBox(height: 4),
              Text(l10n.eliteOperatorAccountLabel, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.colors.white.withValues(alpha: 0.85))),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: _buildOverviewStat(l10n.overviewStatTeamSize, '${op.teamGuideIds.length}')),
                  Expanded(child: _buildOverviewStat(l10n.overviewStatMissions, '${op.totalMissionsCompleted}')),
                  Expanded(child: _buildOverviewStat(l10n.overviewStatAvgRating, op.averageTeamRating.toStringAsFixed(1))),
                ],
              ),
            ],
          ),
        ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0),
      ],
    );
  }

  Widget _buildOverviewStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.colors.white)),
        Text(label, style: GoogleFonts.inter(fontSize: 10, color: AppTheme.colors.white.withValues(alpha: 0.7))),
      ],
    );
  }

  Widget _buildTeamTab() {
    final op = _operator!;
    final l10n = AppLocalizations.of(context)!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
      physics: const BouncingScrollPhysics(),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppTheme.surfaceMuted(context), borderRadius: BorderRadius.circular(16)),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _inviteController,
                  style: GoogleFonts.inter(color: AppTheme.textPrimary(context)),
                  decoration: InputDecoration(
                    hintText: l10n.guideUserIdToInviteHint,
                    hintStyle: GoogleFonts.inter(color: AppTheme.textSecondary(context), fontSize: 13),
                    border: InputBorder.none,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.person_add_alt_1_rounded, color: Theme.of(context).colorScheme.primary),
                onPressed: _isSaving ? null : _inviteGuide,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(l10n.teamMembersCountTitle(op.teamGuideIds.length), style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary(context))),
        const SizedBox(height: 12),
        ...op.teamGuideIds.map((guideId) => _buildTeamMemberTile(guideId, op.teamRoles[guideId] ?? l10n.roleMember)),
      ],
    );
  }

  Widget _buildTeamMemberTile(String guideId, String role) {
    final isOwner = guideId == _operator!.ownerUserId;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppTheme.colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: AppTheme.borderColor(context), child: Icon(Icons.person, size: 18, color: AppTheme.textPrimary(context))),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(guideId, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary(context)), overflow: TextOverflow.ellipsis),
                Text(role, style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textSecondary(context))),
              ],
            ),
          ),
          if (!isOwner)
            IconButton(
              icon: Icon(Icons.remove_circle_outline, color: Theme.of(context).colorScheme.error, size: 20),
              onPressed: _isSaving ? null : () => _removeGuide(guideId),
            ),
        ],
      ),
    );
  }

  Widget _buildBrandingTab() {
    final op = _operator!;
    final swatches = [AppPalette.rust, AppPalette.earth, AppPalette.heroOchre, AppPalette.success, const Color(0xFF3B82F6)];

    final l10n = AppLocalizations.of(context)!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
      physics: const BouncingScrollPhysics(),
      children: [
        Text(l10n.logoLabel, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary(context))),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _isSaving ? null : _pickAndUploadLogo,
          child: Container(
            height: 100,
            width: 100,
            decoration: BoxDecoration(
              color: AppTheme.surfaceMuted(context),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.borderColor(context)),
            ),
            child: op.logoUrl != null
                ? ClipRRect(borderRadius: BorderRadius.circular(20), child: CachedImage(url: op.logoUrl!, fit: BoxFit.cover))
                : Icon(Icons.add_photo_alternate_outlined, color: AppTheme.textSecondary(context)),
          ),
        ),
        const SizedBox(height: 28),
        Text(l10n.brandColorLabel, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary(context))),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          children: swatches.map((color) {
            final isSelected = _brandColor.toARGB32() == color.toARGB32();
            return GestureDetector(
              onTap: _isSaving ? null : () => _updatePrimaryColor(color),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: isSelected ? Border.all(color: AppTheme.textPrimary(context), width: 2.5) : null,
                ),
                child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 18) : null,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        Text(
          l10n.brandColorAppliedMessage,
          style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary(context)),
        ),
      ],
    );
  }
}
