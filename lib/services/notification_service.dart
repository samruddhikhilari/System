import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

class NotificationService {
  String? _deviceToken;

  Future<void> initialize() async {
    _deviceToken ??= _generateDeviceToken();
  }

  Future<String?> getDeviceToken() async {
    return _deviceToken;
  }

  Future<void> showLocalNotification({
    required String title,
    required String body,
  }) async {
    // Placeholder for flutter_local_notifications integration.
    // Kept async for drop-in replacement with real notification plugin.
  }

  String _generateDeviceToken() {
    final random = Random();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'dev-token-$timestamp-${random.nextInt(999999)}';
  }
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});
