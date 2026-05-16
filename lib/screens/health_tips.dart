import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/student_bottom_nav.dart';

class HealthTipsScreen extends StatelessWidget {
  const HealthTipsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: const StudentBottomNav(currentIndex: 3),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: const [
              BackButton(),
              Text('Health & Tips', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
              Spacer(),
              Icon(Icons.more_horiz),
            ]),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFFBE7D8), borderRadius: BorderRadius.circular(12)),
              child: const Text('Important: Consult a medical professional or university health services before taking any medication or supplements'),
            ),
            const SizedBox(height: 14),
            const Text('"A calm mind brings inner strength and self-confidence."', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.black54)),
            const SizedBox(height: 18),
            const Text('NATURAL SUPPLEMENTS (STUDENT FOCUSED)', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            _item('Magnesium Glycinate', 'Supports relaxation & better sleep'),
            _item('Chamomile Tea', 'Gently reduces anxiety and study stress'),
            _item('L-Theanine', 'Promotes focus without jitters'),
            const SizedBox(height: 14),
            const Text('PRESCRIBED REMINDERS', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary)),
            _item('Propranolol (10mg)', 'Next dose: 8:00 PM'),
            _item('Sertraline (50mg)', 'Taken at 08:30 AM ✓'),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {},
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                icon: const Icon(Icons.local_hospital_outlined),
                label: const Text('Find a Campus Clinic'),
              ),
            )
          ]),
        ),
      ),
    );
  }

  static Widget _item(String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFFF8F9F7), borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        const Icon(Icons.eco_outlined, color: AppColors.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.black54)),
          ]),
        ),
      ]),
    );
  }
}
