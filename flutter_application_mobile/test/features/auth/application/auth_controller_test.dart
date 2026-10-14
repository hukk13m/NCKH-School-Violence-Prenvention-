import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_mobile/features/auth/application/auth_controller.dart';
import 'package:flutter_application_mobile/features/auth/data/unavailable_auth_service.dart';
import 'package:flutter_application_mobile/features/auth/domain/auth_models.dart';

void main() {
  test('controller surfaces a configuration error instead of a session', () async {
    final controller = AuthController(const UnavailableAuthService());
    final result = await controller.login(
      const LoginRequest(
        email: 'student@uel.edu.vn',
        password: 'Preview@123',
        role: AuthRole.student,
      ),
    );

    expect(result.session, isNull);
    expect(result.error?.kind, AuthErrorKind.configuration);
  });
}
