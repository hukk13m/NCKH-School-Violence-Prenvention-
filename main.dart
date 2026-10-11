import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'School Violence Detection',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
      ),
      home: const LoginScreen(),
    );
  }
}

// // //test login register
// // import 'package:flutter/material.dart';
// // import 'screens/login_screen.dart';
// // import 'screens/users_screen.dart';
// //
// // void main() {
// //   runApp(const MyApp());
// // }
// //
// // class MyApp extends StatelessWidget {
// //   const MyApp({super.key});
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return MaterialApp(
// //       title: 'School Violation App',
// //       theme: ThemeData(
// //         primarySwatch: Colors.blue,
// //       ),
// //       home: const LoginScreen(),
// //     );
// //   }
// // }
//
// //tést user management
// import 'package:flutter/material.dart';
//
// import 'screens/users_screen.dart';
//
// void main() {
//   runApp(const MyApp());
// }
//
// class MyApp extends StatelessWidget {
//   const MyApp({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       title: 'School Violence Detection',
//       theme: ThemeData(
//         useMaterial3: true,
//         colorSchemeSeed: Colors.indigo,
//       ),
//       home: const UsersScreen(),
//     );
//   }
// }
//
//
// // //test dashboard
// // import 'package:flutter/material.dart';
// //
// // import 'screens/dashboard_screen.dart';
// //
// //
// // void main() {
// //   runApp(const MyApp());
// // }
// //
// //
// // class MyApp extends StatelessWidget {
// //   const MyApp({super.key});
// //
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return MaterialApp(
// //       debugShowCheckedModeBanner: false,
// //
// //       title: 'School Violence Detection',
// //
// //       theme: ThemeData(
// //         useMaterial3: true,
// //         colorSchemeSeed: Colors.indigo,
// //       ),
// //
// //       home: const DashboardScreen(),
// //     );
// //   }
// // }