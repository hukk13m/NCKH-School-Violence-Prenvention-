class PickedLocation {
  final String? addressText;
  final double? latitude;
  final double? longitude;

  const PickedLocation({this.addressText, this.latitude, this.longitude});

  bool get hasCoordinates => latitude != null && longitude != null;

  String get display {
    if (addressText != null && addressText!.isNotEmpty) return addressText!;
    if (hasCoordinates) {
      return '${latitude!.toStringAsFixed(6)}, ${longitude!.toStringAsFixed(6)}';
    }
    return 'Chưa có vị trí';
  }

  Map<String, dynamic> toJson() => {
    'address_text': addressText,
    'latitude': latitude,
    'longitude': longitude,
  };
}
