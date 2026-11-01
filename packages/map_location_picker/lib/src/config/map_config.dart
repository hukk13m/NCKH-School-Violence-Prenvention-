/// Map style configuration.
class MapLocationPickerConfig {
  const MapLocationPickerConfig._();

  static const String goongMapKey = String.fromEnvironment('GOONG_MAP_KEY');

  static bool get usesGoong => goongMapKey.trim().isNotEmpty;

  static String get normalStyle => usesGoong
      ? 'https://tiles.goong.io/assets/goong_map_highlight.json'
            '?api_key=$goongMapKey'
      : fallbackStyle;

  static String get satelliteStyle => usesGoong
      ? 'https://tiles.goong.io/assets/goong_satellite.json'
            '?api_key=$goongMapKey'
      : fallbackStyle;

  /// High-reliability CartoDB Voyager raster style for MapLibre.
  static const String fallbackStyle = r'''{
  "version": 8,
  "sources": {
    "carto": {
      "type": "raster",
      "tiles": [
        "https://basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png"
      ],
      "tileSize": 256,
      "attribution": "© OpenStreetMap, © CARTO"
    }
  },
  "layers": [
    {
      "id": "carto-tiles",
      "type": "raster",
      "source": "carto",
      "minzoom": 0,
      "maxzoom": 20
    }
  ]
}
''';

  /// Backwards-compatible alias for callers that still use the old name.
  static const String osmFallbackStyle = fallbackStyle;
}
