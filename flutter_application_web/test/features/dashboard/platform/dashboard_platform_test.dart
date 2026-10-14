import 'package:flutter_application_web/features/dashboard/platform/dashboard_platform.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'native fallback reports GPS as unavailable instead of claiming success',
    () {
      final platform = createDashboardPlatform();
      String? error;
      var succeeded = false;

      platform.getCurrentLocation(
        (lat, lng) => succeeded = true,
        (message) => error = message,
      );

      expect(succeeded, isFalse);
      expect(error, 'Vui lÃ²ng nháº­p vá»‹ trÃ­ thá»§ cÃ´ng.');
    },
  );

  test('native fallback does not fabricate a camera file', () {
    final platform = createDashboardPlatform();
    var captured = false;

    platform.captureImage((name, size, bytes) => captured = true);

    expect(captured, isFalse);
  });
}
