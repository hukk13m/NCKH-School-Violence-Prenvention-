# School Violation Detector Authentication Design

## Goal

Replace the starter counter with a responsive, accessible Flutter authentication experience for students and teachers. The UI must be ready for a real backend without pretending that unauthorised or unconfigured providers have authenticated a user.

## Current context

The repository is a newly created Flutter application: `lib/main.dart` is the standard counter sample, `pubspec.yaml` has only Flutter and Cupertino icons, and there are no assets, routes, authentication utilities, APIs, environment configuration, or backend models. No authentic UEL visual asset exists, so the UI will use a deliberately replaceable, code-native campus illustration component rather than a remote image.

## Architecture

Use a feature-first `lib/features/auth` module. Presentation widgets depend on an `AuthController`, which depends only on the `AuthService` interface. `UnavailableAuthService` is the production default until an API implementation is configured; every request returns an explicit configuration error and never yields a false success. `DevelopmentMockAuthService`, which is only selected with `--dart-define=AUTH_MODE=mock`, supports deterministic preview data and is never the default.

`AuthSession` carries a verified backend identity and role. The root app maps an authenticated student to `/student/home` and teacher to `/teacher/dashboard`; unauthenticated users remain at `/auth`. Routes are local named routes for now, keeping a small seam for a router package later.

## Models and service contract

```dart
enum AuthRole { student, teacher }
enum AppLocale { vi, en }

class LoginRequest {
  const LoginRequest({required this.email, required this.password, required this.role, this.rememberMe = false});
  final String email;
  final String password;
  final AuthRole role;
  final bool rememberMe;
}

class RegisterRequest {
  const RegisterRequest({required this.fullName, required this.email, required this.password, required this.role, required this.acceptTerms});
  final String fullName;
  final String email;
  final String password;
  final AuthRole role;
  final bool acceptTerms;
}

abstract interface class AuthService {
  Future<AuthSession> login(LoginRequest request);
  Future<RegistrationResult> register(RegisterRequest request);
  Future<void> requestPasswordReset({required String email, required AppLocale locale});
  Future<void> resetPassword(ResetPasswordRequest request);
  Future<AuthSession> signInWithGoogle(AuthRole role);
  Future<AuthSession> signInWithApple(AuthRole role);
}
```

`AuthException` has safe user-facing categories: `configuration`, `network`, `invalidCredentials`, `validation`, `provider`, and `unknown`. UI messages are localized centrally. No passwords, tokens, or raw provider errors are logged or presented.

### Non-negotiable implementation boundary

`AUTH_MODE=unavailable` is the production default and every authentication operation must resolve as `AuthException(AuthErrorKind.configuration)`: login, registration, forgot/reset password, Google OAuth, and Apple OAuth. It must never create an `AuthSession`, emit a success notification, or navigate to a role route. `AUTH_MODE=mock` is the sole source of deterministic successful sessions during UI development.

## UX and state

The auth screen owns transient form state, visibility toggles, request loading state, selected role, selected locale, and the selected form mode (`login`, `register`, `forgotPassword`, `resetPassword`). Switching roles maintains fields when practical and reverses the desktop split view via `AnimatedSwitcher`/`AnimatedAlign` over 550 ms with `Curves.easeInOutCubic`. If `MediaQuery.disableAnimationsOf(context)` is true it uses a short fade only.

At desktop widths (>= 900 logical px), the auth panel occupies 42% and the visual panel 58%; Student is auth-left/image-right and Teacher is the reverse. Below 900 px the panel compresses; below 640 px it stacks a compact visual banner above the form. `LayoutBuilder`, scroll containment, touch targets at least 44 px, visible focus, semantic labels and live-region error/success messaging are required.

All copy is sourced from an in-memory Vietnamese/English string catalog. The language control is always at the top right. It is intentionally not persisted yet because the project has no storage dependency; the API does receive locale for password-reset messages.

## Forms

- Login: email, password visibility button, remember-me, forgot-password link, disabled/loading submission, inline validation, Google and Apple provider actions.
- Register: name, email, password, confirmation, terms checkbox and strength meter. The current role is submitted as a request field, but backend authorization remains the authority for teacher registration.
- Forgot password: email, safe generic success confirmation, back-to-login action.
- Reset password: token plus new and confirmation passwords. A direct deep-link parser is deferred because no routing/link format exists; the page accepts a token constructor parameter ready for routing integration.

Success notifications only appear after `AuthService` resolves a request. The production unavailable adapter therefore shows a configuration notification, not success. Provider buttons show a provider/configuration error until provider OAuth is configured.

## Backend API specification

All endpoints use JSON over HTTPS, send `Accept-Language: vi|en`, return `{ "error": { "code": "...", "message": "safe message" } }` on failure, and never reveal account existence for password reset.

| Operation | Endpoint | Request | Success |
|---|---|---|---|
| Login | `POST /v1/auth/login` | `email`, `password`, `role`, `rememberMe` | `accessToken`, optional `refreshToken`, `user:{id,fullName,email,role}` |
| Register | `POST /v1/auth/register` | `fullName`, `email`, `password`, `role`, `acceptTerms` | `user:{id,fullName,email,role}`, `requiresEmailVerification` |
| Forgot password | `POST /v1/auth/password/forgot` | `email`, `locale` | `202` and `{accepted:true}` for every valid-shaped email |
| Reset password | `POST /v1/auth/password/reset` | `token`, `newPassword` | `204` or `{changed:true}` |
| Google start | `POST /v1/auth/oauth/google/start` | `role`, `redirectUri` | `{authorizationUrl,state}` |
| Google callback | `POST /v1/auth/oauth/google/callback` | `code`, `state`, `role` | same session payload as login |
| Apple start | `POST /v1/auth/oauth/apple/start` | `role`, `redirectUri` | `{authorizationUrl,state,nonce}` |
| Apple callback | `POST /v1/auth/oauth/apple/callback` | `code`, `state`, `idToken`, `nonce`, `role` | same session payload as login |

Backend must validate role eligibility, hash passwords with a modern password hashing algorithm, rotate/revoke refresh tokens if issued, validate OAuth state/nonce/PKCE where appropriate, rate-limit authentication endpoints, and return stable error codes. The client must store resulting credentials only through a future secure-token implementation; tokens are intentionally not persisted in this frontend phase.

## Configuration

- `AUTH_MODE=unavailable` is the default and safe production behavior.
- `AUTH_MODE=mock` enables development preview credentials only; mock data is isolated from production adapter selection.
- Future API adapter configuration: `AUTH_API_BASE_URL`, `GOOGLE_OAUTH_REDIRECT_URI`, `APPLE_OAUTH_REDIRECT_URI`. These values are build-time configuration only; no secrets belong in the app.

## Testing

Widget and unit tests cover string catalog selection, validation, strength calculation, adapter selection, no-false-success unavailable flow, role animation/state, language switching, and form navigation. Run `flutter test`, `flutter analyze`, and a platform build after implementation.
