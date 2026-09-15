import 'dart:convert';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/theme/app_theme.dart';
import '../../data/datasources/auth_service.dart';
import '../../data/datasources/user_preference_service.dart';
import '../../data/models/tour_session.dart';
import '../../data/repositories/tour_session_repository.dart';
import '../../l10n/app_localizations.dart';
import './tourist_companion_hub.dart';

/// Premium themed QR Code Scanner Screen for Guide Tour Companion Sync
class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  late final MobileScannerController _scannerController;
  bool _isProcessing = false;
  bool _hasConsent = false;
  bool _isTorchOn = false;
  String? _scannedToken;

  final _sessionRepo = TourSessionRepository();

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _toggleTorch() async {
    try {
      await _scannerController.toggleTorch();
      if (mounted) {
        setState(() => _isTorchOn = !_isTorchOn);
      }
    } catch (_) {}
  }

  Future<void> _switchCamera() async {
    try {
      await _scannerController.switchCamera();
    } catch (_) {}
  }

  Future<void> _handleScan(String code) async {
    if (_isProcessing) return;

    try {
      final Map<String, dynamic> data = jsonDecode(code);
      if (data['v'] != 1 || data['t'] != 'join' || data['token'] == null) {
        _showError(AppLocalizations.of(context)!.invalidQrCodeFormatMessage);
        return;
      }

      final token = data['token'];
      if (_scannedToken == token) return; // Prevent duplicate processing

      setState(() {
        _scannedToken = token;
        _isProcessing = true;
      });

      HapticFeedback.mediumImpact();
      _fetchPreview(token);
    } catch (e) {
      _showError(AppLocalizations.of(context)!.unrecognizedQrCodeMessage);
    }
  }

  Future<void> _fetchPreview(String token) async {
    try {
      final query = await FirebaseFirestore.instance
          .collection('tour_sessions')
          .where('joinToken', isEqualTo: token)
          .where('isJoinOpen', isEqualTo: true)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        if (!mounted) return;
        _showError(AppLocalizations.of(context)!.sessionNotFoundClosedMessage);
        setState(() => _isProcessing = false);
        return;
      }

      final session = TourSession.fromJson(query.docs.first.data());
      final guideDoc = await FirebaseFirestore.instance.collection('users').doc(session.guideId).get();

      if (mounted) {
        _showJoinSheet(session, guideDoc.data() ?? {});
      }
    } catch (e) {
      if (!mounted) return;
      _showError(AppLocalizations.of(context)!.connectionErrorMessage);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showJoinSheet(TourSession session, Map<String, dynamic> guideData) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            decoration: BoxDecoration(
              color: AppPaletteDark.surface.withValues(alpha: 0.96),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              border: Border.all(color: AppPaletteDark.gold.withValues(alpha: 0.2)),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.colors.black.withValues(alpha: 0.6),
                  blurRadius: 30,
                  offset: const Offset(0, -10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top drag pill
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                Text(
                  AppLocalizations.of(context)!.tourVerificationTitle,
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                    color: AppTheme.colors.white,
                  ),
                ),
                const SizedBox(height: 20),

                // Guide Info Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppPaletteDark.card,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppPaletteDark.gold.withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: AppPalette.rust.withValues(alpha: 0.2),
                        backgroundImage: guideData['profileImagePath'] != null ? NetworkImage(guideData['profileImagePath']) : null,
                        child: guideData['profileImagePath'] == null ? const Icon(Icons.person, color: AppPaletteDark.gold) : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              guideData['displayName'] ?? AppLocalizations.of(context)!.localGuideFallback,
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                color: AppTheme.colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              session.meetingPointName,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppTheme.colors.white.withValues(alpha: 0.6),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.verified_rounded, color: AppPaletteDark.gold, size: 22),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                if (session.vehicleNumber != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.directions_car_filled_rounded, color: AppPaletteDark.gold, size: 18),
                        const SizedBox(width: 10),
                        Text(
                          AppLocalizations.of(context)!.vehicleNumberLabel(session.vehicleNumber!),
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 24),

                // Consent Layer
                GestureDetector(
                  onTap: () {
                    setSheetState(() => _hasConsent = !_hasConsent);
                    setState(() => _hasConsent = _hasConsent);
                  },
                  child: Row(
                    children: [
                      Checkbox(
                        value: _hasConsent,
                        activeColor: AppPalette.rust,
                        checkColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        onChanged: (val) {
                          setSheetState(() => _hasConsent = val ?? false);
                          setState(() => _hasConsent = val ?? false);
                        },
                      ),
                      Expanded(
                        child: Text(
                          AppLocalizations.of(context)!.consentTrackingMessage,
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            color: AppTheme.colors.white.withValues(alpha: 0.6),
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _hasConsent ? AppPalette.rust : AppTheme.colors.white.withValues(alpha: 0.06),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: _hasConsent ? 4 : 0,
                      shadowColor: AppPalette.rust.withValues(alpha: 0.5),
                    ),
                    onPressed: _hasConsent ? () => _finalJoin(session) : null,
                    child: Text(
                      AppLocalizations.of(context)!.connectSyncButton,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: _hasConsent ? Colors.white : AppTheme.colors.white24,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _finalJoin(TourSession session) async {
    Navigator.pop(context); // Close sheet
    setState(() => _isProcessing = true);

    try {
      final user = AuthService().currentUser;
      if (user == null) throw "AUTH_REQUIRED";

      await _sessionRepo.validateAndJoin(
        token: _scannedToken!,
        touristId: user.uid,
        consent: _hasConsent,
      );

      // Update local preference
      final profile = UserPreferenceService.getProfile();
      profile.currentBatchId = session.sessionId;
      await UserPreferenceService.saveProfile(profile);

      if (mounted) {
        _showSuccessDialog(session.sessionId);
      }
    } catch (e) {
      if (mounted) {
        _showError(e.toString().replaceAll("Exception: ", ""));
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showSuccessDialog(String sessionId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 28),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppPaletteDark.surface.withValues(alpha: 0.96),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AppPaletteDark.gold.withValues(alpha: 0.25)),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.colors.black.withValues(alpha: 0.6),
                  blurRadius: 32,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.link_rounded, color: Color(0xFF10B981), size: 40)
                      .animate()
                      .scale(duration: 600.ms, curve: Curves.elasticOut),
                ),
                const SizedBox(height: 20),
                Text(
                  AppLocalizations.of(context)!.realitySyncedTitle,
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: AppTheme.colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  AppLocalizations.of(context)!.safetyProtocolsActiveMessage,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 13, color: AppTheme.colors.white.withValues(alpha: 0.7)),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppPalette.rust,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 4,
                      shadowColor: AppPalette.rust.withValues(alpha: 0.5),
                    ),
                    onPressed: () {
                      Navigator.pop(context); // Close dialog
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => TouristCompanionHub(sessionId: sessionId)),
                      );
                    },
                    child: Text(
                      AppLocalizations.of(context)!.enterHubButton,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Widget _buildGlassIconButton({
    required IconData icon,
    required VoidCallback onTap,
    Color? iconColor,
    Color? borderColor,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(50),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(50),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppPaletteDark.surface.withValues(alpha: 0.75),
                shape: BoxShape.circle,
                border: Border.all(
                  color: borderColor ?? AppTheme.colors.white.withValues(alpha: 0.15),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.colors.black.withValues(alpha: 0.35),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: iconColor ?? AppTheme.colors.white,
                size: 20,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLaserBeam(double maxHeight) {
    return OverflowBox(
      alignment: Alignment.topCenter,
      maxHeight: maxHeight,
      child: Container(
        width: double.infinity,
        height: 2.5,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppPaletteDark.gold.withValues(alpha: 0.0),
              AppPaletteDark.gold,
              AppPaletteDark.gold.withValues(alpha: 0.0),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: AppPaletteDark.gold.withValues(alpha: 0.85),
              blurRadius: 14,
              spreadRadius: 2.5,
            ),
          ],
        ),
      )
          .animate(onPlay: (controller) => controller.repeat(reverse: true))
          .moveY(begin: 0, end: maxHeight, duration: 1800.ms, curve: Curves.easeInOut),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final size = MediaQuery.of(context).size;
    const scanBoxSize = 250.0;
    // Position scan window slightly above center to balance bottom glass card
    final scanRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.42),
      width: scanBoxSize,
      height: scanBoxSize,
    );

    return Scaffold(
      backgroundColor: AppPaletteDark.bg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera Preview
          MobileScanner(
            controller: _scannerController,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  _handleScan(barcode.rawValue!);
                  break;
                }
              }
            },
          ),

          // Luxury Darkened Viewport Mask with Golden Reticle
          CustomPaint(
            size: size,
            painter: _ScannerOverlayPainter(
              scanWindow: scanRect,
              cornerColor: AppPaletteDark.gold,
              borderRadius: 24,
              cornerLength: 32,
              cornerWidth: 3.5,
              overlayColor: AppTheme.colors.black.withValues(alpha: 0.62),
            ),
          ),

          // Animated Laser Scan Beam inside Viewfinder
          if (!_isProcessing)
            Positioned(
              left: scanRect.left + 12,
              width: scanRect.width - 24,
              top: scanRect.top + 8,
              height: scanRect.height - 16,
              child: _buildLaserBeam(scanRect.height - 16),
            ),

          // Top Navigation & Controls Bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              top: true,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Close button
                    _buildGlassIconButton(
                      icon: Icons.close_rounded,
                      onTap: () => Navigator.pop(context),
                    ),

                    // Header title & live status badge
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'TOUR COMPANION',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2.2,
                            color: AppPaletteDark.gold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: _isProcessing ? AppPaletteDark.gold : const Color(0xFF10B981),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: (_isProcessing ? AppPaletteDark.gold : const Color(0xFF10B981)).withValues(alpha: 0.6),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _isProcessing
                                  ? (l10n?.decryptingTokenMessage ?? 'VERIFYING...')
                                  : 'READY TO SCAN',
                              style: GoogleFonts.inter(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                                color: AppTheme.colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Right action buttons (Torch & Camera flip)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildGlassIconButton(
                          icon: _isTorchOn ? Icons.flashlight_on_rounded : Icons.flashlight_off_rounded,
                          iconColor: _isTorchOn ? AppPaletteDark.gold : AppTheme.colors.white,
                          borderColor: _isTorchOn ? AppPaletteDark.gold.withValues(alpha: 0.6) : null,
                          onTap: _toggleTorch,
                        ),
                        const SizedBox(width: 8),
                        _buildGlassIconButton(
                          icon: Icons.flip_camera_ios_rounded,
                          onTap: _switchCamera,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Instructional & Status Glass Card
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: true,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppPaletteDark.surface.withValues(alpha: 0.88),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: AppPaletteDark.gold.withValues(alpha: 0.25),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.colors.black.withValues(alpha: 0.5),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                          BoxShadow(
                            color: AppPaletteDark.gold.withValues(alpha: 0.08),
                            blurRadius: 20,
                            spreadRadius: -2,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppPalette.rust, AppPaletteDark.gold],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: AppPalette.rust.withValues(alpha: 0.45),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: _isProcessing
                                ? const Center(
                                    child: SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    ),
                                  )
                                : const Icon(
                                    Icons.qr_code_scanner_rounded,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n?.tourVerificationTitle ?? 'Tour Verification',
                                  style: GoogleFonts.outfit(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.colors.white,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  _isProcessing
                                      ? (l10n?.decryptingTokenMessage ?? 'Verifying guide token...')
                                      : (l10n?.scanGuideTourCodeMessage ?? 'Scan your guide\'s tour code'),
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: AppTheme.colors.white.withValues(alpha: 0.75),
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter to draw darkened camera overlay and luxury corner reticles
class _ScannerOverlayPainter extends CustomPainter {
  final Rect scanWindow;
  final double borderRadius;
  final Color overlayColor;
  final Color cornerColor;
  final double cornerLength;
  final double cornerWidth;

  _ScannerOverlayPainter({
    required this.scanWindow,
    this.borderRadius = 24.0,
    this.overlayColor = const Color(0x99000000),
    this.cornerColor = AppPaletteDark.gold,
    this.cornerLength = 32.0,
    this.cornerWidth = 3.5,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()..color = overlayColor;
    final rrect = RRect.fromRectAndRadius(scanWindow, Radius.circular(borderRadius));

    // Draw darkened mask outside the scan window
    final backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(rrect)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(backgroundPath, backgroundPaint);

    // Subtle 1px inner border
    final borderPaint = Paint()
      ..color = cornerColor.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRRect(rrect, borderPaint);

    // 4 Corner Brackets
    final cornerPaint = Paint()
      ..color = cornerColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = cornerWidth
      ..strokeCap = StrokeCap.round;

    final left = scanWindow.left;
    final top = scanWindow.top;
    final right = scanWindow.right;
    final bottom = scanWindow.bottom;
    final r = borderRadius;
    final cl = cornerLength;

    // Top-Left
    final pathTL = Path()
      ..moveTo(left, top + cl)
      ..lineTo(left, top + r)
      ..arcToPoint(Offset(left + r, top), radius: Radius.circular(r))
      ..lineTo(left + cl, top);
    canvas.drawPath(pathTL, cornerPaint);

    // Top-Right
    final pathTR = Path()
      ..moveTo(right - cl, top)
      ..lineTo(right - r, top)
      ..arcToPoint(Offset(right, top + r), radius: Radius.circular(r))
      ..lineTo(right, top + cl);
    canvas.drawPath(pathTR, cornerPaint);

    // Bottom-Left
    final pathBL = Path()
      ..moveTo(left, bottom - cl)
      ..lineTo(left, bottom - r)
      ..arcToPoint(Offset(left + r, bottom), radius: Radius.circular(r))
      ..lineTo(left + cl, bottom);
    canvas.drawPath(pathBL, cornerPaint);

    // Bottom-Right
    final pathBR = Path()
      ..moveTo(right - cl, bottom)
      ..lineTo(right - r, bottom)
      ..arcToPoint(Offset(right, bottom - r), radius: Radius.circular(r))
      ..lineTo(right, bottom - cl);
    canvas.drawPath(pathBR, cornerPaint);
  }

  @override
  bool shouldRepaint(covariant _ScannerOverlayPainter oldDelegate) =>
      oldDelegate.scanWindow != scanWindow ||
      oldDelegate.cornerColor != cornerColor ||
      oldDelegate.overlayColor != overlayColor;
}
