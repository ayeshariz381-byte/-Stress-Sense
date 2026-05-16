import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/consultant_bottom_nav.dart';

class ConsultantProfileScreen extends StatefulWidget {
  const ConsultantProfileScreen({super.key});

  @override
  State<ConsultantProfileScreen> createState() => _ConsultantProfileScreenState();
}

class _ConsultantProfileScreenState extends State<ConsultantProfileScreen> {
  final _currPassCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confPassCtrl = TextEditingController();
  bool _obscureCurr = true, _obscureNew = true, _obscureConf = true;
  bool _alertNotif = true, _sessionNotif = true, _reportNotif = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _currPassCtrl.dispose();
    _newPassCtrl.dispose();
    _confPassCtrl.dispose();
    super.dispose();
  }

  /// Turns "john.doe@example.com" → "John Doe"
  String _emailToName(String email) {
    final local = email.split('@').first;           // "john.doe"
    return local
        .split(RegExp(r'[._]'))                     // ["john","doe"]
        .map((w) => w.isEmpty
            ? ''
            : w[0].toUpperCase() + w.substring(1)) // ["John","Doe"]
        .join(' ');
  }

  /// Turns "john.doe@example.com" → "JD"
  String _emailToInitials(String email) {
    final parts = email.split('@').first.split(RegExp(r'[._]'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0].substring(0, parts[0].length.clamp(0, 2)).toUpperCase();
  }

  void _changePassword() {
    if (!_formKey.currentState!.validate()) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Password updated successfully'),
        backgroundColor: Colors.green,
      ),
    );
    _currPassCtrl.clear();
    _newPassCtrl.clear();
    _confPassCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final email = auth.email.isNotEmpty ? auth.email : 'consultant@university.edu';
    final displayName = _emailToName(email);
    final initials = _emailToInitials(email);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('My Profile',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700)),
      ),
      bottomNavigationBar: const ConsultantBottomNav(currentIndex: 3),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // ── Profile header (dynamic) ───────────────────────────────────
          Center(
            child: Column(children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: const Color(0xFFEDE9FE),
                child: Text(initials,
                    style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF6C4FF6))),
              ),
              const SizedBox(height: 10),
              Text(displayName,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w700)),
              const Text('Mental Health Consultant',
                  style: TextStyle(color: Colors.black54)),
              const SizedBox(height: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Text('Verified · Active',
                    style: TextStyle(
                        color: Colors.green.shade700,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ),
            ]),
          ),

          const SizedBox(height: 20),
          _sectionTitle('Account Details'),

          // ── Account details (email is dynamic) ────────────────────────
          _infoCard([
            ('Email', email, Icons.email_outlined),
            ('Consultant ID', 'CON-2024-0042', Icons.badge_outlined),
            ('Department', 'Student Wellness', Icons.business_outlined),
            ('Joined', 'August 2022', Icons.calendar_today_outlined),
          ]),

          const SizedBox(height: 16),
          _sectionTitle('Change Password'),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12)),
            child: Form(
              key: _formKey,
              child: Column(children: [
                _passField(
                  'Current password',
                  _currPassCtrl,
                  _obscureCurr,
                  () => setState(() => _obscureCurr = !_obscureCurr),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 10),
                _passField(
                  'New password (min 8 chars)',
                  _newPassCtrl,
                  _obscureNew,
                  () => setState(() => _obscureNew = !_obscureNew),
                  validator: (v) =>
                      (v == null || v.length < 8) ? 'Minimum 8 characters' : null,
                ),
                const SizedBox(height: 10),
                _passField(
                  'Confirm new password',
                  _confPassCtrl,
                  _obscureConf,
                  () => setState(() => _obscureConf = !_obscureConf),
                  validator: (v) =>
                      v != _newPassCtrl.text ? 'Passwords do not match' : null,
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _changePassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Update Password'),
                  ),
                ),
              ]),
            ),
          ),

          const SizedBox(height: 16),
          _sectionTitle('Notifications'),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12)),
            child: Column(children: [
              _switchTile('Critical alerts', 'Always on', _alertNotif,
                  (v) => setState(() => _alertNotif = v)),
              _switchTile('Session reminders', 'Email + push', _sessionNotif,
                  (v) => setState(() => _sessionNotif = v)),
              _switchTile('Weekly report', 'Email only', _reportNotif,
                  (v) => setState(() => _reportNotif = v)),
            ]),
          ),

          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                await context.read<AuthProvider>().logout();
                if (!mounted) return;
                Navigator.pushReplacementNamed(context, '/consultant-login');
              },
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _sectionTitle(String t) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(t,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)));

  Widget _infoCard(List<(String, String, IconData)> rows) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: rows
            .map((r) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(children: [
                    Icon(r.$3, size: 18, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Text(r.$1,
                        style: const TextStyle(
                            color: Colors.black54, fontSize: 13)),
                    const Spacer(),
                    Flexible(
                      child: Text(r.$2,
                          textAlign: TextAlign.end,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w500)),
                    ),
                  ]),
                ))
            .toList(),
      ),
    );
  }

  Widget _passField(
    String hint,
    TextEditingController ctrl,
    bool obscure,
    VoidCallback toggle, {
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      obscureText: obscure,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        suffixIcon: IconButton(
          onPressed: toggle,
          icon: Icon(obscure
              ? Icons.visibility_outlined
              : Icons.visibility_off_outlined),
        ),
        border:
            OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }

  Widget _switchTile(
      String title, String sub, bool val, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500)),
              Text(sub,
                  style: const TextStyle(
                      fontSize: 12, color: Colors.black54)),
            ])),
        Switch(
            value: val,
            onChanged: onChanged,
            activeColor: AppColors.primary),
      ]),
    );
  }
}