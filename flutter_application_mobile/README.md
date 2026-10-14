# School Violation Detector

Flutter authentication frontend for Student and Teacher roles. It is backend-ready but deliberately fails safely until an API adapter is supplied.

## Run

```powershell
flutter run
```

The default `AUTH_MODE=unavailable` is production-safe: every login, registration, password-reset, Google, and Apple action returns a localized configuration error and never creates a session.

For deterministic UI preview only:

```powershell
flutter run --dart-define=AUTH_MODE=mock
```

Mock credentials are `student@uel.edu.vn` / `Preview@123` and `teacher@uel.edu.vn` / `Preview@123`. The mock adapter is isolated under `lib/features/auth/data/development_mock_auth_service.dart`; remove it from a release build or leave `AUTH_MODE` unset.

## Backend integration contract

Implement an `AuthService` adapter with `AUTH_API_BASE_URL`, then replace the factory's unavailable branch. The complete request/response contract and security rules are in [authentication design](docs/superpowers/specs/2026-09-07-authentication-design.md), covering `POST /v1/auth/login`, registration, forgot/reset password, and Google/Apple OAuth start/callback endpoints.

Never embed OAuth secrets in this application. A backend must validate role entitlement, rate limit auth requests, prevent forgot-password account enumeration, and own token lifecycle/storage policy.

## Checks

```powershell
flutter test
flutter analyze
flutter build windows
```

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
