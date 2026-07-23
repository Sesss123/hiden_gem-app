import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:ar_flutter_plugin_2/datatypes/node_types.dart';
import 'package:ar_flutter_plugin_2/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin_2/models/ar_hittest_result.dart';
import 'package:ar_flutter_plugin_2/models/ar_node.dart';
import 'package:vector_math/vector_math_64.dart' as vector;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'asset_cache_service.dart';
import '../../data/models/ar_artifact.dart';
import '../../data/models/ar_place_data.dart';
import 'package:cloud_functions/cloud_functions.dart';

/// Manages the ARCore session and 3D node placement for AR Mode.
class ARService {
  ARSessionManager? _sessionManager;
  ARObjectManager? _objectManager;
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

  /// Check if the device hardware supports ARCore. ar_flutter_plugin_2 has
  /// no static availability check; this is a platform-level gate only —
  /// genuine ARCore-missing devices are caught later via onError.
  static Future<bool> isSupported() async {
    if (kIsWeb || !Platform.isAndroid) return false;
    return true;
  }

  /// Called when the ARView is ready.
  void onARViewCreated(
    ARSessionManager sessionManager,
    ARObjectManager objectManager,
    ARAnchorManager anchorManager,
    ARLocationManager locationManager,
  ) {
    _sessionManager = sessionManager;
    _objectManager = objectManager;
    _sessionManager!.onInitialize(showFeaturePoints: false, showPlanes: true);
    _objectManager!.onInitialize();
    _sessionManager!.onPlaneOrPointTap = _handlePlaneTap;
    _sessionManager!.onError = (error) => onArError?.call(error);
    _objectManager!.onNodeTap = _handleNodeTap;
    _isInitialized = true;
  }

  void Function(String nodeName)? onArtifactFound;
  void Function(vector.Vector3 position)? onNodePlaced;
  /// Surfaces native AR failures (ARCore unavailable, session errors) that
  /// were previously silently dropped — ARSessionManager.onError was never
  /// wired to anything. ARObjectManager has no equivalent callback exposed
  /// by ar_flutter_plugin_2 (its 'onError' case only print()s internally),
  /// so per-node load failures are instead reported via the bool? result of
  /// addNode() in _addHeritageNode below.
  void Function(String message)? onArError;

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

  ARNode? _heritageNode;
  final Map<String, ARNode> _artifactNodes = {};

  /// Local cache paths (from AssetCacheService) load as fileSystemAppFolderGLB;
  /// anything else (a raw https:// URL, or the fallback where caching failed)
  /// loads as webGLB.
  NodeType _nodeTypeFor(String pathOrUrl) {
    return pathOrUrl.startsWith('http://') || pathOrUrl.startsWith('https://')
        ? NodeType.webGLB
        : NodeType.fileSystemAppFolderGLB;
  }

  /// Handles a tap on any placed AR node. Artifact nodes are named
  /// 'artifact_{id}' in placeArtifacts() below — this was previously wired
  /// nowhere, so onArtifactFound could never fire and the hidden-artifact
  /// gamification feature was unreachable dead code regardless of how many
  /// artifacts were placed in the scene.
  void _handleNodeTap(List<String> nodeNames) {
    for (final name in nodeNames) {
      if (!name.startsWith('artifact_')) continue;
      final artifactId = name.substring('artifact_'.length);
      if (_artifactNodes.containsKey(artifactId)) {
        onArtifactFound?.call(artifactId);
      }
    }
  }

  void _handlePlaneTap(List<ARHitTestResult> results) {
    if (_pendingModelUrl == null || results.isEmpty) return;

    final hit = results.first;
    final position = hit.worldTransform.getTranslation();

    _addHeritageNode(
      url: isHistoricalMode.value && _pendingHistoricalModelUrl != null
          ? _pendingHistoricalModelUrl!
          : _pendingModelUrl!,
      transformation: hit.worldTransform,
    );

    // Trigger callback to spawn artifacts at this position
    onNodePlaced?.call(position);

    _pendingModelUrl = null;
    _pendingHistoricalModelUrl = null;
  }

