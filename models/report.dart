class IncidentReport {
  final String id;
  final String incidentType;
  final String location;
  final double? latitude;
  final double? longitude;
  final String description;
  final bool anonymous;
  String status;

  IncidentReport({
    required this.id,
    required this.incidentType,
    required this.location,
    this.latitude,
    this.longitude,
    required this.description,
    required this.anonymous,
    this.status = "Under Review",
  });
}