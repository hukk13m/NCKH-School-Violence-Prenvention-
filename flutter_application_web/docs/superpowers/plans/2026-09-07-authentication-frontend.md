# Authentication Frontend Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a secure-by-default, responsive student and teacher authentication frontend and backend-ready contract for School Violation Detector.

**Architecture:** Feature-first Flutter auth module with presentational widgets consuming a controller and an `AuthService` interface. The default service fails safely until a backend adapter is configured; an isolated `AUTH_MODE=mock` service supports previews only.

**Tech Stack:** Flutter Material 3, Dart, flutter_test; no new runtime package in this frontend-only phase.

**Spec:** `docs/superpowers/specs/2026-09-07-authentication-design.md`

## Global Constraints

- Keep production default `AUTH_MODE=unavailable`; never return a fabricated session from it.
- Do not hard-code credentials, OAuth secrets, remote visual URLs, or plaintext-token persistence.
- Use Vietnamese and English catalog keys for all visible auth copy.
- Maintain 44 px touch targets, semantics, visible focus, and reduced-motion behavior.
- Use `LayoutBuilder` for desktop/tablet/mobile auth layout.

---

### Task 1: Auth domain types and validation

**Files:**
- Create: `lib/features/auth/domain/auth_models.dart`
- Create: `lib/features/auth/domain/auth_service.dart`
- Create: `lib/features/auth/domain/auth_validation.dart`
- Test: `test/features/auth/domain/auth_validation_test.dart`

**Interfaces:**
- Produces `AuthRole`, `AuthSession`, request/result classes, `AuthException`, `AuthService`, `validateEmail`, `validatePassword`, `passwordStrength`.

- [ ] **Step 1: Write failing validation tests**

```dart
test('rejects an invalid email', () {
  expect(validateEmail('student@'), isNotNull);
});
test('rates an eight-character mixed password as stronger than a short password', () {
  expect(passwordStrength('Truong@2026').index, greaterThan(passwordStrength('123').index));
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/auth/domain/auth_validation_test.dart`
Expected: FAIL because domain library does not exist.

- [ ] **Step 3: Add minimum domain implementation**

```dart
String? validateEmail(String value) => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value.trim()) ? null : 'invalidEmail';
```

Define typed request classes and an abstract `AuthService` exactly as the design spec.

- [ ] **Step 4: Re-run focused test**

Run: `flutter test test/features/auth/domain/auth_validation_test.dart`
Expected: PASS.

### Task 2: Safe service adapters and controller

**Files:**
- Create: `lib/features/auth/data/unavailable_auth_service.dart`
- Create: `lib/features/auth/data/development_mock_auth_service.dart`
- Create: `lib/features/auth/data/auth_service_factory.dart`
- Create: `lib/features/auth/application/auth_controller.dart`
- Test: `test/features/auth/data/auth_service_factory_test.dart`
- Test: `test/features/auth/application/auth_controller_test.dart`

**Interfaces:**
- Consumes `AuthService` and domain requests from Task 1.
- Produces `AuthController.submitLogin`, `submitRegister`, `requestReset`, `resetPassword`, and social methods with loading/error states.

- [ ] **Step 1: Write a failing safe-default test**

```dart
test('unavailable mode never creates a session', () async {
  final service = AuthServiceFactory(mode: 'unavailable').create();
  expect(() => service.login(const LoginRequest(email: 'a@b.com', password: 'Pass@123', role: AuthRole.student)), throwsA(isA<AuthException>()));
});
```

- [ ] **Step 2: Run focused test and observe expected failure**

Run: `flutter test test/features/auth/data/auth_service_factory_test.dart`
Expected: FAIL because factory is absent.

- [ ] **Step 3: Implement safe adapters**

`UnavailableAuthService` throws `AuthException.configuration` from every method. The mock adapter only returns deterministic sessions for documented preview credentials and is selected only by `const String.fromEnvironment('AUTH_MODE', defaultValue: 'unavailable')`.

- [ ] **Step 4: Re-run adapter and controller tests**

Run: `flutter test test/features/auth/data/auth_service_factory_test.dart test/features/auth/application/auth_controller_test.dart`
Expected: PASS.

### Task 3: Localization, theme, reusable controls

**Files:**
- Create: `lib/features/auth/presentation/auth_strings.dart`
- Create: `lib/features/auth/presentation/auth_theme.dart`
- Create: `lib/features/auth/presentation/widgets/password_field.dart`
- Create: `lib/features/auth/presentation/widgets/language_switcher.dart`
- Create: `lib/features/auth/presentation/widgets/password_strength_meter.dart`
- Test: `test/features/auth/presentation/auth_strings_test.dart`
- Test: `test/features/auth/presentation/widgets/password_field_test.dart`

**Interfaces:**
- Produces `AuthStrings`, `AppLocale`, `AuthTheme`, `PasswordField`, `LanguageSwitcher`, `PasswordStrengthMeter`.

