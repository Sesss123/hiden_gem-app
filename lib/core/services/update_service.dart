import 'package:package_info_plus/package_info_plus.dart';
import '../config/remote_config_service.dart';

enum UpdateType { force, soft, none }

class UpdateService {
  static final UpdateService _instance = UpdateService._internal();
  factory UpdateService() => _instance;
  UpdateService._internal();

  UpdateType _currentUpdateType = UpdateType.none;
  UpdateType get currentUpdateType => _currentUpdateType;

  Future<UpdateType> checkUpdate() async {
    try {
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      final String currentVersion = packageInfo.version;
      
      final remoteConfig = await RemoteConfigService.getInstance();
      final String minVersion = remoteConfig.minAppVersion;
      final String latestVersion = remoteConfig.latestAppVersion;

      if (_isVersionLower(currentVersion, minVersion)) {
        _currentUpdateType = UpdateType.force;
      } else if (_isVersionLower(currentVersion, latestVersion)) {
        _currentUpdateType = UpdateType.soft;
      } else {
        _currentUpdateType = UpdateType.none;
      }
    } catch (e) {
      // In case of error (e.g. offline), don't block the user
      _currentUpdateType = UpdateType.none;
    }
    return _currentUpdateType;
  }

  bool _isVersionLower(String current, String target) {
    if (current == target) return false;
    
    final List<int> currentParts = current.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final List<int> targetParts = target.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    for (int i = 0; i < currentParts.length && i < targetParts.length; i++) {
      if (currentParts[i] < targetParts[i]) return true;
      if (currentParts[i] > targetParts[i]) return false;
    }

    // If all parts so far are equal, and target has more parts, it's a higher version
    return targetParts.length > currentParts.length;
  }
}
