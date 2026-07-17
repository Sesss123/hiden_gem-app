import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_theme.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/oracle_ui_system.dart';
import '../../data/models/guide_listing.dart';
import '../../data/models/guide_availability.dart';
import '../../data/repositories/marketplace_repository.dart';
import '../../data/repositories/guide_application_repository.dart';
import '../../data/services/subscription_service.dart';
import 'subscription_screen.dart';
import '../widgets/cached_image.dart';
import 'guide_availability_screen.dart';
import 'package:hidden_gems_sl/core/utils/secure_logger.dart';
import '../../l10n/app_localizations.dart';

class GuideListingEditorScreen extends ConsumerStatefulWidget {
  final bool embedded;
  const GuideListingEditorScreen({super.key, this.embedded = false});

  @override
  ConsumerState<GuideListingEditorScreen> createState() => _GuideListingEditorScreenState();
}

class _GuideListingEditorScreenState extends ConsumerState<GuideListingEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _bioController = TextEditingController();
  final _vehicleTypeController = TextEditingController();
  final _hourlyRateController = TextEditingController();
  final _languagesController = TextEditingController();
  final _specializationsController = TextEditingController();
  final _regionsController = TextEditingController();

  String _guideCategory = 'Chauffeur';
  String _currency = 'USD';
  bool _vehicleAvailable = false;
  String? _vehicleImageUrl;
  String? _licenseNumber;
  List<String> _coverPhotos = [];
  bool _isLoading = true;
  bool _isSaving = false;
  GuideListing? _existingListing;
  bool _isFeaturedRequested = false;
  bool _canFeature = false;
  bool _isInsured = false;

  final _picker = ImagePicker();

  final List<String> _categories = [
    'Chauffeur',
    'Site Guide',
    'Adventure',
    'Wildlife',
    'Heritage',
    'Photography',
  ];

  final List<String> _currencies = ['USD', 'LKR', 'EUR', 'GBP'];

  @override
  void initState() {
    super.initState();
    _loadExistingListing();
  }

  Future<void> _loadExistingListing() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final repo = ref.read(marketplaceRepositoryProvider);
      final listing = await repo.getListing(uid);
      if (listing != null && mounted) {
        _existingListing = listing;
        _displayNameController.text = listing.displayName;
        _bioController.text = listing.bio ?? '';
        _guideCategory = listing.guideCategory;
        _currency = listing.currency;
        _hourlyRateController.text = listing.hourlyRate.toStringAsFixed(0);
        _vehicleAvailable = listing.vehicleAvailable;
        _vehicleTypeController.text = listing.vehicleType ?? '';
        _vehicleImageUrl = listing.vehicleImageUrl;
        _licenseNumber = listing.licenseNumber;
        _isFeaturedRequested = listing.isFeaturedRequested;
        _coverPhotos = List.from(listing.coverPhotos);
        _languagesController.text = listing.languages.join(', ');
        _specializationsController.text = listing.specializations.join(', ');
        _regionsController.text = listing.regions.join(', ');
      } else if (mounted) {
        // Set defaults from auth user if available
        final user = FirebaseAuth.instance.currentUser;
        if (user?.displayName != null) {
          _displayNameController.text = user!.displayName!;
        }
        _languagesController.text = 'English, Sinhala';
        _regionsController.text = 'Central, Southern, Western';
        _hourlyRateController.text = '25';
      }

      // The license number is a verified credential set at enrollment time
      // (GuideApplicationController::approve gate) — always source it from
      // the application record rather than letting the listing drift out of
      // sync, and backfill it onto the listing the first time this screen
      // runs for a guide who was approved before this field existed.
      if (_licenseNumber == null || _licenseNumber!.isEmpty) {
        final application = await GuideApplicationRepository().getMyApplication().catchError((_) => null);
        if (application != null && mounted) {
          _licenseNumber = application.licenseNumber;
        }
      }

      final canFeature = await SubscriptionService().hasEntitlement(uid, 'featuredListings');
      final canInsure = await SubscriptionService().hasEntitlement(uid, 'verifiedInsured');
      if (mounted) {
        _canFeature = canFeature;
        _isInsured = canInsure;
      }
    } catch (e, st) {
      SecureLogger.error("Error loading listing", e, st, "GuideListingEditor");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAndUploadCoverPhoto() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 75);
      if (image == null) return;

      if (!mounted) return;
      setState(() => _isSaving = true);
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.uploadingPhotoMessage), backgroundColor: Theme.of(context).colorScheme.primary),
      );

      final repo = ref.read(marketplaceRepositoryProvider);
      final url = await repo.uploadListingPhoto(
        file: image,
        photoType: 'cover_${DateTime.now().millisecondsSinceEpoch}',
      );

      if (url != null && mounted) {
        setState(() {
          _coverPhotos.add(url);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.photoUploadedSuccessMessage), backgroundColor: AppTheme.colors.green),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.failedToUploadPhotoMessage), backgroundColor: AppTheme.colors.redAccent),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.errorGenericMessage(e.toString())), backgroundColor: AppTheme.colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _pickAndUploadVehiclePhoto() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 75);
      if (image == null) return;

      if (!mounted) return;
      setState(() => _isSaving = true);
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.uploadingVehiclePhotoMessage), backgroundColor: Theme.of(context).colorScheme.primary),
      );

      final repo = ref.read(marketplaceRepositoryProvider);
      final url = await repo.uploadListingPhoto(file: image, photoType: 'vehicle');

      if (url != null && mounted) {
        setState(() => _vehicleImageUrl = url);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.vehiclePhotoUploadedMessage), backgroundColor: AppTheme.colors.green),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.failedToUploadPhotoMessage), backgroundColor: AppTheme.colors.redAccent),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.errorGenericMessage(e.toString())), backgroundColor: AppTheme.colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _saveListing({required String status}) async {
    if (!_formKey.currentState!.validate()) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => _isSaving = true);

    try {
      final now = DateTime.now();
      final languages = _languagesController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      final specializations = _specializationsController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      final regions = _regionsController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final hourlyRate = double.tryParse(_hourlyRateController.text) ?? 0.0;

      final updatedListing = GuideListing(
        listingId: uid,
        guideId: uid,
        displayName: _displayNameController.text.trim(),
        bio: _bioController.text.trim(),
        profilePhotoUrl: _existingListing?.profilePhotoUrl ?? FirebaseAuth.instance.currentUser?.photoURL,
        licenseNumber: _licenseNumber,
        isInsured: _isInsured,
        coverPhotos: _coverPhotos,
        guideCategory: _guideCategory,
        languages: languages.isEmpty ? ['English'] : languages,
        specializations: specializations,
        regions: regions,
        ratingAverage: _existingListing?.ratingAverage ?? 5.0,
        reviewCount: _existingListing?.reviewCount ?? 0,
        trustTierPublic: _existingListing?.trustTierPublic ?? 'Strong',
        yearsExperience: _existingListing?.yearsExperience ?? 2,
        vehicleAvailable: _vehicleAvailable,
        vehicleType: _vehicleAvailable ? _vehicleTypeController.text.trim() : null,
        vehicleImageUrl: _vehicleAvailable ? _vehicleImageUrl : null,
        hourlyRate: hourlyRate,
        currency: _currency,
        status: status, // 'published' or 'draft'
        // moderationStatus/isFeatured/featuredUntil are admin-controlled —
        // firestore.rules requires moderationStatus:'pending', isFeatured:
        // false at create, and blocks both from ever changing via a client
        // update. Always mirror the existing server value (or the safe
        // create default) rather than deriving from local UI state, so this
        // save always passes the rules unchanged instead of getting
        // rejected. The actual moderation decision and featured grant now
        // happen server-side via GuideListingController (Laravel admin API).
        moderationStatus: _existingListing?.moderationStatus ?? 'pending',
        availability: _existingListing?.availability ?? GuideAvailability(listingId: uid),
        isFeatured: _existingListing?.isFeatured ?? false,
        featuredUntil: _existingListing?.featuredUntil,
        isFeaturedRequested: _canFeature && _isFeaturedRequested,
        profileViews: _existingListing?.profileViews ?? 0,
        bookingRequestsCount: _existingListing?.bookingRequestsCount ?? 0,
        createdAt: _existingListing?.createdAt ?? now,
        updatedAt: now,
      );

      final repo = ref.read(marketplaceRepositoryProvider);
      await repo.upsertListing(updatedListing);
      _existingListing = updatedListing;

      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(status == 'published' ? l10n.listingPublishedMessage : l10n.draftSavedMessage),
            backgroundColor: status == 'published' ? AppTheme.colors.green : AppTheme.colors.blueAccent,
          ),
        );
        if (status == 'published' && !widget.embedded && Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.failedToSaveListingMessage(e.toString())), backgroundColor: AppTheme.colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _bioController.dispose();
    _vehicleTypeController.dispose();
    _hourlyRateController.dispose();
    _languagesController.dispose();
    _specializationsController.dispose();
    _regionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary)),
      );
    }

    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.colors.transparent,
        elevation: 0,
        title: Text(
          l10n.yourListingTitle,
          style: GoogleFonts.outfit(fontWeight: FontWeight.w800, letterSpacing: -0.5, fontSize: 20, color: AppTheme.textPrimary(context)),
        ),
        centerTitle: false,
      ),
      body: OracleUI.auraBackground(
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              physics: const BouncingScrollPhysics(),
              children: [
                _buildSectionTitle(l10n.basicInformationTitle),
                const SizedBox(height: 12),
                if (_licenseNumber != null && _licenseNumber!.isNotEmpty) ...[
                  _buildVerifiedLicenseTile(),
                  const SizedBox(height: 16),
                ],
                _buildTextField(
                  controller: _displayNameController,
                  label: l10n.displayNameLabel,
                  hint: l10n.displayNameHint,
                  icon: Icons.person_outline,
                  validator: (v) => v == null || v.isEmpty ? l10n.requiredFieldMessage : null,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _bioController,
                  label: l10n.aboutMeBioLabel,
                  hint: l10n.aboutMeBioHint,
                  icon: Icons.info_outline,
                  maxLines: 4,
                  validator: (v) => v == null || v.isEmpty ? l10n.requiredFieldMessage : null,
                ),
                const SizedBox(height: 24),

                _buildSectionTitle(l10n.categorySpecialtiesTitle),
                const SizedBox(height: 12),
                _buildDropdown(
                  label: l10n.primaryCategoryLabel,
                  value: _guideCategory,
                  items: _categories,
                  onChanged: (val) => setState(() => _guideCategory = val!),
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _languagesController,
                  label: l10n.languagesCommaLabel,
                  hint: l10n.languagesCommaHint,
                  icon: Icons.language,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _specializationsController,
                  label: l10n.specializationsCommaLabel,
                  hint: l10n.specializationsCommaHint,
                  icon: Icons.star_border,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _regionsController,
                  label: l10n.serviceRegionsLabel,
                  hint: l10n.serviceRegionsHint,
                  icon: Icons.map_outlined,
                ),
                const SizedBox(height: 24),

                _buildSectionTitle(l10n.pricingVehicleTitle),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: _buildTextField(
                        controller: _hourlyRateController,
                        label: l10n.hourlyRateFieldLabel,
                        hint: l10n.hourlyRateHint,
                        icon: Icons.attach_money,
                        keyboardType: TextInputType.number,
                        validator: (v) => v == null || v.isEmpty ? l10n.requiredFieldMessage : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: _buildDropdown(
                        label: l10n.currencyLabel,
                        value: _currency,
                        items: _currencies,
                        onChanged: (val) => setState(() => _currency = val!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceMuted(context),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: SwitchListTile(
                    title: Text(l10n.vehicleAvailableForToursLabel, style: GoogleFonts.outfit(color: AppTheme.textPrimary(context), fontWeight: FontWeight.w600)),
                    subtitle: Text(l10n.provideTransportationLabel, style: GoogleFonts.inter(color: AppTheme.textSecondary(context), fontSize: 12)),
                    value: _vehicleAvailable,
                    activeThumbColor: Theme.of(context).colorScheme.primary,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) => setState(() => _vehicleAvailable = val),
                  ),
                ),
                if (_vehicleAvailable) ...[
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _vehicleTypeController,
                    label: l10n.vehicleTypeModelLabel,
                    hint: l10n.vehicleTypeModelHint,
                    icon: Icons.directions_car_outlined,
                  ),
                  const SizedBox(height: 16),
                  _buildVehiclePhotoPicker(),
                ],
                const SizedBox(height: 24),

                _buildSectionTitle(l10n.coverPhotosCountTitle(_coverPhotos.length)),
                const SizedBox(height: 12),
                _buildCoverPhotosSection(),
                const SizedBox(height: 24),

                _buildSectionTitle(l10n.availabilityCalendarTitle),
                const SizedBox(height: 12),
                _buildAvailabilityButton(context),
                const SizedBox(height: 24),

                _buildSectionTitle(l10n.visibilityBoostTitle),
                const SizedBox(height: 12),
                _buildFeaturedToggle(),
                const SizedBox(height: 36),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSaving ? null : () => _saveListing(status: 'draft'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                        ),
                        child: Text(
                          l10n.saveDraftButton,
                          style: GoogleFonts.inter(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : () => _saveListing(status: 'published'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Theme.of(context).colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                          elevation: 0,
                        ),
                        child: _isSaving
                            ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Theme.of(context).colorScheme.onPrimary))
                            : Text(
                                l10n.publishListingButton,
                                style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14),
                              ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        color: AppTheme.textPrimary(context),
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: GoogleFonts.inter(color: AppTheme.textPrimary(context), fontSize: 15),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: GoogleFonts.outfit(color: AppTheme.textSecondary(context)),
        hintStyle: GoogleFonts.inter(color: AppTheme.textSecondary(context).withValues(alpha: 0.5), fontSize: 13),
        prefixIcon: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
        filled: true,
        fillColor: AppTheme.surfaceMuted(context),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.5)),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceMuted(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: GoogleFonts.inter(color: AppTheme.textPrimary(context))))).toList(),
        onChanged: onChanged,
        dropdownColor: Theme.of(context).cardColor,
        style: GoogleFonts.inter(color: AppTheme.textPrimary(context)),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.outfit(color: AppTheme.textSecondary(context)),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildCoverPhotosSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _coverPhotos.length + 1,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              if (index == _coverPhotos.length) {
                return GestureDetector(
                  onTap: _isSaving ? null : _pickAndUploadCoverPhoto,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Theme.of(context).colorScheme.primary, style: BorderStyle.solid, width: 1.5),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo_outlined, color: Theme.of(context).colorScheme.primary, size: 28),
                        const SizedBox(height: 6),
                        Text(AppLocalizations.of(context)!.addPhotoLabel, style: GoogleFonts.inter(color: Theme.of(context).colorScheme.primary, fontSize: 11, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                );
              }
              final photoUrl = _coverPhotos[index];
              return Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SizedBox(
                      width: 100,
                      height: 100,
                      child: CachedImage(url: photoUrl, fit: BoxFit.cover),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _coverPhotos.removeAt(index);
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(color: AppTheme.colors.black87, shape: BoxShape.circle),
                        child: Icon(Icons.close, color: AppTheme.colors.white, size: 14),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildVerifiedLicenseTile() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.colors.greenAccent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.colors.greenAccent.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.verified_rounded, color: AppTheme.colors.greenAccent, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppLocalizations.of(context)!.verifiedLicenseLabel, style: GoogleFonts.inter(color: AppTheme.textSecondary(context), fontSize: 11, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(_licenseNumber!, style: GoogleFonts.outfit(color: AppTheme.textPrimary(context), fontWeight: FontWeight.w700, fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehiclePhotoPicker() {
    return GestureDetector(
      onTap: _isSaving ? null : _pickAndUploadVehiclePhoto,
      child: Container(
        width: double.infinity,
        height: 140,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).colorScheme.primary, width: 1.5),
        ),
        child: _vehicleImageUrl == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo_outlined, color: Theme.of(context).colorScheme.primary, size: 28),
                  const SizedBox(height: 8),
                  Text(AppLocalizations.of(context)!.addVehiclePhotoLabel, style: GoogleFonts.inter(color: Theme.of(context).colorScheme.primary, fontSize: 12, fontWeight: FontWeight.w700)),
                ],
              )
            : Stack(
                fit: StackFit.expand,
                children: [
                  CachedImage(url: _vehicleImageUrl!, fit: BoxFit.cover),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => setState(() => _vehicleImageUrl = null),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: AppTheme.colors.black87, shape: BoxShape.circle),
                        child: Icon(Icons.close, color: AppTheme.colors.white, size: 16),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildAvailabilityButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GuideAvailabilityScreen(listing: _existingListing),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: AppTheme.colors.black.withValues(alpha: 0.05), blurRadius: 14, offset: const Offset(0, 5)),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.calendar_month_outlined, color: Theme.of(context).colorScheme.primary, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppLocalizations.of(context)!.manageAvailabilityTitle, style: GoogleFonts.outfit(color: AppTheme.textPrimary(context), fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(AppLocalizations.of(context)!.manageAvailabilitySubtitle, style: GoogleFonts.inter(color: AppTheme.textSecondary(context), fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.textSecondary(context), size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedToggle() {
    final l10n = AppLocalizations.of(context)!;
    final isLiveFeatured = _existingListing?.isFeatured == true;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _canFeature ? AppTheme.surfaceMuted(context) : AppTheme.surfaceMuted(context).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: _canFeature ? null : Border.all(color: AppTheme.borderColor(context)),
      ),
      child: _canFeature
          ? SwitchListTile(
              title: Text(l10n.featureThisListingLabel, style: GoogleFonts.outfit(color: AppTheme.textPrimary(context), fontWeight: FontWeight.w600)),
              subtitle: Text(
                isLiveFeatured
                    ? l10n.currentlyFeaturedMessage
                    : (_isFeaturedRequested
                        ? l10n.featureRequestedMessage
                        : l10n.featureRequestPromptMessage),
                style: GoogleFonts.inter(color: AppTheme.textSecondary(context), fontSize: 12),
              ),
              // isFeatured itself is admin-granted (server-side, via
              // GuideListingController) — this switch only records the
              // guide's REQUEST (isFeaturedRequested), a non-privileged
              // field the client is allowed to write freely.
              value: isLiveFeatured || _isFeaturedRequested,
              activeThumbColor: Theme.of(context).colorScheme.primary,
              contentPadding: EdgeInsets.zero,
              onChanged: isLiveFeatured ? null : (val) => setState(() => _isFeaturedRequested = val),
            )
          : ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.lock_outline_rounded, color: Theme.of(context).colorScheme.primary, size: 20),
              title: Text(l10n.featureThisListingLabel, style: GoogleFonts.outfit(color: AppTheme.textPrimary(context), fontWeight: FontWeight.w600)),
              subtitle: Text(l10n.upgradeToProFeatureMessage, style: GoogleFonts.inter(color: AppTheme.textSecondary(context), fontSize: 12)),
              trailing: TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionScreen())),
                child: Text(l10n.upgradeButtonLabel, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12, color: Theme.of(context).colorScheme.primary)),
              ),
            ),
    );
  }
}
