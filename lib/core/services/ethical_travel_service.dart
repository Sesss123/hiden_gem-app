import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/secure_logger.dart';

class EthicalTravelService {
  static const _storage = FlutterSecureStorage();
  static const _scoreKey = 'ethical_travel_score';

  static Future<int> getScore() async {
    final scoreStr = await _storage.read(key: _scoreKey);
    return int.tryParse(scoreStr ?? '0') ?? 0;
  }

  static Future<void> incrementScore(int points) async {
    final current = await getScore();
    await _storage.write(key: _scoreKey, value: (current + points).toString());
    SecureLogger.info('Ethical Score increased by $points: Total ${current + points}');
  }

  static String getRank(int score) {
    if (score > 500) return 'Eco Guardian';
    if (score > 200) return 'Conscious Explorer';
    if (score > 50) return 'Green Traveler';
    return 'Seedling';
  }

  /// Points for specific actions
  static const pointsReview = 10;
  static const pointsLocalFood = 15;
  static const pointsHeritageVisit = 20;
}
