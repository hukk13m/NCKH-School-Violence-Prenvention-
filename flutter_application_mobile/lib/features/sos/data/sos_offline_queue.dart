import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../dashboard/data/case_service.dart';

/// Một báo cáo SOS được lưu lại khi thiết bị mất kết nối.
class QueuedSosReport {
  const QueuedSosReport({
    required this.id,
    required this.description,
    required this.location,
    required this.reportType,
    required this.priority,
    required this.userId,
    required this.createdAt,
    this.latitude,
    this.longitude,
  });

  final String id;
  final String description;
  final String location;
  final String reportType;
  final String priority;
  final String? userId;
  final DateTime createdAt;
  final double? latitude;
  final double? longitude;

  Map<String, dynamic> toJson() => {
    'id': id,
    'description': description,
    'location': location,
    'report_type': reportType,
    'priority': priority,
    'user_id': userId,
    'created_at': createdAt.toIso8601String(),
    'latitude': latitude,
    'longitude': longitude,
  };

  factory QueuedSosReport.fromJson(Map<String, dynamic> json) {
    return QueuedSosReport(
      id: json['id'] as String? ?? '',
      description: json['description'] as String? ?? '',
      location: json['location'] as String? ?? '',
      reportType: json['report_type'] as String? ?? 'SOS',
      priority: json['priority'] as String? ?? 'High',
      userId: json['user_id'] as String?,
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }
}

/// Hàng đợi báo cáo SOS ngoại tuyến.
///
/// Dữ liệu được giữ trong SharedPreferences để sống sót qua các lần khởi động
/// lại ứng dụng mà không cần thêm cơ sở dữ liệu cục bộ.
class SosOfflineQueue {
  static const _queueKey = 'sos_offline_queue_v1';
  static const _maxItems = 30;

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  Future<List<QueuedSosReport>> read() async {
    final prefs = await _prefs;
    final raw = prefs.getStringList(_queueKey) ?? const [];
    final result = <QueuedSosReport>[];
    for (final item in raw) {
      try {
        final decoded = jsonDecode(item);
        if (decoded is Map<String, dynamic>) {
          result.add(QueuedSosReport.fromJson(decoded));
        }
      } catch (_) {
        // Bỏ qua bản ghi hỏng, không làm mất các báo cáo còn lại.
      }
    }
    return result;
  }

  Future<void> add(QueuedSosReport report) async {
    final prefs = await _prefs;
    final raw = prefs.getStringList(_queueKey) ?? <String>[];
    raw.add(jsonEncode(report.toJson()));
    final trimmed = raw.length > _maxItems
        ? raw.sublist(raw.length - _maxItems)
        : raw;
    await prefs.setStringList(_queueKey, trimmed);
  }

  Future<void> clear() async {
    final prefs = await _prefs;
    await prefs.remove(_queueKey);
  }

  /// Gửi lại toàn bộ hàng đợi và trả về số báo cáo đã gửi thành công.
  Future<int> flush(CaseService caseService) async {
    final items = await read();
    if (items.isEmpty) return 0;

    final sentIds = <String>{};
    for (final item in items) {
      try {
        await caseService.submitReport(
          description: item.description,
          location: item.location,
          reportType: item.reportType,
          priority: item.priority,
          userId: item.userId,
          latitude: item.latitude,
          longitude: item.longitude,
        );
        sentIds.add(item.id);
      } catch (_) {
        // Giữ lại báo cáo này để lần sau thử tiếp.
      }
    }

    if (sentIds.isNotEmpty) {
      final prefs = await _prefs;
      final remaining = items
          .where((item) => !sentIds.contains(item.id))
          .map((item) => jsonEncode(item.toJson()))
          .toList();
      await prefs.setStringList(_queueKey, remaining);
    }
    return sentIds.length;
  }
}
