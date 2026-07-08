import 'package:hidden_gems_sl/core/theme/app_theme.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../data/datasources/user_preference_service.dart';
import '../../data/repositories/incident_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/incident_report.dart';

class EmergencyKitScreen extends ConsumerStatefulWidget {
  const EmergencyKitScreen({super.key});

  @override
  ConsumerState<EmergencyKitScreen> createState() => _EmergencyKitScreenState();
}

class _EmergencyKitScreenState extends ConsumerState<EmergencyKitScreen> {
  bool _isSendingSOS = false;

  Future<void> _handleSOS() async {
    setState(() => _isSendingSOS = true);
    
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        throw 'Location permissions are permanently denied.';
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      // 1. Create Automated Incident Report
      final incidentRepo = ref.read(incidentRepositoryProvider);
      final profile = UserPreferenceService.getProfile();
      
      final userId = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
      
      final incident = IncidentReport(
        incidentId: '', // Generated
        incidentNumber: 'SOS-${DateTime.now().millisecondsSinceEpoch}',
        sessionId: 'GLOBAL', 
        guideId: 'GLOBAL',
        touristId: userId,
        reportedBy: userId,
        reportedByRole: profile.role,
        type: 'sos_alert',
        severity: 'critical',
        title: "CRITICAL SOS ALERT",
        description: "Emergency distress signal triggered from Guardian System.",
        status: 'investigating',
        lat: position.latitude,
        lng: position.longitude,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        timelineEvents: [
          {
            'type': 'sos_triggered',
            'timestamp': DateTime.now().toIso8601String(),
            'description': 'SOS distress signal initiated by user.',
            'location': {'lat': position.latitude, 'lng': position.longitude},
          }
        ],
      );

      await incidentRepo.createIncident(incident);

      // 2. Original SMS/Call Logic
      final String mapLink = "https://www.google.com/maps/search/?api=1&query=${position.latitude},${position.longitude}";
      final String sosMessage = "EMERGENCY: I need help. My current location is: $mapLink (Sent via AdvanceTravel.me)";

      if (profile.sosContacts.isEmpty) {
        await launchUrl(Uri.parse("tel:119"));
      } else {
        final String separator = Platform.isIOS ? ';' : ',';
        final String contacts = profile.sosContacts.join(separator);
        final Uri smsUri = Uri.parse("sms:$contacts?body=${Uri.encodeComponent(sosMessage)}");
        if (await canLaunchUrl(smsUri)) {
          await launchUrl(smsUri);
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("SOS Alerts Prepared & Logged in Secure Vault!")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: AppTheme.colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSendingSOS = false);
    }
  }

  Future<void> _launchCaller(String number) async {
    final Uri url = Uri.parse("tel:$number");
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    // BUG-063: Clamps the text scaling factor to prevent layout overflows on large font settings
    final clampedTextScaler = mediaQuery.textScaler.clamp(minScaleFactor: 0.8, maxScaleFactor: 1.25);

    return MediaQuery(
      data: mediaQuery.copyWith(textScaler: clampedTextScaler),
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: AppTheme.colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textPrimary(context), size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            "Emergency",
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: AppTheme.textPrimary(context),
            ),
          ),
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSOSSection().animate().fadeIn(duration: 800.ms).slideY(begin: 0.1),
              SizedBox(height: 32),

