import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'address_format.dart';

@immutable
class GeocodedPlace {
  final String displayName;
  final double latitude;
  final double longitude;

  const GeocodedPlace({
    required this.displayName,
    required this.latitude,
    required this.longitude,
  });
}

/// One row in the address suggestion list.
///
/// [resolved] is filled when the provider already knows the coordinates
/// (Nominatim); Goong needs a second Place Detail call, done by [resolve].
@immutable
class PlaceSuggestion {
  final String id;
  final String primaryText;
  final String secondaryText;
  final String description;
  final GeocodedPlace? resolved;

  const PlaceSuggestion({
    required this.id,
    required this.primaryText,
    required this.secondaryText,
    required this.description,
    this.resolved,
  });

  String get label => description.isNotEmpty
      ? description
      : [primaryText, secondaryText]
            .where((part) => part.trim().isNotEmpty)
            .join(', ');
}

class GeocodingException implements Exception {
  final String message;

  const GeocodingException(this.message);

  @override
  String toString() => message;
}

abstract class GeocodingService {
  Future<List<PlaceSuggestion>> suggest(String query, {int limit = 5});

  Future<GeocodedPlace?> resolve(PlaceSuggestion suggestion);

  Future<GeocodedPlace?> reverse(double latitude, double longitude);

  void dispose();
}

/// Geocoder that calls the Django proxy.
///
/// The proxy keeps the Goong REST key on the server and transparently falls
/// back to Nominatim while `GOONG_API_KEY` is not configured.
class BackendGeocoder implements GeocodingService {
  BackendGeocoder({
    required String baseUrl,
    http.Client? client,
    this.timeout = const Duration(seconds: 10),
  }) : baseUrl = baseUrl.endsWith('/')
           ? baseUrl.substring(0, baseUrl.length - 1)
           : baseUrl,
       _client = client ?? http.Client(),
       _ownsClient = client == null;

  final String baseUrl;
  final Duration timeout;
  final http.Client _client;
  final bool _ownsClient;

  final Map<String, GeocodedPlace?> _reverseCache = {};

  Map<String, String> get _headers => const {
    'Accept': 'application/json',
  };

  Uri _uri(String path, Map<String, String> query) =>
      Uri.parse('$baseUrl$path').replace(queryParameters: query);