- [ ] **Step 1: Write failing locale and visibility tests**

```dart
testWidgets('language switcher exposes English copy', (tester) async {
  await tester.pumpWidget(testApp(const LanguageSwitcher(locale: AppLocale.vi)));
  expect(find.text('English'), findsOneWidget);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/auth/presentation`
Expected: FAIL because widgets do not exist.

- [ ] **Step 3: Implement reusable controls**

Give icon-only controls semantic labels and tooltips, use `TextFormField`, and expose strength by text and color.

- [ ] **Step 4: Re-run presentation-control tests**

Run: `flutter test test/features/auth/presentation`
Expected: PASS.

### Task 4: Auth forms and feedback

**Files:**
- Create: `lib/features/auth/presentation/widgets/login_form.dart`
- Create: `lib/features/auth/presentation/widgets/register_form.dart`
- Create: `lib/features/auth/presentation/widgets/forgot_password_form.dart`
- Create: `lib/features/auth/presentation/widgets/reset_password_form.dart`
- Create: `lib/features/auth/presentation/widgets/social_login_buttons.dart`
- Create: `lib/features/auth/presentation/widgets/auth_notification.dart`
- Test: `test/features/auth/presentation/widgets/login_form_test.dart`
- Test: `test/features/auth/presentation/widgets/register_form_test.dart`

**Interfaces:**
- Consumes controller, reusable controls, locale strings.
- Produces validated, loading-safe submit interactions.

- [ ] **Step 1: Write failing login validation test**

```dart
testWidgets('login keeps request from submitting invalid email', (tester) async {
  await tester.pumpWidget(testApp(LoginForm(controller: fakeController)));
  await tester.tap(find.text('Login'));
  await tester.pump();
  expect(find.textContaining('email'), findsWidgets);
});
```

- [ ] **Step 2: Run focused tests and verify failure**

Run: `flutter test test/features/auth/presentation/widgets/login_form_test.dart`
Expected: FAIL because `LoginForm` is absent.

- [ ] **Step 3: Implement forms**

Use `Form` validation, disable submits while controller state is loading, and show only controller-confirmed success messages. Forgot-password confirmation must use non-enumerating copy.

- [ ] **Step 4: Re-run form tests**

Run: `flutter test test/features/auth/presentation/widgets/login_form_test.dart test/features/auth/presentation/widgets/register_form_test.dart`
Expected: PASS.

### Task 5: Responsive animated shell and role-based routes

**Files:**
- Create: `lib/features/auth/presentation/auth_screen.dart`
- Create: `lib/features/auth/presentation/widgets/auth_visual_panel.dart`
- Create: `lib/features/auth/presentation/widgets/role_switcher.dart`
- Create: `lib/features/auth/presentation/widgets/auth_panel.dart`
- Modify: `lib/main.dart`
- Test: `test/features/auth/presentation/auth_screen_test.dart`

**Interfaces:**
- Consumes all previous auth components.
- Produces `/auth`, `/student/home`, `/teacher/dashboard` named routing and responsive animated role transformation.

- [ ] **Step 1: Write failing role-switch test**

```dart
testWidgets('teacher switch reverses the desktop auth layout', (tester) async {
  await tester.pumpWidget(const MyApp());
  await tester.tap(find.textContaining('Teacher'));
  await tester.pump(const Duration(milliseconds: 600));
  expect(find.text('Teacher portal'), findsOneWidget);
});
```

- [ ] **Step 2: Run focused test and verify failure**

Run: `flutter test test/features/auth/presentation/auth_screen_test.dart`
Expected: FAIL because the auth app is absent.

- [ ] **Step 3: Implement auth shell and routes**

Use `LayoutBuilder`; switch ordering and alignment without duplicating forms. Respect `MediaQuery.disableAnimationsOf(context)`. Use a replaceable vector campus visual composed from Material shapes/icons.

- [ ] **Step 4: Re-run screen test**

Run: `flutter test test/features/auth/presentation/auth_screen_test.dart`
Expected: PASS.

### Task 6: Documentation and full verification

**Files:**
- Modify: `README.md`
- Modify: `docs/superpowers/specs/2026-09-07-authentication-design.md`

- [ ] **Step 1: Document preview configuration and exact backend API contract**

Add commands:

```powershell
flutter run
flutter run --dart-define=AUTH_MODE=mock
flutter test
flutter analyze
```

Document mock credentials and every endpoint in the specification.

- [ ] **Step 2: Run all tests**

Run: `flutter test`
Expected: PASS with zero failures.

- [ ] **Step 3: Run static analysis**

Run: `flutter analyze`
Expected: `No issues found!`.

- [ ] **Step 4: Run a platform build**

Run: `flutter build windows`
Expected: successful Windows executable build.

- [ ] **Step 5: Review against spec**

Confirm every design requirement maps to Tasks 1-6 and report OAuth/backend configuration gaps without claiming provider authentication works.
