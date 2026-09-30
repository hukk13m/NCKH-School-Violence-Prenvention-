import 'dart:convert';
import 'package:http/http.dart' as http;
import '../domain/auth_models.dart';
import '../domain/auth_service.dart';

class DjangoAuthService implements AuthService {
  DjangoAuthService({String? baseUrl})
    : baseUrl = baseUrl ?? 'http://localhost:8000/api/users';

  final String baseUrl;

  @override
  Future<AuthSession> login(LoginRequest request) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': request.email,
          'password': request.password,
          'role': request.role.name,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return AuthSession(
          userId: data['userId'] as String? ?? '1',
          fullName: data['fullName'] as String? ?? 'User',
          email: data['email'] as String? ?? request.email,
          role: (data['role'] == 'teacher')
              ? AuthRole.teacher
              : AuthRole.student,
          accessToken: data['accessToken'] as String?,
          refreshToken: data['refreshToken'] as String?,
        );
      } else {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final errorMsg = data['error'] as String? ?? 'Login failed';
        throw AuthException(
          AuthErrorKind.invalidCredentials,
          message: errorMsg,
        );
      }
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException(AuthErrorKind.network, message: e.toString());
    }
  }

  @override
  Future<RegistrationResult> register(RegisterRequest request) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'fullName': request.fullName,
          'email': request.email,
          'password': request.password,
          'role': request.role.name,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return RegistrationResult(
          userId: data['userId'] as String? ?? '1',
          requiresEmailVerification: false,
        );
      } else {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final errorMsg = data['error'] as String? ?? 'Registration failed';
        throw AuthException(AuthErrorKind.validation, message: errorMsg);
      }
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException(AuthErrorKind.network, message: e.toString());
    }
  }

  @override
  Future<void> requestPasswordReset({
    required String email,
    required AppLocale locale,
  }) async {}

  @override
  Future<void> resetPassword(ResetPasswordRequest request) async {}

  @override
  Future<AuthSession> signInWithGoogle(AuthRole role) async {
    throw const AuthException(
      AuthErrorKind.provider,
      message: 'Google sign in not supported',
    );
  }

  @override
  Future<AuthSession> signInWithApple(AuthRole role) async {
    throw const AuthException(
      AuthErrorKind.provider,
      message: 'Apple sign in not supported',
    );
  }
}
