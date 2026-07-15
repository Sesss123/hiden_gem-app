import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/tour_package.dart';
import '../../data/repositories/package_repository.dart';
import '../../l10n/app_localizations.dart';

/// Custom Tour Packages — Pro/Elite guide benefit (gated at the profile hub
/// entry point). Lets a guide offer multiple priced tour options instead of
/// a single flat hourly rate; TourPackage model + Firestore rules already
/// existed with zero UI before this screen.
class GuidePackagesScreen extends ConsumerStatefulWidget {
  const GuidePackagesScreen({super.key});

  @override
  ConsumerState<GuidePackagesScreen> createState() => _GuidePackagesScreenState();
}

class _GuidePackagesScreenState extends ConsumerState<GuidePackagesScreen> {
  bool _isLoading = true;
  List<TourPackage> _packages = [];

  @override
  void initState() {
    super.initState();
    _loadPackages();
  }

  Future<void> _loadPackages() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _isLoading = false);
      return;
    }
    final packages = await PackageRepository().getPackagesByOwner(uid);
    if (mounted) {
      setState(() {
        _packages = packages;
        _isLoading = false;
      });
    }
  }

  Future<void> _deletePackage(String packageId) async {
    await PackageRepository().deletePackage(packageId);
    _loadPackages();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, size: 20, color: AppTheme.textPrimary(context)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(AppLocalizations.of(context)!.tourPackagesTitle, style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 20, letterSpacing: -0.5, color: AppTheme.textPrimary(context))),
        centerTitle: false,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).colorScheme.primary,
        onPressed: () async {
          final created = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => const _PackageEditorScreen()));
          if (created == true) _loadPackages();
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary))
          : _packages.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                  physics: const BouncingScrollPhysics(),
                  itemCount: _packages.length,
                  itemBuilder: (context, index) => _buildPackageCard(_packages[index]),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.local_offer_outlined, size: 56, color: AppTheme.textSecondary(context).withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text(AppLocalizations.of(context)!.noPackagesYetTitle, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary(context))),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.noPackagesYetSubtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary(context)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPackageCard(TourPackage package) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: AppTheme.colors.black.withValues(alpha: 0.05), blurRadius: 14, offset: const Offset(0, 5))],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () async {
          final updated = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => _PackageEditorScreen(existing: package)));
          if (updated == true) _loadPackages();
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(package.title, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary(context)))),
                        if (!package.isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: AppTheme.surfaceMuted(context), borderRadius: BorderRadius.circular(100)),
                            child: Text(l10n.inactiveLabel, style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, color: AppTheme.textSecondary(context))),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.durationGuestsLabel(package.durationHours.toString(), package.maxGuests.toString()),
                      style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary(context)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.currencyPriceLabel(package.currency, package.price.toStringAsFixed(0)),
                      style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.primary),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.delete_outline_rounded, color: Theme.of(context).colorScheme.error, size: 20),
                onPressed: () => _deletePackage(package.packageId),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}

class _PackageEditorScreen extends StatefulWidget {
  final TourPackage? existing;
  const _PackageEditorScreen({this.existing});

  @override
  State<_PackageEditorScreen> createState() => _PackageEditorScreenState();
}

