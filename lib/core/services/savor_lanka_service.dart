import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import '../utils/secure_logger.dart';
import '../../data/models/food_model.dart';
import '../../core/config/app_config.dart';

class SavorLankaService {
  // The commercial Gemini path has been removed — food identification now runs
  // exclusively against the self-hosted model (BYOM) endpoint. `apiKey` is
  // retained in the signature only for call-site compatibility and is unused.
  final String apiKey;

  SavorLankaService({this.apiKey = ''});

  Future<FoodModel?> identifyFood(File imageFile, {
    String spicePreference = 'Medium',
    String userMode = 'Tourist',
  }) async {
    // 🏛️ Self-Hosted BYOM Custom Model Integration — the only path now.
    return _callCustomByomFoodScanner(imageFile, spicePreference, userMode);
  }


  Future<FoodModel?> _callCustomByomFoodScanner(File imageFile, String spicePreference, String userMode) async {
    try {
      final imageBytes = await imageFile.readAsBytes();
      
      // BUG-099: Validate image file integrity before starting conversions/GZIP encoding
      if (imageBytes.isEmpty || imageBytes.length < 4) {
        SecureLogger.warning("Custom BYOM Scanner: Image file is empty or corrupted. Aborting scan.");
        return null;
      }

      final compressedBytes = GZipCodec().encode(imageBytes);
      final base64Image = base64Encode(compressedBytes);

      final response = await http.post(
        Uri.parse('${AppConfig.pythonUrl}/food/scan'),
        headers: {
          'Content-Type': 'application/json',
          'Content-Encoding': 'gzip', // Signal to server that payload is compressed
        },
        body: json.encode({
          'image_base64': base64Image,
          'user_mode': userMode,
          'spice_preference': spicePreference,
          'compressed': true,
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        // BUG-139: Validate that the response is actually JSON before decoding.
        // Servers under load may return HTML error pages or empty bodies.
        final contentType = response.headers['content-type'] ?? '';
        final body = response.body.trim();
        if (body.isEmpty || !contentType.contains('application/json')) {
          SecureLogger.warning(
            'Custom BYOM Scanner: unexpected response format '
            '(content-type: $contentType, body length: ${body.length}). Skipping decode.',
          );
          return null;
        }
        final Map<String, dynamic> data = json.decode(body);
        return FoodModel.fromJson(data);
      }
    } on TimeoutException catch (e) {
      SecureLogger.error('Custom BYOM Food Scanner timed out (15s limit)', e);
    } on HttpException catch (e) {
      SecureLogger.error('Custom BYOM Food Scanner HTTP protocol error', e);
    } on SocketException catch (e) {
      SecureLogger.error('Custom BYOM Food Scanner connection failed: Network unreachable', e);
    } catch (e) {
      SecureLogger.warning('Custom BYOM Food Scanner offline or unreachable: $e');
    }
    return null;
  }
}
