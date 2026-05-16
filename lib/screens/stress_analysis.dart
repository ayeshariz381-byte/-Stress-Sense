import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_colors.dart';
import '../widgets/student_bottom_nav.dart';
import 'messaging_screen.dart';

class StressAnalysisScreen extends StatefulWidget {
  final int? bpm;
  final int? hrv;
  final String? stressLevel;

  const StressAnalysisScreen({
    super.key,
    this.bpm,
    this.hrv,
    this.stressLevel,
  });

  @override
  State<StressAnalysisScreen> createState() => _StressAnalysisScreenState();
}

class _StressAnalysisScreenState extends State<StressAnalysisScreen> {
  List<Map<String, dynamic>> _history = [];
  bool _loading = true;

  int _displayBpm = 72;
  int _displayHrv = 35;
  String _displayStress = 'Moderate';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final snapshot = await FirebaseFirestore.instance
          .collection('stress_readings')
          .where('uid', isEqualTo: user.uid)
          .orderBy('timestamp', descending: true)
          .limit(10)
          .get();

      final readings = snapshot.docs.map((doc) => doc.data()).toList();

      if (mounted) {
        setState(() {
          _history = readings;
          if (readings.isNotEmpty) {
            final latest = readings.first;
            _displayBpm = widget.bpm ?? latest['bpm'] ?? 72;
            _displayHrv = widget.hrv ?? latest['hrv'] ?? 35;
            _displayStress =
                widget.stressLevel ?? latest['stressLevel'] ?? 'Moderate';
          } else {
            _displayBpm = widget.bpm ?? 72;
            _displayHrv = widget.hrv ?? 35;
            _displayStress = widget.stressLevel ?? 'Moderate';
          }
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isHigh = _displayStress == 'High';
    final isMod = _displayStress == 'Moderate';
    final stressColor =
        isHigh ? Colors.red : isMod ? Colors.orange : AppColors.primary;
    final bgColor = isHigh
        ? const Color(0xFFFDE8E4)
        : isMod
            ? const Color(0xFFFFF3E0)
            : const Color(0xFFE8F5E9);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/heart-rate'),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: const StudentBottomNav(currentIndex: 1),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header with fixed back button ──────────────
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
                        icon: const Icon(Icons.arrow_back),
                      ),
                      const Text('Stress Analysis',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w700)),
                    ]),
                    const SizedBox(height: 4),
                    const Text('Based on your biometric data',
                        style: TextStyle(color: Colors.black54)),
                    const SizedBox(height: 16),

                    // Main result card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(children: [
                        CircleAvatar(
                          backgroundColor: Colors.white,
                          child: Icon(
                            isHigh
                                ? Icons.warning_amber_rounded
                                : Icons.check_circle_outline,
                            color: stressColor,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          isHigh
                              ? 'High Stress Detected'
                              : isMod
                                  ? 'Moderate Stress'
                                  : 'You\'re Calm',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 22,
                            color: stressColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _metric('Heart Rate', '$_displayBpm BPM'),
                        _metric('HRV Score', '${_displayHrv}ms'),
                        _metric('Stress Level', _displayStress),
                        const SizedBox(height: 16),
                        if (isHigh || isMod)
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => Navigator.pushNamed(
                                  context, '/breathing'),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.orange,
                                  foregroundColor: Colors.white),
                              icon: const Icon(Icons.air),
                              label: const Text('Start Guided Breathing'),
                            ),
                          ),
                        if (!isHigh)
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => Navigator.pushNamed(
                                  context, '/healing-audio'),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white),
                              icon: const Icon(Icons.music_note_outlined),
                              label: const Text('Healing Audio'),
                            ),
                          ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const MessagingScreen(
                                  patientName: 'Dr. Sarah Jenkins',
                                  patientInitials: 'SJ',
                                ),
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1B4332),
                              foregroundColor: Colors.white,
                            ),
                            icon: const Icon(Icons.chat_bubble_outline),
                            label: const Text('Talk to a Counselor'),
                          ),
                        ),
                      ]),
                    ),

                    const SizedBox(height: 16),

                    // History section
                    if (_history.isNotEmpty) ...[
                      const Text('Recent Readings',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 16)),
                      const SizedBox(height: 8),
                      ..._history.map((r) => _historyCard(r)),
                      const SizedBox(height: 16),
                    ],

                    // Medicine recommendations
                    if (isHigh) ...[
                      const Text('Recommended Supplements',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 16)),
                      const SizedBox(height: 4),
                      const Text(
                        'These are general wellness supplements. Consult your doctor before use.',
                        style:
                            TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                      const SizedBox(height: 8),
                      _medicineCard(
                        name: 'Ashwagandha 300mg',
                        desc: 'Adaptogen that reduces cortisol & anxiety',
                        icon: Icons.local_pharmacy_outlined,
                        color: Colors.green,
                      ),
                      _medicineCard(
                        name: 'Magnesium Glycinate 400mg',
                        desc: 'Calms the nervous system & improves sleep',
                        icon: Icons.nightlight_round,
                        color: Colors.indigo,
                      ),
                      _medicineCard(
                        name: 'Omega-3 Fish Oil 1000mg',
                        desc: 'Reduces inflammation linked to stress',
                        icon: Icons.water_drop_outlined,
                        color: Colors.blue,
                      ),
                      _medicineCard(
                        name: 'L-Theanine 200mg',
                        desc: 'Promotes calm focus without drowsiness',
                        icon: Icons.spa_outlined,
                        color: Colors.teal,
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Suggestions
                    const Text('Smart Suggestions',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 16)),
                    const SizedBox(height: 8),
                    if (isHigh) ...[
                      _suggestion('Take a break',
                          subtitle:
                              'Step away from screens for 10 minutes'),
                      _suggestion('Quick meditation',
                          subtitle:
                              'Even 5 minutes reduces cortisol levels'),
                      _suggestion('Go for a walk',
                          subtitle:
                              '4-5 min walk can lower stress significantly'),
                    ] else if (isMod) ...[
                      _suggestion('Deep breathing',
                          subtitle: 'Try the 4-7-8 breathing technique'),
                      _suggestion('Stay hydrated',
                          subtitle:
                              'Dehydration increases stress hormones'),
                    ] else ...[
                      _suggestion('Keep it up!',
                          subtitle:
                              'Your stress levels are well managed'),
                      _suggestion('Stay consistent',
                          subtitle:
                              'Regular monitoring helps track patterns'),
                    ],

                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            Navigator.pushNamed(context, '/heart-rate'),
                        icon: const Icon(Icons.favorite_border),
                        label: const Text('Measure Again'),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _historyCard(Map<String, dynamic> r) {
    final stress = r['stressLevel'] ?? 'Low';
    final isH = stress == 'High';
    final isM = stress == 'Moderate';
    final color = isH ? Colors.red : isM ? Colors.orange : AppColors.primary;
    final ts = r['timestamp'];
    String timeStr = '';
    if (ts != null && ts is Timestamp) {
      final dt = ts.toDate();
      timeStr =
          '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(children: [
        CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(Icons.favorite, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${r['bpm'] ?? '--'} BPM  •  HRV ${r['hrv'] ?? '--'}ms',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  '$stress Stress  •  $timeStr',
                  style: TextStyle(fontSize: 12, color: color),
                ),
              ]),
        ),
      ]),
    );
  }

  Widget _medicineCard({
    required String name,
    required String desc,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(children: [
        CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(name,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13)),
              Text(desc,
                  style: const TextStyle(
                      fontSize: 12, color: Colors.black54)),
            ])),
      ]),
    );
  }

  Widget _metric(String name, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Text(name, style: const TextStyle(color: Colors.black54)),
        const Spacer(),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
      ]),
    );
  }

  Widget _suggestion(String title, {String? subtitle}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child:
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        if (subtitle != null)
          Text(subtitle,
              style:
                  const TextStyle(fontSize: 12, color: Colors.black54)),
      ]),
    );
  }
}