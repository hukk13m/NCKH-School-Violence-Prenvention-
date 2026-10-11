import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';

class ReportService {
  static const String baseUrl = 'http://127.0.0.1:3000';
  final ApiService _api = ApiService();

  Future<bool> createReport({
    required String incidentType,
    required String description,
    required bool anonymous,
    String? locationText,
    double? latitude,
    double? longitude,
    String? addressText,
  }) async {
    try {
      final headers = await _api.getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/api/incidents'),
        headers: headers,
        body: jsonEncode({
          'incident_type': incidentType,
          'description': description,
          'anonymous': anonymous,
          'location_text': locationText,
          'latitude': latitude,
          'longitude': longitude,
          'address_text': addressText,
        }),
      );
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      print('createReport error: $e');
      return false;
    }
  }
}