  Future<Map<String, dynamic>> _getJson(Uri uri) async {
    final response = await _client
        .get(uri, headers: _headers)
        .timeout(timeout);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw GeocodingException(_messageFrom(response));
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const GeocodingException('Dữ liệu địa chỉ trả về không hợp lệ.');
    }
    return decoded;
  }

  String _messageFrom(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic> && decoded['error'] is String) {
        return decoded['error'] as String;
      }
    } catch (_) {
      // Fall through to the generic message.
    }
    if (response.statusCode == 503) {
      return 'Dịch vụ địa chỉ chưa được cấu hình trên máy chủ.';
    }
    return 'Dịch vụ địa chỉ đang bận (HTTP ${response.statusCode}).';
  }

  @override
  Future<List<PlaceSuggestion>> suggest(String query, {int limit = 5}) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const [];

    final json = await _getJson(
      _uri('/api/places/autocomplete', {
        'input': trimmed,
        'limit': '$limit',
      }),
    );

    final predictions = json['predictions'];
    if (predictions is! List) return const [];

    final suggestions = <PlaceSuggestion>[];
    for (final item in predictions) {
      if (item is! Map<String, dynamic>) continue;

      final description = (item['description'] as String? ?? '').trim();
      final primary = (item['main_text'] as String? ?? '').trim();
      final secondary = (item['secondary_text'] as String? ?? '').trim();
      final latitude = (item['lat'] as num?)?.toDouble();
      final longitude = (item['lng'] as num?)?.toDouble();

      GeocodedPlace? resolved;
      if (latitude != null && longitude != null) {
        resolved = GeocodedPlace(
          displayName: normalizeDisplayName(description),
          latitude: latitude,
          longitude: longitude,
        );
      }

      suggestions.add(
        PlaceSuggestion(
          id: item['place_id'] as String? ?? '',
          primaryText: primary.isEmpty ? description : primary,
          secondaryText: secondary,
          description: description,
          resolved: resolved,
        ),
      );
    }
    return suggestions;
  }

  @override
  Future<GeocodedPlace?> resolve(PlaceSuggestion suggestion) async {
    if (suggestion.resolved != null) return suggestion.resolved;
    if (suggestion.id.isEmpty) return null;

    final json = await _getJson(
      _uri('/api/places/detail', {'place_id': suggestion.id}),
    );

    final result = json['result'];
    if (result is! Map<String, dynamic>) return null;

    final latitude = (result['lat'] as num?)?.toDouble();
    final longitude = (result['lng'] as num?)?.toDouble();
    if (latitude == null || longitude == null) return null;

    final address = (result['formatted_address'] as String? ?? '').trim();
    return GeocodedPlace(
      displayName: normalizeDisplayName(
        address.isEmpty ? suggestion.description : address,
      ),
      latitude: latitude,
      longitude: longitude,
    );
  }

  @override
  Future<GeocodedPlace?> reverse(double latitude, double longitude) {
    final key =
        '${latitude.toStringAsFixed(4)},${longitude.toStringAsFixed(4)}';
    if (_reverseCache.containsKey(key)) {
      return Future<GeocodedPlace?>.value(_reverseCache[key]);
    }

    return _reverseUncached(latitude, longitude, key);
  }

  Future<GeocodedPlace?> _reverseUncached(
    double latitude,
    double longitude,
    String cacheKey,
  ) async {
    final json = await _getJson(
      _uri('/api/places/reverse', {
        'lat': latitude.toString(),
        'lng': longitude.toString(),
      }),
    );

    final result = json['result'];
    GeocodedPlace? place;
    if (result is Map<String, dynamic>) {
      final resultLatitude = (result['lat'] as num?)?.toDouble();
      final resultLongitude = (result['lng'] as num?)?.toDouble();
      final address = (result['formatted_address'] as String? ?? '').trim();
      if (resultLatitude != null &&
          resultLongitude != null &&
          address.isNotEmpty) {
        place = GeocodedPlace(
          displayName: normalizeDisplayName(address),
          latitude: resultLatitude,
          longitude: resultLongitude,
        );
      }
    }

    _reverseCache[cacheKey] = place;
    if (_reverseCache.length > 200) {
      _reverseCache.remove(_reverseCache.keys.first);
    }
    return place;
  }

  @override
  void dispose() {
    if (_ownsClient) _client.close();
  }
}

/// Geocoding backed by Nominatim (OpenStreetMap).
///
/// Kept for tests and for running the picker without the Django backend.
/// Nominatim's usage policy requires one request per second at most and an
/// identifiable client, so requests are serialised and throttled here.
class NominatimGeocoder implements GeocodingService {
  NominatimGeocoder({
    http.Client? client,
    this.userAgent = 'school-violation-detector/1.0',
    this.minimumInterval = const Duration(seconds: 1),
    this.timeout = const Duration(seconds: 8),
  }) : _client = client ?? http.Client(),
       _ownsClient = client == null;

  final http.Client _client;
  final bool _ownsClient;
  final String userAgent;
  final Duration minimumInterval;
  final Duration timeout;

  final Map<String, GeocodedPlace?> _reverseCache = {};
  final Map<String, _SearchCacheEntry> _searchCache = {};

  Future<void> _gate = Future<void>.value();
  DateTime _nextSlot = DateTime.fromMillisecondsSinceEpoch(0);

  Map<String, String> get _headers => {
    'Accept': 'application/json',
    'Accept-Language': 'vi',
    if (!kIsWeb) 'User-Agent': userAgent,
  };

  Future<T> _enqueue<T>(Future<T> Function() action) {
    final completer = Completer<T>();
    _gate = _gate.then((_) async {
      final wait = _nextSlot.difference(DateTime.now());
      if (wait > Duration.zero) {
        await Future<void>.delayed(wait);
      }
      try {
        completer.complete(await action());
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      } finally {
        _nextSlot = DateTime.now().add(minimumInterval);
      }
    });
    return completer.future;
  }

