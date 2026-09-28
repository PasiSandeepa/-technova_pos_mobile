import 'dart:async';
import 'package:flutter/material.dart';
import 'home_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Animation Controller
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Scale Animation
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );

    // Fade Animation
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    // Start animation
    _controller.forward();

    // Open the UI after the splash screen.
    Timer(const Duration(seconds: 5), () {
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const HomePage(),
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,

        // Background Gradient
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF064E46),
              Color(0xFF087F73),
              Color(0xFF0D9488),
            ],
          ),
        ),

        child: Stack(
          children: [
            // ============================================
            // DECORATIVE CIRCLE - TOP RIGHT
            // ============================================

            Positioned(
              top: -100,
              right: -80,
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.06),
                ),
              ),
            ),

            // ============================================
            // DECORATIVE CIRCLE - BOTTOM LEFT
            // ============================================

            Positioned(
              bottom: -120,
              left: -90,
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
            ),

            // ============================================
            // MAIN CONTENT
            // ============================================

            Center(
              child: FadeTransition(
                opacity: _fadeAnimation,

                child: ScaleTransition(
                  scale: _scaleAnimation,

                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ====================================
                      // LOGO
                      // ====================================

                      FractionallySizedBox(
                        widthFactor: 0.80,
                        child: Container(
                          height: 125,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 30,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: Image.asset(
                            'assets/images/technova-logo-tight.png',
                            width: 330,
                            height: 105,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),

                      // ====================================
                      // APP NAME
                      // ====================================

                      const Text(
                        'TechNova',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // ====================================
                      // SUB TITLE
                      // ====================================

                      Text(
                        'SMART RETAIL MANAGEMENT',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withOpacity(0.75),
                          letterSpacing: 2,
                        ),
                      ),

                      const SizedBox(height: 35),

                      // ====================================
                      // LOADING INDICATOR
                      // ====================================

                      const SizedBox(
                        width: 25,
                        height: 25,

                        child: CircularProgressIndicator(
                          strokeWidth: 2,

                          valueColor:
                              AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ============================================
            // BOTTOM TEXT
            // ============================================

            Positioned(
              bottom: 35,
              left: 0,
              right: 0,

              child: Text(
                'Powering smarter businesses',
                textAlign: TextAlign.center,

                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.65),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

