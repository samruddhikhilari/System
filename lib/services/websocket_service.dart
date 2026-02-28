import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../core/app_config.dart';

class WebSocketService {
  io.Socket? _socket;
  final StreamController<Map<String, dynamic>> _alertsController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get alertsStream => _alertsController.stream;

  Future<void> connect(String token) async {
    if (_socket?.connected == true) {
      return;
    }

    _socket = io.io(
      '${AppConfig.current.baseUrl}/ws',
      io.OptionBuilder()
          .setTransports(['websocket'])
          .enableReconnection()
          .setAuth({'Authorization': 'Bearer $token'})
          .disableAutoConnect()
          .build(),
    );

    _socket?.on('alert', (data) {
      if (data is Map<String, dynamic>) {
        _alertsController.add(data);
      }
    });

    _socket?.connect();
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }

  void dispose() {
    disconnect();
    _alertsController.close();
  }
}

final webSocketServiceProvider = Provider<WebSocketService>((ref) {
  final service = WebSocketService();
  ref.onDispose(service.dispose);
  return service;
});
