import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

// Providers
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';

// Screens
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/consultant_login.dart';
import 'screens/home_dashboard.dart';
import 'screens/consultant_dashboard.dart';
import 'screens/heart_rate_screen.dart';
import 'screens/stress_analysis.dart';
import 'screens/zen_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/breathing_therapy.dart';
import 'screens/healing_audio.dart';
import 'screens/health_tips.dart';
import 'screens/emergency_screen.dart';
import 'screens/messaging_screen.dart';
import 'screens/patient_consultation.dart';
import 'screens/consultant_profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const StressSenseApp(),
    ),
  );
}

class StressSenseApp extends StatelessWidget {
  const StressSenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'StressSense',

      // ── Light theme ──────────────────────────────────────────
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1F6F5F),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          filled: true,
          fillColor: Colors.white,
        ),
      ),

      // ── Dark theme ───────────────────────────────────────────
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1F6F5F),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF121212),
        cardColor: const Color(0xFF1E1E1E),
        inputDecorationTheme: InputDecorationTheme(
          border: const OutlineInputBorder(),
          filled: true,
          fillColor: Colors.grey.shade900,
        ),
      ),

      // ── Controlled by ThemeProvider ──────────────────────────
      themeMode: themeProvider.themeMode,

      home: const SplashScreen(),
      routes: {
        '/login': (ctx) => const LoginScreen(),
        '/consultant-login': (ctx) => const ConsultantLoginScreen(),
        '/student-dashboard': (ctx) => const HomeDashboardScreen(),
        '/consultant-dashboard': (ctx) => const ConsultantDashboardScreen(),
        '/heart-rate': (ctx) => const HeartRateScreen(),
        '/analysis': (ctx) {
          final args = ModalRoute.of(ctx)!.settings.arguments
              as Map<String, dynamic>?;
          return StressAnalysisScreen(
            bpm: args?['bpm'] as int?,
            hrv: args?['hrv'] as int?,
            stressLevel: args?['stressLevel'] as String?,
          );
        },
        '/zen': (ctx) => const ZenScreen(),
        '/profile': (ctx) => const ProfileScreen(),
        '/breathing': (ctx) => const BreathingTherapyScreen(),
        '/healing-audio': (ctx) => const HealingAudioScreen(),
        '/health-tips': (ctx) => const HealthTipsScreen(),
        '/emergency': (ctx) => const EmergencyScreen(),
        '/messaging': (ctx) {
          final args = ModalRoute.of(ctx)!.settings.arguments
              as Map<String, String>?;
          return MessagingScreen(
            patientName: args?['patientName'] ?? 'Dr. Sarah Jenkins',
            patientInitials: args?['patientInitials'] ?? 'SJ',
          );
        },
        '/patient-consultation': (ctx) => const PatientConsultationScreen(),
        '/consultant-profile': (ctx) => const ConsultantProfileScreen(),
      },
    );
  }
}