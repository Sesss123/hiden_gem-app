import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/oracle_ui_system.dart';
import '../../data/datasources/user_preference_service.dart';
import '../../data/datasources/auth_service.dart';
import '../../data/models/tour_session.dart';
import '../../data/repositories/tour_session_repository.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';
import 'dart:convert';
import 'package:flutter/services.dart';
import './tourist_companion_hub.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  bool _isProcessing = false;
  bool _hasConsent = false;
  String? _scannedToken;
  
  final _sessionRepo = TourSessionRepository();

  Future<void> _handleScan(String code) async {
    if (_isProcessing) return;

    try {
      final Map<String, dynamic> data = jsonDecode(code);
      if (data['v'] != 1 || data['t'] != 'join' || data['token'] == null) {
        _showError("INVALID QR FORMAT");
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
      _showError("UNRECOGNIZED QR CODE");
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
        _showError("SESSION NOT FOUND OR CLOSED");
        setState(() => _isProcessing = false);
        return;
      }

      final session = TourSession.fromJson(query.docs.first.data());
      final guideDoc = await FirebaseFirestore.instance.collection('users').doc(session.guideId).get();
      
      if (mounted) {
        _showJoinSheet(session, guideDoc.data() ?? {});
      }
    } catch (e) {
      _showError("CONNECTION ERROR");
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _showJoinSheet(TourSession session, Map<String, dynamic> guideData) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A).withOpacity(0.9),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                OracleUI.neonText("TOUR VERIFICATION", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                
                // Guide Info Card
                OracleUI.glassContainer(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 25, 
                        backgroundColor: Colors.white10, 
                        backgroundImage: guideData['profileImagePath'] != null ? NetworkImage(guideData['profileImagePath']) : null,
                        child: guideData['profileImagePath'] == null ? const Icon(Icons.person, color: Colors.white) : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(guideData['displayName'] ?? "LOCAL GUIDE", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
                            Text(session.meetingPointName, style: GoogleFonts.inter(fontSize: 12, color: Colors.white54), overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                      const Icon(Icons.verified, color: Colors.blueAccent, size: 20),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                if (session.vehicleNumber != null)
                   Row(
                    children: [
                      const Icon(Icons.garage_rounded, color: Colors.orangeAccent, size: 16),
                      const SizedBox(width: 8),
                      Text("VEHICLE: ${session.vehicleNumber}", style: GoogleFonts.inter(fontSize: 12, color: Colors.white70)),
                    ],
                  ),
                const SizedBox(height: 32),

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
                        activeColor: Theme.of(context).colorScheme.primary,
                        onChanged: (val) {
                          setSheetState(() => _hasConsent = val ?? false);
                          setState(() => _hasConsent = val ?? false);
                        },
                      ),
                      Expanded(
                        child: Text(
                          "I consent to live location tracking and safety monitoring for this tour session.",
                          style: GoogleFonts.inter(fontSize: 11, color: Colors.white54),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _hasConsent ? Theme.of(context).colorScheme.primary : Colors.white.withOpacity(0.05),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: _hasConsent ? () => _finalJoin(session) : null,
                    child: Text("CONNECT & SYNC", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: _hasConsent ? Colors.black : Colors.white24)),
                  ),
                ),
                const SizedBox(height: 16),
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
      _showError(e.toString().replaceAll("Exception: ", ""));
      setState(() => _isProcessing = false);
    }
  }

  void _showSuccessDialog(String sessionId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Center(
          child: OracleUI.glassContainer(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.link_rounded, color: Colors.greenAccent, size: 64)
                    .animate().scale(duration: 600.ms, curve: Curves.elasticOut),
                const SizedBox(height: 24),
                OracleUI.neonText("REALITY SYNCED", style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                const Text("Global safety protocols and live tracking active.", textAlign: TextAlign.center, style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => TouristCompanionHub(sessionId: sessionId)),
                    );
                  },
                  child: const Text("ENTER HUB"),
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
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
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
          // Scanner Overlay
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).colorScheme.primary, width: 2),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Stack(
                    children: [
                      // Laser Line Animation
                      if (!_isProcessing)
                        _buildLaserLine(),
                    ],
                  ),
                ),
                if (_isProcessing)
                  Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: OracleUI.neonText("DECRYPTING TOKEN...", style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          ),
          // Controls
          Positioned(
            top: 60,
            left: 20,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 28),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Center(
              child: OracleUI.glassContainer(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: OracleUI.neonText(
                  "SCAN PROTECTED QR",
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLaserLine() {
    return Container(
      width: double.infinity,
      height: 2,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        boxShadow: [
          BoxShadow(color: Theme.of(context).colorScheme.primary, blurRadius: 10, spreadRadius: 2),
        ],
      ),
    ).animate(onPlay: (controller) => controller.repeat(reverse: true))
     .moveY(begin: 0, end: 248, duration: 1500.ms, curve: Curves.easeInOut);
  }
}
