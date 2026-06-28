import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import 'package:hidden_gems_sl/data/repositories/discovery_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/discovery_place.dart';
import 'place_details_screen.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/datasources/user_preference_service.dart';
import 'dart:ui';

class MapExplorerScreen extends ConsumerStatefulWidget {
  final LatLng initialPosition;
  const MapExplorerScreen({super.key, required this.initialPosition});

  @override
  ConsumerState<MapExplorerScreen> createState() => _MapExplorerScreenState();
}

class _MapExplorerScreenState extends ConsumerState<MapExplorerScreen> {
  final Set<Marker> _markers = {};
  List<DiscoveryPlace> _places = [];
  DiscoveryPlace? _selectedPlace;
  StreamSubscription? _guideSubscription;
  LatLng? _guideLocation;
  LatLng? _vehicleLocation;
  LatLng? _meetingPointLocation;
  String? _meetingPointName;
  bool _isSosActive = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    _setupSessionTracking();
  }

  @override
  void dispose() {
    _guideSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    // Load all places (proximity handled by DiscoveryRepository)
    final repo = ref.read(discoveryRepositoryProvider);
    final places = await repo.getDiscoveryPlaces(
      userLat: widget.initialPosition.latitude,
      userLng: widget.initialPosition.longitude,
    );

    if (mounted) {
      setState(() {
        _places = places;
        _createMarkers();
      });
    }
  }

  void _setupSessionTracking() {
    final profile = UserPreferenceService.getProfile();
    if (profile.currentBatchId == null) return;

    _guideSubscription?.cancel();
    _guideSubscription = FirebaseFirestore.instance
        .collection('tour_sessions')
        .doc(profile.currentBatchId)
        .snapshots()
        .listen((sessionDoc) {
      if (!sessionDoc.exists) return;
      
      final data = sessionDoc.data()!;
      final sosActive = data['sosActive'] ?? false;
      
      setState(() {
        _isSosActive = sosActive;
        
        if (data.containsKey('lastGuideLat') && data['lastGuideLat'] != null) {
          _guideLocation = LatLng((data['lastGuideLat'] as num).toDouble(), (data['lastGuideLng'] as num).toDouble());
        }
        
        if (data.containsKey('lastVehicleLat') && data['lastVehicleLat'] != null) {
          _vehicleLocation = LatLng((data['lastVehicleLat'] as num).toDouble(), (data['lastVehicleLng'] as num).toDouble());
        }

        if (data.containsKey('meetingPointLat') && data['meetingPointLat'] != null) {
          _meetingPointLocation = LatLng((data['meetingPointLat'] as num).toDouble(), (data['meetingPointLng'] as num).toDouble());
          _meetingPointName = data['meetingPointName'];
        }

        _createMarkers();
      });
    });
  }

  void _createMarkers() {
    _markers.clear();
    for (var place in _places) {
      _markers.add(
        Marker(
          markerId: MarkerId(place.name),
          position: LatLng(place.lat, place.lng),
          onTap: () => setState(() => _selectedPlace = place),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            place.arSupported ? BitmapDescriptor.hueYellow : BitmapDescriptor.hueAzure
          ),
        ),
      );
    }

    if (_guideLocation != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('guide_location'),
          position: _guideLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan),
          infoWindow: const InfoWindow(title: "YOUR GUIDE (LIVE)"),
          zIndexInt: 15,
        ),
      );
    }

    if (_vehicleLocation != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('vehicle_location'),
          position: _vehicleLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
          infoWindow: const InfoWindow(title: "YOUR VEHICLE"),
          zIndexInt: 12,
        ),
      );
    }

    if (_meetingPointLocation != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('meeting_point'),
          position: _meetingPointLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(title: "MEETING POINT: $_meetingPointName"),
          zIndexInt: 10,
        ),
      );
    }
  }

  Future<void> _launchTransport(DiscoveryPlace place) async {
    final googleMapsUrl = "https://www.google.com/maps/dir/?api=1&destination=${place.lat},${place.lng}&travelmode=driving";
    if (await canLaunchUrl(Uri.parse(googleMapsUrl))) {
      await launchUrl(Uri.parse(googleMapsUrl));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(widget.initialPosition.latitude, widget.initialPosition.longitude),
              zoom: 12,
            ),
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
          ),
          
          // Back Button
          Positioned(
            top: 50,
            left: 20,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: AppTheme.secondaryBorder(context)),
                ),
                child: Icon(Icons.arrow_back_ios_new, color: AppTheme.textPrimary(context), size: 20),
              ),
            ),
          ),

          // Selected Place Card
          if (_selectedPlace != null)
            Positioned(
              bottom: 40,
              left: 20,
              right: 20,
              child: _buildPlaceCard(_selectedPlace!),
            ),

            Center(child: CircularProgressIndicator(color: AppPalette.rust)),

          // 4. SOS Overlay (Zenith Refinement)
          if (_isSosActive)
            _buildSosCinematicOverlay(),
        ],
      ),
    );
  }

  Widget _buildSosCinematicOverlay() {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(
        color: Colors.red.withValues(alpha: 0.2),
        width: double.infinity,
        height: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 80)
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(begin: const Offset(1, 1), end: const Offset(1.2, 1.2), duration: 500.ms)
                .tint(color: Colors.redAccent),
            const SizedBox(height: 24),
            Text(
              "EMERGENCY SIGNAL",
              style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(
              "YOUR GUIDE HAS TRIGGERED AN SOS",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1),
            ),
            const SizedBox(height: 48),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
              ),
              child: Column(
                children: [
                   Text("SAFETY PROTOCOLS", style: GoogleFonts.outfit(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                   const SizedBox(height: 16),
                   _buildProtocolItem("1. Stay in your current location."),
                   _buildProtocolItem("2. Open your live map to track the guide."),
                   _buildProtocolItem("3. Wait for emergency services or guide signal."),
                ],
              ),
            ).animate().slideY(begin: 0.5, end: 0, duration: 800.ms, curve: Curves.easeOut),
            const SizedBox(height: 48),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white, 
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => setState(() => _isSosActive = false),
              child: const Text("ACKNOWLEDGE"),
            ),
          ],
        ),
      ).animate(onPlay: (c) => c.repeat())
       .shimmer(color: Colors.red.withValues(alpha: 0.3), duration: 2.seconds),
    );
  }

  Widget _buildProtocolItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(text, style: GoogleFonts.inter(color: Colors.white70, fontSize: 13)),
    );
  }

  Widget _buildPlaceCard(DiscoveryPlace place) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PlaceDetailsScreen(place: place))),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: AppTheme.secondaryBorder(context)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                "https://images.unsplash.com/photo-1552465011-b4e21bf6e79a?q=80&w=200&auto=format&fit=crop",
                width: 80,
                height: 80,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    place.name,
                    style: GoogleFonts.outfit(color: AppTheme.textPrimary(context), fontWeight: FontWeight.bold, fontSize: 18),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    place.category,
                    style: GoogleFonts.inter(color: AppTheme.textSecondary(context), fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.directions_car_filled, color: AppPalette.rust, size: 14),
                      const SizedBox(width: 4),
                      Text("${place.distanceKm.toStringAsFixed(1)} km away", style: GoogleFonts.inter(color: AppPalette.rust, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              children: [
                IconButton(
                  icon: Icon(Icons.close, color: AppTheme.textSecondary(context), size: 20),
                  onPressed: () => setState(() => _selectedPlace = null),
                ),
                IconButton(
                  icon: const Icon(Icons.navigation_rounded, color: AppPalette.rust),
                  onPressed: () => _launchTransport(place),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
