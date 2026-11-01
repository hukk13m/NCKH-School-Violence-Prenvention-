/// Helpers for turning raw geocoder payloads and user input into values the
/// picker can use. Kept free of Flutter/widget dependencies so they can be
/// unit tested.
library;

/// Removes the country suffix Nominatim appends, plus duplicate whitespace.
String normalizeDisplayName(String raw) {
  var value = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
  for (final suffix in const [', Việt Nam', ', Vietnam']) {
    if (value.toLowerCase().endsWith(suffix.toLowerCase())) {
      value = value.substring(0, value.length - suffix.length).trim();
    }
  }
  return value;
}

/// Parses user input such as `10.7769, 106.7009` (comma or semicolon).
///
/// Returns `null` when the text is not a pair of valid coordinates.
({double latitude, double longitude})? parseCoordinateInput(String raw) {
  final match = RegExp(
    r'^\s*(-?\d{1,3}(?:[.,]\d+)?)\s*[,;]\s*(-?\d{1,3}(?:[.,]\d+)?)\s*$',
  ).firstMatch(raw);
  if (match == null) return null;

  final lat = double.tryParse(match.group(1)!.replaceAll(',', '.'));
  final lng = double.tryParse(match.group(2)!.replaceAll(',', '.'));
  if (lat == null || lng == null) return null;
  if (lat < -90 || lat > 90 || lng < -180 || lng > 180) return null;
  return (latitude: lat, longitude: lng);
}
