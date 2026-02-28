import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../core/app_config.dart';

class WebSocketService {
  static const Duration _pingInterval = Duration(seconds: 25);

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  Timer? _pingTimer;
  final StreamController<Map<String, dynamic>> _alertsController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get alertsStream => _alertsController.stream;

  Future<void> connect(String token) async {
    if (_channel != null) {
      return;
    }

    final baseUri = Uri.parse(AppConfig.current.baseUrl);
    final wsUri = baseUri
        .replace(
          scheme: baseUri.scheme == 'https' ? 'wss' : 'ws',
          path: '/api/v1/ws/alerts',
          queryParameters: {'token': token},
        )
        .toString();

    _channel = WebSocketChannel.connect(Uri.parse(wsUri));
    _pingTimer = Timer.periodic(_pingInterval, (_) {
      final channel = _channel;
      if (channel == null) {
        return;
      }
      channel.sink.add(
        jsonEncode({
          'type': 'ping',
          'sent_at': DateTime.now().toUtc().toIso8601String(),
        }),
      );
    });

    _subscription = _channel?.stream.listen((event) {
      if (event is Map<String, dynamic>) {
        _alertsController.add(event);
        return;
      }

      if (event is String && event.isNotEmpty) {
        try {
          final decoded = jsonDecode(event);
          if (decoded is Map<String, dynamic>) {
            _alertsController.add(decoded);
          }
        } catch (_) {
          return;
        }
      }
    }, onError: (_) {
      disconnect();
    }, onDone: disconnect);
  }

  void disconnect() {
    _pingTimer?.cancel();
    _pingTimer = null;
    _subscription?.cancel();
    _subscription = null;
    _channel?.sink.close();
    _channel = null;
  }

  void dispose() {
    disconnect();
    if (!_alertsController.isClosed) {
      _alertsController.close();
    }
  }
}

final webSocketServiceProvider = Provider<WebSocketService>((ref) {
  final service = WebSocketService();
  ref.onDispose(service.dispose);
  return service;
});
