import 'package:geolocator/geolocator.dart';

class CurrentLocationService {
  const CurrentLocationService._();

  static Future<Position> getRequiredPosition({
    LocationAccuracy accuracy = LocationAccuracy.high,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw StateError('Location permission was denied.');
    }
    if (permission == LocationPermission.deniedForever) {
      throw StateError(
          'Location permission is permanently denied. Enable it in device settings.');
    }
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw StateError('Location services are turned off.');
    }

    return Geolocator.getCurrentPosition(
      locationSettings: LocationSettings(
        accuracy: accuracy,
        timeLimit: timeout,
      ),
    ).timeout(timeout + const Duration(seconds: 2));
  }
}
