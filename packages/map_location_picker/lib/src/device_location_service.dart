import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

class LocationFailure implements Exception {
  final String message;

  const LocationFailure(this.message);

  @override
  String toString() => message;
}

/// Thin wrapper around `geolocator` so the dialog does not depend on the
/// plugin directly and errors can be shown in Vietnamese.
class DeviceLocationService {
  const DeviceLocationService();

  Future<LatLng> currentPosition() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw const LocationFailure(
          'Dịch vụ vị trí đang tắt. Vui lòng bật GPS rồi thử lại.',
        );
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        throw const LocationFailure(
          'Bạn chưa cấp quyền truy cập vị trí cho ứng dụng.',
        );
      }
      if (permission == LocationPermission.deniedForever) {
        throw const LocationFailure(
          'Quyền truy cập vị trí đã bị chặn. Hãy mở Cài đặt để cấp lại.',
        );
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
      return LatLng(position.latitude, position.longitude);
    } on LocationFailure {
      rethrow;
    } on TimeoutException {
      throw const LocationFailure(
        'Không lấy được vị trí kịp thời. Hãy thử lại ở nơi thoáng hơn.',
      );
    } catch (error) {
      debugPrint('DeviceLocationService failed: $error');
      throw LocationFailure('Không thể lấy vị trí GPS: $error');
    }
  }
}