  @override
  Future<GeocodedPlace?> reverse(double latitude, double longitude) {
    final key =
        '${latitude.toStringAsFixed(4)},${longitude.toStringAsFixed(4)}';
    if (_reverseCache.containsKey(key)) {
      return Future<GeocodedPlace?>.value(_reverseCache[key]);
    }

    return _enqueue(() async {
      final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
        'format': 'jsonv2',
        'lat': latitude.toString(),
        'lon': longitude.toString(),
        'zoom': '18',
        'accept-language': 'vi',
      });

      final json = await _getJsonObject(uri);
      final place = _placeFromJson(json);
      _reverseCache[key] = place;
      if (_reverseCache.length > 200) {
        _reverseCache.remove(_reverseCache.keys.first);
      }
      return place;
    });
  }

  @override
  Future<List<PlaceSuggestion>> suggest(String query, {int limit = 5}) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return Future<List<PlaceSuggestion>>.value(const []);
    }

    final cacheKey = '${trimmed.toLowerCase()}|$limit';
    final cached = _searchCache[cacheKey];
    if (cached != null &&
        DateTime.now().difference(cached.fetchedAt) <
            const Duration(minutes: 2)) {
      return Future<List<PlaceSuggestion>>.value(cached.suggestions);
    }

    return _enqueue(() async {
      final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
        'format': 'jsonv2',
        'q': trimmed,
        'limit': '$limit',
        'accept-language': 'vi',
        'countrycodes': 'vn',
      });

      final response = await _client
          .get(uri, headers: _headers)
          .timeout(timeout);
      if (response.statusCode != 200) {
        throw GeocodingException(
          'Dịch vụ địa chỉ đang bận (HTTP ${response.statusCode}). '
          'Vui lòng thử lại sau.',
        );
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! List) {
        throw const GeocodingException('Dữ liệu địa chỉ trả về không hợp lệ.');
      }

      final suggestions = <PlaceSuggestion>[];
      for (final item in decoded) {
        if (item is! Map<String, dynamic>) continue;
        final place = _placeFromJson(item);
        if (place == null) continue;
        suggestions.add(
          PlaceSuggestion(
            id: '',
            primaryText: place.displayName,
            secondaryText: '',
            description: place.displayName,
            resolved: place,
          ),
        );
      }

      _searchCache[cacheKey] = _SearchCacheEntry(
        suggestions,
        DateTime.now(),
      );
      if (_searchCache.length > 50) {
        _searchCache.remove(_searchCache.keys.first);
      }
      return suggestions;
    });
  }

  @override
  Future<GeocodedPlace?> resolve(PlaceSuggestion suggestion) {
    if (suggestion.resolved != null) {
      return Future<GeocodedPlace?>.value(suggestion.resolved);
    }
    return Future<GeocodedPlace?>.value(null);
  }

  Future<Map<String, dynamic>> _getJsonObject(Uri uri) async {
    final response = await _client
        .get(uri, headers: _headers)
        .timeout(timeout);
    if (response.statusCode != 200) {
      throw GeocodingException(
        'Dịch vụ địa chỉ đang bận (HTTP ${response.statusCode}). '
        'Vui lòng thử lại sau.',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const GeocodingException('Dữ liệu địa chỉ trả về không hợp lệ.');
    }
    if (decoded['error'] != null) {
      throw const GeocodingException('Không tìm thấy địa chỉ cho vị trí này.');
    }
    return decoded;
  }

  GeocodedPlace? _placeFromJson(Map<String, dynamic> json) {
    final latitude = double.tryParse('${json['lat']}');
    final longitude = double.tryParse('${json['lon']}');
    final display = json['display_name'];
    if (latitude == null || longitude == null || display is! String) {
      return null;
    }

    final name = normalizeDisplayName(display);
    if (name.isEmpty) return null;

    return GeocodedPlace(
      displayName: name,
      latitude: latitude,
      longitude: longitude,
    );
  }

  @override
  void dispose() {
    if (_ownsClient) _client.close();
  }
}

class _SearchCacheEntry {
  final List<PlaceSuggestion> suggestions;
  final DateTime fetchedAt;

  const _SearchCacheEntry(this.suggestions, this.fetchedAt);
}
