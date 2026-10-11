import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';
import '../models/user.dart';

class UserService {
  static const String baseUrl = 'http://127.0.0.1:3000';

  Future<List<User>> getUsers() async {
    final url = Uri.parse('$baseUrl/api/users');

    print('GET: $url');

    final headers = await ApiService().getAuthHeaders();
    final response = await http.get(url, headers: headers);

    print('Status code: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      if (decoded is! List) {
        throw Exception(
          'API không trả về danh sách users: ${response.body}',
        );
      }

      return decoded
          .map<User>(
            (json) => User.fromJson(
          Map<String, dynamic>.from(json),
        ),
      )
          .toList();
    }

    throw Exception(
      'API error ${response.statusCode}: ${response.body}',
    );
  }
}