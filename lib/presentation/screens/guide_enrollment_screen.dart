import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_fonts/google_fonts.dart';
import '../../core/services/oracle_guardian.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/oracle_ui_system.dart';
import '../../data/datasources/user_preference_service.dart';
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
  final _repo = GuideApplicationRepository();
  final _storage = FirebaseStorageService();
  final _picker = ImagePicker();

  XFile? _licenseFile;
  XFile? _nicFile;
  XFile? _selfieFile;

  final _licenseController = TextEditingController();
  final _bioController = TextEditingController();

  bool _isLoading = false;
  String _loadingStatus = "Verifying your details...";
  String _selectedCategory = 'National';
  String? _rejectionReason;
  GuideStatus _currentStatus = GuideStatus.none;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _startWatchingApplication();
  }

  /// Polls the Laravel backend (MySQL-backed, zero Firestore cost) for
  /// application status instead of holding an open Firestore listener.
  /// This screen only matters while the user is actively waiting for
  /// approval, so a 20s poll interval is responsive enough without paying
  /// for a persistent connection the whole time the screen is mounted.
  void _startWatchingApplication() {
    final profile = UserPreferenceService.getProfile();
    setState(() {
      _currentStatus = profile.guideStatus;
    });
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    _pollStatus();
    _pollTimer = Timer.periodic(const Duration(seconds: 20), (_) => _pollStatus());
  }

  Future<void> _pollStatus() async {
    final app = await _repo.getMyApplication().catchError((_) => null);
    if (app != null && mounted) {
      setState(() {
        _currentStatus = app.status;
        if (app.status == GuideStatus.rejected) {
          _rejectionReason = app.adminComment ?? "Please ensure your license documents and photos are clear and valid.";
        }
      });
      final currentProfile = UserPreferenceService.getProfile();
      bool changed = false;
      if (app.status == GuideStatus.approved && currentProfile.guideStatus != GuideStatus.approved) {
        currentProfile.guideStatus = GuideStatus.approved;
        currentProfile.role = 'guide_approved';
        currentProfile.isGuideApproved = true;
        changed = true;
      } else if (app.status == GuideStatus.rejected && currentProfile.guideStatus != GuideStatus.rejected) {
        currentProfile.guideStatus = GuideStatus.rejected;
        changed = true;
      } else if (app.status == GuideStatus.pending && currentProfile.guideStatus != GuideStatus.pending) {
        currentProfile.guideStatus = GuideStatus.pending;
        changed = true;
      }
      if (changed) {
        UserPreferenceService.saveProfile(currentProfile);
      }
      if (app.status == GuideStatus.approved || app.status == GuideStatus.rejected) {
        _pollTimer?.cancel();
      }
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
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
        if (!mounted) return;
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
      backgroundColor: AppTheme.colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: AppTheme.colors.black.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 8))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              type == 'selfie' ? "Take a selfie" : "Upload document",
              style: GoogleFonts.outfit(
                color: AppTheme.textPrimary(context),
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _photoOption(Icons.camera_alt_outlined, "Camera", ImageSource.camera, type),
                _photoOption(Icons.photo_library_outlined, "Gallery", ImageSource.gallery, type),
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
              color: AppTheme.surfaceMuted(context),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppTheme.textPrimary(context), size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: GoogleFonts.inter(
              color: AppTheme.textSecondary(context),
              fontSize: 11,
              fontWeight: FontWeight.w600,
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
      if (!mounted) return;
      setState(() => _loadingStatus = "Synchronizing application...");
      
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
          _loadingStatus = "Verifying your details...";
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
        Text(
          _loadingStatus,
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppTheme.modernGreen(context),
          ),
        ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 2.seconds),
        const SizedBox(height: 8),
        Text(
          "Your credentials are being securely verified.",
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: AppTheme.textSecondary(context),
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
          child: Container(
            width: 300,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: AppTheme.colors.black.withValues(alpha: 0.12), blurRadius: 24, offset: const Offset(0, 10))],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_outline, color: AppTheme.colors.greenAccent, size: 64)
                    .animate()
                    .scale(duration: 600.ms, curve: Curves.elasticOut),
                const SizedBox(height: 24),
                Text(
                  "Submitted",
                  style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -0.3, color: AppTheme.textPrimary(context)),
                ),
                const SizedBox(height: 16),
                Text(
                  "Our team will review your application soon.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(color: AppTheme.textSecondary(context)),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: AppTheme.colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                    ),
                    onPressed: () {
                      Navigator.pop(context); // Close dialog
                      Navigator.pop(context); // Close screen
                    },
                    child: Text("Return", style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                  ),
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppTheme.colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new, size: 20, color: AppTheme.textPrimary(context)),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              "Become a guide",
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: AppTheme.textPrimary(context),
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
                    if (_currentStatus == GuideStatus.pending) ...[
                      _buildStatusBanner(
                        title: "Application under review",
                        message: "Your guide application has been submitted and is currently being reviewed. You will be notified once a decision is made.",
                        color: AppTheme.colors.amber,
                      ),
                      const SizedBox(height: 20),
                    ] else if (_currentStatus == GuideStatus.rejected) ...[
                      _buildStatusBanner(
                        title: "Application rejected",
                        message: "Reason: ${_rejectionReason ?? 'Documents incomplete or unclear.'}\n\nYou can re-submit your application below once you fix the required items.",
                        color: AppTheme.colors.redAccent,
                      ),
                      const SizedBox(height: 20),
                    ] else if (_currentStatus == GuideStatus.approved) ...[
                      _buildStatusBanner(
                        title: "You are an approved guide",
                        message: "Congratulations! Your guide identity is active. You can access the Guide Dashboard from your profile.",
                        color: AppTheme.colors.greenAccent,
                      ),
                      const SizedBox(height: 20),
                    ],
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
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
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppTheme.colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.verified_user_outlined,
                              size: 22,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            "Share your local knowledge",
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Guide travelers and earn on your own schedule.",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AppTheme.colors.white.withValues(alpha: 0.8),
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(duration: 800.ms).slideY(begin: 0.1, end: 0),
                    const SizedBox(height: 28),
                    _buildCategorySelector(),
                    const SizedBox(height: 24),
                    _buildInputField(
                      "License number",
                      "SLTDA-XXXX-XXXX",
                      _licenseController,
                    ).animate().fadeIn(delay: 200.ms, duration: 800.ms).slideX(begin: -0.1, end: 0),
                    const SizedBox(height: 24),
                    _buildInputField(
                      "Short bio",
                      "Tell us about your experience...",
                      _bioController,
                      maxLines: 4,
                    ).animate().fadeIn(delay: 400.ms, duration: 800.ms).slideX(begin: 0.1, end: 0),
                    const SizedBox(height: 28),
                    Text(
                      "Verification documents",
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                        color: AppTheme.textPrimary(context),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildDocPicker("Guide license", _licenseFile, () => _showPhotoPicker('license')),
                    const SizedBox(height: 12),
                    _buildDocPicker("NIC / passport", _nicFile, () => _showPhotoPicker('nic')),
                    const SizedBox(height: 12),
                    _buildDocPicker("Selfie for identity", _selfieFile, () => _showPhotoPicker('selfie')),
                    const SizedBox(height: 40),
                    _isLoading
                        ? Container(
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(22),
                              boxShadow: [BoxShadow(color: AppTheme.colors.black.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, 6))],
                            ),
                            child: _buildLoadingAura(),
                          ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95))
                        : SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.primary,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(100),
                                ),
                              ),
                              onPressed: _submitApplication,
                              child: Text(
                                "Submit application",
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: AppTheme.colors.white,
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
      );
  }

  Widget _buildCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Guide category",
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
            color: AppTheme.textPrimary(context),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: ['National', 'Provincial', 'Site'].map((cat) {
            final isSelected = _selectedCategory == cat;
            return GestureDetector(
              onTap: () => setState(() => _selectedCategory = cat),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? Theme.of(context).colorScheme.primary : AppTheme.surfaceMuted(context),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  cat,
                  style: GoogleFonts.inter(
                    color: isSelected ? AppTheme.colors.white : AppTheme.textSecondary(context),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
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
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceMuted(context),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(
              file == null ? Icons.add_a_photo_outlined : Icons.check_circle_rounded,
              color: file == null ? AppTheme.textSecondary(context) : AppTheme.colors.greenAccent,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(color: AppTheme.textPrimary(context), fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
            if (file != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
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
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary(context),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceMuted(context),
            borderRadius: BorderRadius.circular(14),
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            style: GoogleFonts.inter(color: AppTheme.textPrimary(context)),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.inter(color: AppTheme.textSecondary(context)),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBanner({required String title, required String message, required Color color}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border(left: BorderSide(color: color, width: 4)),
        boxShadow: [
          BoxShadow(color: AppTheme.colors.black.withValues(alpha: 0.05), blurRadius: 14, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.outfit(color: color, fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: -0.2)),
          const SizedBox(height: 8),
          Text(message, style: GoogleFonts.inter(color: AppTheme.textPrimary(context), fontSize: 13, height: 1.5)),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.1, end: 0);
  }
}
