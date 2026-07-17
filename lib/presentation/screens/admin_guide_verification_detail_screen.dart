import 'package:hidden_gems_sl/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/oracle_ui_system.dart';
import '../../data/models/guide_application.dart';
import '../../data/models/guide_status.dart';
import '../../data/repositories/guide_application_repository.dart';
import '../widgets/cached_image.dart';
import '../../core/services/media_cache_manager.dart';
import '../../l10n/app_localizations.dart';

class AdminGuideVerificationDetailScreen extends StatefulWidget {
  final GuideApplication application;
  const AdminGuideVerificationDetailScreen({super.key, required this.application});

  @override
  State<AdminGuideVerificationDetailScreen> createState() => _AdminGuideVerificationDetailScreenState();
}

class _AdminGuideVerificationDetailScreenState extends State<AdminGuideVerificationDetailScreen> {
  final _repo = GuideApplicationRepository();
  final _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _review(GuideStatus status) async {
    final l10n = AppLocalizations.of(context)!;
    if (status == GuideStatus.rejected && _commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.rejectionReasonRequiredMessage)),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await _repo.reviewApplication(
        userId: widget.application.userId,
        status: status,
        adminComment: _commentController.text.trim().isEmpty ? null : _commentController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(status == GuideStatus.approved ? l10n.applicationApprovedNoticeMessage : l10n.applicationRejectedNoticeMessage)),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.reviewActionFailedMessage(e.toString()))),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final application = widget.application;

    return Scaffold(
      body: OracleUI.auraBackground(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor: AppTheme.colors.transparent,
              elevation: 0,
              pinned: true,
              title: Text(
                application.licenseNumber,
                style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 18, color: AppTheme.textPrimary(context)),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildApplicantInfo(l10n, application),
                    const SizedBox(height: 28),
                    Text(
                      l10n.licenseDocumentLabel,
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.textPrimary(context)),
                    ),
                    const SizedBox(height: 10),
                    _buildDocPreview(l10n, application.licenseDocUrl),
                    const SizedBox(height: 20),
                    Text(
                      l10n.nicDocumentLabel,
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.textPrimary(context)),
                    ),
                    const SizedBox(height: 10),
                    _buildDocPreview(l10n, application.nicDocUrl),
                    const SizedBox(height: 20),
                    Text(
                      l10n.selfiePhotoLabel,
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.textPrimary(context)),
                    ),
                    const SizedBox(height: 10),
                    _buildDocPreview(l10n, application.selfieDocUrl),
                    const SizedBox(height: 28),
                    _buildCommentField(l10n),
                    const SizedBox(height: 24),
                    _buildActionButtons(l10n),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApplicantInfo(AppLocalizations l10n, GuideApplication application) {
    final expiryStatus = _expiryStatus(application.licenseExpiryDate);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceMuted(context),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.applicantDetailsTitle,
            style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.textPrimary(context)),
          ),
          const SizedBox(height: 12),
          _infoRow(l10n.categoryLabel, application.category),
          const SizedBox(height: 8),
          _infoRow(l10n.bioLabel, application.bio),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _infoRow(l10n.licenseExpiryLabel, _formatExpiry(l10n, application.licenseExpiryDate))),
              if (expiryStatus != null) _expiryBadge(l10n, expiryStatus),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(color: AppTheme.textSecondary(context), fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text(value, style: GoogleFonts.inter(color: AppTheme.textPrimary(context), fontSize: 13)),
      ],
    );
  }

  String? _expiryStatus(DateTime? expiry) {
    if (expiry == null) return null;
    final now = DateTime.now();
    if (expiry.isBefore(now)) return 'expired';
    if (expiry.difference(now).inDays <= 30) return 'expiring_soon';
    return 'valid';
  }

  Widget _expiryBadge(AppLocalizations l10n, String status) {
    final Map<String, Color> colors = {
      'valid': AppTheme.colors.greenAccent,
      'expiring_soon': AppTheme.colors.amber,
      'expired': AppTheme.colors.redAccent,
    };
    final Map<String, String> labels = {
      'valid': l10n.expiryStatusValid,
      'expiring_soon': l10n.expiryStatusExpiringSoon,
      'expired': l10n.expiryStatusExpired,
    };
    final color = colors[status]!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(100)),
      child: Text(labels[status]!, style: GoogleFonts.inter(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
    );
  }

  String _formatExpiry(AppLocalizations l10n, DateTime? expiry) {
    if (expiry == null) return l10n.notProvidedLabel;
    return "${expiry.year}-${expiry.month.toString().padLeft(2, '0')}-${expiry.day.toString().padLeft(2, '0')}";
  }

  Widget _buildDocPreview(AppLocalizations l10n, String? url) {
    if (url == null || url.isEmpty) {
      return Container(
        width: double.infinity,
        height: 160,
        decoration: BoxDecoration(color: AppTheme.surfaceMuted(context), borderRadius: BorderRadius.circular(14)),
        child: Center(
          child: Text(l10n.noDocumentProvidedMessage, style: GoogleFonts.inter(color: AppTheme.textSecondary(context), fontSize: 12)),
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: CachedImage(
        url: url,
        width: double.infinity,
        height: 220,
        fit: BoxFit.cover,
        poolType: CachePoolType.full,
        errorWidget: Container(
          width: double.infinity,
          height: 220,
          color: AppTheme.surfaceMuted(context),
          child: Center(
            child: Text(l10n.imageFailedToLoadMessage, style: GoogleFonts.inter(color: AppTheme.textSecondary(context), fontSize: 12)),
          ),
        ),
      ),
    );
  }

  Widget _buildCommentField(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceMuted(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        controller: _commentController,
        maxLines: 3,
        style: TextStyle(color: AppTheme.textPrimary(context)),
        decoration: InputDecoration(
          hintText: l10n.adminCommentHint,
          hintStyle: TextStyle(color: AppTheme.textSecondary(context), fontSize: 13),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildActionButtons(AppLocalizations l10n) {
    if (widget.application.status != GuideStatus.pending) {
      return const SizedBox.shrink();
    }
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 52,
            child: OutlinedButton(
              onPressed: _isSubmitting ? null : () => _review(GuideStatus.rejected),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.colors.redAccent,
                side: BorderSide(color: AppTheme.colors.redAccent),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
              ),
              child: Text(l10n.rejectButtonLabel, style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : () => _review(GuideStatus.approved),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.colors.greenAccent,
                foregroundColor: AppTheme.colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
              ),
              child: _isSubmitting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(l10n.approveButtonLabel, style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
            ),
          ),
        ),
      ],
    );
  }
}
