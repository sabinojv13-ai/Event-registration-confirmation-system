
import 'package:flutter/material.dart';
import 'screens/ministry_dashboard.dart';

void main() {
  runApp(const LiturgicalMinistryApp());
}

class LiturgicalMinistryApp extends StatelessWidget {
  const LiturgicalMinistryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Liturgical Ministry System',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF345B45),
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F7F4),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF345B45),
          foregroundColor: Colors.white,
          centerTitle: false,
        ),
      ),
      home: const MinistryDashboard(),
    );
  }
}
