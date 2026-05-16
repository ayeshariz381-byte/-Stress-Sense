import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/student_bottom_nav.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final name = auth.displayName;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'S';

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () => Navigator.pushNamed(context, '/heart-rate'),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: const StudentBottomNav(currentIndex: 3),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Profile',
                style:
                    TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),

            Center(
              child: Column(children: [
                CircleAvatar(
                  radius: 44,
                  backgroundColor:
                      AppColors.primary.withValues(alpha: 0.15),
                  child: Text(
                    initial,
                    style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary),
                  ),
                ),
                const SizedBox(height: 12),
                Text(name,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w700)),
                const Text('Student',
                    style: TextStyle(color: Colors.black54)),
              ]),
            ),

            const SizedBox(height: 24),

            _infoCard(Icons.person_outline, 'Full Name', name),
            _infoCard(Icons.email_outlined, 'Email',
                auth.email.isEmpty ? 'Not available' : auth.email),
            _infoCard(Icons.school_outlined, 'Role', 'Student'),
            _infoCard(Icons.shield_outlined, 'Data Privacy',
                'Your data is stored securely'),

            const SizedBox(height: 24),

            const Text('Quick Actions',
                style: TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 10),
            _actionTile(context, Icons.favorite_border,
                'Measure Stress', '/heart-rate'),
            _actionTile(context, Icons.music_note_outlined,
                'Healing Audio', '/healing-audio'),
            _actionTile(
                context, Icons.air, 'Breathing Therapy', '/breathing'),
            _actionTile(context, Icons.self_improvement_outlined,
                'Zen Mode', '/zen'),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await auth.logout();
                  if (!context.mounted) return;
                  Navigator.pushNamedAndRemoveUntil(
                      context, '/login', (_) => false);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade50,
                  foregroundColor: Colors.red,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.logout),
                label: const Text('Logout',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 80),
          ]),
        ),
      ),
    );
  }

  Widget _infoCard(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 11, color: Colors.black45)),
                Text(value,
                    style:
                        const TextStyle(fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis),
              ]),
        ),
      ]),
    );
  }

  Widget _actionTile(
      BuildContext context, IconData icon, String label, String route) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(label),
        trailing:
            const Icon(Icons.chevron_right, color: Colors.black38),
        onTap: () => Navigator.pushNamed(context, route),
      ),
    );
  }
}