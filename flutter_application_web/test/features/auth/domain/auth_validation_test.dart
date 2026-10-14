import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_web/features/auth/domain/auth_models.dart';
import 'package:flutter_application_web/features/auth/domain/auth_validation.dart';

void main() {
  group('validateEmail', () {
    test('rejects an email missing its domain suffix', () {
      expect(validateEmail('student@uel'), 'invalidEmail');
    });

    test('accepts a well-formed student email', () {
      expect(validateEmail('student@uel.edu.vn'), isNull);
    });
  });

  group('passwordStrength', () {
    test('rates a mixed long password stronger than a short numeric password', () {
      expect(
        passwordStrength('Truong@2026').index,
        greaterThan(passwordStrength('123').index),
      );
    });

    test('returns weak for an empty password', () {
      expect(passwordStrength(''), PasswordStrength.weak);
    });
  });
}