  Future<void> _addHeritageNode({
    required String url,
    required vector.Matrix4 transformation,
  }) async {
    final node = ARNode(
      type: _nodeTypeFor(url),
      uri: url,
      name: 'heritage_model',
      transformation: transformation,
      scale: vector.Vector3(_pendingScale, _pendingScale, _pendingScale),
    );
    _heritageNode = node;
    // addNode() returns false (not just an exception) when the native side
    // fails to load the GLB (e.g. a 404'd/corrupt model) — this was
    // previously ignored entirely, so a broken model placed with zero error
    // feedback: the loading overlay had already dismissed, the "tap to
    // place" snackbar already showed, and the user's tap just produced
    // nothing with no explanation anywhere.
    final added = await _objectManager?.addNode(node);
    if (added != true) {
      _heritageNode = null;
      onArError?.call('model_placement_failed');
    }
  }

  /// 🕰️ THEN/NOW TOGGLE: Swaps between normal ruins and reconstructed model.
  Future<void> toggleHistoricalMode() async {
    if (_objectManager == null || _heritageNode == null) return;
    if (_currentHistoricalUrl == null) return;

    isHistoricalMode.value = !isHistoricalMode.value;
    final transformation = _heritageNode!.transform;

    // Remove only the heritage node — NOT removeModel(), which now also
    // clears artifact nodes (see removeModel() doc). Toggling Then/Now must
    // not make already-placed gamification artifacts disappear.
    _objectManager?.removeNode(_heritageNode!);
    _heritageNode = null;

    // Add new node at same position
    await _addHeritageNode(
      url: isHistoricalMode.value ? _currentHistoricalUrl! : _currentModelUrl!,
      transformation: transformation,
    );

    debugPrint("[AR] Swapped model. HistoricalMode: ${isHistoricalMode.value}");
  }

  /// Places hidden heritage artifacts relative to the placed model.
  Future<void> placeArtifacts(List<ARArtifact> artifacts, vector.Vector3 parentPosition, Set<String> foundIds) async {
    if (_objectManager == null) return;

    for (var artifact in artifacts) {
      if (foundIds.contains(artifact.id)) continue;

      // Calculate absolute position based on parent and relative offset
      final absX = parentPosition.x + artifact.relativePosition[0];
      final absY = parentPosition.y + artifact.relativePosition[1];
      final absZ = parentPosition.z + artifact.relativePosition[2];

      final url = artifact.modelUrl.isNotEmpty
          ? artifact.modelUrl
          : "https://raw.githubusercontent.com/KhronosGroup/glTF-Sample-Models/master/2.0/Box/glTF-Binary/Box.glb";

      final node = ARNode(
        type: _nodeTypeFor(url),
        uri: url,
        name: 'artifact_${artifact.id}',
        position: vector.Vector3(absX, absY, absZ),
        // Scale artifacts to be smaller and harder to find
        scale: vector.Vector3(0.005, 0.005, 0.005),
      );

      _artifactNodes[artifact.id] = node;
      _objectManager?.addNode(node);
    }
  }

  /// Remove the current model and any placed artifact nodes. Previously this
  /// only removed the heritage node — artifact GLBs placed by
  /// placeArtifacts() stayed resident in the native AR scene across repeated
  /// place/reset cycles, leaking GPU/memory with no bound over one session.
  Future<void> removeModel() async {
    if (_heritageNode != null) {
      _objectManager?.removeNode(_heritageNode!);
      _heritageNode = null;
    }
    for (final node in _artifactNodes.values) {
      _objectManager?.removeNode(node);
    }
    _artifactNodes.clear();
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
    _sessionManager?.dispose();
    _isInitialized = false;
  }
}
