import 'package:flutter/foundation.dart';

/// Ghi đè địa chỉ backend lúc build/run, không cần sửa code:
///
///   flutter run --dart-define=API_BASE=http://192.168.1.10:8000
///   flutter build apk --release --dart-define=API_BASE=http://192.168.1.10:8000
///
/// Giá trị là gốc server, KHÔNG có dấu `/` ở cuối và KHÔNG kèm `/api`.
const String _apiBaseOverride = String.fromEnvironment('API_BASE');

/// Gốc server backend, ví dụ `http://10.0.2.2:8000`.
///
/// Thứ tự ưu tiên:
/// 1. `--dart-define=API_BASE=...` (dùng khi test trên điện thoại thật)
/// 2. web / desktop  -> `localhost` (chạy chung máy với Django)
/// 3. Android        -> `127.0.0.1` (qua `adb reverse tcp:8000 tcp:8000`)
///
/// Với emulator không dùng `adb reverse`, truyền
/// `--dart-define=API_BASE=http://10.0.2.2:8000`.
String resolveApiBaseUrl() {
  if (_apiBaseOverride.isNotEmpty) {
    return _apiBaseOverride.endsWith('/')
        ? _apiBaseOverride.substring(0, _apiBaseOverride.length - 1)
        : _apiBaseOverride;
  }
  if (kIsWeb) {
    return 'http://localhost:8000';
  }
  if (defaultTargetPlatform == TargetPlatform.android) {
    return 'http://127.0.0.1:8000';
  }
  return 'http://localhost:8000';
}

/// Danh sách URL sẽ thử lần lượt cho [path] (bắt đầu bằng `/`).
///
/// Android ưu tiên cổng đã forward qua USB, sau đó mới tới địa chỉ host của
/// emulator. Nhờ vậy điện thoại thật dùng `adb reverse` vẫn chạy mà không cần
/// truyền `API_BASE` mỗi lần.
List<String> apiUrlCandidates(String path) {
  final base = resolveApiBaseUrl();
  return [
    '$base$path',
    if (base.contains('127.0.0.1')) 'http://10.0.2.2:8000$path',
    if (base.contains('127.0.0.1')) 'http://localhost:8000$path',
  ];
}
