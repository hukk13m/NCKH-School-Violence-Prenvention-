import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/dashboard.dart';
import 'api_service.dart';

class DashboardService {
  static const String baseUrl =
      'http://127.0.0.1:3000';

  Future<DashboardData> getDashboard() async {
    final uri = Uri.parse(
      '$baseUrl/api/dashboard',
    );

    print('GET: $uri');
    final headers = await ApiService().getAuthHeaders();
    final response = await http.get(uri, headers: headers);
    print('Status code: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception('Không thể lấy dữ liệu dashboard (HTTP ${response.statusCode})',);
    }

    final json = jsonDecode(response.body);

    return DashboardData.fromJson(json);
  }
}
