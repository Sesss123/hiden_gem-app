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
import '../../core/services/monsoon_broadcast_service.dart';
import 'incident_center_screen.dart';
import '../../data/models/incident_report.dart';
import '../../data/repositories/incident_repository.dart';
import 'subscription_screen.dart';
import 'guide_reviews_screen.dart';

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
  StreamSubscription<Map<String, dynamic>>? _monsoonSub;
  Map<String, dynamic>? _activeMonsoonAlert;
  int _currentTabIndex = 0;
  
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
    _monsoonSub?.cancel();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      _loadActiveSession(),
      _loadVehicles(),
    ]);
    if (!mounted) return;
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Zenith Presence Sync Error: ${e.toString()}"),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
      return const Duration(seconds: 20); // Fallback on error
    }
  }

  Future<void> _loadActiveSession() async {
    final uid = AuthService().currentUser?.uid;
    if (uid == null) return;

    var session = await _sessionRepo.getActiveOrInitialSessionForGuide(uid);
    if (session == null) {
      final profile = UserPreferenceService.getProfile();
      if (profile.currentBatchId != null) {
        session = await _sessionRepo.getSession(profile.currentBatchId!);
      }
    }

    if (session != null) {
      final profile = UserPreferenceService.getProfile();
      profile.currentBatchId = session.sessionId;
      await UserPreferenceService.saveProfile(profile);

      if (!mounted) return;
      setState(() => _activeSession = session);
      _setupMonsoonSafetyListener(session.meetingPointName);
      if (session.status == 'active' && !session.isLocked) {
        _startLocationSync();
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

    if (!mounted) return;
    setState(() {
      _activeSession = newSession;
      _isLoading = false;
    });

    await _sessionRepo.startSession(sessionId);
    await _sessionRepo.generateJoinToken(sessionId);
    if (!mounted) return;
    _startLocationSync();
    _setupMonsoonSafetyListener("Initial Meeting Point");
  }

  Future<void> _updatePhase(String phase) async {
    if (_activeSession == null) return;
    try {
      await _sessionRepo.updateSessionPhase(_activeSession!.sessionId, phase);
      if (!mounted) return;
      setState(() {
        _activeSession = _activeSession!.copyWith(currentPhase: phase);
      });
      HapticFeedback.mediumImpact();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to update phase: ${e.toString()}"),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _setMeetingPoint() async {
    final TextEditingController nameController = TextEditingController();
    
    final name = await showDialog<String>(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          backgroundColor: AppTheme.colors.white.withValues(alpha: 0.05),
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
              child: Text("SET HERE", style: GoogleFonts.outfit(color: AppTheme.colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );

    if (name == null || name.isEmpty) return;

    if (!mounted) return;
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
      if (!mounted) return;
      setState(() {
        _activeSession = _activeSession!.copyWith(
          meetingPointName: name,
          meetingPointLat: pos.latitude,
          meetingPointLng: pos.longitude,
          meetingPointVersion: _activeSession!.meetingPointVersion + 1,
        );
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to set meeting point: ${e.toString()}"),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateVehicleLocation() async {
    setState(() => _isLoading = true);
    try {
      final pos = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));
      await _presenceRepo.updateVehiclePresence(_activeSession!.sessionId, pos.latitude, pos.longitude);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("VEHICLE POSITION MARKED"), backgroundColor: AppTheme.colors.orangeAccent),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to update vehicle location: ${e.toString()}"),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _stopTour() async {
    if (_activeSession == null) return;
    setState(() => _isLoading = true);
    final profile = UserPreferenceService.getProfile();
    
    await _sessionRepo.endSession(_activeSession!.sessionId);
    
    profile.currentBatchId = null;
    await UserPreferenceService.saveProfile(profile);

    if (!mounted) return;
    setState(() {
      _activeSession = null;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: PopScope(
        canPop: _currentTabIndex == 0,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop && _currentTabIndex != 0) {
            setState(() => _currentTabIndex = 0);
          }
        },
        child: _buildTabContent(),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildTabContent() {
    switch (_currentTabIndex) {
      case 1:
        return const SubscriptionScreen();
      case 2:
        return GuideReviewsScreen(guideId: AuthService().currentUser?.uid ?? "guest_guide");
      case 3:
        return IncidentCenterScreen(sessionId: _activeSession?.sessionId);
      case 0:
      default:
        return CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor: AppTheme.colors.transparent,
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
        );
    }
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.95),
        border: Border(top: BorderSide(color: AppTheme.secondaryBorder(context), width: 0.5)),
      ),
      child: NavigationBar(
        selectedIndex: _currentTabIndex,
        onDestinationSelected: (index) {
          HapticFeedback.lightImpact();
          setState(() => _currentTabIndex = index);
        },
        backgroundColor: AppTheme.colors.transparent,
        elevation: 0,
        indicatorColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore, color: AppTheme.colors.amber),
            label: 'Tour Session',
          ),
          NavigationDestination(
            icon: Icon(Icons.card_membership_outlined),
            selectedIcon: Icon(Icons.card_membership, color: AppTheme.colors.amber),
            label: 'Subscription',
          ),
          NavigationDestination(
            icon: Icon(Icons.star_border_rounded),
            selectedIcon: Icon(Icons.star_rounded, color: AppTheme.colors.amber),
            label: 'Reviews',
          ),
          NavigationDestination(
            icon: Icon(Icons.shield_outlined),
            selectedIcon: Icon(Icons.shield, color: AppTheme.colors.amber),
            label: 'Safety',
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
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Text("Session data unavailable.",
              style: TextStyle(color: AppTheme.textSecondary(context))),
        ),
      );
    }

    return Column(
      children: [
        if (_activeMonsoonAlert != null) _buildMonsoonSafetyBanner(_activeMonsoonAlert!),
        if (session.status == 'initial')
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 24),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.colors.amber.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.colors.amber, width: 1.5),
            ),
            child: Column(
              children: [
                Text("UPCOMING TOUR SESSION READY", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.colors.amber)),
                const SizedBox(height: 8),
                Text("Travelers and meeting point confirmed. Tap below when you and the travelers arrive at the meeting point to officially start the timer and tracking.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textPrimary(context))),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.colors.amber,
                      foregroundColor: AppTheme.colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.play_arrow_rounded, size: 24),
                    label: Text("START TOUR SESSION", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15)),
                    onPressed: () async {
                      HapticFeedback.mediumImpact();
                      setState(() => _isLoading = true);
                      await _sessionRepo.startSession(session.sessionId);
                      await _sessionRepo.generateJoinToken(session.sessionId);
                      final updated = await _sessionRepo.getSession(session.sessionId);
                      if (mounted) {
                        setState(() {
                          _activeSession = updated ?? session.copyWith(status: 'active');
                          _isLoading = false;
                        });
                        _startLocationSync();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("🚀 Tour Session Started!"), backgroundColor: AppTheme.colors.green),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
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
                  foregroundColor: AppTheme.colors.greenAccent,
                  side: const BorderSide(color: AppTheme.colors.greenAccent, width: 1),
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
                  foregroundColor: AppTheme.colors.orangeAccent,
                  side: const BorderSide(color: AppTheme.colors.orangeAccent, width: 1),
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
                  style: GoogleFonts.inter(fontSize: 10, color: session.isJoinOpen ? AppTheme.colors.greenAccent : AppTheme.colors.redAccent)),
              ],
            ),
            Switch(
              value: session.isJoinOpen,
              activeThumbColor: AppTheme.colors.greenAccent,
              onChanged: (val) => _sessionRepo.toggleJoinStatus(session.sessionId, val),
            ),
          ],
        ),
        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppTheme.cardColor(context),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.secondaryBorder(context)),
            boxShadow: [BoxShadow(color: AppTheme.colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Column(
            children: [
              if (session.joinToken != null && session.isJoinOpen)
                QrImageView(
                  data: '{"v":1,"t":"join","token":"${session.joinToken}"}',
                  version: QrVersions.auto,
                  size: 200.0,
                  eyeStyle: QrEyeStyle(eyeShape: QrEyeShape.square, color: Theme.of(context).colorScheme.primary),
                  dataModuleStyle: QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: AppTheme.textPrimary(context)),
                ).animate().scale(duration: 800.ms, curve: Curves.elasticOut)
              else
                SizedBox(
                  height: 200,
                  child: Center(
                    child: Text("JOINING PAUSED", style: GoogleFonts.outfit(color: AppTheme.textSecondary(context), fontWeight: FontWeight.bold)),
                  ),
                ),
              const SizedBox(height: 16),
              TextButton.icon(
                icon: const Icon(Icons.refresh, size: 14),
                label: Text("REFRESH CODE", style: GoogleFonts.outfit(fontSize: 10, color: AppTheme.textSecondary(context))),
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
              backgroundColor: AppTheme.colors.indigoAccent,
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
            Text("${session.touristIds.length} ACTIVE", style: GoogleFonts.inter(fontSize: 12, color: AppTheme.colors.greenAccent)),
          ],
        ),
        const SizedBox(height: 16),
        session.touristIds.isEmpty
          ? Text("Waiting for scans...", style: GoogleFonts.inter(color: AppTheme.textSecondary(context)))
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
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.secondaryBorder(context)),
        boxShadow: [BoxShadow(color: AppTheme.colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
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
                  color: isSelected ? Theme.of(context).colorScheme.primary : AppTheme.borderColor(context),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isSelected ? Colors.transparent : AppTheme.borderColor(context)),
                ),
                child: Row(
                  children: [
                    Icon(p['icon'] as IconData, size: 16, color: isSelected ? Theme.of(context).colorScheme.onPrimary : AppTheme.textSecondary(context)),
                    const SizedBox(width: 8),
                    Text(
                      p['label'] as String,
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Theme.of(context).colorScheme.onPrimary : AppTheme.textSecondary(context),
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
          side: const BorderSide(color: AppTheme.colors.redAccent, width: 2),
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
        child: Text("TRIGGER SOS SIGNAL", style: GoogleFonts.outfit(color: AppTheme.colors.redAccent, fontWeight: FontWeight.bold, letterSpacing: 2)),
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
              style: GoogleFonts.outfit(color: AppTheme.colors.redAccent, fontWeight: FontWeight.bold, letterSpacing: 1),
            ),
          ),
        );
  }

  Future<void> _showVehiclePicker() async {
    final vehicle = await showModalBottomSheet<Vehicle>(
      context: context,
      backgroundColor: AppTheme.colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppTheme.cardColor(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: Border.all(color: AppTheme.borderColor(context)),
        ),
        padding: const EdgeInsets.all(32),
        child: Material(
          type: MaterialType.transparency,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("SELECT VEHICLE", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary(context))),
              const SizedBox(height: 24),
                ..._vehicles.map((v) => ListTile(
                  leading: const Icon(Icons.garage_rounded, color: AppTheme.colors.orangeAccent),
                  title: Text(v.type, style: GoogleFonts.outfit(color: AppTheme.textPrimary(context))),
                  subtitle: Text(v.vehicleNumber, style: GoogleFonts.inter(color: AppTheme.textSecondary(context))),
                  onTap: () => Navigator.pop(context, v),
                )),
            ],
          ),
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
          color: AppTheme.cardColor(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.secondaryBorder(context)),
          boxShadow: [BoxShadow(color: AppTheme.colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: AppTheme.textSecondary(context)),
            const SizedBox(height: 8),
            Text(value, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary(context))),
            const SizedBox(height: 4),
            Text(label, style: GoogleFonts.inter(fontSize: 10, letterSpacing: 1, color: AppTheme.textSecondary(context))),
          ],
        ),
      ),
    );
  }

  Widget _buildTouristTile(String uid) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.secondaryBorder(context)),
        boxShadow: [BoxShadow(color: AppTheme.colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
            CircleAvatar(backgroundColor: AppTheme.borderColor(context), child: Icon(Icons.person, size: 20, color: AppTheme.textPrimary(context))),
            const SizedBox(width: 16),
            Text("Traveler ${uid.substring(0, 6)}", style: GoogleFonts.inter(color: AppTheme.textPrimary(context))),
            const Spacer(),
            const Icon(Icons.location_on, size: 16, color: AppTheme.colors.greenAccent),
          ],
        ),
      );
  }

  void _setupMonsoonSafetyListener(String location) {
    _monsoonSub?.cancel();
    MonsoonBroadcastService().init(district: location.isNotEmpty ? location : "Colombo");
    _monsoonSub = MonsoonBroadcastService().broadcastStream.listen((alert) {
      if (mounted) {
        setState(() => _activeMonsoonAlert = alert);
      }
    });
  }

  Widget _buildMonsoonSafetyBanner(Map<String, dynamic> alert) {
    final title = alert['title'] as String? ?? alert['event']?.toString() ?? '🚨 EMERGENCY MONSOON ALERT';
    final msg = alert['message'] as String? ?? alert['description']?.toString() ?? 'Severe weather warning in your tour district.';
    final severity = alert['severity'] as String? ?? 'CRITICAL';

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.colors.redAccent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.colors.redAccent, width: 2),
        boxShadow: [
          BoxShadow(color: AppTheme.colors.redAccent.withValues(alpha: 0.2), blurRadius: 15, spreadRadius: 2),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppTheme.colors.redAccent, size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  style: GoogleFonts.outfit(color: AppTheme.colors.redAccent, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1.2),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: AppTheme.colors.redAccent, borderRadius: BorderRadius.circular(8)),
                child: Text(severity.toUpperCase(), style: GoogleFonts.outfit(color: AppTheme.colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(msg, style: GoogleFonts.inter(color: AppTheme.textPrimary(context), fontSize: 12)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _logMonsoonIncident(title, msg, severity),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.colors.redAccent,
                    foregroundColor: AppTheme.colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.shield_outlined, size: 16),
                  label: Text("LOG INCIDENT", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 11)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    if (_activeSession != null) {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => IncidentCenterScreen(sessionId: _activeSession!.sessionId)));
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.textPrimary(context),
                    side: BorderSide(color: AppTheme.borderColor(context)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: Text("SAFETY CONSOLE", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 11)),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn().shake(duration: 500.ms);
  }

  Future<void> _logMonsoonIncident(String title, String desc, String severity) async {
    if (_activeSession == null) return;
    try {
      final repo = IncidentRepository();
      final report = IncidentReport(
        incidentId: '',
        incidentNumber: 'INC-WTR-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
        sessionId: _activeSession!.sessionId,
        guideId: _activeSession!.guideId,
        touristId: 'all_session_guests',
        reportedBy: _activeSession!.guideId,
        reportedByRole: 'guide',
        type: 'weather_hazard',
        severity: severity.toLowerCase() == 'critical' ? 'critical' : 'high',
        title: title,
        description: desc,
        lat: _activeSession!.meetingPointLat,
        lng: _activeSession!.meetingPointLng,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await repo.createIncident(report);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Weather hazard logged to Safety Console!"), backgroundColor: AppTheme.colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error logging incident: $e"), backgroundColor: AppTheme.colors.red),
      );
    }
  }
}
