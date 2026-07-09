import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../config/app_config.dart';
import '../utils/secure_logger.dart';

/// Generic Laravel Reverb (Pusher-protocol) channel subscriber.
///
/// Reused by any repository/service that wants a live push update for data
/// it already fetches via a cached HTTP endpoint (see MarketplaceRepository,
/// ARVideoRepository) — the WebSocket push is purely an optimization layered
/// on top of that existing HTTP-cache path, never a replacement for it: if
/// the socket never connects or drops, callers keep working exactly as they
/// did before this class existed.
///
/// Handles the Pusher wire protocol Reverb speaks: connect, wait for
/// `pusher:connection_established`, send `pusher:subscribe` for the target
/// channel, then decode named events on that channel. Reconnects with
/// exponential backoff, same shape as MonsoonBroadcastService.
class ReverbChannelService {
  ReverbChannelService({required this.channelName});

  final String channelName;

  WebSocketChannel? _channel;
  StreamSubscription? _socketSub;
  final StreamController<Map<String, dynamic>> _eventController =
      StreamController<Map<String, dynamic>>.broadcast();

  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  bool _isSubscribed = false;
  bool _isDisposed = false;

  /// Whether the channel subscription handshake has completed — callers can
  /// use this to show a "live" indicator, or to know whether to trust that
  /// their in-memory cache is being kept fresh by pushes right now.
  bool get isSubscribed => _isSubscribed;

  static const int _maxReconnectAttempts = 10;

  /// Stream of decoded `data` payloads for every event received on
  /// [channelName], keyed by the Reverb event name (`broadcastAs()` on the
  /// Laravel side) so one channel can carry more than one event type.
  Stream<ReverbEvent> get events => _eventController.stream
      .map((raw) => ReverbEvent(name: raw['event'] as String? ?? '', data: raw['data']));

  void connect() {
    _isDisposed = false;
    _reconnectAttempts = 0;
    _connectSocket();
  }

  Future<void> _connectSocket() async {
    _reconnectTimer?.cancel();

    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult.contains(ConnectivityResult.none)) {
        SecureLogger.warning('[ReverbChannel:$channelName] Device is offline. Postponing connect.');
        _scheduleReconnect();
        return;
      }
    } catch (e) {
      SecureLogger.warning('[ReverbChannel:$channelName] Connectivity query error: $e');
    }

    try {
      final wsUrl = Uri.parse(AppConfig.reverbWsUrl);
      _channel = WebSocketChannel.connect(wsUrl);
      _isSubscribed = false;

      _socketSub = _channel!.stream.listen(
        _handleMessage,
        onError: (error) {
          SecureLogger.warning('[ReverbChannel:$channelName] Socket error: $error');
          _isSubscribed = false;
          _scheduleReconnect();
        },
        onDone: () {
          SecureLogger.info('[ReverbChannel:$channelName] Socket closed.');
          _isSubscribed = false;
          _scheduleReconnect();
        },
      );
    } catch (e) {
      SecureLogger.warning('[ReverbChannel:$channelName] Failed to connect: $e');
      _scheduleReconnect();
    }
  }

  void _handleMessage(dynamic message) {
    try {
      final decoded = json.decode(message as String) as Map<String, dynamic>;
      final event = decoded['event'] as String?;

      if (event == 'pusher:connection_established') {
        _reconnectAttempts = 0;
        _subscribeToChannel();
        return;
      }

      if (event == 'pusher_internal:subscription_succeeded') {
        _isSubscribed = true;
        SecureLogger.info('[ReverbChannel:$channelName] Subscribed.');
        return;
      }

      if (event == null || event.startsWith('pusher')) return;

      final rawData = decoded['data'];
      final data = rawData is String ? json.decode(rawData) : rawData;
      _eventController.add({'event': event, 'data': data});
    } catch (e) {
      SecureLogger.warning('[ReverbChannel:$channelName] Message parse error: $e');
    }
  }

  void _subscribeToChannel() {
    _channel?.sink.add(json.encode({
      'event': 'pusher:subscribe',
      'data': {'channel': channelName},
    }));
  }

  void _scheduleReconnect() {
    if (_isDisposed) return;
    if (_reconnectTimer?.isActive ?? false) return;
    _reconnectAttempts++;

    if (_reconnectAttempts > _maxReconnectAttempts) {
      SecureLogger.warning(
        '[ReverbChannel:$channelName] Max reconnect attempts ($_maxReconnectAttempts) reached. '
        'Giving up — callers should keep relying on their HTTP-cache fallback.',
      );
      return;
    }

    final backoffSeconds = (1 << (_reconnectAttempts - 1)).clamp(1, 60);
    _reconnectTimer = Timer(Duration(seconds: backoffSeconds), () {
      if (!_isDisposed) _connectSocket();
    });
  }

  void dispose() {
    _isDisposed = true;
    _isSubscribed = false;
    _reconnectTimer?.cancel();
    _socketSub?.cancel();
    _channel?.sink.close();
    if (!_eventController.isClosed) _eventController.close();
  }
}

class ReverbEvent {
  const ReverbEvent({required this.name, required this.data});
  final String name;
  final dynamic data;
}
