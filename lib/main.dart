import 'package:flutter/material.dart';
import 'pages/splash_screen.dart';

void main() {
  runApp(const TechNovaApp());
}

class TechNovaApp extends StatelessWidget {
  const TechNovaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TechNova POS',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0D9488),
        ),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}