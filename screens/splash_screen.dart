import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import 'admin_navigation.dart';
import 'user_navigation.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final ApiService _api = ApiService();

  @override
  void initState() {
    super.initState();
    _decideRoute();
  }

  Future<void> _decideRoute() async {
    await Future.delayed(const Duration(milliseconds: 600));

    if (!await _api.isLoggedIn()) {
      _go(const LoginScreen());
      return;
    }

    final user = await _api.getMe() ?? await _api.getCachedUser();

    if (user == null) {
      _go(const LoginScreen());
    } else if (user.isAdmin) {
      _go(const AdminNavigation());
    } else {
      _go(const UserNavigation());
    }
  }

  void _go(Widget page) {
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}