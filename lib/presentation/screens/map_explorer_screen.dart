import 'dart:async';
import 'package:flutter/foundation.dart';
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
import '../widgets/cached_image.dart';
import '../../l10n/app_localizations.dart';
import 'package:geolocator/geolocator.dart';

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
  StreamSubscription? _alertSubscription;
  final Set<Polygon> _hazardPolygons = {};
  final Set<Polyline> _closedRoadLines = {};
  bool _hazardFeedOffline = false;
  LatLng? _guideLocation;
  LatLng? _vehicleLocation;
  LatLng? _meetingPointLocation;
  String? _meetingPointName;
  bool _isSosActive = false;
  bool _canShowUserLocation = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    _checkLocationPermission();
    _setupSessionTracking();
    _setupHazardTracking();
  }

  Future<void> _checkLocationPermission() async {
    final permission = await Geolocator.checkPermission();
    if (!mounted) return;
    setState(() => _canShowUserLocation =
        permission == LocationPermission.always ||
            permission == LocationPermission.whileInUse);
  }

  @override
  void dispose() {
    _guideSubscription?.cancel();
    _alertSubscription?.cancel();
    super.dispose();
  }

  void _setupHazardTracking() {
    _alertSubscription = FirebaseFirestore.instance
        .collection('travel_alerts')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .listen((snapshot) {
      final polygons = <Polygon>{};
      final closedRoads = <Polyline>{};
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final expiresAt = DateTime.tryParse('${data['expiresAt'] ?? ''}');
        if (expiresAt != null && expiresAt.isBefore(DateTime.now().toUtc())) continue;
        final geometry = data['hazard_geometry'] ?? data['hazardGeometry'];
        if (geometry is! List) continue;
        final points = geometry.whereType<Map>().map((point) => LatLng(
              (point['lat'] as num).toDouble(),
              (point['lng'] as num).toDouble(),
            )).toList();
        final level = (data['level'] as num?)?.toInt() ?? 1;
        final color = level >= 3 ? Colors.red : level == 2 ? Colors.orange : Colors.yellow.shade700;
        if (data['type'] == 'closed_road' && points.length >= 2) {
          closedRoads.add(Polyline(
            polylineId: PolylineId('closed_${doc.id}'),
            points: points,
            color: Colors.red.shade800,
            width: 6,
            patterns: [PatternItem.dash(18), PatternItem.gap(8)],
          ));
          continue;
        }
        if (points.length < 3) continue;
        polygons.add(Polygon(
          polygonId: PolygonId('hazard_${doc.id}'),
          points: points,
          fillColor: color.withValues(alpha: 0.22),
          strokeColor: color,
          strokeWidth: 2,
        ));
      }
      if (mounted) setState(() { _hazardPolygons..clear()..addAll(polygons); _closedRoadLines..clear()..addAll(closedRoads); _hazardFeedOffline = false; });
    }, onError: (_) {
      if (mounted) setState(() => _hazardFeedOffline = true);
    });
  }

  Future<void> _loadData() async {
    try {
      // Load all places (proximity handled by DiscoveryRepository)
      final repo = ref.read(discoveryRepositoryProvider);
      final result = await repo.getDiscoveryPlaces(
        userLat: widget.initialPosition.latitude,
        userLng: widget.initialPosition.longitude,
      );

      if (mounted) {
        setState(() {
          _places = result.valueOrNull ?? [];
          _createMarkers();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!
                .mapLoadErrorMessage(e.toString())),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
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
      if (!mounted || !sessionDoc.exists) return;

      final data = sessionDoc.data()!;
      final sosActive = data['sosActive'] ?? false;

      setState(() {
        _isSosActive = sosActive;

        if (data.containsKey('lastGuideLat') && data['lastGuideLat'] != null) {
          _guideLocation = LatLng((data['lastGuideLat'] as num).toDouble(),
              (data['lastGuideLng'] as num).toDouble());
        }

        if (data.containsKey('lastVehicleLat') &&
            data['lastVehicleLat'] != null) {
          _vehicleLocation = LatLng((data['lastVehicleLat'] as num).toDouble(),
              (data['lastVehicleLng'] as num).toDouble());
        }

        if (data.containsKey('meetingPointLat') &&
            data['meetingPointLat'] != null) {
          _meetingPointLocation = LatLng(
              (data['meetingPointLat'] as num).toDouble(),
              (data['meetingPointLng'] as num).toDouble());
          _meetingPointName = data['meetingPointName'];
        }

        _createMarkers();
      });
    });
  }

  void _createMarkers() {
    final l10n = AppLocalizations.of(context)!;
    _markers.clear();
    for (var place in _places) {
      _markers.add(
        Marker(
          markerId: MarkerId(place.id),
          position: LatLng(place.lat, place.lng),
          onTap: () => setState(() => _selectedPlace = place),
          icon: BitmapDescriptor.defaultMarkerWithHue(place.arSupported
              ? BitmapDescriptor.hueYellow
              : BitmapDescriptor.hueAzure),
        ),
      );
    }

    if (_guideLocation != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('guide_location'),
          position: _guideLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan),
          infoWindow: InfoWindow(title: l10n.guideLiveMarkerLabel),
          zIndexInt: 15,
        ),
      );
    }

    if (_vehicleLocation != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('vehicle_location'),
          position: _vehicleLocation!,
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
          infoWindow: InfoWindow(title: l10n.vehicleMarkerLabel),
          zIndexInt: 12,
        ),
      );
    }

    if (_meetingPointLocation != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('meeting_point'),
          position: _meetingPointLocation!,
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(
              title: l10n.meetingPointMarkerLabel(_meetingPointName ?? '')),
          zIndexInt: 10,
        ),
      );
    }
  }

  Future<void> _launchTransport(DiscoveryPlace place) async {
    if (place.lat < -90 ||
        place.lat > 90 ||
        place.lng < -180 ||
        place.lng > 180 ||
        (place.lat == 0 && place.lng == 0)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(AppLocalizations.of(context)!.invalidMapCoordinates)));
      }
      return;
    }
    final googleMapsUrl =
        "https://www.google.com/maps/dir/?api=1&destination=${place.lat},${place.lng}&travelmode=driving";
    if (await canLaunchUrl(Uri.parse(googleMapsUrl))) {
      await launchUrl(Uri.parse(googleMapsUrl),
          mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.mapAppUnavailable)));
    }
  }

  @override
  Widget build(BuildContext context) {
    // The web build has no Google Maps JavaScript SDK script loaded (that
    // requires its own browser-restricted API key, separate from the
    // Android/iOS native SDK key), so google_maps_flutter_web crashes on
    // web trying to read google.maps.MapTypeId off an undefined `google`
    // object. Native platforms are unaffected — only bail out on web.
    if (kIsWeb) {
      final l10n = AppLocalizations.of(context)!;
      return Scaffold(
        appBar: AppBar(
          leading: BackButton(onPressed: () => Navigator.of(context).pop()),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.map_outlined,
                    size: 48, color: AppTheme.textSecondary(context)),
                const SizedBox(height: 16),
                Text(
                  l10n.mapNotAvailableOnWeb,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                      fontSize: 14, color: AppTheme.textSecondary(context)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(widget.initialPosition.latitude,
                  widget.initialPosition.longitude),
              zoom: 12,
            ),
            markers: _markers,
            polygons: _hazardPolygons,
            polylines: _closedRoadLines,
            myLocationEnabled: _canShowUserLocation,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
          ),

          Positioned(
            top: 50,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(color: AppTheme.colors.white, borderRadius: BorderRadius.circular(12)),
              child: Text(
                _hazardFeedOffline ? 'Hazards: offline/cache' : 'Hazards  🟡 Watch  🟠 Warning  🔴 Stop',
                style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.textPrimary(context)),
              ),
            ),
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
                  color: AppTheme.colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: AppTheme.secondaryBorder(context)),
                ),
                child: Icon(Icons.arrow_back_ios_new,
                    color: AppTheme.textPrimary(context), size: 20),
              ),
            ),
          ),

          // Selected Place Card
          if (_selectedPlace != null)
            Positioned(
              bottom: 40,
              left: 20,
              right: 20,
              child: SafeArea(
                bottom: true,
                top: false,
                child: _buildPlaceCard(_selectedPlace!),
              ),
            ),

          // 4. SOS Overlay (Zenith Refinement)
          if (_isSosActive) _buildSosCinematicOverlay(),
        ],
      ),
    );
  }

  Widget _buildSosCinematicOverlay() {
    final l10n = AppLocalizations.of(context)!;
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(
        color: AppTheme.colors.red.withValues(alpha: 0.2),
        width: double.infinity,
        height: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.warning_amber_rounded,
                    color: AppTheme.colors.white, size: 80)
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(
                    begin: const Offset(1, 1),
                    end: const Offset(1.2, 1.2),
                    duration: 500.ms)
                .tint(color: AppTheme.colors.redAccent),
            const SizedBox(height: 24),
            Text(
              l10n.sosEmergencySignalTitle,
              style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.colors.white),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.sosGuideTriggeredMessage,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  color: AppTheme.colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1),
            ),
            const SizedBox(height: 48),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: AppTheme.colors.redAccent.withValues(alpha: 0.5)),
              ),
              child: Column(
                children: [
                  Text(l10n.sosSafetyProtocolsTitle,
                      style: GoogleFonts.outfit(
                          color: AppTheme.colors.redAccent,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildProtocolItem(l10n.sosProtocolStayInLocation),
                  _buildProtocolItem(l10n.sosProtocolOpenLiveMap),
                  _buildProtocolItem(l10n.sosProtocolWaitForHelp),
                ],
              ),
            ).animate().slideY(
                begin: 0.5, end: 0, duration: 800.ms, curve: Curves.easeOut),
            const SizedBox(height: 48),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.colors.white,
                foregroundColor: AppTheme.colors.black,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => setState(() => _isSosActive = false),
              child: Text(l10n.sosAcknowledgeButton),
            ),
          ],
        ),
      ).animate(onPlay: (c) => c.repeat()).shimmer(
          color: AppTheme.colors.red.withValues(alpha: 0.3),
          duration: 2.seconds),
    );
  }

  Widget _buildProtocolItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(text,
          style:
              GoogleFonts.inter(color: AppTheme.colors.white70, fontSize: 13)),
    );
  }

  Widget _buildPlaceCard(DiscoveryPlace place) {
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => PlaceDetailsScreen(place: place))),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppTheme.colors.black.withValues(alpha: 0.1),
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
              child: CachedImage(
                url:
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
                    style: GoogleFonts.outfit(
                        color: AppTheme.textPrimary(context),
                        fontWeight: FontWeight.bold,
                        fontSize: 18),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    place.category,
                    style: GoogleFonts.inter(
                        color: AppTheme.textSecondary(context), fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.directions_car_filled,
                          color: AppPalette.rust, size: 14),
                      const SizedBox(width: 4),
                      Text(
                          AppLocalizations.of(context)!.distanceAwayLabel(
                              place.distanceKm.toStringAsFixed(1)),
                          style: GoogleFonts.inter(
                              color: AppPalette.rust,
                              fontSize: 12,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              children: [
                IconButton(
                  icon: Icon(Icons.close,
                      color: AppTheme.textSecondary(context), size: 20),
                  onPressed: () => setState(() => _selectedPlace = null),
                ),
                IconButton(
                  icon: const Icon(Icons.navigation_rounded,
                      color: AppPalette.rust),
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
