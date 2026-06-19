import 'dart:convert';
import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../data/models/passport_model.dart';
import '../utils/secure_logger.dart';
import 'package:geolocator/geolocator.dart';

class Web3PassportService {
  static const _storage = FlutterSecureStorage();
  static const _key = 'heritage_stamps_collection';

  static Future<List<HeritageStamp>> getCollection() async {
    try {
      final jsonStr = await _storage.read(key: _key);
      if (jsonStr == null) return [];
      final List<dynamic> list = json.decode(jsonStr);
      return list.map((e) => HeritageStamp.fromJson(e)).toList();
    } catch (e) {
      SecureLogger.error('Failed to read passport collection: $e');
      return [];
    }
  }

  static Future<bool> claimStamp({
    required String placeName,
    required double targetLat,
    required double targetLng,
    required String imageUrl,
  }) async {
    try {
      // 1. Proximity Check (100m radius)
      final pos = await Geolocator.getCurrentPosition();
      final distance = Geolocator.distanceBetween(
        pos.latitude, pos.longitude, 
        targetLat, targetLng
      );

      if (distance > 100) {
        SecureLogger.warning('Claim failed: Too far from location ($distance m)');
        return false;
      }

      // 2. Already claimed?
      final current = await getCollection();
      if (current.any((s) => s.placeName == placeName)) {
        return false;
      }

      // 3. Generate Simulated Blockchain Hash
      final hash = _generateSimulatedHash(placeName);
      
      // 4. Determine Rarity
      final rarity = _determineRarity();

      final stamp = HeritageStamp(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        placeName: placeName,
        imageUrl: imageUrl,
        claimDate: DateTime.now(),
        rarity: rarity,
        hash: hash,
      );

      current.add(stamp);
      await _storage.write(key: _key, value: json.encode(current.map((e) => e.toJson()).toList()));
      SecureLogger.info('Heritage Stamp claimed: $placeName');
      return true;
    } catch (e) {
      SecureLogger.error('Failed to claim stamp: $e');
      return false;
    }
  }

  static String _generateSimulatedHash(String input) {
    final random = Random();
    final chars = '0123456789abcdef';
    return List.generate(64, (index) => chars[random.nextInt(chars.length)]).join();
  }

  static String _determineRarity() {
    final r = Random().nextDouble();
    if (r < 0.05) return 'Mythic';
    if (r < 0.20) return 'Rare';
    return 'Common';
  }
}
