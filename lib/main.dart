import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';

import 'screens/splash_screen.dart';
import 'screens/main_navigation.dart';
import 'screens/scan_screen.dart';
import 'screens/scan_progress_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/notification_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const SkincareAnalyzerApp());
}

// Color Palette based on design
class AppColors {
  static const Color primaryGreen = Color(0xFF68D377);
  static const Color primaryGreenDark = Color(0xFF4CB35B);
  static const Color secondaryGreen = Color(0xFFD9F4DF);
  static const Color backgroundLight = Color(0xFFF8F9FA);
  static const Color textDark = Color(0xFF1E293B);
  static const Color textGray = Color(0xFF64748B);
  static const Color cardLight = Colors.white;
  static const Color surfaceGreen = Color(0xFFE8F6EA);
}

class SkincareAnalyzerApp extends StatelessWidget {
  const SkincareAnalyzerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Skincare AI Analyzer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryGreen,
          surface: AppColors.backgroundLight,
        ),
        scaffoldBackgroundColor: AppColors.backgroundLight,
        textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme)
            .apply(
              bodyColor: AppColors.textDark,
              displayColor: AppColors.textDark,
            ),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/main': (context) => const MainNavigation(),
        '/scan': (context) => const ScanScreen(),
        '/notifications': (context) => const NotificationScreen(),
        // Progress and Results typically get pushed with arguments rather than simple routes
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/progress') {
          final imageFile = settings.arguments as dynamic; // File
          return MaterialPageRoute(
            builder: (context) => ScanProgressScreen(imageFile: imageFile),
          );
        }
        return null;
      },
    );
  }
}
