import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:arcore_flutter_plugin/arcore_flutter_plugin.dart';
import 'package:vector_math/vector_math_64.dart' as vector;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'asset_cache_service.dart';
import '../../data/models/ar_artifact.dart';
import '../../data/models/ar_place_data.dart';
import 'package:cloud_functions/cloud_functions.dart';

/// Manages the ARCore session and 3D node placement for AR Mode.
class ARService {
  ArCoreController? _controller;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  String? _pendingModelUrl;
  String? _pendingHistoricalModelUrl;
  
  String? _currentModelUrl;    // Current active model path/URL
  String? _currentHistoricalUrl; // Historical path/URL
  
  double _pendingScale = 0.01;

  // Production Readiness: Progress Tracking
  final ValueNotifier<double> downloadProgress = ValueNotifier(0.0);
  final ValueNotifier<bool> isDownloading = ValueNotifier(false);
  final ValueNotifier<bool> isHistoricalMode = ValueNotifier(false); // Toggle state


  // 🔐 Layer 9: Server-side AR session timer
  String? _activeSessionId;
  bool _sessionExpired = false;

  /// Whether the server has validated this session as expired.
  bool get isSessionExpired => _sessionExpired;

  /// Check if the device hardware supports ARCore.
  static Future<bool> isSupported() async {
    if (kIsWeb || !Platform.isAndroid) return false;
    return await ArCoreController.checkArCoreAvailability();
  }

  /// Check if ARCore services are installed.
  static Future<bool> isInstalled() async {
    if (kIsWeb || !Platform.isAndroid) return false;
    return await ArCoreController.checkIsArCoreInstalled();
  }

  /// Called when the ArCoreView is ready.
  void onArCoreViewCreated(ArCoreController controller) {
    _controller = controller;
    _controller!.onPlaneTap = _handlePlaneTap;
    // _controller!.onNodeTap is usually the property name in newer arcore_flutter_plugin
    // Fallback or comment out if undefined in this specific version
    // _controller!.onNodeTap = (nodeName) => _handleNodeTap(nodeName);
    _isInitialized = true;
  }

  void Function(String nodeName)? onArtifactFound;
  void Function(vector.Vector3 position)? onNodePlaced;

  /// Request model placement on next plane tap.
  Future<void> requestPlaceModel({
    required String modelUrl, 
    String? historicalModelUrl,
    double scale = 0.01
  }) async {
    isDownloading.value = true;
    downloadProgress.value = 0.05;

    try {
      // 1. Load Primary Model
      _pendingModelUrl = await _getLoadedPath(modelUrl, (p) => downloadProgress.value = (0.05 + (p * 0.45)));
      _currentModelUrl = _pendingModelUrl;

      // 2. Load Historical Model (if exists)
      if (historicalModelUrl != null && historicalModelUrl.isNotEmpty) {
        _pendingHistoricalModelUrl = await _getLoadedPath(historicalModelUrl, (p) => downloadProgress.value = (0.50 + (p * 0.45)));
        _currentHistoricalUrl = _pendingHistoricalModelUrl;
      }
      
      downloadProgress.value = 1.0;
    } catch (e) {
      debugPrint("[Offline] Cache error: $e");
      _pendingModelUrl = modelUrl;
      _pendingHistoricalModelUrl = historicalModelUrl;
    }
    
    _pendingScale = scale;
    isDownloading.value = false;
  }

  Future<String?> _getLoadedPath(String url, Function(double) onProgress) async {
    final localPath = await AssetCacheService.getLocalPath(url);
    if (localPath != null) return localPath;
    
    final file = await AssetCacheService.getAssetFile(url, onProgress: onProgress);
    return file?.path ?? url;
  }

  vector.Vector3? _lastPlacedPosition;
  vector.Vector4? _lastPlacedRotation;

  void _handlePlaneTap(List<ArCoreHitTestResult> results) {
    if (_pendingModelUrl == null || results.isEmpty) return;

    final hit = results.first;
    _lastPlacedPosition = hit.pose.translation;
    _lastPlacedRotation = hit.pose.rotation;

    _addHeritageNode(
      url: isHistoricalMode.value && _pendingHistoricalModelUrl != null 
          ? _pendingHistoricalModelUrl! 
          : _pendingModelUrl!,
      position: _lastPlacedPosition!,
      rotation: _lastPlacedRotation!,
    );
    
    // Trigger callback to spawn artifacts at this position
    onNodePlaced?.call(_lastPlacedPosition!);
    
    _pendingModelUrl = null;
    _pendingHistoricalModelUrl = null;
  }

