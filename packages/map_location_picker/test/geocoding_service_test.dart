import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:map_location_picker/map_location_picker.dart';

http.Response _jsonResponse(Map<String, dynamic> payload, [int status = 200]) {
  return http.Response(
    jsonEncode(payload),
    status,
    headers: const {'content-type': 'application/json; charset=utf-8'},
  );
}

void main() {
  test('Fallback style is a JSON object MapLibre can parse', () {
    // MapLibre checks startsWith('{') on web/iOS, so a leading newline breaks
    // the fallback style before it ever reaches the JSON parser.
    expect(MapLocationPickerConfig.fallbackStyle.startsWith('{'), isTrue);

    final style =
        jsonDecode(MapLocationPickerConfig.fallbackStyle)
            as Map<String, dynamic>;
    expect(style['version'], 8);
    expect(style['sources'], isA<Map<String, dynamic>>());
    expect(style['layers'], isA<List<dynamic>>());

    // OSM blocks embedded app traffic with 403; CARTO watermarks keyless tiles.
    expect(
      MapLocationPickerConfig.fallbackStyle,
      isNot(contains('tile.openstreetmap.org')),
    );
    expect(
      MapLocationPickerConfig.fallbackStyle,
      isNot(contains('basemaps.cartocdn.com')),
    );
    expect(
      MapLocationPickerConfig.fallbackStyle,
      contains('server.arcgisonline.com'),
    );
  });

  test('BackendGeocoder parses Goong autocomplete predictions', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/api/places/autocomplete');
      expect(request.url.queryParameters['input'], 'UEL');
      return _jsonResponse({
        'provider': 'goong',
        'predictions': [
          {
            'place_id': 'place-1',
            'description': 'Đại học Kinh tế - Luật, TP. Hồ Chí Minh',
            'main_text': 'Đại học Kinh tế - Luật',
            'secondary_text': 'TP. Hồ Chí Minh',
          },
        ],
      });
    });

    final geocoder = BackendGeocoder(
      baseUrl: 'http://example.test/',
      client: client,
    );
    addTearDown(geocoder.dispose);

    final results = await geocoder.suggest('UEL');

    expect(results, hasLength(1));
    expect(results.first.id, 'place-1');
    expect(results.first.primaryText, 'Đại học Kinh tế - Luật');
    expect(results.first.resolved, isNull);
  });

  test('BackendGeocoder resolves a Goong place id to coordinates', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/api/places/detail');
      expect(request.url.queryParameters['place_id'], 'place-1');
      return _jsonResponse({
        'result': {
          'lat': 10.761,
          'lng': 106.668,
          'formatted_address': 'Đại học Kinh tế - Luật, Việt Nam',
        },
      });
    });

    final geocoder = BackendGeocoder(
      baseUrl: 'http://example.test',
      client: client,
    );
    addTearDown(geocoder.dispose);

    final place = await geocoder.resolve(
      const PlaceSuggestion(
        id: 'place-1',
        primaryText: 'Đại học Kinh tế - Luật',
        secondaryText: 'TP. Hồ Chí Minh',
        description: 'Đại học Kinh tế - Luật, TP. Hồ Chí Minh',
      ),
    );

    expect(place, isNotNull);
    expect(place!.latitude, 10.761);
    expect(place.longitude, 106.668);
    expect(place.displayName, 'Đại học Kinh tế - Luật');
  });

  test('BackendGeocoder reverse parses the proxy result', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/api/places/reverse');
      expect(request.url.queryParameters['lat'], '10.7769');
      return _jsonResponse({
        'provider': 'nominatim',
        'result': {
          'lat': 10.777,
          'lng': 106.701,
          'formatted_address': 'Chợ Bến Thành, Việt Nam',
        },
      });
    });

    final geocoder = BackendGeocoder(
      baseUrl: 'http://example.test',
      client: client,
    );
    addTearDown(geocoder.dispose);

    final place = await geocoder.reverse(10.7769, 106.7009);

    expect(place, isNotNull);
    expect(place!.displayName, 'Chợ Bến Thành');
    expect(place.latitude, 10.777);
    expect(place.longitude, 106.701);
  });

  test('BackendGeocoder surfaces proxy error messages', () async {
    final client = MockClient(
      (_) async => _jsonResponse({
        'error': 'Goong chưa được cấu hình trên máy chủ.',
      }, 503),
    );

    final geocoder = BackendGeocoder(
      baseUrl: 'http://example.test',
      client: client,
    );
    addTearDown(geocoder.dispose);

    expect(
      () => geocoder.suggest('UEL'),
      throwsA(
        isA<GeocodingException>().having(
          (error) => error.message,
          'message',
          'Goong chưa được cấu hình trên máy chủ.',
        ),
      ),
    );
  });
}
