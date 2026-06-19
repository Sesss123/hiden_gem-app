import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/datasources/user_preference_service.dart';

part 'screenshot_provider.g.dart';

@riverpod
class ScreenshotNotifier extends _$ScreenshotNotifier {
  @override
  bool build() {
    return UserPreferenceService.getProfile().showScreenshotButton;
  }

  void toggleVisibility(bool value) {
    state = value;
    UserPreferenceService.updateScreenshotMode(value);
  }
}
