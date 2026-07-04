import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/oracle_ui_system.dart';
import '../../data/models/guide_listing.dart';
import '../../data/models/guide_availability.dart';
import '../../data/repositories/marketplace_repository.dart';
import '../../data/datasources/firebase_storage_service.dart';
import '../widgets/cached_image.dart';
import 'guide_availability_screen.dart';

class GuideListingEditorScreen extends ConsumerStatefulWidget {
  const GuideListingEditorScreen({super.key});

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
  List<String> _coverPhotos = [];
  bool _isLoading = true;
  bool _isSaving = false;
  GuideListing? _existingListing;

  final _storage = FirebaseStorageService();
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
    } catch (e) {
      debugPrint('Error loading listing: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAndUploadCoverPhoto() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 75);
      if (image == null) return;

      setState(() => _isSaving = true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Uploading photo to vault...'), backgroundColor: Colors.amber),
      );

      final url = await _storage.uploadGuideDocument(
        file: image,
        docType: 'cover_${DateTime.now().millisecondsSinceEpoch}',
      );

      if (url != null && mounted) {
        setState(() {
          _coverPhotos.add(url);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo uploaded successfully!'), backgroundColor: Colors.green),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to upload photo.'), backgroundColor: Colors.redAccent),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
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
        hourlyRate: hourlyRate,
        currency: _currency,
        status: status, // 'published' or 'draft'
        moderationStatus: _existingListing?.moderationStatus ?? 'approved',
        availability: _existingListing?.availability ?? GuideAvailability(listingId: uid),
        isFeatured: _existingListing?.isFeatured ?? false,
        featuredUntil: _existingListing?.featuredUntil,
        profileViews: _existingListing?.profileViews ?? 0,
        bookingRequestsCount: _existingListing?.bookingRequestsCount ?? 0,
        createdAt: _existingListing?.createdAt ?? now,
        updatedAt: now,
      );

      final repo = ref.read(marketplaceRepositoryProvider);
      await repo.upsertListing(updatedListing);
      _existingListing = updatedListing;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(status == 'published' ? '🎉 Listing Published to Marketplace!' : '💾 Draft Saved Successfully'),
            backgroundColor: status == 'published' ? Colors.green : Colors.blueAccent,
          ),
        );
        if (status == 'published') {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save listing: $e'), backgroundColor: Colors.redAccent),
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
        body: const Center(child: CircularProgressIndicator(color: Colors.amber)),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'MY GUIDE LISTING',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 16),
        ),
        centerTitle: true,
      ),
      body: OracleUI.auraBackground(
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              physics: const BouncingScrollPhysics(),
              children: [
                _buildSectionTitle('BASIC INFORMATION'),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _displayNameController,
                  label: 'Display Name',
                  hint: 'e.g. Kasun Perera',
                  icon: Icons.person_outline,
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _bioController,
                  label: 'About Me (Bio)',
                  hint: 'Tell tourists about your passion, experience, and favorite spots...',
                  icon: Icons.info_outline,
                  maxLines: 4,
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 24),

                _buildSectionTitle('CATEGORY & SPECIALTIES'),
                const SizedBox(height: 12),
                _buildDropdown(
                  label: 'Primary Category',
                  value: _guideCategory,
                  items: _categories,
                  onChanged: (val) => setState(() => _guideCategory = val!),
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _languagesController,
                  label: 'Languages (comma separated)',
                  hint: 'e.g. English, Sinhala, German',
                  icon: Icons.language,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _specializationsController,
                  label: 'Specializations (comma separated)',
                  hint: 'e.g. Heritage, Wildlife, Photography',
                  icon: Icons.star_border,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _regionsController,
                  label: 'Service Regions (comma separated)',
                  hint: 'e.g. Central, Southern, Western',
                  icon: Icons.map_outlined,
                ),
                const SizedBox(height: 24),

                _buildSectionTitle('PRICING & VEHICLE'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: _buildTextField(
                        controller: _hourlyRateController,
                        label: 'Hourly Rate',
                        hint: 'e.g. 25',
                        icon: Icons.attach_money,
                        keyboardType: TextInputType.number,
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: _buildDropdown(
                        label: 'Currency',
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
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                  ),
                  child: SwitchListTile(
                    title: Text('Vehicle Available for Tours', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600)),
                    subtitle: Text('Do you provide transportation?', style: GoogleFonts.inter(color: Colors.white60, fontSize: 12)),
                    value: _vehicleAvailable,
                    activeThumbColor: Colors.amber,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) => setState(() => _vehicleAvailable = val),
                  ),
                ),
                if (_vehicleAvailable) ...[
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _vehicleTypeController,
                    label: 'Vehicle Type & Model',
                    hint: 'e.g. Toyota Prius Hybrid / Luxury Van',
                    icon: Icons.directions_car_outlined,
                  ),
                ],
                const SizedBox(height: 24),

                _buildSectionTitle('COVER PHOTOS (${_coverPhotos.length})'),
                const SizedBox(height: 12),
                _buildCoverPhotosSection(),
                const SizedBox(height: 24),

                _buildSectionTitle('AVAILABILITY CALENDAR'),
                const SizedBox(height: 12),
                _buildAvailabilityButton(context),
                const SizedBox(height: 36),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSaving ? null : () => _saveListing(status: 'draft'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: Colors.amber, width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Text(
                          'SAVE DRAFT',
                          style: GoogleFonts.outfit(color: Colors.amber, fontWeight: FontWeight.bold, letterSpacing: 1),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : () => _saveListing(status: 'published'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 8,
                        ),
                        child: _isSaving
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                            : Text(
                                'PUBLISH LISTING 🚀',
                                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, letterSpacing: 1, fontSize: 15),
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
      style: GoogleFonts.outfit(
        color: Colors.amber[400],
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 2.0,
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
      style: GoogleFonts.inter(color: Colors.white, fontSize: 15),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: GoogleFonts.outfit(color: Colors.white70),
        hintStyle: GoogleFonts.inter(color: Colors.white30, fontSize: 13),
        prefixIcon: Icon(icon, color: Colors.amber[300], size: 20),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.08),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.amber, width: 1.5)),
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
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: GoogleFonts.inter(color: Colors.white)))).toList(),
        onChanged: onChanged,
        dropdownColor: const Color(0xFF1E1E1E),
        style: GoogleFonts.inter(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.outfit(color: Colors.white70),
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
                      color: Colors.amber.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.amber, style: BorderStyle.solid, width: 1.5),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo_outlined, color: Colors.amber, size: 28),
                        SizedBox(height: 6),
                        Text('Add Photo', style: TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold)),
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
                        decoration: const BoxDecoration(color: Colors.black87, shape: BoxShape.circle),
                        child: const Icon(Icons.close, color: Colors.white, size: 14),
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
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.calendar_month_outlined, color: Colors.amber, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Manage Availability', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text('Set blackout dates & recurring working hours', style: GoogleFonts.inter(color: Colors.white60, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white60, size: 16),
          ],
        ),
      ),
    );
  }
}
