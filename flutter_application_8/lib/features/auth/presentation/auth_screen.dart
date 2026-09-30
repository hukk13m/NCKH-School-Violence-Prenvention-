import 'package:flutter/material.dart';

import '../application/auth_controller.dart';
import '../data/auth_service_factory.dart';
import '../domain/auth_models.dart';
import '../domain/auth_validation.dart';
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
    _auth = AuthController(const AuthServiceFactory().create());
  }

  @override
  void dispose() {
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
      Navigator.of(context).pushReplacementNamed(
        r.session!.role == AuthRole.student
            ? '/student/home'
            : '/teacher/dashboard',
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

  Future<void> _oauth(bool google) async {
    setState(() => _busy = true);
    final r = google ? await _auth.google(_role) : await _auth.apple(_role);
    if (!mounted) return;
    setState(() => _busy = false);
    if (r.session != null) {
      Navigator.of(context).pushReplacementNamed(
        r.session!.role == AuthRole.student
            ? '/student/home'
            : '/teacher/dashboard',
      );
    } else {
      _toast(_failure(r.error!), false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xfff4f7fb),
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, box) {
          final compact = box.maxWidth < 640;
          var items = <Widget>[_formPanel(), _visual(compact)];
          if (_role == AuthRole.teacher) items = items.reversed.toList();
          return Stack(
            children: [
              Positioned(
                top: 8,
                right: 14,
                child: PopupMenuButton<AppLocale>(
                  tooltip: 'Đổi ngôn ngữ',
                  onSelected: _busy
                      ? null
                      : (value) => setState(() => _locale = value),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: AppLocale.vi,
                      child: Text('Tiếng Việt'),
                    ),
                    const PopupMenuItem(
                      value: AppLocale.en,
                      child: Text('English'),
                    ),
                  ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.language, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          _locale == AppLocale.vi ? 'Tiếng Việt' : 'English',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              AnimatedSwitcher(
                duration: MediaQuery.disableAnimationsOf(context)
                    ? const Duration(milliseconds: 120)
                    : const Duration(milliseconds: 550),
                child: Flex(
                  key: ValueKey('${_role.name}-$compact'),
                  direction: compact ? Axis.vertical : Axis.horizontal,
                  children: items,
                ),
              ),
            ],
          );
        },
      ),
    ),
  );

  Widget _formPanel() => Expanded(
    flex: 42,
    child: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 70, 24, 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 470),
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            child: Padding(
              padding: const EdgeInsets.all(26),
              child: Form(key: _key, child: _content()),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _content() {
    final login = _mode == AuthFormMode.login,
        register = _mode == AuthFormMode.register,
        forgot = _mode == AuthFormMode.forgot,
        reset = _mode == AuthFormMode.reset;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(Icons.shield_outlined, color: Color(0xff0b3b7a)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                s.appName,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Color(0xff0b2b5b),
                ),
              ),
            ),
            Semantics(
              label: _role == AuthRole.student
                  ? s.studentPortal
                  : s.teacherPortal,
              child: Text(
                _role == AuthRole.student ? s.studentPortal : s.teacherPortal,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          forgot || reset ? s.resetTitle : s.welcome,
          style: const TextStyle(
            fontSize: 27,
            fontWeight: FontWeight.w800,
            color: Color(0xff102a56),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          forgot ? s.resetDescription : s.subtitle,
          style: const TextStyle(color: Color(0xff58708f)),
        ),
        const SizedBox(height: 22),
        if (register) ...[
          _input(_name, s.fullName, Icons.person_outline, validateRequired),
          const SizedBox(height: 12),
        ],
        if (reset) ...[
          _input(_token, s.resetToken, Icons.key_outlined, validateRequired),
          const SizedBox(height: 12),
        ],
        if (!reset) ...[
          _input(
            _email,
            s.email,
            Icons.mail_outline,
            validateEmail,
            email: true,
          ),
          const SizedBox(height: 12),
        ],
        if (!forgot) ...[
          _password(
            _passwordController,
            s.password,
            _visible,
            () => setState(() => _visible = !_visible),
            (v) => validatePassword(v ?? ''),
          ),
          if (register || reset) ...[
            const SizedBox(height: 7),
            _strength(),
            const SizedBox(height: 12),
            _password(
              _confirm,
              s.confirmPassword,
              _visibleConfirm,
              () => setState(() => _visibleConfirm = !_visibleConfirm),
              (v) => validatePasswordConfirmation(
                v ?? '',
                _passwordController.text,
              ),
            ),
          ],
        ],
        if (login)
          Row(
            children: [
              Checkbox(
                value: _remember,
                onChanged: (v) => setState(() => _remember = v ?? false),
              ),
              Expanded(
                child: Text(s.remember, style: const TextStyle(fontSize: 13)),
              ),
              TextButton(
                onPressed: () => _switchMode(AuthFormMode.forgot),
                child: Text(s.forgot),
              ),
            ],
          ),
        if (register)
          Row(
            children: [
              Checkbox(
                value: _terms,
                onChanged: (v) => setState(() => _terms = v ?? false),
              ),
              Expanded(
                child: Text(s.agree, style: const TextStyle(fontSize: 12)),
              ),
            ],
          ),
        const SizedBox(height: 14),
        SizedBox(
          height: 50,
          child: FilledButton(
            onPressed: _busy ? null : _submit,
            child: _busy
                ? const CircularProgressIndicator()
                : Text(
                    forgot
                        ? s.sendInstructions
                        : reset
                        ? s.resetTitle
                        : register
                        ? s.register
                        : s.login,
                  ),
          ),
        ),
        if (login) ...[
          _divider(),
          _social(s.google, Icons.g_mobiledata, () => _oauth(true)),
          const SizedBox(height: 8),
          _social(s.apple, Icons.apple, () => _oauth(false)),
        ],
        Center(
          child: TextButton(
            onPressed: () =>
                _switchMode(login ? AuthFormMode.register : AuthFormMode.login),
            child: Text(
              login
                  ? '${s.needAccount} ${s.register}'
                  : '${s.haveAccount} ${s.login}',
            ),
          ),
        ),
        if (forgot || reset)
          Center(
            child: TextButton(
              onPressed: () => _switchMode(AuthFormMode.login),
              child: Text(s.backToLogin),
            ),
          ),
        if (forgot)
          Center(
            child: TextButton(
              onPressed: () => _switchMode(AuthFormMode.reset),
              child: Text(s.haveResetToken),
            ),
          ),
        const Divider(),
        Center(
          child: TextButton.icon(
            onPressed: () => setState(
              () => _role = _role == AuthRole.student
                  ? AuthRole.teacher
                  : AuthRole.student,
            ),
            icon: const Icon(Icons.swap_horiz),
            label: Text(s.switchRole(_role)),
          ),
        ),
      ],
    );
  }

  Widget _input(
    TextEditingController c,
    String label,
    IconData icon,
    String? Function(String) validate, {
    bool email = false,
  }) => TextFormField(
    controller: c,
    keyboardType: email ? TextInputType.emailAddress : TextInputType.text,
    validator: (v) => _text(validate(v ?? '')),
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );
  Widget _password(
    TextEditingController c,
    String label,
    bool shown,
    VoidCallback toggle,
    String? Function(String?) validate,
  ) => TextFormField(
    controller: c,
    obscureText: !shown,
    onChanged: (_) => setState(() {}),
    validator: (v) => _text(validate(v)),
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: const Icon(Icons.lock_outline),
      suffixIcon: IconButton(
        tooltip: shown ? s.hidePassword : s.showPassword,
        onPressed: toggle,
        icon: Icon(
          shown ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        ),
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );
  Widget _strength() {
    final p = passwordStrength(_passwordController.text);
    return Semantics(
      label: 'Password strength ${s.strength(p)}',
      child: Row(
        children: [
          Expanded(
            child: LinearProgressIndicator(
              value: (p.index + 1) / 4,
              minHeight: 5,
            ),
          ),
          const SizedBox(width: 8),
          Text(s.strength(p), style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _divider() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 18),
    child: Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(s.continueWith, style: const TextStyle(fontSize: 12)),
        ),
        const Expanded(child: Divider()),
      ],
    ),
  );
  Widget _social(String label, IconData icon, VoidCallback action) => SizedBox(
    height: 48,
    child: OutlinedButton.icon(
      onPressed: _busy ? null : action,
      icon: Icon(icon),
      label: Text(label),
    ),
  );
  Widget _visual(bool compact) => Expanded(
    flex: 58,
    child: Container(
      margin: EdgeInsets.all(compact ? 10 : 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xff071b3c), Color(0xff1676b8)],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(compact ? 24 : 48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            const Icon(
              Icons.account_balance_outlined,
              size: 42,
              color: Color(0xffb8e1ff),
            ),
            const SizedBox(height: 12),
            Text(
              s.universityName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              s.universityTagline,
              style: const TextStyle(color: Color(0xffd5e9ff)),
            ),
          ],
        ),
      ),
    ),
  );
}
