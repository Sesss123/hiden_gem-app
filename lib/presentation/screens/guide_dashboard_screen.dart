import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/tour_session.dart';
import '../../data/models/vehicle.dart';
import '../../data/datasources/user_preference_service.dart';
import '../../data/datasources/auth_service.dart';
import '../../data/repositories/tour_session_repository.dart';
import '../../data/repositories/vehicle_repository.dart';
import 'package:uuid/uuid.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:ui';
import '../../data/repositories/presence_repository.dart';
import 'guide_broadcast_screen.dart';

import '../../data/repositories/meeting_point_repository.dart';
import '../../data/models/meeting_checkpoint.dart';

class GuideDashboardScreen extends StatefulWidget {
  const GuideDashboardScreen({super.key});

  @override
  State<GuideDashboardScreen> createState() => _GuideDashboardScreenState();
}

class _GuideDashboardScreenState extends State<GuideDashboardScreen> {
  TourSession? _activeSession;
  List<Vehicle> _vehicles = [];
  bool _isLoading = true;
  Timer? _locationTimer;
  StreamSubscription? _vehicleSub;
  
  final _sessionRepo = TourSessionRepository();
  final _vehicleRepo = VehicleRepository();
  final _presenceRepo = PresenceRepository();
  final _meetingRepo = MeetingPointRepository();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    _vehicleSub?.cancel();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      _loadActiveSession(),
      _loadVehicles(),
    ]);
    setState(() => _isLoading = false);
  }

  void _startLocationSync() {
    _locationTimer?.cancel();
    
    // Initial sync
    _performSync();

    // Start dynamic throttling
    _scheduleNextSync(const Duration(seconds: 10));
  }

  void _scheduleNextSync(Duration delay) {
    _locationTimer?.cancel();
    _locationTimer = Timer(delay, () async {
      final nextDelay = await _performSync();
      if (nextDelay != null) {
        _scheduleNextSync(nextDelay);
      }
    });
  }

  Future<Duration?> _performSync() async {
    if (_activeSession == null || _activeSession!.status != 'active' || _activeSession!.isLocked) {
      return null;
    }

    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 5)),
      );
      
      await _presenceRepo.updateGuidePresence(_activeSession!.sessionId, pos);
      
      // Smart Throttle Logic:
      // Speed > 5 m/s (~18 km/h) -> 5s (Vehicle)
      // Speed > 1 m/s -> 15s (Walking)
      // Speed <= 1 m/s -> 30s (Stationary)
      if (pos.speed > 5) return const Duration(seconds: 5);
      if (pos.speed > 1) return const Duration(seconds: 15);
      return const Duration(seconds: 30);
    } catch (e) {
      debugPrint("Zenith Presence Sync Error: $e");
      return const Duration(seconds: 20); // Fallback on error
    }
  }

  Future<void> _loadActiveSession() async {
    final profile = UserPreferenceService.getProfile();
    if (profile.currentBatchId != null) {
      final session = await _sessionRepo.getSession(profile.currentBatchId!);
      if (session != null) {
        setState(() => _activeSession = session);
      }
    }
  }

  Future<void> _loadVehicles() async {
    final uid = AuthService().currentUser?.uid;
    if (uid != null) {
      final stream = _vehicleRepo.getGuideVehicles(uid);
      _vehicleSub = stream.listen((v) {
        if (mounted) setState(() => _vehicles = v);
      });
    }
  }

  Future<void> _startNewTour(Vehicle vehicle) async {
    setState(() => _isLoading = true);
    final profile = UserPreferenceService.getProfile();
    final sessionId = const Uuid().v4();
    final uid = AuthService().currentUser?.uid ?? "unknown";
    
    final pos = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));
    
    final newSession = TourSession(
      sessionId: sessionId,
      guideId: uid,
      vehicleId: vehicle.id,
      meetingPointName: 'Initial Meeting Point',
      meetingPointLat: pos.latitude,
      meetingPointLng: pos.longitude,
      touristIds: const [],
      status: 'active',
      startedAt: DateTime.now(),
      trackingEnabled: true,
      sosActive: false,
    );

    await _sessionRepo.createSession(newSession);

    profile.currentBatchId = sessionId;
    await UserPreferenceService.saveProfile(profile);

    setState(() {
      _activeSession = newSession;
      _isLoading = false;
    });

    await _sessionRepo.startSession(sessionId);
    await _sessionRepo.generateJoinToken(sessionId);
    _startLocationSync();
  }

  Future<void> _updatePhase(String phase) async {
    if (_activeSession == null) return;
    try {
      await _sessionRepo.updateSessionPhase(_activeSession!.sessionId, phase);
      setState(() {
        _activeSession = _activeSession!.copyWith(currentPhase: phase);
      });
      HapticFeedback.mediumImpact();
    } catch (e) {
      debugPrint("Update Phase Error: $e");
    }
  }

  Future<void> _setMeetingPoint() async {
    final TextEditingController nameController = TextEditingController();
    
    final name = await showDialog<String>(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          backgroundColor: Colors.white.withValues(alpha: 0.05),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: AppTheme.secondaryBorder(context))),
          title: Text("SET MEETING POINT", style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary(context))),
          content: TextField(
            controller: nameController,
            autofocus: true,
            style: GoogleFonts.inter(color: AppTheme.textPrimary(context)),
            decoration: InputDecoration(
              hintText: "e.g., Temple Entrance, Bus Stand",
              hintStyle: GoogleFonts.inter(color: AppTheme.textSecondary(context)),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.secondaryBorder(context))),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text("CANCEL", style: GoogleFonts.outfit(color: AppTheme.textSecondary(context)))),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, nameController.text),
              style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary),
              child: Text("SET HERE", style: GoogleFonts.outfit(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );

    if (name == null || name.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final pos = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));
      final checkpoint = MeetingCheckpoint(
        checkpointId: const Uuid().v4(),
        sessionId: _activeSession!.sessionId,
        title: name,
        lat: pos.latitude,
        lng: pos.longitude,
        createdAt: DateTime.now(),
        createdBy: AuthService().currentUser?.uid ?? "unknown",
      );

      await _meetingRepo.updateMeetingPoint(checkpoint);
      
      // Update local state for immediate UI feedback
      setState(() {
        _activeSession = _activeSession!.copyWith(
          meetingPointName: name,
          meetingPointLat: pos.latitude,
          meetingPointLng: pos.longitude,
          meetingPointVersion: _activeSession!.meetingPointVersion + 1,
        );
      });
    } catch (e) {
      debugPrint("Set Meeting Point Error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateVehicleLocation() async {
    setState(() => _isLoading = true);
    try {
      final pos = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));
      await _presenceRepo.updateVehiclePresence(_activeSession!.sessionId, pos.latitude, pos.longitude);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("VEHICLE POSITION MARKED"), backgroundColor: Colors.orangeAccent),
      );
    } catch (e) {
      debugPrint("Update Vehicle Location Error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _stopTour() async {
    if (_activeSession == null) return;
    setState(() => _isLoading = true);
    final profile = UserPreferenceService.getProfile();
    
    await _sessionRepo.endSession(_activeSession!.sessionId);
    
    profile.currentBatchId = null;
    await UserPreferenceService.saveProfile(profile);

    setState(() {
      _activeSession = null;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new, size: 20, color: AppTheme.textPrimary(context)),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              "GUIDE COMMAND",
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                color: AppTheme.textPrimary(context),
              ),
            ),
          ),
          SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: _isLoading 
                  ? const Center(child: CircularProgressIndicator())
                  : _activeSession == null 
                    ? _buildEmptyState()
                    : _buildActiveSessionState(),
              ),
            ),
          ],
        ),
      );
  }

  Widget _buildEmptyState() {
    return Column(
      children: [
        const SizedBox(height: 100),
        Icon(Icons.tour_outlined, size: 80, color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)),
        const SizedBox(height: 24),
        Text(
          "NO ACTIVE TOUR",
          style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary(context)),
        ),
        const SizedBox(height: 12),
        Text(
          "Start a new tour and generate a QR for your travelers to connect.",
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(color: AppTheme.textSecondary(context)),
        ),
        const SizedBox(height: 48),
        SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () {
              if (_vehicles.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("ADD A VEHICLE IN PROFILE FIRST")));
                return;
              }
              _showVehiclePicker();
            },
            child: Text("GENERATE TOUR QR", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, letterSpacing: 2)),
          ),
        ),
      ],
    );
  }

  Widget _buildActiveSessionState() {
    // Guard: crash-safe null check before any access
    final session = _activeSession;
    if (session == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Text("Session data unavailable.",
              style: TextStyle(color: Colors.white38)),
        ),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            _buildStatCard("TRAVELERS", "${session.touristIds.length}", Icons.people_outline),
            const SizedBox(width: 12),
            _buildStatCard("RATING", "4.9", Icons.star_border_rounded),
            const SizedBox(width: 12),
            _buildStatCard("HOURS", "128h", Icons.timer_outlined),
          ],
        ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.2),
        const SizedBox(height: 24),
        
        // Phase Selector
        _buildPhaseSelector(),
        const SizedBox(height: 24),

        // Meeting & Vehicle Controls
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.add_location_alt_outlined, size: 18),
                label: Text(session.meetingPointName.isNotEmpty ? "UPDATE POINT" : "SET POINT"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.greenAccent,
                  side: const BorderSide(color: Colors.greenAccent, width: 1),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _setMeetingPoint,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.garage_outlined, size: 18),
                label: const Text("MARK VEHICLE"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orangeAccent,
                  side: const BorderSide(color: Colors.orangeAccent, width: 1),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _updateVehicleLocation,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Join Management
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("JOIN STATUS", style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary(context))),
                Text(session.isJoinOpen ? "OPEN TO SCANS" : "LOCKED",
                  style: GoogleFonts.inter(fontSize: 10, color: session.isJoinOpen ? Colors.greenAccent : Colors.redAccent)),
              ],
            ),
            Switch(
              value: session.isJoinOpen,
              activeThumbColor: Colors.greenAccent,
              onChanged: (val) => _sessionRepo.toggleJoinStatus(session.sessionId, val),
            ),
          ],
        ),
        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.secondaryBorder(context)),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Column(
            children: [
              if (session.joinToken != null && session.isJoinOpen)
                QrImageView(
                  data: '{"v":1,"t":"join","token":"${session.joinToken}"}',
                  version: QrVersions.auto,
                  size: 200.0,
                  eyeStyle: QrEyeStyle(eyeShape: QrEyeShape.square, color: Theme.of(context).colorScheme.primary),
                  dataModuleStyle: QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Colors.white),
                ).animate().scale(duration: 800.ms, curve: Curves.elasticOut)
              else
                SizedBox(
                  height: 200,
                  child: Center(
                    child: Text("JOINING PAUSED", style: GoogleFonts.outfit(color: Colors.white24, fontWeight: FontWeight.bold)),
                  ),
                ),
              const SizedBox(height: 16),
              TextButton.icon(
                icon: const Icon(Icons.refresh, size: 14),
                label: Text("REFRESH CODE", style: GoogleFonts.outfit(fontSize: 10, color: Colors.white54)),
                onPressed: () => _sessionRepo.generateJoinToken(session.sessionId),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 200.ms),
        const SizedBox(height: 32),

        // Broadcast Button
        SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.record_voice_over_rounded),
            label: Text("BROADCAST CENTER", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, letterSpacing: 2)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigoAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GuideBroadcastScreen(sessionId: session.sessionId),
                ),
              );
            },
          ),
        ).animate().fadeIn(delay: 400.ms),
        const SizedBox(height: 16),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("CONNECTED TRAVELERS", style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary(context))),
            Text("${session.touristIds.length} ACTIVE", style: GoogleFonts.inter(fontSize: 12, color: Colors.greenAccent)),
          ],
        ),
        const SizedBox(height: 16),
        session.touristIds.isEmpty
          ? Text("Waiting for scans...", style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.4)))
          : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: session.touristIds.length,
              itemBuilder: (context, index) => _buildTouristTile(session.touristIds[index]),
            ),
        const SizedBox(height: 32),
        _buildSosButton(),
        const SizedBox(height: 16),
        _buildEndTourButton(),
      ],
    );
  }

  Widget _buildPhaseSelector() {
    final phases = [
      {'id': 'assembling', 'label': 'ASSEMBLY', 'icon': Icons.group_add_outlined},
      {'id': 'en_route', 'label': 'EN ROUTE', 'icon': Icons.directions_bus_filled_outlined},
      {'id': 'at_site', 'label': 'AT SITE', 'icon': Icons.museum_outlined},
      {'id': 'break_time', 'label': 'BREAK', 'icon': Icons.coffee_outlined},
      {'id': 'returning', 'label': 'RETURNING', 'icon': Icons.keyboard_return_rounded},
    ];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.secondaryBorder(context)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: phases.map((p) {
            final isSelected = _activeSession?.currentPhase == p['id'];
            return GestureDetector(
              onTap: () => _updatePhase(p['id'] as String),
              child: AnimatedContainer(
                duration: 300.ms,
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? Theme.of(context).colorScheme.primary : Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isSelected ? Colors.transparent : Colors.white10),
                ),
                child: Row(
                  children: [
                    Icon(p['icon'] as IconData, size: 16, color: isSelected ? Colors.black : Colors.white54),
                    const SizedBox(width: 8),
                    Text(
                      p['label'] as String,
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.black : Colors.white54,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSosButton() {
     return SizedBox(
      width: double.infinity,
      height: 60,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.redAccent, width: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: () async {
          HapticFeedback.heavyImpact();
          final sessionId = _activeSession?.sessionId;
          if (sessionId == null) return; // Guard against null crash
          await _sessionRepo.triggerSos(sessionId, true);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("SOS ALERT BROADCASTED!")),
            );
          }
        },
        child: Text("TRIGGER SOS SIGNAL", style: GoogleFonts.outfit(color: Colors.redAccent, fontWeight: FontWeight.bold, letterSpacing: 2)),
      ),
    );
  }

  Widget _buildEndTourButton() {
    return SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: _stopTour,
            child: Text(
              "STOP TOUR SESSION",
              style: GoogleFonts.outfit(color: Colors.white54, fontWeight: FontWeight.bold, letterSpacing: 1),
            ),
          ),
        );
  }

  Future<void> _showVehiclePicker() async {
    final vehicle = await showModalBottomSheet<Vehicle>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: Border.all(color: Colors.white10),
        ),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("SELECT VEHICLE", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 24),
              ..._vehicles.map((v) => ListTile(
                leading: const Icon(Icons.garage_rounded, color: Colors.orangeAccent),
                title: Text(v.type, style: GoogleFonts.outfit(color: Colors.white)),
                subtitle: Text(v.vehicleNumber, style: GoogleFonts.inter(color: Colors.white38)),
                onTap: () => Navigator.pop(context, v),
              )),
          ],
        ),
      ),
    );

    if (vehicle != null) {
      _startNewTour(vehicle);
    }
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.secondaryBorder(context)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: Colors.white54),
            const SizedBox(height: 8),
            Text(value, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 4),
            Text(label, style: GoogleFonts.inter(fontSize: 10, letterSpacing: 1, color: Colors.white54)),
          ],
        ),
      ),
    );
  }

  Widget _buildTouristTile(String uid) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.secondaryBorder(context)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
            const CircleAvatar(backgroundColor: Colors.white10, child: Icon(Icons.person, size: 20, color: Colors.white)),
            const SizedBox(width: 16),
            Text("Traveler ${uid.substring(0, 6)}", style: GoogleFonts.inter(color: Colors.white)),
            const Spacer(),
            const Icon(Icons.location_on, size: 16, color: Colors.greenAccent),
          ],
        ),
      );
  }
}
