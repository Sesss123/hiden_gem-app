import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/oracle_ui_system.dart';
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
        reportedByRole: profile.role ?? 'tourist',
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
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
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
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: OracleUI.neonText(
          "GUARDIAN SYSTEM",
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: 4,
            color: Colors.white,
          ),
        ),
      ),
      body: OracleUI.auraBackground(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSOSSection().animate().fadeIn(duration: 800.ms).slideY(begin: 0.1),
              SizedBox(height: 48),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OracleUI.neonText(
                    "CRITICAL CONTACTS",
                    style: GoogleFonts.inter(
                      fontSize: 12, 
                      fontWeight: FontWeight.w900, 
                      letterSpacing: 2, 
                      color: Colors.white24
                    ),
                  ),
                  Text(
                    "DIRECT LINES",
                    style: GoogleFonts.inter(color: Colors.white10, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)
                  ),
                ],
              ),
              SizedBox(height: 24),
              _buildContactGrid(),
              
              SizedBox(height: 48),
              _buildSOSContactManager(),

              SizedBox(height: 48),
              OracleUI.neonText(
                "MEDICAL NODES NEARBY",
                style: GoogleFonts.inter(
                  fontSize: 12, 
                  fontWeight: FontWeight.w900, 
                  letterSpacing: 2, 
                  color: Colors.white24
                ),
              ),
              SizedBox(height: 24),
              _buildHospitalsList(),
              SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSOSSection() {
    return OracleUI.glassContainer(
      padding: EdgeInsets.all(32),
      borderRadius: BorderRadius.circular(32),
      borderColor: Colors.redAccent.withValues(alpha: 0.1),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              // Outer Pulse
              Container(
                width: 140, height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.redAccent.withValues(alpha: 0.2), width: 1),
                ),
              ).animate(onPlay: (c) => c.repeat()).scale(
                begin: const Offset(1, 1), end: const Offset(1.5, 1.5), 
                duration: 2000.ms, curve: Curves.easeOut
              ).fadeOut(),
              
              GestureDetector(
                onTap: _isSendingSOS ? null : _handleSOS,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.redAccent.withValues(alpha: 0.5),
                        blurRadius: 40,
                        spreadRadius: 5,
                      )
                    ],
                  ),
                  child: Center(
                    child: _isSendingSOS 
                      ? CircularProgressIndicator(color: Colors.white, strokeWidth: 3)
                      : Text(
                          "SOS",
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 24, letterSpacing: 2),
                        ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 32),
          OracleUI.neonText(
            "DISTRESS BEACON",
            style: GoogleFonts.inter(
              fontSize: 13, 
              fontWeight: FontWeight.w900, 
              letterSpacing: 1.5, 
              color: Colors.white
            ),
            glowColor: Colors.redAccent,
          ),
          SizedBox(height: 8),
          Text(
            "Sends location-tagged alerts to contacts",
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: Colors.white30, fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildContactGrid() {
    final List<Map<String, dynamic>> contacts = [
      {"name": "Police", "phone": "119", "icon": Icons.local_police, "color": Colors.blueAccent},
      {"name": "Ambulance", "phone": "1990", "icon": Icons.medical_services, "color": Theme.of(context).colorScheme.primary},
      {"name": "Tourist Police", "phone": "0112421451", "icon": Icons.beach_access, "color": Colors.orangeAccent},
      {"name": "Fire Dept", "phone": "110", "icon": Icons.fire_truck, "color": Colors.redAccent},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.1,
      ),
      itemCount: contacts.length,
      itemBuilder: (context, index) {
        final contact = contacts[index];
        return OracleUI.glassContainer(
          padding: EdgeInsets.all(20),
          borderRadius: BorderRadius.circular(24),
          borderColor: (contact['color'] as Color).withValues(alpha: 0.1),
          child: InkWell(
            onTap: () => _launchCaller(contact['phone'] as String),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(contact['icon'] as IconData, color: contact['color'] as Color, size: 28),
                SizedBox(height: 12),
                Text(
                  (contact['name'] as String).toUpperCase(), 
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: Colors.white, 
                    fontWeight: FontWeight.w900, 
                    fontSize: 10,
                    letterSpacing: 1,
                  )
                ),
                SizedBox(height: 4),
                OracleUI.neonText(
                  contact['phone'] as String,
                  style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white),
                  glowColor: (contact['color'] as Color).withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        ).animate().fadeIn(delay: (index * 100).ms, duration: 400.ms).scale(begin: const Offset(0.9, 0.9));
      },
    );
  }

  Widget _buildSOSContactManager() {
    final profile = UserPreferenceService.getProfile();
    return OracleUI.glassContainer(
      padding: EdgeInsets.all(24),
      borderRadius: BorderRadius.circular(24),
      borderColor: Colors.white.withValues(alpha: 0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "PRIVATE GUARDIANS", 
                style: GoogleFonts.inter(color: Colors.white30, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 2)
              ),
              IconButton(
                onPressed: _showAddContactDialog,
                icon: Icon(Icons.add_link_rounded, color: Theme.of(context).colorScheme.primary, size: 20),
              ),
            ],
          ),
          SizedBox(height: 12),
          if (profile.sosContacts.isEmpty)
            Text(
              "No guardians assigned. Signals will default to emergency services.", 
              style: GoogleFonts.inter(color: Colors.white12, fontSize: 11, fontStyle: FontStyle.italic)
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: profile.sosContacts.map((c) => OracleUI.glassContainer(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                borderRadius: BorderRadius.circular(12),
                borderColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(c, style: GoogleFonts.outfit(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                    SizedBox(width: 8),
                    GestureDetector(
                      onTap: () async {
                        final p = UserPreferenceService.getProfile();
                        p.sosContacts.remove(c);
                        await UserPreferenceService.saveProfile(p);
                        setState(() {});
                      },
                      child: Icon(Icons.close_rounded, color: Colors.redAccent, size: 14),
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
    return OracleUI.glassContainer(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(24),
      borderColor: Colors.white.withValues(alpha: 0.05),
      child: Row(
        children: [
          OracleUI.glassContainer(
            padding: EdgeInsets.all(12),
            borderRadius: BorderRadius.circular(12),
            borderColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            child: Icon(Icons.local_hospital, color: Theme.of(context).colorScheme.primary, size: 20),
          ),
          SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.toUpperCase(), 
                  style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5)
                ),
                Text(
                  "$location • $distance", 
                  style: GoogleFonts.inter(color: Colors.white10, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.phone_paused_rounded, color: Colors.white30, size: 20),
            onPressed: () => _launchCaller(phone),
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
        backgroundColor: Colors.transparent,
        child: OracleUI.glassContainer(
          padding: EdgeInsets.all(32),
          borderRadius: BorderRadius.circular(32),
          borderColor: Colors.white.withValues(alpha: 0.1),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              OracleUI.neonText(
                "LINK GUARDIAN", 
                style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 2, color: Colors.white)
              ),
              SizedBox(height: 24),
              OracleUI.glassContainer(
                padding: EdgeInsets.symmetric(horizontal: 16),
                borderRadius: BorderRadius.circular(16),
                borderColor: Colors.white.withValues(alpha: 0.05),
                child: TextField(
                  style: TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: "Guardian Phone Number",
                    hintStyle: TextStyle(color: Colors.white24, fontSize: 13),
                    border: InputBorder.none,
                  ),
                  keyboardType: TextInputType.phone,
                  onChanged: (v) => phone = v,
                ),
              ),
              SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (phone.isNotEmpty) {
                      final p = UserPreferenceService.getProfile();
                      p.sosContacts.add(phone);
                      await UserPreferenceService.saveProfile(p);
                      setState(() {});
                      if (context.mounted) Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text("ESTABLISH LINK", style: TextStyle(fontWeight: FontWeight.w900)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
