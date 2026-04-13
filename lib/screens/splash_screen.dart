import 'package:flutter/material.dart';
import 'package:skincare_analyzer_app/main.dart'; // To access AppColors

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
  with TickerProviderStateMixin {
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  late AnimationController _fadeController;
  late Animation<double> _logoFadeAnimation;
  late Animation<double> _loadingFadeAnimation;

  @override
  void initState() {
    super.initState();

    // Fade-in animation for logo
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _logoFadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _loadingFadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
    );

    // Progress bar animation
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _progressAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );

    // Start animations
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 400), () {
      _progressController.forward().then((_) {
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
      });
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5),
      body: SafeArea(
        child: Column(
          children: [
            // Top spacer — pushes logo to ~center-upper area
            const Spacer(flex: 3),

            // Logo image with fade-in
            FadeTransition(
              opacity: _logoFadeAnimation,
              child: Center(
                child: Image.asset(
                  'assets/images/logo2_splash.png',
                  width: screenWidth * 0.55,
                  fit: BoxFit.contain,
                ),
              ),
            ),

            // Spacer between logo and loading bar
            const Spacer(flex: 2),

            // Loading section with fade-in
            FadeTransition(
              opacity: _loadingFadeAnimation,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.12),
                child: Column(
                  children: [
                    // "LOADING" label and percentage
                    AnimatedBuilder(
                      animation: _progressAnimation,
                      builder: (context, child) {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'LOADING',
                              style: TextStyle(
                                color: Color(0xFF4CAF50),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 2.0,
                              ),
                            ),
                            Text(
                              '${(_progressAnimation.value * 100).toInt()}%',
                              style: const TextStyle(
                                color: Color(0xFF4CAF50),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 12),

                    // Progress bar
                    AnimatedBuilder(
                      animation: _progressAnimation,
                      builder: (context, child) {
                        return Container(
                          height: 7,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0E0E0),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: FractionallySizedBox(
                              widthFactor: _progressAnimation.value,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF66BB6A),
                                      Color(0xFF4CAF50),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF4CAF50)
                                          .withValues(alpha: 0.4),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Bottom spacer
            const Spacer(flex: 1),
          ],
        ),
      ),
    );
  }
}
