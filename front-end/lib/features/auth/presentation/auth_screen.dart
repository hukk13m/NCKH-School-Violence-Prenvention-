import 'package:flutter/material.dart';

import '../application/auth_controller.dart';
import '../data/auth_service_factory.dart';
import '../domain/auth_models.dart';
import '../domain/auth_validation.dart';
import '../../dashboard/presentation/web_utils/web_utils.dart';
import '../../../core/localization/app_language.dart';
import 'auth_strings.dart';

enum AuthFormMode { login, register, forgot, reset }

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _key = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirm = TextEditingController();
  final _name = TextEditingController();
  final _token = TextEditingController();
  late final AuthController _auth;
  AuthRole _role = AuthRole.student;
  AppLocale _locale = AppLocale.vi;
  AuthFormMode _mode = AuthFormMode.login;
  bool _busy = false,
      _visible = false,
      _visibleConfirm = false,
      _remember = false,
      _terms = false;

  @override
  void initState() {
    super.initState();
    _locale = AppLanguage.instance.currentLocale;
    AppLanguage.instance.localeNotifier.addListener(_onLocaleChanged);
    _auth = AuthController(const AuthServiceFactory().create());
  }

  void _onLocaleChanged() {
    if (mounted) setState(() => _locale = AppLanguage.instance.currentLocale);
  }

  @override
  void dispose() {
    AppLanguage.instance.localeNotifier.removeListener(_onLocaleChanged);
    for (final c in [_email, _passwordController, _confirm, _name, _token]) {
      c.dispose();
    }
    super.dispose();
  }

  AuthStrings get s => AuthStrings(_locale);
  String? _text(String? error) => switch (error) {
    'required' => s.required,
    'invalidEmail' => s.invalidEmail,
    'passwordTooShort' => s.shortPassword,
    'passwordMismatch' => s.mismatch,
    _ => null,
  };
  String _failure(AuthException e) =>
      e.message ??
      switch (e.kind) {
        AuthErrorKind.configuration => s.configuration,
        AuthErrorKind.invalidCredentials => s.invalidCredentials,
        AuthErrorKind.provider => s.providerError,
        _ => s.genericError,
      };
  void _toast(String text, bool success) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: success
              ? const Color(0xff08765a)
              : const Color(0xffb42318),
          content: Semantics(liveRegion: true, child: Text(text)),
        ),
      );
  void _switchMode(AuthFormMode mode) => setState(() {
    _mode = mode;
    _key.currentState?.reset();
  });

  Future<void> _submit() async {
    if (!_key.currentState!.validate() ||
        (_mode == AuthFormMode.register && !_terms)) {
      if (_mode == AuthFormMode.register && !_terms) _toast(s.agree, false);
      return;
    }
    setState(() => _busy = true);
    AuthActionResult r;
    if (_mode == AuthFormMode.login) {
      r = await _auth.login(
        LoginRequest(
          email: _email.text.trim(),
          password: _passwordController.text,
          role: _role,
          rememberMe: _remember,
        ),
      );
    } else if (_mode == AuthFormMode.register)
      r = await _auth.register(
        RegisterRequest(
          fullName: _name.text.trim(),
          email: _email.text.trim(),
          password: _passwordController.text,
          role: _role,
          acceptTerms: _terms,
        ),
      );
    else if (_mode == AuthFormMode.forgot)
      r = await _auth.forgotPassword(_email.text.trim(), _locale);
    else
      r = await _auth.resetPassword(
        ResetPasswordRequest(
          token: _token.text.trim(),
          newPassword: _passwordController.text,
        ),
      );
    if (!mounted) return;
    setState(() => _busy = false);
    if (r.session != null) {
      final targetRoute = switch (r.session!.role) {
        AuthRole.admin => '/admin/dashboard',
        AuthRole.teacher => '/teacher/dashboard',
        AuthRole.student => '/student/home',
      };
      Navigator.of(context).pushReplacementNamed(
        targetRoute,
        arguments: r.session,
      );
      return;
    }
    _toast(
      r.isSuccess
          ? (_mode == AuthFormMode.register
                ? s.registrationSuccess
                : _mode == AuthFormMode.forgot
                ? s.resetSent
                : s.passwordChanged)
          : _failure(r.error!),
      r.isSuccess,
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F2038),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 960;
          return Stack(
            children: [
              // Main Layout
              if (isDesktop)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Left Campus Banner Showcase (Portal UEL style)
                    Expanded(
                      flex: 52,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            'banner_campus.jpg',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: const Color(0xFF033877),
                            ),
                          ),
                          // Subtle edge feathering blending gently into deep navy on the right
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                stops: const [0.0, 0.78, 1.0],
                                colors: [
                                  Colors.transparent,
                                  Colors.transparent,
                                  const Color(0xFF033877).withValues(alpha: 0.85),
                                ],
                              ),
                            ),
                          ),
                          // Subtle top badge on banner
                          Positioned(
                            top: 24,
                            left: 32,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.94),
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.12),
                                    blurRadius: 12,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const _AppShieldLogo(size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    _locale == AppLocale.vi
                                        ? 'AN TOÀN HỌC ĐƯỜNG'
                                        : 'CAMPUS SAFETY',
                                    style: const TextStyle(
                                      color: Color(0xFF033877),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Right Form Area (Deep Navy Background with Floating White Card)
                    Expanded(
                      flex: 48,
                      child: Container(
                        color: const Color(0xFF033877),
                        child: Center(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 440),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildAuthCard(),
                                  const SizedBox(height: 18),
                                  // Minimalist footer under card
                                  const Column(
                                    children: [
                                      Text(
                                        'Hotline: 1900 6868  •  Email: hotro@safety.edu.vn',
                                        style: TextStyle(fontSize: 12, color: Colors.white70),
                                      ),
                                      SizedBox(height: 3),
                                      Text(
                                        '© 2026 Campus Safety System',
                                        style: TextStyle(fontSize: 11, color: Colors.white54),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              else
                // Mobile / Tablet Layout
                Container(
                  color: const Color(0xFF033877),
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 440),
                        child: Column(
                          children: [
                            _buildMobileHeader(),
                            const SizedBox(height: 20),
                            _buildAuthCard(),
                            const SizedBox(height: 20),
                            _buildMobileFooter(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

              // Top Bar with Admin Portal link & Language Switcher
              Positioned(
                top: 16,
                right: 20,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Admin Portal Button
                    InkWell(
                      onTap: () => openUrl('/admin/'),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.admin_panel_settings_outlined, size: 16, color: Color(0xFF033877)),
                            const SizedBox(width: 6),
                            Text(
                              _locale == AppLocale.vi ? 'Trang Admin' : 'Admin Portal',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 12.5,
                                color: Color(0xFF033877),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Language Switcher
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: PopupMenuButton<AppLocale>(
                        tooltip: 'Language',
                        initialValue: _locale,
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        onSelected: _busy ? null : (value) => AppLanguage.instance.setLocale(value),
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: AppLocale.vi,
                            child: Row(
                              children: [
                                Text('🇻🇳', style: TextStyle(fontSize: 16)),
                                SizedBox(width: 8),
                                Text('Tiếng Việt', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: AppLocale.en,
                            child: Row(
                              children: [
                                Text('🇬🇧', style: TextStyle(fontSize: 16)),
                                SizedBox(width: 8),
                                Text('English', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                              ],
                            ),
                          ),
                        ],
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.language_rounded, size: 16, color: Color(0xFF033877)),
                              const SizedBox(width: 6),
                              Text(
                                _locale == AppLocale.vi ? 'Tiếng Việt' : 'English',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12.5,
                                  color: Color(0xFF033877),
                                ),
                              ),
                              const SizedBox(width: 2),
                              const Icon(Icons.arrow_drop_down, size: 18, color: Color(0xFF033877)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ─── AUTHENTICATION CARD (PORTAL UEL STYLE, MINIMAL TEXT) ──────────────────
  Widget _buildAuthCard() {
    final login = _mode == AuthFormMode.login;
    final register = _mode == AuthFormMode.register;
    final forgot = _mode == AuthFormMode.forgot;
    final reset = _mode == AuthFormMode.reset;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF3F4F6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(28),
      child: Form(
        key: _key,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Row (Icon box + Portal Title)
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFF033877).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: _AppShieldLogo(size: 20),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _locale == AppLocale.vi
                        ? 'CỔNG AN TOÀN HỌC ĐƯỜNG'
                        : 'CAMPUS SAFETY PORTAL',
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF033877),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // Main Title
            Text(
              forgot
                  ? s.resetTitle
                  : reset
                  ? (_locale == AppLocale.vi ? 'Tạo mật khẩu mới' : 'New password')
                  : register
                  ? (_locale == AppLocale.vi ? 'Đăng ký' : 'Register')
                  : (_locale == AppLocale.vi ? 'Đăng nhập' : 'Sign In'),
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: Color(0xFF033877),
                letterSpacing: -0.3,
              ),
            ),

            // Tab Switcher between Login & Register (When not forgot/reset)
            if (!forgot && !reset) ...[
              const SizedBox(height: 16),
              Container(
                height: 38,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _switchMode(AuthFormMode.login),
                        borderRadius: BorderRadius.circular(6),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          decoration: BoxDecoration(
                            color: login ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: login
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.06),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ]
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            _locale == AppLocale.vi ? 'Đăng nhập' : 'Sign In',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: login ? FontWeight.w700 : FontWeight.w500,
                              color: login ? const Color(0xFF033877) : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () => _switchMode(AuthFormMode.register),
                        borderRadius: BorderRadius.circular(6),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          decoration: BoxDecoration(
                            color: register ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: register
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.06),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ]
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            _locale == AppLocale.vi ? 'Đăng ký' : 'Register',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: register ? FontWeight.w700 : FontWeight.w500,
                              color: register ? const Color(0xFF033877) : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Role Switcher Tabs (Sinh viên / Giảng viên)
            if (!forgot && !reset) ...[
              const SizedBox(height: 14),
              Container(
                height: 38,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _role = AuthRole.student),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          decoration: BoxDecoration(
                            color: _role == AuthRole.student
                                ? Colors.white
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: _role == AuthRole.student
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ]
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.school_outlined,
                                size: 15,
                                color: _role == AuthRole.student ? const Color(0xFF0F2942) : const Color(0xFF64748B),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                s.roleName(AuthRole.student),
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: _role == AuthRole.student ? FontWeight.w700 : FontWeight.w500,
                                  color: _role == AuthRole.student ? const Color(0xFF0F2942) : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _role = AuthRole.teacher),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          decoration: BoxDecoration(
                            color: _role == AuthRole.teacher
                                ? Colors.white
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: _role == AuthRole.teacher
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ]
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.badge_outlined,
                                size: 15,
                                color: _role == AuthRole.teacher ? const Color(0xFF0F2942) : const Color(0xFF64748B),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                s.roleName(AuthRole.teacher),
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: _role == AuthRole.teacher ? FontWeight.w700 : FontWeight.w500,
                                  color: _role == AuthRole.teacher ? const Color(0xFF0F2942) : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            ],

            const SizedBox(height: 16),

            // Input Fields
            if (register) ...[
              _buildFieldLabel(_locale == AppLocale.vi ? 'Họ và tên' : 'Full name', Icons.person_outline_rounded),
              _inputField(
                controller: _name,
                hintText: _locale == AppLocale.vi ? 'Nhập họ và tên' : 'Enter your full name',
                icon: Icons.person_outline_rounded,
                validator: validateRequired,
              ),
              const SizedBox(height: 12),
            ],

            if (reset) ...[
              _buildFieldLabel(_locale == AppLocale.vi ? 'Mã xác thực' : 'Verification code', Icons.key_rounded),
              _inputField(
                controller: _token,
                hintText: _locale == AppLocale.vi ? 'Nhập mã xác thực' : 'Enter verification code',
                icon: Icons.key_rounded,
                validator: validateRequired,
              ),
              const SizedBox(height: 12),
            ],

            if (!reset) ...[
              _buildFieldLabel(
                _locale == AppLocale.vi
                    ? (_role == AuthRole.student ? 'Mã số hoặc Email' : 'Email giảng viên')
                    : (_role == AuthRole.student ? 'Student ID or Email' : 'Lecturer email'),
                Icons.account_circle_outlined,
              ),
              _inputField(
                controller: _email,
                hintText: _locale == AppLocale.vi
                    ? (_role == AuthRole.student ? 'Nhập MSSV hoặc email' : 'Nhập email giảng viên')
                    : (_role == AuthRole.student ? 'Enter Student ID or email' : 'Enter lecturer email'),
                icon: Icons.mail_outline_rounded,
                validator: validateEmail,
                email: true,
              ),
              const SizedBox(height: 12),
            ],

            if (!forgot) ...[
              _buildFieldLabel(_locale == AppLocale.vi ? 'Mật khẩu' : 'Password', Icons.lock_outline_rounded),
              _passwordField(
                controller: _passwordController,
                hintText: _locale == AppLocale.vi ? 'Nhập mật khẩu' : 'Enter password',
                shown: _visible,
                toggle: () => setState(() => _visible = !_visible),
                validator: (v) => validatePassword(v ?? ''),
              ),
              if (register || reset) ...[
                const SizedBox(height: 6),
                _strength(),
                const SizedBox(height: 12),
                _buildFieldLabel(_locale == AppLocale.vi ? 'Xác nhận mật khẩu' : 'Confirm password', Icons.lock_outline_rounded),
                _passwordField(
                  controller: _confirm,
                  hintText: _locale == AppLocale.vi ? 'Nhập lại mật khẩu' : 'Re-enter password',
                  shown: _visibleConfirm,
                  toggle: () => setState(() => _visibleConfirm = !_visibleConfirm),
                  validator: (v) => validatePasswordConfirmation(v ?? '', _passwordController.text),
                ),
              ],
            ],

            // Remember me & Forgot Password Row
            if (login) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: Checkbox(
                      value: _remember,
                      activeColor: const Color(0xFF033877),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      onChanged: (v) => setState(() => _remember = v ?? false),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    s.remember,
                    style: const TextStyle(fontSize: 12.5, color: Color(0xFF475569), fontWeight: FontWeight.w500),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => _switchMode(AuthFormMode.forgot),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      s.forgot,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF033877),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],

            if (register) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: Checkbox(
                      value: _terms,
                      activeColor: const Color(0xFF033877),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      onChanged: (v) => setState(() => _terms = v ?? false),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _locale == AppLocale.vi
                          ? 'Tôi đồng ý với quy chế và điều khoản sử dụng.'
                          : 'I agree to the safety regulations and terms of use.',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.35),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 18),

            // Primary Action Button (Portal style)
            SizedBox(
              height: 44,
              child: ElevatedButton(
                onPressed: _busy ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F2038),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: _busy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        forgot
                            ? s.sendInstructions
                            : reset
                            ? s.resetTitle
                            : register
                            ? s.register
                            : s.login,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),

            // Back to Login Link for Forgot/Reset
            if (forgot || reset) ...[
              const SizedBox(height: 12),
              Center(
                child: TextButton.icon(
                  onPressed: () => _switchMode(AuthFormMode.login),
                  icon: const Icon(Icons.arrow_back_rounded, size: 16),
                  label: Text(s.backToLogin),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF033877),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 13, color: const Color(0xFF111827)),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    required String? Function(String) validator,
    bool email = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: email ? TextInputType.emailAddress : TextInputType.text,
      validator: (v) => _text(validator(v ?? '')),
      style: const TextStyle(fontSize: 13.5, color: Color(0xFF1E293B)),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
        prefixIcon: Icon(icon, size: 18, color: const Color(0xFF94A3B8)),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Color(0xFF033877), width: 1.8),
        ),
      ),
    );
  }

  Widget _passwordField({
    required TextEditingController controller,
    required String hintText,
    required bool shown,
    required VoidCallback toggle,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: !shown,
      validator: (v) => _text(validator(v)),
      onChanged: (_) => setState(() {}),
      style: const TextStyle(fontSize: 13.5, color: Color(0xFF1E293B)),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
        prefixIcon: const Icon(Icons.lock_outline_rounded, size: 18, color: Color(0xFF6B7280)),
        suffixIcon: IconButton(
          icon: Icon(
            shown ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            size: 18,
            color: const Color(0xFF6B7280),
          ),
          onPressed: toggle,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Color(0xFF033877), width: 1.8),
        ),
      ),
    );
  }

  Widget _strength() {
    final p = passwordStrength(_passwordController.text);
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (p.index + 1) / 4,
              minHeight: 4,
              backgroundColor: const Color(0xFFE2E8F0),
              color: p == PasswordStrength.strong
                  ? const Color(0xFF10B981)
                  : p == PasswordStrength.good
                  ? const Color(0xFF0A3878)
                  : const Color(0xFFE11D48),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          s.strength(p),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: p == PasswordStrength.strong
                ? const Color(0xFF10B981)
                : const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  // ─── MOBILE SPECIFIC HEADER & FOOTER ──────────────────────────────────────
  Widget _buildMobileHeader() {
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Center(
            child: _AppShieldLogo(size: 24),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          _locale == AppLocale.vi ? 'HỆ THỐNG AN TOÀN HỌC ĐƯỜNG' : 'CAMPUS SAFETY SYSTEM',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          _locale == AppLocale.vi ? 'Cổng an toàn & Tiếp nhận phản ánh' : 'Campus Safety & Reporting Portal',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildMobileFooter() {
    return const Column(
      children: [
        Text(
          'Hotline: 1900 6868  •  Email: hotro@safety.edu.vn',
          style: TextStyle(fontSize: 11.5, color: Colors.white70),
        ),
        SizedBox(height: 3),
        Text(
          '© 2026 Campus Safety System',
          style: TextStyle(fontSize: 11, color: Colors.white54),
        ),
      ],
    );
  }
}

// ─── CAMPUS SHIELD VECTOR LOGO ───────────────────────────────────────────────
class _AppShieldLogo extends StatelessWidget {
  const _AppShieldLogo({this.size = 20});
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _AppShieldPainter(),
      ),
    );
  }
}

class _AppShieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / 24.0;
    final scaleY = size.height / 24.0;
    canvas.scale(scaleX, scaleY);

    // 1. Navy bottom shield
    final paintNavy = Paint()
      ..color = const Color(0xFF033877)
      ..style = PaintingStyle.fill;
    final pathShield = Path()
      ..moveTo(12, 2)
      ..lineTo(3, 6)
      ..lineTo(3, 12)
      ..cubicTo(3, 17.5, 6.8, 22.7, 12, 24)
      ..cubicTo(17.2, 22.7, 21, 17.5, 21, 12)
      ..lineTo(21, 6)
      ..close();
    canvas.drawPath(pathShield, paintNavy);

    // 2. Orange accent chevron on top of shield
    final paintOrange = Paint()
      ..color = const Color(0xFFF05A22)
      ..style = PaintingStyle.fill;
    final pathOrange = Path()
      ..moveTo(12, 2)
      ..lineTo(3, 6)
      ..lineTo(3, 9)
      ..lineTo(12, 6)
      ..lineTo(21, 9)
      ..lineTo(21, 6)
      ..close();
    canvas.drawPath(pathOrange, paintOrange);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
