import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart';

class ApiService {
  static const String baseUrl = "http://127.0.0.1:3000";
  final storage = const FlutterSecureStorage();

  Future<Map<String, String>> getAuthHeaders() async {
    final token = await storage.read(key: 'jwt_token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<bool> register({
    required String username,
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'email': email,
          'password': password,
          'first_name': firstName,
          'last_name': lastName,
        }),
      );
      return response.statusCode == 201;
    } catch (e) {
      print("Lỗi kết nối: $e");
      return false;
    }
  }

  /// ✅ Trả về User? thay vì bool
  Future<User?> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body);
      final token = data['token'];
      if (token == null) return null;

      await storage.write(key: 'jwt_token', value: token);

      if (data['user'] != null) {
        final user = User.fromJson(Map<String, dynamic>.from(data['user']));
        await storage.write(key: 'cached_user', value: jsonEncode(user.toJson()));
        return user;
      }
      return await getMe();
    } catch (e) {
      print("Lỗi kết nối: $e");
      return null;
    }
  }

  Future<User?> getMe() async {
    try {
      final headers = await getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/me'),
        headers: headers,
      );
      if (response.statusCode != 200) return null;

      final user = User.fromJson(jsonDecode(response.body));
      await storage.write(key: 'cached_user', value: jsonEncode(user.toJson()));
      return user;
    } catch (e) {
      print("getMe error: $e");
      return null;
    }
  }

  Future<User?> getCachedUser() async {
    final raw = await storage.read(key: 'cached_user');
    if (raw == null) return null;
    try {
      return User.fromJson(jsonDecode(raw));
    } catch (_) {
      return null;
    }
  }

  Future<bool> isLoggedIn() async {
    final token = await storage.read(key: 'jwt_token');
    return token != null;
  }

  Future<void> logout() async {
    await storage.delete(key: 'jwt_token');
    await storage.delete(key: 'cached_user');
  }
}