import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';

/// Phát hiện khi điện thoại bị lắc [shakeCountThreshold] lần liên tiếp
/// trong khoảng [shakeCountResetTimeMs] mili-giây, rồi gọi [onShakeThresholdReached].
///
/// Cách dùng: xem file shake_usage_example.dart
class ShakeDetector {
  final void Function() onShakeThresholdReached;

  /// Số lần lắc cần đạt để trigger (mặc định 5)
  final int shakeCountThreshold;

  /// Độ nhạy: giá trị càng nhỏ càng dễ trigger (mặc định 2.7 lần trọng lực)
  final double shakeThresholdGravity;

  /// Thời gian tối thiểu giữa 2 lần lắc được tính, tránh 1 cái lắc bị đếm nhiều lần
  final int shakeSlopTimeMs;

  /// Nếu quá thời gian này mà không lắc tiếp thì reset bộ đếm về 0
  final int shakeCountResetTimeMs;

  StreamSubscription<AccelerometerEvent>? _subscription;
  int _shakeCount = 0;
  int _lastShakeTimestamp = DateTime.now().millisecondsSinceEpoch;
  int _lastResetTimestamp = DateTime.now().millisecondsSinceEpoch;

  ShakeDetector({
    required this.onShakeThresholdReached,
    this.shakeCountThreshold = 5,
    this.shakeThresholdGravity = 2.7,
    this.shakeSlopTimeMs = 500,
    this.shakeCountResetTimeMs = 3000,
  });

  void startListening() {
    _subscription = accelerometerEventStream().listen(_onAccelerometerEvent);
  }

  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
  }

  void _onAccelerometerEvent(AccelerometerEvent event) {
    final gX = event.x / 9.81;
    final gY = event.y / 9.81;
    final gZ = event.z / 9.81;
    final gForce = sqrt(gX * gX + gY * gY + gZ * gZ);

    if (gForce < shakeThresholdGravity) return;

    final now = DateTime.now().millisecondsSinceEpoch;

    // Bỏ qua rung liên tiếp quá gần nhau (1 cú lắc không bị đếm thành nhiều lần)
    if (_lastShakeTimestamp + shakeSlopTimeMs > now) return;

    // Quá lâu không lắc tiếp -> reset bộ đếm
    if (_lastResetTimestamp + shakeCountResetTimeMs < now) {
      _shakeCount = 0;
      _lastResetTimestamp = now;
    }

    _lastShakeTimestamp = now;
    _shakeCount++;

    if (_shakeCount >= shakeCountThreshold) {
      _shakeCount = 0;
      onShakeThresholdReached();
    }
  }
}
