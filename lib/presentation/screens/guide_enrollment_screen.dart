import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_fonts/google_fonts.dart';
import '../../core/services/oracle_guardian.dart';
import '../../core/theme/oracle_ui_system.dart';
import '../../core/theme/app_theme.dart';
import '../../data/datasources/user_preference_service.dart';
import '../../data/datasources/auth_service.dart';
import '../../data/datasources/firebase_storage_service.dart';
import '../../data/repositories/guide_application_repository.dart';
import '../../data/models/guide_application.dart';
import '../../data/models/guide_status.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io' as io;
import 'dart:ui';

class GuideEnrollmentScreen extends StatefulWidget {
  const GuideEnrollmentScreen({super.key});

  @override
  State<GuideEnrollmentScreen> createState() => _GuideEnrollmentScreenState();
}

class _GuideEnrollmentScreenState extends State<GuideEnrollmentScreen> {
  final _licenseController = TextEditingController();
  final _bioController = TextEditingController();
  String _selectedCategory = 'National';
  bool _isLoading = false;
  String _loadingStatus = "INITIATING VERIFICATION...";

  XFile? _licenseFile;
  XFile? _nicFile;
  XFile? _selfieFile;

  final _picker = ImagePicker();
  final _storage = FirebaseStorageService();
  final _repo = GuideApplicationRepository();