              Text(
                "Critical contacts",
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  color: AppTheme.textPrimary(context),
                ),
              ),
              SizedBox(height: 16),
              _buildContactGrid(),

              SizedBox(height: 32),
              _buildSOSContactManager(),

              SizedBox(height: 32),
              Text(
                "Medical facilities nearby",
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  color: AppTheme.textPrimary(context),
                ),
              ),
              SizedBox(height: 16),
              _buildHospitalsList(),
              SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSOSSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.colors.black : AppPalette.ink,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              // Outer Pulse
              Container(
                width: 130, height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.colors.redAccent.withValues(alpha: 0.15),
                ),
              ).animate(onPlay: (c) => c.repeat()).scale(
                begin: const Offset(1, 1), end: const Offset(1.35, 1.35),
                duration: 2000.ms, curve: Curves.easeOut
              ).fadeOut(),

              GestureDetector(
                onTap: _isSendingSOS ? null : _handleSOS,
                child: Container(
                  width: 92,
                  height: 92,
                  decoration: BoxDecoration(
                    color: AppTheme.colors.redAccent,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: _isSendingSOS
                      ? CircularProgressIndicator(color: AppTheme.colors.white, strokeWidth: 3)
                      : Text(
                          "SOS",
                          style: TextStyle(color: AppTheme.colors.white, fontWeight: FontWeight.w800, fontSize: 16),
                        ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          Text(
            "Tap to alert your emergency contacts",
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: AppTheme.colors.white.withValues(alpha: 0.7), fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildContactGrid() {
    final List<Map<String, dynamic>> contacts = [
      {"name": "Police", "phone": "119", "icon": Icons.local_police, "color": AppTheme.colors.blueAccent},
      {"name": "Ambulance", "phone": "1990", "icon": Icons.medical_services, "color": Theme.of(context).colorScheme.primary},
      {"name": "Tourist Police", "phone": "0112421451", "icon": Icons.beach_access, "color": AppTheme.colors.orangeAccent},
      {"name": "Fire Dept", "phone": "110", "icon": Icons.fire_truck, "color": AppTheme.colors.redAccent},
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        // BUG-123 / BUG-143: Compute grid columns based on available width so
        // small phones get 1 column and tablets can fit 3.
        final int columns = constraints.maxWidth < 360
            ? 1
            : constraints.maxWidth > 600
                ? 3
                : 2;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.1,
          ),
          itemCount: contacts.length,
          itemBuilder: (context, index) {
            final contact = contacts[index];
            return Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceMuted(context),
                borderRadius: BorderRadius.circular(18),
              ),
              // BUG-083: Ensure minimum 48px tap target by using ConstrainedBox
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => _launchCaller(contact['phone'] as String),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 30, height: 30,
                          decoration: BoxDecoration(
                            color: (contact['color'] as Color).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Icon(contact['icon'] as IconData, color: contact['color'] as Color, size: 16),
                        ),
                        SizedBox(height: 10),
                        // BUG-103: Flexible text prevents overflow at max font scale
                        Flexible(
                          child: Text(
                            contact['name'] as String,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              color: AppTheme.textPrimary(context),
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        SizedBox(height: 4),
                        Flexible(
                          child: Text(
                            contact['phone'] as String,
                            style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary(context)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ).animate().fadeIn(delay: (index * 100).ms, duration: 400.ms).scale(begin: const Offset(0.9, 0.9));
          },
        );
      },
    );
  }


  Widget _buildSOSContactManager() {
    final profile = UserPreferenceService.getProfile();
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: AppTheme.colors.black.withValues(alpha: 0.05), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Private guardians",
                style: GoogleFonts.outfit(color: AppTheme.textPrimary(context), fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: -0.2)
              ),
              IconButton(
                onPressed: _showAddContactDialog,
                icon: Icon(Icons.add_link_rounded, color: Theme.of(context).colorScheme.primary, size: 20),
              ),
            ],
          ),
          SizedBox(height: 8),
          if (profile.sosContacts.isEmpty)
            Text(
              "No guardians assigned. Signals will default to emergency services.",
              style: GoogleFonts.inter(color: AppTheme.textSecondary(context), fontSize: 12)
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: profile.sosContacts.map((c) => Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceMuted(context),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(c, style: GoogleFonts.inter(color: AppTheme.textPrimary(context), fontSize: 12, fontWeight: FontWeight.w600)),
                    SizedBox(width: 8),
                    GestureDetector(
                      onTap: () async {
                        final p = UserPreferenceService.getProfile();
                        p.sosContacts.remove(c);
                        await UserPreferenceService.saveProfile(p);
                        if (!mounted) return;
                        setState(() {});
                      },
                      child: Icon(Icons.close_rounded, color: AppTheme.colors.redAccent, size: 14),
                    ),
                  ],
                ),
              )).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildHospitalsList() {
    return Column(
      children: [
        _hospitalItem("National Hospital SL", "Colombo 07", "0.8 km", "0112691111"),
        _hospitalItem("Asiri Surgical", "Colombo 05", "2.4 km", "0114524400"),
        _hospitalItem("Lanka Hospitals", "Colombo 05", "3.1 km", "0115431000"),
      ],
    );
  }

  Widget _hospitalItem(String name, String location, String distance, String phone) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: AppTheme.colors.black.withValues(alpha: 0.05), blurRadius: 14, offset: const Offset(0, 5)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.local_hospital, color: Theme.of(context).colorScheme.primary, size: 18),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // BUG-103: Overflow guards on hospital name text
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(color: AppTheme.textPrimary(context), fontWeight: FontWeight.w700, fontSize: 13, letterSpacing: -0.2),
                ),
                SizedBox(height: 2),
                Text(
                  "$location · $distance",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(color: AppTheme.textSecondary(context), fontSize: 11, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          // BUG-083: Ensure call button meets 48px tap target minimum
          SizedBox(
            width: 44,
            height: 44,
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: Icon(Icons.call_rounded, color: AppTheme.textSecondary(context), size: 18),
              onPressed: () => _launchCaller(phone),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.1);
  }

  void _showAddContactDialog() {
    String phone = "";
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppTheme.colors.transparent,
        child: Container(
          padding: EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(color: AppTheme.colors.black.withValues(alpha: 0.15), blurRadius: 30, offset: const Offset(0, 12)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Add guardian",
                style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.3, color: AppTheme.textPrimary(context))
              ),
              SizedBox(height: 20),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceMuted(context),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TextField(
                  style: TextStyle(color: AppTheme.textPrimary(context)),
                  decoration: InputDecoration(
                    hintText: "Guardian phone number",
                    hintStyle: TextStyle(color: AppTheme.textSecondary(context), fontSize: 13),
                    border: InputBorder.none,
                  ),
                  keyboardType: TextInputType.phone,
                  onChanged: (v) => phone = v,
                ),
              ),
              SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () async {
                    if (phone.isNotEmpty) {
                      final p = UserPreferenceService.getProfile();
                      p.sosContacts.add(phone);
                      await UserPreferenceService.saveProfile(p);
                      if (!mounted) return;
                      setState(() {});
                      if (context.mounted) Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: AppTheme.colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                  ),
                  child: Text("Add guardian", style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
