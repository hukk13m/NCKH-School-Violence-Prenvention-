import 'package:geolocator/geolocator.dart';
import 'package:map_location_picker/map_location_picker.dart';

import '../../../core/config/api_config.dart';
import '../../dashboard/data/case_service.dart';
import 'sos_offline_queue.dart';
import 'sos_settings_store.dart';

class SosSendResult {
  const SosSendResult({
    required this.success,
    required this.queued,
    required this.message,
    this.latitude,
    this.longitude,
    this.locationLabel,
  });

  final bool success;
  final bool queued;
  final String message;
  final double? latitude;
  final double? longitude;
  final String? locationLabel;

  bool get failed => !success && !queued;
}

/// Xử lý gửi báo cáo SOS, lấy vị trí và lưu báo cáo khi mất mạng.
class SosService {
  SosService({
    CaseService? caseService,
    SosOfflineQueue? queue,
    SosSettingsStore? settingsStore,
    BackendGeocoder? geocoder,
  }) : _caseService = caseService ?? CaseService(),
       _queue = queue ?? SosOfflineQueue(),
       _settingsStore = settingsStore ?? SosSettingsStore(),
       _geocoder = geocoder ?? BackendGeocoder(baseUrl: resolveApiBaseUrl());

  final CaseService _caseService;
  final SosOfflineQueue _queue;
  final SosSettingsStore _settingsStore;
  final BackendGeocoder _geocoder;

  Future<SosSendResult> sendSos({
    required String userId,
    String? note,
    String? locationOverride,
    double? latitudeOverride,
    double? longitudeOverride,
  }) async {
    final settings = await _settingsStore.load();
    final position = await _resolvePosition();
    final lat = latitudeOverride ?? position?.latitude;
    final lng = longitudeOverride ?? position?.longitude;

    String location = locationOverride?.trim() ?? '';
    if (location.isEmpty && lat != null && lng != null) {
      location = await _reverseGeocode(lat, lng);
    }
    if (location.isEmpty) {
      location = 'Chưa xác định được vị trí';
    }

    final noteText = (note ?? settings.emergencyMessage).trim();
    final description = StringBuffer(
      'SOS KHẨN CẤP - Bạo lực học đường. '
      'Người dùng cần hỗ trợ ngay lập tức.',
    );
    if (noteText.isNotEmpty) {
      description.write('\nLời nhắn: $noteText');
    }
    if (lat != null && lng != null) {
      description.write(
        '\nTọa độ: ${lat.toStringAsFixed(7)}, ${lng.toStringAsFixed(7)}',
      );
    }

    try {
      await _caseService.submitReport(
        description: description.toString(),
        location: location,
        reportType: 'SOS',
        priority: 'High',
        userId: userId,
        latitude: lat,
        longitude: lng,
      );
      return SosSendResult(
        success: true,
        queued: false,
        message: 'Đã gửi báo cáo SOS đến trung tâm hỗ trợ.',
        latitude: lat,
        longitude: lng,
        locationLabel: location,
      );
    } catch (error) {
      final queuedReport = QueuedSosReport(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        description: description.toString(),
        location: location,
        reportType: 'SOS',
        priority: 'High',
        userId: userId,
        createdAt: DateTime.now(),
        latitude: lat,
        longitude: lng,
      );
      await _queue.add(queuedReport);
      return SosSendResult(
        success: false,
        queued: true,
        message:
            'Không thể kết nối máy chủ. Báo cáo SOS đã được lưu và sẽ tự '
            'gửi lại khi có mạng.',
        latitude: lat,
        longitude: lng,
        locationLabel: location,
      );
    }
  }

  Future<int> flushPendingReports() => _queue.flush(_caseService);

  Future<Position?> _resolvePosition() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      try {
        return await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 8),
          ),
        );
      } catch (_) {
        return Geolocator.getLastKnownPosition();
      }
    } catch (_) {
      return null;
    }
  }

  Future<String> _reverseGeocode(double latitude, double longitude) async {
    try {
      final place = await _geocoder.reverse(latitude, longitude);
      final name = place?.displayName.trim() ?? '';
      if (name.isNotEmpty) return name;
    } catch (_) {
      // Không có mạng hoặc dịch vụ địa chỉ lỗi: dùng tọa độ làm nhãn.
    }
    return 'Vị trí GPS: ${latitude.toStringAsFixed(5)}, '
        '${longitude.toStringAsFixed(5)}';
  }

  void dispose() {
    _geocoder.dispose();
  }
}
