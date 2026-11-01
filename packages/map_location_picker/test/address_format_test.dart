import 'package:flutter_test/flutter_test.dart';
import 'package:map_location_picker/map_location_picker.dart';

void main() {
  group('normalizeDisplayName', () {
    test('removes the trailing country and trims whitespace', () {
      expect(
        normalizeDisplayName(
          '  669 Nguyễn Tri Phương, Phường 9, Quận 5, '
          'Thành phố Hồ Chí Minh, Việt Nam  ',
        ),
        '669 Nguyễn Tri Phương, Phường 9, Quận 5, Thành phố Hồ Chí Minh',
      );
    });

    test('keeps the address when there is no country suffix', () {
      expect(
        normalizeDisplayName('12 Lê Lợi, Quận 1'),
        '12 Lê Lợi, Quận 1',
      );
    });

    test('collapses repeated whitespace', () {
      expect(normalizeDisplayName('A   B\nC'), 'A B C');
    });
  });

  group('parseCoordinateInput', () {
    test('parses a comma separated pair', () {
      final result = parseCoordinateInput('10.7769, 106.7009');
      expect(result, isNotNull);
      expect(result!.latitude, closeTo(10.7769, 0.000001));
      expect(result.longitude, closeTo(106.7009, 0.000001));
    });

    test('parses a semicolon separated pair with negatives', () {
      final result = parseCoordinateInput('-33.8688; 151.2093');
      expect(result, isNotNull);
      expect(result!.latitude, closeTo(-33.8688, 0.000001));
      expect(result.longitude, closeTo(151.2093, 0.000001));
    });

    test('rejects out-of-range coordinates', () {
      expect(parseCoordinateInput('91, 106.7'), isNull);
      expect(parseCoordinateInput('10.7, 181'), isNull);
    });

    test('rejects free text', () {
      expect(parseCoordinateInput('12 Lê Lợi, Quận 1'), isNull);
    });
  });
}
