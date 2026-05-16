import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final auth = context.read<AuthProvider>();
    await auth.initialize();
    if (!mounted) return;

    if (auth.isConsultant) {
      Navigator.pushReplacementNamed(context, '/consultant-dashboard');
    } else if (auth.isStudent) {
      Navigator.pushReplacementNamed(context, '/student-dashboard');
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1F6F5F),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ── Logo ─────────────────────────────────────────
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.psychology,
                    color: Colors.white, size: 60),
              ),
              const SizedBox(height: 24),

              // ── App name ──────────────────────────────────────
              const Text(
                'StressSense',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 6),

              // ── Tagline ───────────────────────────────────────
              const Text(
                'Your Mental Wellness Companion',
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 13,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 32),

              // ── Divider ───────────────────────────────────────
              Row(children: [
                Expanded(
                    child: Divider(
                        color: Colors.white.withValues(alpha: 0.3),
                        thickness: 1)),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child:
                      Icon(Icons.star, color: Colors.white38, size: 14),
                ),
                Expanded(
                    child: Divider(
                        color: Colors.white.withValues(alpha: 0.3),
                        thickness: 1)),
              ]),
              const SizedBox(height: 20),

              // ── Quran verse ───────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2)),
                ),
                child: Column(children: [
                  const Text(
                    '"My Lord! I am in need of whatever\ngood you send down to me."',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '— Surah Al-Qasas 28:24',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ]),
              ),

              const SizedBox(height: 48),

              // ── Loading indicator ─────────────────────────────
              const CircularProgressIndicator(color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}