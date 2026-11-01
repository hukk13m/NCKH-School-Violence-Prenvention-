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

  /// Keyless Esri World Street Map raster style for MapLibre.
  /// Does NOT watermark "API KEY REQUIRED" and does NOT return 403.
  static const String fallbackStyle = r'''{
  "version": 8,
  "sources": {
    "esri": {
      "type": "raster",
      "tiles": [
        "https://server.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer/tile/{z}/{y}/{x}"
      ],
      "tileSize": 256,
      "attribution": "Tiles © Esri"
    }
  },
  "layers": [
    {
      "id": "esri-tiles",
      "type": "raster",
      "source": "esri",
      "minzoom": 0,
      "maxzoom": 19
    }
  ]
}
''';

  /// Backwards-compatible alias for callers that still use the old name.
  static const String osmFallbackStyle = fallbackStyle;
}
