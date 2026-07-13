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
import 'guide_listing_editor_screen.dart';
import '../../data/repositories/marketplace_repository.dart';
import '../../data/repositories/broadcast_repository.dart';
import '../../data/models/broadcast_message.dart';

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
  StreamSubscription<Map<String, dynamic>>? _monsoonSub;
  Map<String, dynamic>? _activeMonsoonAlert;
  int _currentTabIndex = 0;
  
  final _sessionRepo = TourSessionRepository();
  final _vehicleRepo = VehicleRepository();
  final _presenceRepo = PresenceRepository();
  final _meetingRepo = MeetingPointRepository();
  final _marketplaceRepo = MarketplaceRepository();
  final _broadcastRepo = BroadcastRepository();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
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
      // Speed > 5 m/s (~18 km/h) -> 12s (Vehicle)
      // Speed > 1 m/s -> 20s (Walking)
      // Speed <= 1 m/s -> 30s (Stationary)
      //
      // Cost fix: the vehicle tier was previously 5s. PresenceRepository's
      // 12m movement filter provides little protection at that speed (a
      // vehicle moving >5 m/s covers >12m well within 5s, so almost every
      // tick wrote), meaning this timer alone drove ~24 writes/min for the
      // whole duration of every active vehicle tour — the single largest
      // Firestore write source in the app. 12s still gives a live map dot
      // that updates ~5x/minute (smooth enough for a following-a-guide UX)
      // while roughly halving vehicle-tour write volume.
      if (pos.speed > 5) return const Duration(seconds: 12);
      if (pos.speed > 1) return const Duration(seconds: 20);
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
    if (uid == null) return;

    var v = await _vehicleRepo.getGuideVehicles(uid);

    // Fall back to the vehicle info captured on the guide's own marketplace
    // listing — most guides only ever set this via "My Listing" and never
    // use the separate (legacy) vehicle-add flow that populates `vehicles`.
    if (v.isEmpty) {
      try {
        final listing = await _marketplaceRepo.getListing(uid);
        if (listing != null && listing.vehicleAvailable && (listing.vehicleType?.isNotEmpty ?? false)) {
          v = [
            Vehicle(
              id: 'listing_$uid',
              guideId: uid,
              vehicleNumber: listing.displayName,
              type: listing.vehicleType!,
              seatCapacity: 4,
              driverName: listing.displayName,
              imageUrl: listing.vehicleImageUrl,
              createdAt: listing.updatedAt,
            ),
          ];
        }
      } catch (_) {
        // Listing fetch failure just leaves _vehicles empty — handled by the empty-state UI.
      }
    }

    if (mounted) setState(() => _vehicles = v);
  }

  Future<void> _startNewTour(Vehicle vehicle) async {
    setState(() => _isLoading = true);
    final profile = UserPreferenceService.getProfile();
    final sessionId = const Uuid().v4();
    final uid = AuthService().currentUser?.uid ?? "unknown";

    // BUG-4 FIX: Wrap GPS call in try/catch so a denied permission or
    // location timeout shows a friendly message instead of crashing the app.
    double lat = 6.9271; // Default: Colombo (fallback only)
    double lng = 79.8612;
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      lat = pos.latitude;
      lng = pos.longitude;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Could not get your location. Using default coordinates. ($e)"),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }

    final newSession = TourSession(
      sessionId: sessionId,
      guideId: uid,
      vehicleId: vehicle.id,
      meetingPointName: 'Initial Meeting Point',
      meetingPointLat: lat,
      meetingPointLng: lng,
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

      // Notify connected travelers so they don't have to notice the map pin move themselves.
      await _broadcastRepo.sendBroadcast(BroadcastMessage(
        messageId: const Uuid().v4(),
        sessionId: _activeSession!.sessionId,
        guideId: AuthService().currentUser?.uid ?? "unknown",
        type: BroadcastType.meetingPoint,
        title: "Meeting point updated",
        body: "New meeting point: $name",
        priority: BroadcastPriority.high,
        createdAt: DateTime.now(),
      ));

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
        SnackBar(content: Text("Vehicle position marked"), backgroundColor: AppPalette.earth),
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

    // BUG-3 FIX: Cancel the GPS location timer and monsoon WebSocket
    // subscription when the tour ends. Previously these kept running after
    // _stopTour(), causing unnecessary battery drain and Firestore writes.
    _locationTimer?.cancel();
    _locationTimer = null;
    _monsoonSub?.cancel();
    _monsoonSub = null;

    final profile = UserPreferenceService.getProfile();

    await _sessionRepo.endSession(_activeSession!.sessionId);

    profile.currentBatchId = null;
    await UserPreferenceService.saveProfile(profile);

    if (!mounted) return;
    setState(() {
      _activeSession = null;
      _activeMonsoonAlert = null;
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
      case 4:
        return const GuideListingEditorScreen(embedded: true);
      case 0:
      default:
        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              elevation: 0,
              leading: IconButton(
                icon: Icon(Icons.arrow_back_ios_new, size: 20, color: AppTheme.textPrimary(context)),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                "Tour dashboard",
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  color: AppTheme.textPrimary(context),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                child: _isLoading
                  ? const Padding(padding: EdgeInsets.only(top: 100), child: Center(child: CircularProgressIndicator()))
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
    final items = [
      (Icons.explore_outlined, Icons.explore_rounded, 'Tour'),
      (Icons.card_membership_outlined, Icons.card_membership_rounded, 'Plan'),
      (Icons.star_border_rounded, Icons.star_rounded, 'Reviews'),
      (Icons.shield_outlined, Icons.shield_rounded, 'Safety'),
      (Icons.edit_document, Icons.edit_document, 'Listing'),
    ];
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        border: Border(top: BorderSide(color: AppTheme.secondaryBorder(context), width: 1)),
        boxShadow: [
          BoxShadow(color: AppTheme.colors.black.withValues(alpha: 0.05), blurRadius: 16, offset: const Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(items.length, (index) {
            final isSelected = _currentTabIndex == index;
            final (outlineIcon, filledIcon, label) = items[index];
            return Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() => _currentTabIndex = index);
                },
                child: AnimatedContainer(
                  duration: 250.ms,
                  curve: Curves.easeOut,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? primary.withValues(alpha: 0.12) : AppTheme.colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(isSelected ? filledIcon : outlineIcon, size: 22, color: isSelected ? primary : AppTheme.textSecondary(context)),
                      const SizedBox(height: 4),
                      Text(
                        label,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? primary : AppTheme.textSecondary(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }


  Widget _buildEmptyState() {
    return Column(
      children: [
        const SizedBox(height: 40),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Theme.of(context).colorScheme.primary, AppPalette.rustDim],
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppTheme.colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.qr_code_2_rounded, size: 32, color: Colors.white),
              ),
              const SizedBox(height: 20),
              Text(
                "No active tour",
                style: GoogleFonts.outfit(fontSize: 19, fontWeight: FontWeight.w800, color: AppTheme.colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                "Start a new tour and generate a QR for your travelers to connect.",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 12.5, color: AppTheme.colors.white.withValues(alpha: 0.85)),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.colors.white,
                    foregroundColor: Theme.of(context).colorScheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                    elevation: 0,
                  ),
                  onPressed: () {
                    if (_vehicles.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Add your vehicle in the \"My Listing\" tab first")),
                      );
                      setState(() => _currentTabIndex = 4);
                      return;
                    }
                    _showVehiclePicker();
                  },
                  child: Text("Generate tour QR", style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 14)),
                ),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.08, end: 0),
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
              color: AppPalette.heroOchre.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppPalette.heroOchre, width: 1.5),
            ),
            child: Column(
              children: [
                Text("Upcoming tour session ready", style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 15, color: AppTheme.textPrimary(context))),
                const SizedBox(height: 8),
                Text("Travelers and meeting point confirmed. Tap below when you and the travelers arrive at the meeting point to officially start the timer and tracking.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 12.5, color: AppTheme.textSecondary(context))),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.play_arrow_rounded, size: 22),
                    label: Text("Start tour session", style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 14)),
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
                          SnackBar(content: Text("🚀 Tour Session Started!"), backgroundColor: AppTheme.colors.green),
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
            _buildStatCard(
              "RATING",
              (UserPreferenceService.getProfile().guideProfile?.ratingAverage ?? 5.0).toStringAsFixed(1),
              Icons.star_border_rounded,
            ),
            const SizedBox(width: 12),
            _buildStatCard("SERVED", "${UserPreferenceService.getProfile().guideProfile?.travelersServed ?? 0}", Icons.groups_outlined),
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
                label: Text(session.meetingPointName.isNotEmpty ? "Update point" : "Set point"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.primary,
                  side: BorderSide(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4), width: 1.2),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                  textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12.5),
                ),
                onPressed: _setMeetingPoint,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.garage_outlined, size: 18),
                label: const Text("Mark vehicle"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppPalette.earth,
                  side: BorderSide(color: AppPalette.earth.withValues(alpha: 0.4), width: 1.2),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                  textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12.5),
                ),
                onPressed: _updateVehicleLocation,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Join Management
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.surfaceMuted(context),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Join status", style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textPrimary(context))),
                  Text(session.isJoinOpen ? "Open to scans" : "Locked",
                    style: GoogleFonts.inter(fontSize: 11, color: session.isJoinOpen ? AppPalette.success : AppPalette.error)),
                ],
              ),
              Switch(
                value: session.isJoinOpen,
                activeThumbColor: Theme.of(context).colorScheme.primary,
                onChanged: (val) => _sessionRepo.toggleJoinStatus(session.sessionId, val),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: AppPalette.ink,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              if (session.joinToken != null && session.isJoinOpen)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: QrImageView(
                    data: '{"v":1,"t":"join","token":"${session.joinToken}"}',
                    version: QrVersions.auto,
                    size: 180.0,
                    backgroundColor: AppTheme.colors.transparent,
                    eyeStyle: QrEyeStyle(eyeShape: QrEyeShape.square, color: AppPalette.ink),
                    dataModuleStyle: QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: AppPalette.ink),
                  ),
                ).animate().scale(duration: 800.ms, curve: Curves.elasticOut)
              else
                SizedBox(
                  height: 180,
                  child: Center(
                    child: Text("Joining paused", style: GoogleFonts.outfit(color: AppTheme.colors.white70, fontWeight: FontWeight.w600)),
                  ),
                ),
              const SizedBox(height: 16),
              TextButton.icon(
                icon: Icon(Icons.refresh, size: 14, color: AppPalette.heroOchre),
                label: Text("Tap to refresh join code", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppPalette.heroOchre)),
                onPressed: () => _sessionRepo.generateJoinToken(session.sessionId),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 200.ms),
        const SizedBox(height: 24),

        // Broadcast + SOS row
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.record_voice_over_rounded, size: 18),
                  label: Text("Broadcast", style: AppTheme.buttonLabelStyle(context)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                    elevation: 0,
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
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 52,
              height: 52,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppPalette.error, width: 2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                  padding: EdgeInsets.zero,
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
                child: Icon(Icons.priority_high_rounded, color: AppPalette.error, size: 22),
              ),
            ),
          ],
        ).animate().fadeIn(delay: 400.ms),
        const SizedBox(height: 16),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Connected travelers", style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary(context))),
            Text("${session.touristIds.length} active", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppPalette.success)),
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
        const SizedBox(height: 24),
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

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          ...phases.map((p) {
          final isSelected = _activeSession?.currentPhase == p['id'];
          return GestureDetector(
            onTap: () => _updatePhase(p['id'] as String),
            child: AnimatedContainer(
              duration: 300.ms,
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? Theme.of(context).colorScheme.primary : AppTheme.surfaceMuted(context),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Row(
                children: [
                  Icon(p['icon'] as IconData, size: 15, color: isSelected ? Theme.of(context).colorScheme.onPrimary : AppTheme.textSecondary(context)),
                  const SizedBox(width: 6),
                  Text(
                    _sentenceCase(p['label'] as String),
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Theme.of(context).colorScheme.onPrimary : AppTheme.textSecondary(context),
                    ),
                  ),
                ],
              ),
            ),
          );
          }),
          const SizedBox(width: 12),
        ],
      ),
    );
  }

  Widget _buildEndTourButton() {
    return SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: _stopTour,
            child: Text(
              "Stop tour session",
              style: GoogleFonts.inter(color: AppPalette.error, fontWeight: FontWeight.w700, fontSize: 13),
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
              Text("Select vehicle", style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.w800, color: AppTheme.textPrimary(context))),
              const SizedBox(height: 20),
                ..._vehicles.map((v) => ListTile(
                  leading: Icon(Icons.garage_rounded, color: Theme.of(context).colorScheme.primary),
                  title: Text(v.type, style: GoogleFonts.outfit(color: AppTheme.textPrimary(context), fontWeight: FontWeight.w600)),
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
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
        decoration: BoxDecoration(
          color: AppTheme.surfaceMuted(context),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(value, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textPrimary(context))),
            const SizedBox(height: 2),
            Text(_sentenceCase(label), style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w600, color: AppTheme.textSecondary(context))),
          ],
        ),
      ),
    );
  }

  String _sentenceCase(String label) {
    if (label.isEmpty) return label;
    return label[0].toUpperCase() + label.substring(1).toLowerCase();
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
            Icon(Icons.location_on, size: 16, color: AppPalette.success),
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
        color: AppPalette.error.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppPalette.error, width: 2),
        boxShadow: [
          BoxShadow(color: AppPalette.error.withValues(alpha: 0.2), blurRadius: 15, spreadRadius: 2),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppPalette.error, size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  style: GoogleFonts.outfit(color: AppPalette.error, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1.2),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: AppPalette.error, borderRadius: BorderRadius.circular(8)),
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
                    backgroundColor: AppPalette.error,
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
        SnackBar(content: Text("✅ Weather hazard logged to Safety Console!"), backgroundColor: AppTheme.colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error logging incident: $e"), backgroundColor: AppTheme.colors.red),
      );
    }
  }
}
