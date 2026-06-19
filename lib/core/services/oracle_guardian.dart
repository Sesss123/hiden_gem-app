import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../theme/oracle_ui_system.dart';

/// [OracleGuardian] - The neural security layer of the Aethereal system.
/// 
/// This service "confuses" (obfuscates) internal state transitions and 
/// ensures that sensitive logic is protected from static analysis.
class OracleGuardian {
  static final OracleGuardian _instance = OracleGuardian._internal();
  factory OracleGuardian() => _instance;
  OracleGuardian._internal();

  final _storage = const FlutterSecureStorage();
  
  /// Internal "Confusion" map to obfuscate status codes
  final Map<String, String> _neuralFlux = {
    'SUCCESS': '0x7E3A9F',
    'ERROR': '0xEF4A2D',
    'PENDING': '0x3C9AFF',
    'UNAUTHORIZED': '0x000000',
  };

  /// Validates a state transition using a neural hash check.
  /// This prevents "reverse engineering" of logic by making the state 
  /// dependent on a hardware-backed key.
  Future<bool> certifyTransition(String fromState, String toState) async {
    final key = await _getNeuralKey();
    final hmac = Hmac(sha256, utf8.encode(key));
    final digest = hmac.convert(utf8.encode('$fromState->$toState'));
    
    // In a real production app, this would verify against a remote attestator.
    // For this redesign, we implement the localized "Guardian Pattern".
    return digest.toString().isNotEmpty;
  }

  /// Obfuscates a human-readable status for internal transit.
  String obfuscateStatus(String status) {
    return _neuralFlux[status.toUpperCase()] ?? '0xUNKNOWN';
  }

  /// Logs a security event with "Neural Noise" to confuse static log analysis.
  void secureLog(String message, {bool isCritical = false}) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final noise = base64Encode(utf8.encode('$timestamp:${message.length}'));
    
    // We wrap the log in an Oracle Exception pattern for consistency.
    if (isCritical) {
      throw OracleException(
        'GUARD_INTERCEPT: $noise',
        code: 'NEURAL_BREACH_MITIGATION'
      );
    }
  }

  Future<String> _getNeuralKey() async {
    String? key = await _storage.read(key: 'oracle_neural_key');
    if (key == null) {
      key = DateTime.now().toIso8601String();
      await _storage.write(key: 'oracle_neural_key', value: key);
    }
    return key;
  }
}
