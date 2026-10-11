class PickedLocation {
  final String? addressText;
  final double? latitude;
  final double? longitude;

  PickedLocation({this.addressText, this.latitude, this.longitude});

  bool get hasCoordinates => latitude != null && longitude != null;

  /// Chuỗi hiển thị gọn cho UI
  String get display {
    if (addressText != null && addressText!.isNotEmpty) return addressText!;
    if (hasCoordinates) {
      return '${latitude!.toStringAsFixed(5)}, ${longitude!.toStringAsFixed(5)}';
    }
    return 'Chưa có vị trí';
  }
}