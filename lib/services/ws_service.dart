import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/ws_event.dart';
import 'api_service.dart';

typedef WsEventHandler = void Function(MattermostWebSocketEvent event);

class WsService {
  static final WsService _instance = WsService._internal();
  factory WsService() => _instance;
  WsService._internal();

  WebSocketChannel? _channel;
  StreamSubscription? _sub;
  Timer? _pingTimer;
  Timer? _reconnectTimer;
  int _seq = 0;
  bool _isManuallyClosed = false;
  bool _isConnecting = false;

  final Map<String, Set<WsEventHandler>> _handlers = {};

  bool get isConnected => _channel != null;

  void connect([String? token]) {
    final authToken = token ?? ApiService().token;
    final baseUrl = ApiService().baseUrl;

    if (authToken == null || authToken.isEmpty || baseUrl.isEmpty) {
      return;
    }

    if (_channel != null || _isConnecting) {
      return;
    }

    _isManuallyClosed = false;
    _isConnecting = true;

    final parsed = Uri.parse(baseUrl);
    final isHttps = parsed.scheme == 'https';
    final wsScheme = isHttps ? 'wss' : 'ws';
    final wsUrl = '$wsScheme://${parsed.host}${parsed.hasPort ? ':${parsed.port}' : ''}/api/v4/websocket';

    try {
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      _sub = _channel!.stream.listen(
        (data) {
          _isConnecting = false;
          _handleIncoming(data);
        },
        onDone: () {
          _cleanup();
          if (!_isManuallyClosed) {
            _scheduleReconnect();
          }
        },
        onError: (_) {
          _cleanup();
          if (!_isManuallyClosed) {
            _scheduleReconnect();
          }
        },
      );

      // Send authentication challenge immediately on connect
      sendAction('authentication_challenge', {'token': authToken});
      _startPing();
    } catch (_) {
      _cleanup();
      _scheduleReconnect();
    }
  }

  void disconnect() {
    _isManuallyClosed = true;
    _cleanup();
    if (_channel != null) {
      _channel!.sink.close();
      _channel = null;
    }
  }

  void _cleanup() {
    _isConnecting = false;
    _pingTimer?.cancel();
    _pingTimer = null;
    _sub?.cancel();
    _sub = null;
    _channel = null;
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 3), () {
      connect();
    });
  }

  void _startPing() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_channel != null) {
        sendAction('ping', {});
      }
    });
  }

  void sendAction(String action, Map<String, dynamic> data) {
    if (_channel != null) {
      final payload = {
        'seq': ++_seq,
        'action': action,
        'data': data,
      };
      _channel!.sink.add(jsonEncode(payload));
    }
  }

  void sendTyping(String channelId, [String parentId = '']) {
    sendAction('user_typing', {
      'channel_id': channelId,
      'parent_id': parentId,
    });
  }

  void on(String event, WsEventHandler handler) {
    _handlers.putIfAbsent(event, () => {}).add(handler);
  }

  void off(String event, WsEventHandler handler) {
    _handlers[event]?.remove(handler);
  }

  void _handleIncoming(dynamic raw) {
    try {
      final json = jsonDecode(raw.toString());
      if (json is Map<String, dynamic> && json['event'] != null) {
        final wsEvent = MattermostWebSocketEvent.fromJson(json);
        _emit(wsEvent.event, wsEvent);
        _emit('*', wsEvent);
      }
    } catch (_) {}
  }

  void _emit(String event, MattermostWebSocketEvent wsEvent) {
    final handlers = _handlers[event];
    if (handlers != null) {
      for (final handler in handlers.toList()) {
        try {
          handler(wsEvent);
        } catch (_) {}
      }
    }
  }
}
