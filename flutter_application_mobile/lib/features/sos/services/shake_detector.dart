import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// Nhận diện 5 lần lắc điện thoại liên tiếp.
///
/// Chỉ hoạt động khi màn hình SOS đang mở. Mỗi lần vượt ngưỡng cách nhau ít
/// nhất [debounce], và cả chuỗi 5 lần phải nằm trong [window].
class ShakeDetector {
  ShakeDetector({
    required this.onShake,
    this.threshold = 18,
    this.requiredShakes = 5,
    this.debounce = const Duration(milliseconds: 220),
    this.window = const Duration(seconds: 4),
  });

  final VoidCallback onShake;
  final double threshold;
  final int requiredShakes;
  final Duration debounce;
  final Duration window;

  StreamSubscription<AccelerometerEvent>? _subscription;
  DateTime? _lastShakeAt;
  DateTime? _firstShakeAt;
  DateTime? _cooldownUntil;
  int _shakeCount = 0;

  bool get isListening => _subscription != null;

  void start() {
    if (_subscription != null) return;
    try {
      _subscription =
          accelerometerEventStream(
            samplingPeriod: const Duration(milliseconds: 50),
          ).listen(
            _onEvent,
            onError: (_) {
              // Trình duyệt/thiết bị không có cảm biến: bỏ qua.
            },
            cancelOnError: false,
          );
    } catch (_) {
      _subscription = null;
    }
  }

  void _onEvent(AccelerometerEvent event) {
    final now = DateTime.now();
    final cooldown = _cooldownUntil;
    if (cooldown != null && now.isBefore(cooldown)) return;

    final magnitude = math.sqrt(
      event.x * event.x + event.y * event.y + event.z * event.z,
    );
    if (magnitude < threshold) return;

    final last = _lastShakeAt;
    if (last != null && now.difference(last) < debounce) return;

    final first = _firstShakeAt;
    if (first == null || now.difference(first) > window) {
      _firstShakeAt = now;
      _shakeCount = 0;
    }

    _lastShakeAt = now;
    _shakeCount++;

    if (_shakeCount >= requiredShakes) {
      _shakeCount = 0;
      _firstShakeAt = null;
      _lastShakeAt = null;
      _cooldownUntil = now.add(const Duration(seconds: 5));
      onShake();
    }
  }

  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
    _shakeCount = 0;
    _firstShakeAt = null;
    _lastShakeAt = null;
  }

  Future<void> dispose() => stop();
}
