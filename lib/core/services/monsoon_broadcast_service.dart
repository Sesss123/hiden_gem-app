import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import '../config/app_config.dart';
import '../utils/secure_logger.dart';

/// 🌧️ [MonsoonBroadcastService] — Phase 5 Real-Time Reverb & WebSocket Safety Engine
/// 
/// Listens to live monsoon emergency broadcasts dispatched by Laravel Task Scheduler
/// or Admin Dashboard and streams safety warnings directly to tourist screens.
class MonsoonBroadcastService {
  static final MonsoonBroadcastService _instance = MonsoonBroadcastService._internal();
  factory MonsoonBroadcastService() => _instance;
  MonsoonBroadcastService._internal();

  WebSocketChannel? _channel;
  final StreamController<Map<String, dynamic>> _broadcastController = StreamController<Map<String, dynamic>>.broadcast();
  
  Stream<Map<String, dynamic>> get broadcastStream => _broadcastController.stream;
  bool _isConnected = false;
  Timer? _pollingFallbackTimer;

  /// Initialize Reverb WebSocket connection & fallback poller
  void init({String district = "Colombo"}) {
    _connectWebSocket(district);
    _startFallbackPoller(district);
  }

  void _connectWebSocket(String district) {
    try {
      // Reverb / Pusher WebSocket URL syntax (defaulting to ws://localhost:8080/app/reverb_key)
      final wsUrl = Uri.parse('ws://10.0.2.2:8080/app/hiddengems_reverb_key?protocol=7&client=js&version=8.0.0&flash=false');
      _channel = WebSocketChannel.connect(wsUrl);
      
      _channel!.stream.listen(
        (message) {
          _isConnected = true;
          try {
            final data = json.decode(message as String);
            // Check if it is an emergency broadcast event
            if (data['event'] == 'MonsoonHazardBroadcast' || data['event'] == 'client-emergency') {
              final payload = data['data'] is String ? json.decode(data['data']) : data['data'];
              _broadcastController.add(payload as Map<String, dynamic>);
              SecureLogger.info('[MonsoonBroadcast] Real-time emergency hazard received via Reverb WebSockets.');
            }
          } catch (e) {
            SecureLogger.warning('[MonsoonBroadcast] WebSocket message parse error: $e');
          }
        },
        onError: (error) {
          _isConnected = false;
          SecureLogger.warning('[MonsoonBroadcast] Reverb WebSocket disconnected: $error');
        },
        onDone: () {
          _isConnected = false;
          SecureLogger.info('[MonsoonBroadcast] Reverb WebSocket stream closed.');
        },
      );
    } catch (e) {
      _isConnected = false;
      SecureLogger.warning('[MonsoonBroadcast] Failed to initialize WebSocket: $e');
    }
  }

  /// Polling fallback when WebSockets are unavailable in remote monsoon terrains
  void _startFallbackPoller(String district) {
    _pollingFallbackTimer?.cancel();
    _pollingFallbackTimer = Timer.periodic(const Duration(minutes: 5), (timer) async {
      if (_isConnected) return; // Skip polling if real-time WebSocket is active

      try {
        final uri = Uri.parse('${AppConfig.pythonUrl}/weather/alerts');
        final response = await http.get(uri).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final body = json.decode(response.body) as Map<String, dynamic>;
          final alerts = body['alerts'] as List<dynamic>? ?? [];

          for (final alert in alerts) {
            if ((alert['district'] as String?).toString().toLowerCase() == district.toLowerCase() &&
                alert['hazard_level'] == 'ALERT') {
              _broadcastController.add({
                'district': alert['district'],
                'message': alert['advice'],
                'severity': 'CRITICAL',
                'source': 'polling_fallback'
              });
            }
          }
        }
      } catch (e) {
        SecureLogger.warning('[MonsoonBroadcast] Fallback poller failed: $e');
      }
    });
  }

  void dispose() {
    _channel?.sink.close();
    _pollingFallbackTimer?.cancel();
    _broadcastController.close();
  }
}