  void _addHeritageNode({
    required String url, 
    required vector.Vector3 position, 
    required vector.Vector4 rotation
  }) {
    final node = ArCoreReferenceNode(
      name: 'heritage_model',
      objectUrl: url,
      position: position,
      rotation: rotation,
      scale: vector.Vector3(_pendingScale, _pendingScale, _pendingScale),
    );

    _controller?.addArCoreNodeWithAnchor(node);
  }

  /// 🕰️ THEN/NOW TOGGLE: Swaps between normal ruins and reconstructed model.
  Future<void> toggleHistoricalMode() async {
    if (_controller == null || _lastPlacedPosition == null || _lastPlacedRotation == null) return;
    if (_currentHistoricalUrl == null) return;

    isHistoricalMode.value = !isHistoricalMode.value;
    
    // Remove existing node
    await removeModel();

    // Add new node at same position
    _addHeritageNode(
      url: isHistoricalMode.value ? _currentHistoricalUrl! : _currentModelUrl!,
      position: _lastPlacedPosition!,
      rotation: _lastPlacedRotation!,
    );

    debugPrint("[AR] Swapped model. HistoricalMode: ${isHistoricalMode.value}");
  }

  /// Places hidden heritage artifacts relative to the placed model.
  Future<void> placeArtifacts(List<ARArtifact> artifacts, vector.Vector3 parentPosition, Set<String> foundIds) async {
    if (_controller == null) return;

    for (var artifact in artifacts) {
      if (foundIds.contains(artifact.id)) continue;

      // Calculate absolute position based on parent and relative offset
      final absX = parentPosition.x + artifact.relativePosition[0];
      final absY = parentPosition.y + artifact.relativePosition[1];
      final absZ = parentPosition.z + artifact.relativePosition[2];

      final node = ArCoreReferenceNode(
        name: 'artifact_${artifact.id}',
        // Use a generic treasure model or a specific one
        objectUrl: artifact.modelUrl.isNotEmpty 
          ? artifact.modelUrl 
          : "https://raw.githubusercontent.com/KhronosGroup/glTF-Sample-Models/master/2.0/Box/glTF-Binary/Box.glb",
        position: vector.Vector3(absX, absY, absZ),
        // Scale artifacts to be smaller and harder to find
        scale: vector.Vector3(0.005, 0.005, 0.005),
      );

      _controller?.addArCoreNode(node);
    }
  }

  /// Remove the current model by name.
  Future<void> removeModel() async {
    await _controller?.removeNode(nodeName: 'heritage_model');
  }

  /// Adjust scale for next placement.
  void scaleModel(double factor) {
    _pendingScale = (_pendingScale * factor).clamp(0.001, 0.5);
  }

  /// 🔐 LAYER 9 — Start an AR session with a server-recorded start time.
  /// Writes a Firestore document with sessionStartTime so the server
  /// can validate duration. Call this when the AR view becomes visible.
  Future<String?> startArSession({required String locationId}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    try {
      final sessionRef = FirebaseFirestore.instance.collection('ar_sessions').doc();
      await sessionRef.set({
        'userId': user.uid,
        'locationId': locationId,
        'sessionStartTime': FieldValue.serverTimestamp(),
        'expired': false,
      });
      _activeSessionId = sessionRef.id;
      _sessionExpired = false;
      debugPrint('[ARSession] Started: $_activeSessionId');
      return _activeSessionId;
    } catch (e) {
      debugPrint('[ARSession] Failed to start session: $e');
      return null;
    }
  }

  /// 🔐 LAYER 9 — End an AR session and validate duration server-side.
  /// For free users, the Cloud Function checks if session exceeded 60 seconds.
  /// Returns [ArSessionValidation] — use [ArSessionValidation.allowed] to decide
  /// whether to show the upgrade prompt.
  Future<ArSessionValidation> endArSession() async {
    if (_activeSessionId == null) {
      return const ArSessionValidation(allowed: true, reason: 'no_session');
    }

    try {
      final result = await FirebaseFunctions.instance
          .httpsCallable('validateArSession')
          .call({'sessionId': _activeSessionId});

      final data = result.data as Map<String, dynamic>;
      _sessionExpired = !(data['allowed'] ?? true);
      _activeSessionId = null;

      debugPrint('[ARSession] Validation: $data');
      return ArSessionValidation(
        allowed: data['allowed'] ?? true,
        reason: data['reason'] ?? 'unknown',
        elapsedSeconds: data['elapsedSeconds'] as int?,
      );
    } catch (e) {
      debugPrint('[ARSession] Validation failed: $e');
      _activeSessionId = null;
      return const ArSessionValidation(allowed: true, reason: 'validation_error');
    }
  }

  /// Dispose the controller.
  Future<void> dispose() async {
    // End any open session on dispose
    if (_activeSessionId != null) {
      await endArSession();
    }
    _controller?.dispose();
    _isInitialized = false;
  }
}
