/// Map style configuration.
///
/// Set the Goong map key at build/run time:
///
///   flutter run -d chrome --dart-define=GOONG_MAP_KEY=<map-key>
///
/// When the key is empty the picker uses a keyless Esri World Street Map
/// fallback so the app keeps working while the Goong account/key is being
/// created. The public `tile.openstreetmap.org` endpoint blocks embedded app
/// usage with HTTP 403, and CARTO now watermarks keyless tiles with
/// "API KEY REQUIRED", so neither is suitable as the fallback.
class MapLocationPickerConfig {
  const MapLocationPickerConfig._();

  static const String goongMapKey = String.fromEnvironment(
    'GOONG_MAP_KEY',
    defaultValue: 'WM0rSDLabCExKus2u3TC0eqsI5yr0YDcc7nB3Y0G',
  );

  static bool get usesGoong => goongMapKey.trim().isNotEmpty;

  static String get normalStyle => usesGoong
      ? 'https://tiles.goong.io/assets/goong_map_web.json'
            '?api_key=$goongMapKey'
      : fallbackStyle;

  static String get satelliteStyle => usesGoong
      ? 'https://tiles.goong.io/assets/goong_satellite.json'
            '?api_key=$goongMapKey'
      : fallbackStyle;

  /// Minimal MapLibre raster style used until a Goong map key is configured.
  ///
  /// Esri's World Street Map is used instead of the public OSM tile server
  /// (403 "Access blocked") and CARTO's keyless tiles ("API KEY REQUIRED").
  static const String fallbackStyle = r'''{
  "version": 8,
  "name": "Esri Street fallback",
  "sources": {
    "esri": {
      "type": "raster",
      "tiles": ["https://server.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer/tile/{z}/{y}/{x}"],
      "tileSize": 256,
      "attribution": "Tiles © Esri"
    }
  },
  "layers": [
    { "id": "esri", "type": "raster", "source": "esri" }
  ]
}
''';

  /// Backwards-compatible alias for callers that still use the old name.
  static const String osmFallbackStyle = fallbackStyle;
}
