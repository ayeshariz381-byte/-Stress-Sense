import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_colors.dart';
import '../widgets/consultant_bottom_nav.dart';

class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key});

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> {
  static const String _demoNumber = '+923144797928';
  List<Map<String, dynamic>> _highRiskStudents = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadHighRiskStudents();
  }

  Future<void> _loadHighRiskStudents() async {
    setState(() => _loading = true);
    try {
      final since = Timestamp.fromDate(
          DateTime.now().subtract(const Duration(hours: 24)));

      // Try fetching only High stress students (requires Firestore composite index)
      // If index not ready yet, falls back to fetching all and filtering in app
      QuerySnapshot<Map<String, dynamic>> snap;
      try {
        snap = await FirebaseFirestore.instance
            .collection('stress_readings')
            .where('stressLevel', isEqualTo: 'High')
            .where('timestamp', isGreaterThan: since)
            .orderBy('timestamp', descending: true)
            .get();
      } catch (_) {
        // Fallback: fetch all recent readings and filter High in app
        final fallback = await FirebaseFirestore.instance
            .collection('stress_readings')
            .where('timestamp', isGreaterThan: since)
            .orderBy('timestamp', descending: true)
            .get();
        snap = fallback;
      }

      final Map<String, Map<String, dynamic>> seen = {};
      for (final doc in snap.docs) {
        final data = doc.data();
        final uid = data['uid'] as String? ?? '';
        final level = data['stressLevel'] as String? ?? '';
        // Keep only High stress entries (handles both query and fallback paths)
        if (uid.isNotEmpty && level == 'High' && !seen.containsKey(uid)) {
          seen[uid] = data;
        }
      }

      final List<Map<String, dynamic>> result = [];
      for (final entry in seen.entries) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(entry.key)
            .get();

        final name = userDoc.data()?['name'] ?? 'Unknown Student';
        final bpm = entry.value['bpm'] ?? '--';
        final ts = entry.value['timestamp'];

        String timeAgo = '';
        if (ts is Timestamp) {
          final diff = DateTime.now().difference(ts.toDate());
          timeAgo = diff.inMinutes < 60
              ? '${diff.inMinutes}m ago'
              : '${diff.inHours}h ago';
        }
        result.add({
          'name': name,
          'bpm': bpm,
          'timeAgo': timeAgo,
        });
      }

      if (mounted) {
        setState(() {
          _highRiskStudents = result;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Emergency load error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _makeCall(
      BuildContext context, String number, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title:
            const Icon(Icons.phone_in_talk, color: Colors.green, size: 36),
        content: Text('Call $name?\n$number', textAlign: TextAlign.center),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white),
            child: const Text('Call Now'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final uri = Uri(scheme: 'tel', path: number);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.red.shade800,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Emergency Protocol',
            style: TextStyle(fontWeight: FontWeight.bold)),
        leading: const Icon(Icons.emergency),
        automaticallyImplyLeading: false,
      ),
      bottomNavigationBar: const ConsultantBottomNav(currentIndex: 2),
      body: RefreshIndicator(
        onRefresh: _loadHighRiskStudents,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMainEmergencyCard(),
              const SizedBox(height: 24),
              const Text('Emergency Contacts',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _contactCard(context, 'Campus Counselling', _demoNumber,
                  'Always available', Icons.psychology),
              _contactCard(context, 'Student Affairs', _demoNumber,
                  'Mon–Fri 8am–6pm', Icons.school),
              _contactCard(context, 'Police / Security', _demoNumber,
                  '24/7', Icons.local_police),
              const SizedBox(height: 24),
              _buildHighRiskHeader(),
              const SizedBox(height: 12),
              _buildStudentList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainEmergencyCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.local_hospital, size: 48, color: Colors.red.shade800),
          const SizedBox(height: 12),
          Text('Campus Health Emergency',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade800)),
          const Text('24/7 Crisis Line · Response < 5 minutes',
              style: TextStyle(color: Colors.black54, fontSize: 13)),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () =>
                  _makeCall(context, _demoNumber, 'Campus Health'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.phone),
              label: const Text('Call Campus Health'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHighRiskHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Expanded(
          child: Text(
            'Active High-Risk Students',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
        const SizedBox(width: 8),
        if (!_loading)
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _highRiskStudents.isEmpty
                  ? Colors.green.shade100
                  : Colors.red.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_highRiskStudents.length} active',
              style: TextStyle(
                color: _highRiskStudents.isEmpty
                    ? Colors.green.shade800
                    : Colors.red.shade800,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStudentList() {
    if (_loading) {
      return const Center(
          child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator()));
    }
    if (_highRiskStudents.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200)),
        child: const Row(children: [
          Icon(Icons.check_circle, color: Colors.green),
          SizedBox(width: 12),
          Expanded(
            child: Text('No high-risk students in the last 24 hours'),
          ),
        ]),
      );
    }
    return Column(
      children: _highRiskStudents
          .map((s) => _alertCard(
                context,
                s['name'],
                'Critical · BPM: ${s['bpm']} · ${s['timeAgo']}',
                _demoNumber,
              ))
          .toList(),
    );
  }

  Widget _contactCard(BuildContext context, String name, String number,
      String hours, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.blueGrey, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14),
                    overflow: TextOverflow.ellipsis),
                Text(hours,
                    style: const TextStyle(
                        color: Colors.black54, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: () => _makeCall(context, number, name),
            style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.green.shade300),
                foregroundColor: Colors.green.shade700,
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8)),
            child: const Text('Call', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _alertCard(BuildContext context, String name, String desc,
      String phone) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade100),
        boxShadow: [
          BoxShadow(
              color: Colors.red.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          const CircleAvatar(
              backgroundColor: Color(0xFFFFEBEE),
              child: Icon(Icons.person, color: Colors.red)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style:
                        const TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis),
                Text(desc,
                    style: const TextStyle(
                        color: Colors.black54, fontSize: 11)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => _makeCall(context, phone, name),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12)),
            child: const Text('Call', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}