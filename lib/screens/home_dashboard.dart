import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/student_bottom_nav.dart';

class HomeDashboardScreen extends StatelessWidget {
  const HomeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final name = auth.displayName;
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDark;

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () => Navigator.pushNamed(context, '/heart-rate'),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: const StudentBottomNav(currentIndex: 0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top Row with greeting + dark mode toggle ──────
              Row(
                children: [
                  Text('As-salaamu Alaikum,',
                      style: TextStyle(
                          color: isDark ? Colors.white60 : Colors.black54)),
                  const Spacer(),
                  // ── Dark/Light toggle button ──────────────────
                  GestureDetector(
                    onTap: () => themeProvider.toggleTheme(),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 56,
                      height: 28,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: isDark
                            ? const Color(0xFF1F6F5F)
                            : const Color(0xFFDDEEE8),
                      ),
                      child: Stack(
                        children: [
                          // sun icon
                          Positioned(
                            left: 6,
                            top: 5,
                            child: Icon(Icons.wb_sunny_rounded,
                                size: 18,
                                color: isDark
                                    ? Colors.white30
                                    : Colors.orange),
                          ),
                          // moon icon
                          Positioned(
                            right: 6,
                            top: 5,
                            child: Icon(Icons.nightlight_round,
                                size: 18,
                                color: isDark
                                    ? Colors.white
                                    : Colors.black26),
                          ),
                          // sliding circle
                          AnimatedPositioned(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            left: isDark ? 30 : 2,
                            top: 2,
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isDark
                                    ? Colors.white
                                    : AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.notifications_none,
                      color: isDark ? Colors.white : Colors.black),
                ],
              ),

              Text(
                name,
                style: const TextStyle(
                    fontSize: 30, color: AppColors.darkGreen),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E3B2F)
                      : const Color(0xFFE9EFE8),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  '"Verily, in the remembrance of Allah do hearts find rest."\nSurah Ar-Ra\'d 13:28',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: AppColors.darkGreen),
                ),
              ),
              const SizedBox(height: 20),

              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/heart-rate'),
                child: Center(
                  child: Column(children: [
                    CircleAvatar(
                      radius: 58,
                      backgroundColor:
                          isDark ? const Color(0xFF2A2A2A) : AppColors.white,
                      child: CircleAvatar(
                        radius: 42,
                        backgroundColor: isDark
                            ? const Color(0xFF1E3B2F)
                            : const Color(0xFFD7E2DC),
                        child: const Icon(Icons.fingerprint,
                            size: 36, color: AppColors.primary),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Place finger on\ncamera',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w600),
                    ),
                    Text('SMART STRESS SENSOR',
                        style: TextStyle(
                            color:
                                isDark ? Colors.white38 : Colors.black45)),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () =>
                          Navigator.pushNamed(context, '/heart-rate'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                      ),
                      icon: const Icon(Icons.favorite_border, size: 16),
                      label: const Text('Measure Now'),
                    ),
                  ]),
                ),
              ),

              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _card(
                      title: 'ACTIVITY',
                      body: '3,420',
                      footer: 'GREAT for your health',
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _card(
                      title: 'DAILY MOOD',
                      body: 'How are you feeling?',
                      footer: '🙂 😐 😣',
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Center(
                child: Text(
                  'Your data is stored securely and never shared.',
                  style: TextStyle(
                      color: isDark ? Colors.white30 : Colors.black45,
                      fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card({
    required String title,
    required String body,
    required String footer,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  color: isDark ? Colors.white38 : Colors.black45,
                  fontSize: 11)),
          const SizedBox(height: 8),
          Text(body,
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black)),
          const SizedBox(height: 8),
          Text(footer,
              style:
                  const TextStyle(color: AppColors.primary, fontSize: 11)),
        ],
      ),
    );
  }
}