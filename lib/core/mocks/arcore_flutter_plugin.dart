import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as vector;

class ArCoreController {
  Function(List<ArCoreHitTestResult>)? onPlaneTap;
  Function(String)? onNodeTap;
  
  void dispose() {}
  Future<void> addArCoreNodeWithAnchor(ArCoreNode node) async {}
  Future<void> addArCoreNode(ArCoreNode node) async {}
  Future<void> removeNode({required String nodeName}) async {}
  Future<void> loadMesh({required String textureBytes, required String name}) async {}

  static Future<bool> checkArCoreAvailability() async {
    return false; // Not available in mock
  }

  static Future<bool> checkIsArCoreInstalled() async {
    return false;
  }
}

class ArCoreNode {
  final String? name;
  final dynamic shape;
  final vector.Vector3? position;
  final vector.Vector4? rotation;

  ArCoreNode({
    this.name,
    this.shape,
    this.position,
    this.rotation,
  });
}

class ArCoreReferenceNode extends ArCoreNode {
  final String objectUrl;
  final vector.Vector3? scale;

  ArCoreReferenceNode({
    super.name,
    required this.objectUrl,
    super.position,
    super.rotation,
    this.scale,
  });
}

class ArCoreHitTestResult {
  final double distance;
  final vector.Vector3 translation;
  final vector.Vector4 rotation;
  final ArCorePose pose;

  ArCoreHitTestResult({
    required this.distance,
    required this.translation,
    required this.rotation,
    required this.pose,
  });
}

class ArCorePose {
  final vector.Vector3 translation;
  final vector.Vector4 rotation;
  ArCorePose({required this.translation, required this.rotation});
}

class ArCoreView extends StatelessWidget {
  final Function(ArCoreController) onArCoreViewCreated;
  final bool enableTapRecognizer;
  final bool enableUpdateListener;
  final bool enablePlaneRenderer;

  const ArCoreView({
    super.key,
    required this.onArCoreViewCreated,
    this.enableTapRecognizer = false,
    this.enableUpdateListener = false,
    this.enablePlaneRenderer = false,
  });

  @override
  Widget build(BuildContext context) {
    // Return a black screen with a warning or just black since it's a fallback
    return Container(
      color: Colors.black,
      child: const Center(
        child: Text(
          'AR Core is currently unavailable on this device.',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}

class ArCoreApkAvailability {
  static const int supportedInstalled = 0;
  static const int supportedNotInstalled = 1;
  static const int unknownChecking = 2;
  static const int unknownError = 3;
  static const int unsupportedDeviceNotCapable = 4;
}

class ArCoreCore {
  static Future<int> checkArCoreApkAvailability() async {
    return ArCoreApkAvailability.unsupportedDeviceNotCapable; // Force fallback
  }

  static Future<bool> checkIfARCoreServicesInstalled() async {
    return false;
  }
}
