import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
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
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  bool _isConnected = false;
  bool _isDisposed = false;
  Timer? _pollingFallbackTimer;

  // BUG-104: Class-level constant — max WebSocket retry count before giving up
  static const int _maxReconnectAttempts = 10;

  /// Initialize Reverb WebSocket connection & fallback poller
  void init({String district = "Colombo"}) {
    _isDisposed = false;
    _reconnectAttempts = 0; // BUG-104: Reset counter on fresh init
    _connectWebSocket(district);
    _startFallbackPoller(district);
  }

  Future<void> _connectWebSocket(String district) async {
    _reconnectTimer?.cancel();

    // BUG-084: Query network connectivity status before opening network sockets
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult.contains(ConnectivityResult.none)) {
        _isConnected = false;
        SecureLogger.warning('[MonsoonBroadcast] Device is offline. Postponing WebSocket link.');
        _scheduleReconnect(district);
        return;
      }
    } catch (e) {
      SecureLogger.warning('[MonsoonBroadcast] Connectivity query error: $e');
    }

    try {
      // Reverb / Pusher WebSocket URL syntax dynamically derived from AppConfig
      final wsUrl = Uri.parse(AppConfig.reverbWsUrl);
      _channel = WebSocketChannel.connect(wsUrl);
      
      _channel!.stream.listen(

        (message) {
          _isConnected = true;
          // BUG-104: Reset counter on success so transient outages don't
          // permanently exhaust the attempt budget.
          _reconnectAttempts = 0;
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
          _scheduleReconnect(district);
        },
        onDone: () {
          _isConnected = false;
          SecureLogger.info('[MonsoonBroadcast] Reverb WebSocket stream closed.');
          _scheduleReconnect(district);
        },
      );
    } catch (e) {
      _isConnected = false;
      SecureLogger.warning('[MonsoonBroadcast] Failed to initialize WebSocket: $e');
      _scheduleReconnect(district);
    }
  }

  void _scheduleReconnect(String district) {
    // BUG-104: Do not schedule reconnects if service has been disposed
    if (_isDisposed) return;
    if (_reconnectTimer?.isActive ?? false) return;
    _reconnectAttempts++;

    // BUG-104 / BUG-124: Stop reconnecting after _maxReconnectAttempts to
    // prevent infinite loops when the server is persistently unreachable.
    if (_reconnectAttempts > _maxReconnectAttempts) {
      SecureLogger.warning(
        '[MonsoonBroadcast] Max reconnect attempts ($_maxReconnectAttempts) reached. '
        'Stopping WebSocket retries — fallback poller will handle updates.',
      );
      return;
    }

    final backoffSeconds = (1 << (_reconnectAttempts - 1)).clamp(1, 60);
    SecureLogger.info('[MonsoonBroadcast] Reconnecting in ${backoffSeconds}s (Attempt $_reconnectAttempts/$_maxReconnectAttempts)');
    _reconnectTimer = Timer(Duration(seconds: backoffSeconds), () {
      if (!_isDisposed) _connectWebSocket(district);
    });
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
    // BUG-104: Set disposed flag first so any pending timer callbacks
    // that fire mid-teardown do not trigger a new reconnect loop.
    _isDisposed = true;
    _isConnected = false;
    _channel?.sink.close();
    _pollingFallbackTimer?.cancel();
    _reconnectTimer?.cancel();
    if (!_broadcastController.isClosed) _broadcastController.close();
  }
}