  @override
  void dispose() {
    _licenseController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(String type, ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source, 
        imageQuality: 70,
        preferredCameraDevice: type == 'selfie' ? CameraDevice.front : CameraDevice.rear,
      );
      if (image != null) {
        setState(() {
          if (type == 'license') _licenseFile = image;
          if (type == 'nic') _nicFile = image;
          if (type == 'selfie') _selfieFile = image;
        });
      }
    } catch (e) {
       if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Camera access denied or error: $e")),
        );
      }
    }
  }

  void _showPhotoPicker(String type) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => OracleUI.glassContainer(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            OracleUI.neonText(
              type == 'selfie' ? "IDENTIFY SELFIE" : "UPLOAD DOCUMENT",
              style: GoogleFonts.outfit(
                color: Theme.of(context).colorScheme.primary, 
                fontSize: 16, 
                fontWeight: FontWeight.bold, 
                letterSpacing: 2
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _photoOption(Icons.camera_alt_outlined, "CAMERA", ImageSource.camera, type),
                _photoOption(Icons.photo_library_outlined, "GALLERY", ImageSource.gallery, type),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _photoOption(IconData icon, String label, ImageSource source, String type) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        _pickImage(type, source);
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white10),
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: GoogleFonts.outfit(
              color: Colors.white70,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  void _showNotification(String text, {bool isError = false}) {
    if (!mounted) return;
    OracleNotification.show(context, text, isError: isError);
  }

  Future<void> _submitApplication() async {
    // 1. Basic UI Check
    if (_licenseController.text.isEmpty || _bioController.text.isEmpty || 
        _licenseFile == null || _nicFile == null || _selfieFile == null) {
      _showNotification("Fields missing: Please fill all and upload documents.", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      final guardian = OracleGuardian();
      
      // Security Certification
      if (!await guardian.certifyTransition('IDLE', 'SUBMITTING')) {
        guardian.secureLog('Unauthorized transition attempt', isCritical: true);
      }

      if (uid == null) {
        throw OracleException("Authentication required. Please login again.", code: "AUTH_REQUIRED");
      }

      // 1. Upload Documents
      _showNotification("Uploading documents...");
      
      final licenseUrl = await _storage.uploadGuideDocument(file: _licenseFile!, docType: 'license');
      final nicUrl = await _storage.uploadGuideDocument(file: _nicFile!, docType: 'nic');
      final selfieUrl = await _storage.uploadGuideDocument(file: _selfieFile!, docType: 'selfie');

      if (licenseUrl == null || nicUrl == null || selfieUrl == null) {
        throw OracleException("Guide documents could not be transmitted to the Oracle vault. Please verify your connection.", code: "UPLOAD_FAILURE");
      }

      // 2. Submit Application
      _showNotification("Saving application...");
      final application = GuideApplication(
        userId: uid,
        licenseNumber: _licenseController.text,
        bio: _bioController.text,
        category: _selectedCategory,
        licenseDocUrl: licenseUrl,
        nicDocUrl: nicUrl,
        selfieDocUrl: selfieUrl,
        status: GuideStatus.pending,
        appliedAt: DateTime.now(),
      );

      await _repo.submitApplication(application);

      // 3. Update Local Cache
      setState(() => _loadingStatus = "ORACLE SYNCHRONIZING...");
      
      final obfuscatedStatus = guardian.obfuscateStatus('PENDING');
      guardian.secureLog("Transitioned state to $obfuscatedStatus");

      final profile = UserPreferenceService.getProfile();
      profile.role = 'guide_pending';
      profile.guideStatus = GuideStatus.pending;
      await UserPreferenceService.saveProfile(profile);
      
      _showNotification("Application submitted successfully!");
      if (mounted) {
        _showSuccessOverlay();
      }
    } catch (e) {
      if (mounted) {
        _showNotification("Error: ${e.toString()}", isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadingStatus = "INITIATING VERIFICATION...";
        });
      }
    }
  }

  Widget _buildLoadingAura() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.modernGreen(context).withValues(alpha: 0.1),
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true))
             .scale(begin: const Offset(1, 1), end: const Offset(1.5, 1.5), duration: 1.5.seconds)
             .blur(begin: const Offset(5, 5), end: const Offset(20, 20)),
            
            SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                color: AppTheme.modernGreen(context),
                strokeWidth: 2,
              ),
            ),
            
            Icon(Icons.security, color: AppTheme.modernGreen(context), size: 24)
              .animate(onPlay: (c) => c.repeat())
              .shimmer(duration: 2.seconds),
          ],
        ),
        const SizedBox(height: 24),
        OracleUI.neonText(
          _loadingStatus,
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            color: AppTheme.modernGreen(context),
          ),
        ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 2.seconds),
        const SizedBox(height: 8),
        Text(
          "The Oracle is synchronizing your credentials with the blockchain.",
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 10,
            color: Colors.white38,
          ),
        ),
      ],
    );
  }

  void _showSuccessOverlay() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Center(
          child: OracleUI.glassContainer(
            width: 300,
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 64)
                    .animate()
                    .scale(duration: 600.ms, curve: Curves.elasticOut),
                const SizedBox(height: 24),
                OracleUI.neonText(
                  "SUBMITTED",
                  style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text(
                  "The Oracle Council will review your application soon.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(color: Colors.white70),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    Navigator.pop(context); // Close screen
                  },
                  child: const Text("RETURN"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: OracleUI.auraBackground(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
              title: OracleUI.neonText(
                "ENROLL AS GUIDE",
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    OracleUI.glassContainer(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Icon(
                            Icons.verified_user_outlined,
                            size: 48,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "BECOME THE ORACLE",
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "Share your local wisdom with international travelers. As a guide, you'll unlock tools to manage groups and ensure their safety.",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(duration: 800.ms).slideY(begin: 0.1, end: 0),
                    const SizedBox(height: 32),
                    _buildCategorySelector(),
                    const SizedBox(height: 24),
                    _buildInputField(
                      "LICENSE NUMBER",
                      "SLTDA-XXXX-XXXX",
                      _licenseController,
                    ).animate().fadeIn(delay: 200.ms, duration: 800.ms).slideX(begin: -0.1, end: 0),
                    const SizedBox(height: 24),
                    _buildInputField(
                      "SHORT BIO",
                      "Tell us about your experience...",
                      _bioController,
                      maxLines: 4,
                    ).animate().fadeIn(delay: 400.ms, duration: 800.ms).slideX(begin: 0.1, end: 0),
                    const SizedBox(height: 32),
                    OracleUI.neonText(
                      "DOCUMENT VERIFICATION",
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildDocPicker("GUIDE LICENSE", _licenseFile, () => _showPhotoPicker('license')),
                    const SizedBox(height: 16),
                    _buildDocPicker("NIC / PASSPORT", _nicFile, () => _showPhotoPicker('nic')),
                    const SizedBox(height: 16),
                    _buildDocPicker("SELFIE FOR IDENTITY", _selfieFile, () => _showPhotoPicker('selfie')),
                    const SizedBox(height: 48),
                    _isLoading
                        ? OracleUI.glassContainer(
                            padding: const EdgeInsets.all(32),
                            child: _buildLoadingAura(),
                          ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95))
                        : SizedBox(
                            width: double.infinity,
                            height: 60,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onPressed: _submitApplication,
                              child: Text(
                                "SUBMIT APPLICATION",
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 2,
                                ),
                              ),
                            ),
                          ).animate(onPlay: (c) => c.repeat(reverse: true))
                           .scale(begin: const Offset(1, 1), end: const Offset(1.02, 1.02), duration: 2.seconds),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OracleUI.neonText(
          "GUIDE CATEGORY",
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: ['National', 'Provincial', 'Site'].map((cat) {
            final isSelected = _selectedCategory == cat;
            return ChoiceChip(
              label: Text(cat),
              selected: isSelected,
              onSelected: (val) => setState(() => _selectedCategory = cat),
              selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.3),
              labelStyle: GoogleFonts.inter(
                color: isSelected ? Colors.white : Colors.white60,
                fontSize: 12,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDocPicker(String label, XFile? file, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: OracleUI.glassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Row(
          children: [
            Icon(
              file == null ? Icons.add_a_photo_outlined : Icons.check_circle_rounded,
              color: file == null ? Colors.white38 : Colors.greenAccent,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
              ),
            ),
            if (file != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: kIsWeb
                    ? Image.network(file.path, width: 40, height: 40, fit: BoxFit.cover)
                    : Image.file(io.File(file.path), width: 40, height: 40, fit: BoxFit.cover),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(String label, String hint, TextEditingController controller, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OracleUI.neonText(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 12),
        OracleUI.glassContainer(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            style: GoogleFonts.inter(color: Colors.white),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.inter(color: Colors.white.withOpacity(0.3)),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }
}