class _PackageEditorScreenState extends State<_PackageEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _durationController = TextEditingController(text: '4');
  final _maxGuestsController = TextEditingController(text: '4');
  final _priceController = TextEditingController();
  final _inclusionsController = TextEditingController();
  String _currency = 'USD';
  bool _includesVehicle = false;
  bool _isActive = true;
  bool _isSaving = false;

  final List<String> _currencies = ['USD', 'LKR', 'EUR', 'GBP'];

  @override
  void initState() {
    super.initState();
    final p = widget.existing;
    if (p != null) {
      _titleController.text = p.title;
      _descriptionController.text = p.description;
      _durationController.text = p.durationHours.toString();
      _maxGuestsController.text = p.maxGuests.toString();
      _priceController.text = p.price.toStringAsFixed(0);
      _currency = p.currency;
      _includesVehicle = p.includesVehicle;
      _isActive = p.isActive;
      _inclusionsController.text = p.inclusions.join(', ');
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    _maxGuestsController.dispose();
    _priceController.dispose();
    _inclusionsController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => _isSaving = true);
    try {
      final now = DateTime.now();
      final inclusions = _inclusionsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      final package = TourPackage(
        packageId: widget.existing?.packageId ?? '',
        ownerId: uid,
        ownerType: 'guide',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        durationHours: int.tryParse(_durationController.text) ?? 4,
        maxGuests: int.tryParse(_maxGuestsController.text) ?? 4,
        price: double.tryParse(_priceController.text) ?? 0.0,
        currency: _currency,
        includesVehicle: _includesVehicle,
        inclusions: inclusions,
        isActive: _isActive,
        isFeatured: widget.existing?.isFeatured ?? false,
        bookingsCount: widget.existing?.bookingsCount ?? 0,
        createdAt: widget.existing?.createdAt ?? now,
        updatedAt: now,
      );

      if (widget.existing == null) {
        await PackageRepository().createPackage(package);
      } else {
        await PackageRepository().updatePackage(package);
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.failedToSavePackageMessage(e.toString())), backgroundColor: Theme.of(context).colorScheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
          widget.existing == null ? l10n.newPackageTitle : l10n.editPackageTitle,
          style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 18, color: AppTheme.textPrimary(context)),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            physics: const BouncingScrollPhysics(),
            children: [
              _buildTextField(controller: _titleController, label: l10n.packageTitleLabel, hint: l10n.packageTitleHint, validator: (v) => v == null || v.isEmpty ? l10n.requiredFieldMessage : null),
              const SizedBox(height: 16),
              _buildTextField(controller: _descriptionController, label: l10n.descriptionLabel, hint: l10n.packageDescriptionHint, maxLines: 3),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildTextField(controller: _durationController, label: l10n.durationHoursLabel, hint: '4', keyboardType: TextInputType.number)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildTextField(controller: _maxGuestsController, label: l10n.maxGuestsLabel, hint: '4', keyboardType: TextInputType.number)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: _buildTextField(controller: _priceController, label: l10n.priceLabel, hint: '150', keyboardType: TextInputType.number, validator: (v) => v == null || v.isEmpty ? l10n.requiredFieldMessage : null),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _currency,
                      items: _currencies.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (v) => setState(() => _currency = v ?? 'USD'),
                      decoration: InputDecoration(labelText: l10n.currencyLabel, border: OutlineInputBorder(borderRadius: BorderRadius.circular(14))),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildTextField(controller: _inclusionsController, label: l10n.inclusionsLabel, hint: l10n.inclusionsHint),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(color: AppTheme.surfaceMuted(context), borderRadius: BorderRadius.circular(16)),
                child: SwitchListTile(
                  title: Text(l10n.includesVehicleLabel, style: GoogleFonts.outfit(color: AppTheme.textPrimary(context), fontWeight: FontWeight.w600)),
                  value: _includesVehicle,
                  activeThumbColor: Theme.of(context).colorScheme.primary,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (val) => setState(() => _includesVehicle = val),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(color: AppTheme.surfaceMuted(context), borderRadius: BorderRadius.circular(16)),
                child: SwitchListTile(
                  title: Text(l10n.activeBookableLabel, style: GoogleFonts.outfit(color: AppTheme.textPrimary(context), fontWeight: FontWeight.w600)),
                  value: _isActive,
                  activeThumbColor: Theme.of(context).colorScheme.primary,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (val) => setState(() => _isActive = val),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Theme.of(context).colorScheme.onPrimary))
                      : Text(l10n.savePackageButton, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      style: GoogleFonts.inter(color: AppTheme.textPrimary(context)),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: GoogleFonts.inter(color: AppTheme.textSecondary(context)),
        hintStyle: GoogleFonts.inter(color: AppTheme.textSecondary(context).withValues(alpha: 0.6)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        filled: true,
        fillColor: AppTheme.surfaceMuted(context),
      ),
    );
  }
}
