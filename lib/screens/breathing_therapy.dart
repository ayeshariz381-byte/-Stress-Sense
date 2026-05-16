import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/student_bottom_nav.dart';

class BreathingTherapyScreen extends StatefulWidget {
  const BreathingTherapyScreen({super.key});

  @override
  State<BreathingTherapyScreen> createState() => _BreathingTherapyScreenState();
}

class _BreathingTherapyScreenState extends State<BreathingTherapyScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
      lowerBound: 0.8,
      upperBound: 1.1,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: const StudentBottomNav(currentIndex: 1),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: const [
              BackButton(),
              Text('StressSense', style: TextStyle(fontWeight: FontWeight.w700)),
              Spacer(),
              Icon(Icons.timer_outlined),
            ]),
            const SizedBox(height: 18),
            Center(
              child: ScaleTransition(
                scale: controller,
                child: Container(
                  width: 210,
                  height: 210,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.4),
                    shape: BoxShape.circle,
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(28),
                    decoration: const BoxDecoration(
                        color: AppColors.primary, shape: BoxShape.circle),
                    child: const Icon(Icons.air, color: Colors.white, size: 38),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text('Breathe In...',
                  style: TextStyle(fontSize: 34, fontWeight: FontWeight.w600)),
            ),
            const Center(child: Text('Follow the rhythm of the circle')),
            const SizedBox(height: 16),
            const Text('SPIRITUAL HEALING',
                style: TextStyle(letterSpacing: 1.1, color: Colors.black54)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(14)),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ',
                      style: TextStyle(fontSize: 22)),
                  SizedBox(height: 6),
                  Text('"Verily, in the remembrance of Allah do hearts find rest."'),
                  Text('Surah Ar-Ra\'d 13:28',
                      style: TextStyle(color: Colors.black54, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const Text('THERAPEUTIC ACTIONS',
                style: TextStyle(letterSpacing: 1.1, color: Colors.black54)),
            const SizedBox(height: 8),
            _actionCard(context, 'Talk to a Counselor', true),
            const SizedBox(height: 8),
            _actionCard(context, 'Health Resources', false),
            const SizedBox(height: 16),
            const Center(
              child: Text(
                'Your sessions are encrypted. PRIVACY IS SACRED',
                style: TextStyle(fontSize: 11, color: Colors.black45),
              ),
            ),
            const SizedBox(height: 80),
          ]),
        ),
      ),
    );
  }

  Widget _actionCard(BuildContext context, String title, bool green) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: green ? AppColors.primary : Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(children: [
        Text(title,
            style: TextStyle(
                color: green ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w600)),
        const Spacer(),
        Icon(Icons.arrow_forward_ios,
            size: 16, color: green ? Colors.white : Colors.black54),
      ]),
    );
  }
}
