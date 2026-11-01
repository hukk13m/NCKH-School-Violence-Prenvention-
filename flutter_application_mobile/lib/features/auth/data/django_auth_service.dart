import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/config/api_config.dart';
import '../domain/auth_models.dart';
import '../domain/auth_service.dart';

String _getDefaultAuthBaseUrl() => '${resolveApiBaseUrl()}/api/users';

class DjangoAuthService implements AuthService {
  DjangoAuthService({String? baseUrl})
    : baseUrl = baseUrl ?? _getDefaultAuthBaseUrl();

  final String baseUrl;

  Future<http.Response> _postJson(String endpoint, Map<String, dynamic> body) async {
    // Chỉ dùng thêm phương án dự phòng khi baseUrl còn là mặc định; nếu nơi
    // gọi tự truyền baseUrl thì tôn trọng đúng giá trị đó.
    final urls = baseUrl == _getDefaultAuthBaseUrl()
        ? apiUrlCandidates('/api/users/$endpoint')
        : <String>['$baseUrl/$endpoint'];

    Object? lastErr;
    for (final url in urls) {
      try {
        final response = await http.post(
          Uri.parse(url),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        ).timeout(const Duration(milliseconds: 2500));
        return response;
      } catch (e) {
        lastErr = e;
      }
    }
    throw lastErr ?? Exception('Không thể kết nối tới Backend Server');
  }

  @override
  Future<AuthSession> login(LoginRequest request) async {
    try {
      final response = await _postJson('login/', {
        'email': request.email,
        'password': request.password,
        'role': request.role.name,
      });

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
      throw AuthException(AuthErrorKind.network, message: 'Lỗi kết nối Server ($e). Đang gọi $baseUrl. Kiểm tra Django đã chạy và địa chỉ API_BASE có đúng không.');
    }
  }

  @override
  Future<RegistrationResult> register(RegisterRequest request) async {
    try {
      final response = await _postJson('register/', {
        'fullName': request.fullName,
        'email': request.email,
        'password': request.password,
        'role': request.role.name,
      });

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
