import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_8/features/auth/data/auth_service_factory.dart';
import 'package:flutter_application_8/features/auth/domain/auth_models.dart';

void main() {
  test('unavailable mode never creates a session', () async {
    final service = AuthServiceFactory(mode: 'unavailable').create();

    expect(
      service.login(
        const LoginRequest(
          email: 'student@uel.edu.vn',
          password: 'Password@123',
          role: AuthRole.student,
        ),
      ),
      throwsA(
        isA<AuthException>().having(
          (error) => error.kind,
          'kind',
          AuthErrorKind.configuration,
        ),
      ),
    );
  });

  test('mock mode creates a deterministic session only for preview credentials', () async {
    final service = AuthServiceFactory(mode: 'mock').create();

    final session = await service.login(
      const LoginRequest(
        email: 'student@uel.edu.vn',
        password: 'Preview@123',
        role: AuthRole.student,
      ),
    );

    expect(session.role, AuthRole.student);
    expect(session.email, 'student@uel.edu.vn');
  });

  test('unavailable mode rejects OAuth and password reset flows', () async {
    final service = AuthServiceFactory(mode: 'unavailable').create();
    final configurationError = isA<AuthException>().having(
      (error) => error.kind,
      'kind',
      AuthErrorKind.configuration,
    );

    await expectLater(service.signInWithGoogle(AuthRole.student), throwsA(configurationError));
    await expectLater(service.signInWithApple(AuthRole.teacher), throwsA(configurationError));
    await expectLater(
      service.requestPasswordReset(email: 'student@uel.edu.vn', locale: AppLocale.en),
      throwsA(configurationError),
    );
  });
}
