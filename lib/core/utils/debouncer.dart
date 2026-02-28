import 'dart:async';
import 'package:flutter/material.dart';

/// Debouncer utility for search and input fields
class Debouncer {
  final Duration delay;
  Timer? _timer;

  Debouncer({this.delay = const Duration(milliseconds: 500)});

  void call(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  void dispose() {
    _timer?.cancel();
  }
}

/// Throttler utility
class Throttler {
  final Duration duration;
  bool _isReady = true;

  Throttler({this.duration = const Duration(milliseconds: 500)});

  void call(VoidCallback action) {
    if (_isReady) {
      _isReady = false;
      action();
      Timer(duration, () => _isReady = true);
    }
  }
}
