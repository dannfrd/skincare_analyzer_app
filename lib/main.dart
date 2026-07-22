import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'config/app_config.dart';
import 'models/scan_payload.dart';
import 'screens/connection_test_screen.dart';
import 'screens/edit_profile_screen.dart';
import 'screens/login_screen.dart';
import 'screens/main_navigation.dart';
import 'screens/notification_screen.dart';
import 'screens/permission_screen.dart';
import 'screens/register_screen.dart';
import 'screens/scan_progress_screen.dart';
import 'screens/scan_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/skincare_tips_screen.dart';
import 'screens/tip_detail_screen.dart';
import 'screens/tutorial_screen.dart';
import 'screens/ingredient_database_screen.dart';
import 'services/api_service.dart';
import 'services/fcm_service.dart';
import 'utils/smooth_page_transitions.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  
  // Print app configuration for debugging
  AppConfig.printConfig();
  
  // Print network diagnostics
  await ApiService.printDiagnostics();
  
  await Firebase.initializeApp();

  // Daftarkan background FCM handler (wajib sebelum runApp)
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Inisialisasi FCM service (permission, subscribe topic, dll)
  await FcmService.instance.init();

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

// Global navigator key for deep linking from background services
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class SkincareAnalyzerApp extends StatelessWidget {
  const SkincareAnalyzerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Skincare AI Analyzer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryGreen,
          surface: AppColors.backgroundLight,
        ),
        scaffoldBackgroundColor: AppColors.backgroundLight,
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: SmoothPageTransitionsBuilder(),
            TargetPlatform.iOS: SmoothPageTransitionsBuilder(),
            TargetPlatform.windows: SmoothPageTransitionsBuilder(),
            TargetPlatform.macOS: SmoothPageTransitionsBuilder(),
            TargetPlatform.linux: SmoothPageTransitionsBuilder(),
          },
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.light,
          ),
        ),
        textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme)
            .apply(
              bodyColor: AppColors.textDark,
              displayColor: AppColors.textDark,
            ),
        useMaterial3: true,
      ),
      initialRoute: '/',
      onGenerateRoute: (settings) {
        WidgetBuilder? builder;
        switch (settings.name) {
          case '/':
            builder = (context) => const SplashScreen();
            break;
          case '/permissions':
            builder = (context) => const PermissionScreen();
            break;
          case '/tutorial':
            builder = (context) => const TutorialScreen();
            break;
          case '/login':
            builder = (context) => const LoginScreen();
            break;
          case '/register':
            builder = (context) => const RegisterScreen();
            break;
          case '/main':
            builder = (context) => const MainNavigation();
            break;
          case '/scan':
            builder = (context) => const ScanScreen();
            break;
          case '/notifications':
            builder = (context) => const NotificationScreen();
            break;
          case '/connection-test':
            builder = (context) => const ConnectionTestScreen();
            break;
          case '/edit-profile':
            builder = (context) => const EditProfileScreen();
            break;
          case '/tips':
            builder = (context) => const SkincareTipsScreen();
            break;
          case '/tip-detail':
            builder = (context) => const TipDetailScreen();
            break;
          case '/ingredients':
            builder = (context) => const IngredientDatabaseScreen();
            break;
          case '/progress':
            final args = settings.arguments;
            ScanPayload? payload;

            if (args is ScanPayload) {
              payload = args;
            } else if (args is File) {
              payload = ScanPayload(imageFile: args);
            }

            if (payload != null) {
              builder = (context) => ScanProgressScreen(payload: payload!);
            }
            break;
        }

        if (builder != null) {
          return SmoothPageRoute(
            builder: builder,
            settings: settings,
          );
        }
        return null;
      },
    );
  }
}
