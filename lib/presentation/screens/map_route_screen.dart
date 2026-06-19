import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/trip_plan_model.dart';
import '../../data/datasources/trip_cache_service.dart';
import '../../core/utils/secure_logger.dart';

class MapRouteScreen extends StatefulWidget {
  final TripPlan plan;

  const MapRouteScreen({super.key, required this.plan});

  @override
  State<MapRouteScreen> createState() => _MapRouteScreenState();
}

class _MapRouteScreenState extends State<MapRouteScreen> {
  late GoogleMapController _controller;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  bool _isSavingMap = false;
  bool _isOfflineMapMode = false;
  late TripPlan _plan;

  @override
  void initState() {
    super.initState();
    _plan = widget.plan;
    _initMarkersAndRoutes(context);
    _checkOfflineStatus();
  }

  Future<void> _checkOfflineStatus() async {
    if (_plan.offlineMapPath != null) {
      if (await File(_plan.offlineMapPath!).exists() == false) return; // double check it exists
      try {
        final connectivityResult = await Connectivity().checkConnectivity();
        if (connectivityResult.contains(ConnectivityResult.none)) {
          if (mounted) setState(() => _isOfflineMapMode = true);
        }
      } catch (_) {
        // Fallback to DNS lookups if connectivity package throws
        try {
          final result = await InternetAddress.lookup('google.com');
          if (result.isEmpty || result[0].rawAddress.isEmpty) {
            if (mounted) setState(() => _isOfflineMapMode = true);
          }
        } catch (_) {
          if (mounted) setState(() => _isOfflineMapMode = true);
        }
      }
    }
  }

  Future<void> _saveOfflineMap() async {
    if (_isSavingMap) return;
    setState(() => _isSavingMap = true);
    
    try {
      final imageBytes = await _controller.takeSnapshot();
      if (imageBytes != null) {
        final allSaved = TripCacheService.getSavedPlans();
        // Fallback match using creation date or destination to find the current item
        final match = allSaved.where((e) => e.plan.destination == _plan.destination && e.plan.itinerary.length == _plan.itinerary.length).toList();
        
        if (match.isNotEmpty) {
          final id = match.first.id;
          final path = await TripCacheService.saveOfflineMap(id, imageBytes);
          if (path != null) {
            setState(() {
              _plan = _plan.copyWith(offlineMapPath: path);
            });
            await TripCacheService.updateSavedPlan(id, _plan);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Offline route map saved successfully!")));
            }
          }
        } else {
           if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text("Cannot save map. Please save the trip plan first!"),
                  action: SnackBarAction(
                    label: "SAVE TRIP",
                    onPressed: () async {
                      try {
                        final id = await TripCacheService.savePlan(_plan);
                        final path = await TripCacheService.saveOfflineMap(id, imageBytes);
                        if (path != null) {
                          setState(() {
                            _plan = _plan.copyWith(offlineMapPath: path);
                          });
                          await TripCacheService.updateSavedPlan(id, _plan);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Offline route map saved successfully!")),
                            );
                          }
                        }
                      } catch (e) {
                        SecureLogger.error("Failed to auto-save trip map", e);
                      }
                    },
                  ),
                ),
              );
           }
        }
      }
    } catch (e) {
      SecureLogger.error("Failed to save map snapshot", e);
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to save map: $e")));
      }
    } finally {
      if (mounted) setState(() => _isSavingMap = false);
    }
  }

  void _initMarkersAndRoutes(BuildContext context) {
    List<LatLng> points = [];
    int counter = 1;

    for (var day in _plan.itinerary) {
      for (var item in day.items) {
        if (item.lat != 0 && item.lng != 0) {
          final pos = LatLng(item.lat, item.lng);
          points.add(pos);
          
          _markers.add(
            Marker(
              markerId: MarkerId("${item.title}_$counter"),
              position: pos,
              infoWindow: InfoWindow(
                title: item.title, 
                snippet: "Day ${day.day} • ${item.time}",
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                item.isHotel ? BitmapDescriptor.hueAzure : BitmapDescriptor.hueOrange
              ),
            ),
          );
          counter++;
        }
      }
    }

    if (points.isNotEmpty) {
      _polylines.add(
        Polyline(
          polylineId: const PolylineId("trip_route"),
          points: points,
          color: AppTheme.accentOchre(context),
          width: 4,
          geodesic: true,
        ),
      );
    }
  }

  void _fitBounds() {
    if (_markers.isEmpty) return;

    double? minLat, maxLat, minLng, maxLng;

    for (var marker in _markers) {
      if (minLat == null || marker.position.latitude < minLat) minLat = marker.position.latitude;
      if (maxLat == null || marker.position.latitude > maxLat) maxLat = marker.position.latitude;
      if (minLng == null || marker.position.longitude < minLng) minLng = marker.position.longitude;
      if (maxLng == null || marker.position.longitude > maxLng) maxLng = marker.position.longitude;
    }

    _controller.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat!, minLng!),
          northeast: LatLng(maxLat!, maxLng!),
        ),
        70.0, // Padding
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text("Visual Route", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppTheme.textPrimary(context))),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: AppTheme.textPrimary(context), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.black54, Colors.transparent],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          if (_isOfflineMapMode && _plan.offlineMapPath != null)
            Positioned.fill(
              child: kIsWeb
                  ? Image.network(
                      _plan.offlineMapPath!,
                      fit: BoxFit.cover,
                    )
                  : Image.file(
                      File(_plan.offlineMapPath!),
                      fit: BoxFit.cover,
                    ),
            )
          else
            GoogleMap(
            initialCameraPosition: const CameraPosition(target: LatLng(7.8731, 80.7718), zoom: 7),
            onMapCreated: (controller) {
              _controller = controller;
              Future.delayed(const Duration(milliseconds: 500), _fitBounds);
            },
            markers: _markers,
            polylines: _polylines,
            myLocationButtonEnabled: false,
            mapToolbarEnabled: true,
            style: _mapStyle,
          ),
          
          // Bottom Info Card
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppTheme.premiumShadow,
                border: Border.all(color: AppTheme.borderColor(context)),
              ),
              child: Row(
                children: [
                  Icon(Icons.explore_outlined, color: AppTheme.accentOchre(context)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Journey Visualizer",
                          style: GoogleFonts.outfit(color: AppTheme.textPrimary(context), fontWeight: FontWeight.bold),
                        ),
                        Text(
                          "${_plan.itinerary.length} Days across ${_plan.destination}",
                          style: GoogleFonts.inter(color: AppTheme.textSecondary(context), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  if (!_isOfflineMapMode) ...[
                    IconButton(
                      icon: _isSavingMap 
                        ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: AppTheme.accentOchre(context), strokeWidth: 2))
                        : Icon(Icons.download, color: AppTheme.accentOchre(context)),
                      onPressed: _saveOfflineMap,
                      tooltip: "Save Offline Map",
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _fitBounds,
                      icon: const Icon(Icons.center_focus_strong, size: 18),
                      label: const Text("FOCUS"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentOchre(context),
                        foregroundColor: Theme.of(context).cardColor,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        textStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  // Minimalist Travel Map Style (optional JSON string for Google Maps)
  final String? _mapStyle = null; 
}
