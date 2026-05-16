import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/student_bottom_nav.dart';
import 'messaging_screen.dart';

class ZenScreen extends StatefulWidget {
  const ZenScreen({super.key});

  @override
  State<ZenScreen> createState() => _ZenScreenState();
}

class _ZenScreenState extends State<ZenScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _breathController;
  bool _breathing = false;
  String _phase = 'Tap to begin';
  int _seconds = 0;
  Timer? _timer;
  int _cycle = 0; // 0=inhale,1=hold,2=exhale

  final List<Map<String, dynamic>> _tips = [
    {'icon': '🌿', 'text': 'Take one thing at a time'},
    {'icon': '💧', 'text': 'Stay hydrated throughout the day'},
    {'icon': '🌙', 'text': 'Sleep 7-8 hours for mental clarity'},
    {'icon': '🤲', 'text': 'Make dua — it brings peace to the heart'},
    {'icon': '🚶', 'text': 'A short walk reduces cortisol levels'},
    {'icon': '📵', 'text': 'Take a break from screens every hour'},
  ];

  @override
  void initState() {
    super.initState();
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
      lowerBound: 0.7,
      upperBound: 1.3,
    );
  }

  @override
  void dispose() {
    _breathController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startBreathing() {
    setState(() {
      _breathing = true;
      _phase = 'Inhale...';
      _cycle = 0;
      _seconds = 4;
    });
    _breathController.forward();
    _timer = Timer.periodic(const Duration(seconds: 1), _tick);
  }

  void _stopBreathing() {
    _timer?.cancel();
    _breathController.stop();
    _breathController.reset();
    setState(() {
      _breathing = false;
      _phase = 'Tap to begin';
      _seconds = 0;
    });
  }

  void _tick(Timer t) {
    if (!mounted) {
      t.cancel();
      return;
    }
    setState(() => _seconds--);
    if (_seconds <= 0) {
      _cycle = (_cycle + 1) % 3;
      if (_cycle == 0) {
        setState(() {
          _phase = 'Inhale...';
          _seconds = 4;
        });
        _breathController.forward(from: 0.7);
      } else if (_cycle == 1) {
        setState(() {
          _phase = 'Hold...';
          _seconds = 4;
        });
      } else {
        setState(() {
          _phase = 'Exhale...';
          _seconds = 4;
        });
        _breathController.reverse();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () => Navigator.pushNamed(context, '/heart-rate'),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: const StudentBottomNav(currentIndex: 2),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1B4332), Color(0xFF2D6A4F)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Column(children: [
              // ── Header with fixed back button ──────────────────
              Row(children: [
                IconButton(
                  onPressed: () {
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    } else {
                      Navigator.pushReplacementNamed(
                          context, '/student-dashboard');
                    }
                  },
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                ),
                const Text('Zen Mode',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700)),
              ]),

              const SizedBox(height: 10),
              const Text(
                '"Verily, in the remembrance of Allah\ndo hearts find rest."',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white70,
                    fontStyle: FontStyle.italic,
                    fontSize: 13),
              ),
              const SizedBox(height: 30),

              // Breathing circle
              GestureDetector(
                onTap: _breathing ? _stopBreathing : _startBreathing,
                child: AnimatedBuilder(
                  animation: _breathController,
                  builder: (context, child) {
                    final scale =
                        _breathing ? _breathController.value : 1.0;
                    return Transform.scale(
                      scale: scale,
                      child: Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.15),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.4),
                              width: 2),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.self_improvement,
                                color: Colors.white, size: 40),
                            const SizedBox(height: 8),
                            Text(
                              _phase,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600),
                            ),
                            if (_breathing)
                              Text('$_seconds s',
                                  style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),
              Text(
                _breathing
                    ? 'Tap to stop'
                    : 'Tap circle to start breathing exercise',
                style:
                    const TextStyle(color: Colors.white60, fontSize: 12),
              ),

              const SizedBox(height: 24),

              // Spiritual healing section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2)),
                ),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  const Text('SPIRITUAL HEALING',
                      style: TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  const Text(
                    'أَلَا بِذِكْرِ ٱللَّهِ تَطْمَئِنُّ ٱلْقُلُوبُ',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontFamily: 'serif'),
                    textAlign: TextAlign.right,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    '"Verily, in the remembrance of Allah do hearts find rest."\nSurah Ar-Ra\'d 13:28',
                    style: TextStyle(
                        color: Colors.white70,
                        fontStyle: FontStyle.italic,
                        fontSize: 12),
                  ),
                ]),
              ),

              const SizedBox(height: 16),

              // Therapeutic actions
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('THERAPEUTIC ACTIONS',
                    style: TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 8),

              _actionTile(
                context,
                label: 'Talk to a Counselor',
                icon: Icons.chat_bubble_outline,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MessagingScreen(
                      patientName: 'Dr. Sarah Jenkins',
                      patientInitials: 'SJ',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _actionTile(
                context,
                label: 'Health Resources',
                icon: Icons.menu_book_outlined,
                onTap: () =>
                    Navigator.pushNamed(context, '/health-tips'),
              ),

              const SizedBox(height: 30),

              // Tips
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Mindfulness Tips',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 12),
              ..._tips.map((tip) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(children: [
                      Text(tip['icon'],
                          style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Text(tip['text'],
                              style: const TextStyle(
                                  color: Colors.white))),
                    ]),
                  )),
              const SizedBox(height: 80),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _actionTile(BuildContext context,
      {required String label,
      required IconData icon,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF2D6A4F),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 12),
          Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14)),
          const Spacer(),
          const Icon(Icons.chevron_right, color: Colors.white70),
        ]),
      ),
    );
  }
}