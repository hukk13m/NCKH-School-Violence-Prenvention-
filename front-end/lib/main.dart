import 'package:flutter/material.dart';

import 'features/auth/presentation/auth_screen.dart';
import 'features/dashboard/presentation/dashboard_screen.dart';
import 'features/dashboard/presentation/teacher_dashboard_screen.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'School Violation Detector',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      fontFamily: 'Roboto',
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF033877),
        primary: const Color(0xFF033877),
        secondary: const Color(0xFFE85D26),
        surface: Colors.white,
      ),
      scaffoldBackgroundColor: const Color(0xFFF5F7FA),
      inputDecorationTheme: const InputDecorationTheme(isDense: true),
    ),
    home: const AuthScreen(),
    routes: {
      '/auth': (_) => const AuthScreen(),
      '/student/home': (_) => const DashboardScreen(),
      '/teacher/dashboard': (_) => const TeacherDashboardScreen(),
      '/admin/dashboard': (_) => const TeacherDashboardScreen(isAdmin: true),
    },
  );
}
