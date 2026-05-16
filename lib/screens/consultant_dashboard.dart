import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/consultant_bottom_nav.dart';
import 'messaging_screen.dart';

class StudentData {
  final String uid;
  final String name;
  final String email;
  final int? bpm;
  final int? hrv;
  final String? stressLevel;
  final DateTime? lastReading;

  StudentData({
    required this.uid,
    required this.name,
    required this.email,
    this.bpm,
    this.hrv,
    this.stressLevel,
    this.lastReading,
  });

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  Color get statusColor {
    switch (stressLevel) {
      case 'High':
        return Colors.red;
      case 'Moderate':
        return Colors.orange;
      case 'Low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String get statusDesc {
    if (stressLevel == null) return 'No readings yet';
    final ago = lastReading != null ? _timeAgo(lastReading!) : '';
    return '$stressLevel stress • $ago';
  }

  static String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class ConsultantDashboardScreen extends StatefulWidget {
  const ConsultantDashboardScreen({super.key});

  @override
  State<ConsultantDashboardScreen> createState() =>
      _ConsultantDashboardScreenState();
}

class _ConsultantDashboardScreenState
    extends State<ConsultantDashboardScreen> {
  List<StudentData> _students = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final usersSnap = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'student')
          .get();

      final List<StudentData> result = [];
      for (final doc in usersSnap.docs) {
        final data = doc.data();
        final uid = doc.id;
        final name = data['name'] ?? data['email'] ?? 'Unknown';
        final email = data['email'] ?? '';

        final readingSnap = await FirebaseFirestore.instance
            .collection('stress_readings')
            .where('uid', isEqualTo: uid)
            .orderBy('timestamp', descending: true)
            .limit(1)
            .get();

        int? bpm;
        int? hrv;
        String? stressLevel;
        DateTime? lastReading;

        if (readingSnap.docs.isNotEmpty) {
          final r = readingSnap.docs.first.data();
          bpm = r['bpm'] as int?;
          hrv = r['hrv'] as int?;
          stressLevel = r['stressLevel'] as String?;
          final ts = r['timestamp'];
          if (ts is Timestamp) lastReading = ts.toDate();
        }

        result.add(StudentData(
          uid: uid,
          name: name,
          email: email,
          bpm: bpm,
          hrv: hrv,
          stressLevel: stressLevel,
          lastReading: lastReading,
        ));
      }

      const order = {'High': 0, 'Moderate': 1, 'Low': 2};
      result.sort((a, b) {
        final aO = order[a.stressLevel] ?? 3;
        final bO = order[b.stressLevel] ?? 3;
        return aO.compareTo(bO);
      });

      setState(() {
        _students = result;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load students: $e';
        _loading = false;
      });
    }
  }

  void _showCallDialog(BuildContext context, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.phone_in_talk, color: Colors.green, size: 40),
          const SizedBox(height: 10),
          Text('Call $name?',
              style: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 4),
          const Text('via in-app call',
              style: TextStyle(color: Colors.black54, fontSize: 13)),
        ]),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Calling $name...')),
              );
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white),
            icon: const Icon(Icons.phone),
            label: const Text('Call Now'),
          ),
        ],
      ),
    );
  }

  void _showNotifications(BuildContext context) {
    final highStress =
        _students.where((s) => s.stressLevel == 'High').toList();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Notifications',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            if (highStress.isEmpty)
              const ListTile(
                leading: Icon(Icons.check_circle, color: Colors.green),
                title: Text('No critical alerts right now'),
              )
            else
              ...highStress.map((s) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.warning_amber_rounded,
                        color: Colors.red),
                    title: Text('${s.name} — High stress alert',
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500)),
                    subtitle: Text(s.statusDesc,
                        style: const TextStyle(fontSize: 11)),
                  )),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final highStressStudents =
        _students.where((s) => s.stressLevel == 'High').toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: const ConsultantBottomNav(currentIndex: 0),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadStudents,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ──
                  Row(children: [
                    const CircleAvatar(
                      backgroundColor: Color(0xFFEDE9FE),
                      child: Text('DR',
                          style: TextStyle(
                              color: Color(0xFF6C4FF6),
                              fontWeight: FontWeight.w700,
                              fontSize: 14)),
                    ),
                    const SizedBox(width: 10),
                    Consumer<AuthProvider>(
                      builder: (ctx, auth, _) {
                        String name = 'Consultant';
                        if (auth.email.isNotEmpty) {
                          name = auth.email
                              .split('@')
                              .first
                              .replaceAll('.', ' ')
                              .split(' ')
                              .map((w) => w.isNotEmpty
                                  ? w[0].toUpperCase() + w.substring(1)
                                  : w)
                              .join(' ');
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700)),
                            const Text('Mental Health Consultant',
                                style: TextStyle(
                                    color: Colors.black54,
                                    fontSize: 12)),
                          ],
                        );
                      },
                    ),
                    const Spacer(),
                    Stack(children: [
                      IconButton(
                        onPressed: () => _showNotifications(context),
                        icon: const Icon(Icons.notifications_none),
                      ),
                      if (highStressStudents.isNotEmpty)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle),
                          ),
                        ),
                    ]),
                  ]),
                  const SizedBox(height: 14),

                  // ── Emergency Banner ──
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: const Color(0xFFFDE8E4),
                        borderRadius: BorderRadius.circular(12)),
                    child: Row(children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Emergency Protocol',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: Colors.deepOrange)),
                            Text('Direct line to Campus Health',
                                style: TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () =>
                            Navigator.pushNamed(context, '/emergency'),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            foregroundColor: Colors.white),
                        child: const Text('CALL NOW'),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 16),

                  // ── REAL TIME EMERGENCY ALERTS ──────────────
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('emergency_alerts')
                        .where('isResolved', isEqualTo: false)
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                    builder: (ctx, snap) {
                      if (!snap.hasData || snap.data!.docs.isEmpty) {
                        return const SizedBox();
                      }
                      final alerts = snap.data!.docs;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFDE8E4),
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: Colors.red.shade300),
                        ),
                        child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                          Row(children: [
                            const Icon(Icons.warning_amber_rounded,
                                color: Colors.red),
                            const SizedBox(width: 8),
                            Text(
                              '${alerts.length} Emergency Alert${alerts.length > 1 ? 's' : ''}!',
                              style: const TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16),
                            ),
                          ]),
                          const SizedBox(height: 10),
                          ...alerts.map((doc) {
                            final data =
                                doc.data() as Map<String, dynamic>;
                            final name =
                                data['studentName'] ?? 'Unknown';
                            final bpm = data['bpm'] ?? '--';
                            final ts = data['timestamp'];
                            String timeAgo = '';
                            if (ts is Timestamp) {
                              final diff = DateTime.now()
                                  .difference(ts.toDate());
                              timeAgo = diff.inMinutes < 60
                                  ? '${diff.inMinutes}m ago'
                                  : '${diff.inHours}h ago';
                            }
                            return Container(
                              margin:
                                  const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius:
                                    BorderRadius.circular(10),
                              ),
                              child: Row(children: [
                                const CircleAvatar(
                                  backgroundColor:
                                      Color(0xFFFFEBEE),
                                  child: Icon(Icons.person,
                                      color: Colors.red),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment
                                                .start,
                                        children: [
                                      Text(name,
                                          style: const TextStyle(
                                              fontWeight:
                                                  FontWeight.w700)),
                                      Text(
                                          'BPM: $bpm • $timeAgo',
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color:
                                                  Colors.black54)),
                                    ])),
                                TextButton(
                                  onPressed: () {
                                    doc.reference.update(
                                        {'isResolved': true});
                                  },
                                  child: const Text('Resolve',
                                      style: TextStyle(
                                          color: Colors.green)),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => MessagingScreen(
                                        patientName: name,
                                        patientInitials:
                                            name.isNotEmpty
                                                ? name[0]
                                                    .toUpperCase()
                                                : '?',
                                      ),
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                      padding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 10)),
                                  child: const Text('Chat',
                                      style:
                                          TextStyle(fontSize: 12)),
                                ),
                              ]),
                            );
                          }),
                        ]),
                      );
                    },
                  ),

                  // ── Loading / Error states ──
                  if (_loading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Column(children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 12),
                          Text('Loading student data...'),
                        ]),
                      ),
                    )
                  else if (_error != null)
                    Center(
                      child: Padding(
                        padding:
                            const EdgeInsets.symmetric(vertical: 40),
                        child: Column(children: [
                          const Icon(Icons.error_outline,
                              color: Colors.red, size: 40),
                          const SizedBox(height: 8),
                          Text(_error!,
                              textAlign: TextAlign.center,
                              style:
                                  const TextStyle(color: Colors.red)),
                          const SizedBox(height: 12),
                          ElevatedButton(
                              onPressed: _loadStudents,
                              child: const Text('Retry')),
                        ]),
                      ),
                    )
                  else ...[
                    // ── Active Alerts ──
                    Row(children: [
                      const Text('Active Alerts',
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700)),
                      const Spacer(),
                      if (highStressStudents.isNotEmpty)
                        Chip(
                          label: Text(
                              '${highStressStudents.length} Critical',
                              style: const TextStyle(
                                  color: Colors.red, fontSize: 12)),
                          backgroundColor: const Color(0xFFFFEBEE),
                        ),
                    ]),
                    const SizedBox(height: 8),
                    if (highStressStudents.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12)),
                        child: const Row(children: [
                          Icon(Icons.check_circle,
                              color: Colors.green),
                          SizedBox(width: 10),
                          Text('No critical alerts right now'),
                        ]),
                      )
                    else
                      ...highStressStudents
                          .map((s) => _alertCard(context, s)),

                    const SizedBox(height: 16),

                    // ── All Students ──
                    Row(children: [
                      const Text('All Students',
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700)),
                      const Spacer(),
                      Text('${_students.length} total',
                          style: const TextStyle(
                              color: Colors.black54, fontSize: 13)),
                    ]),
                    const SizedBox(height: 8),
                    if (_students.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12)),
                        child: const Center(
                          child: Text('No students registered yet.',
                              style:
                                  TextStyle(color: Colors.black54)),
                        ),
                      )
                    else
                      ..._students
                          .map((s) => _studentTile(context, s)),
                  ],

                  const SizedBox(height: 16),

                  // ── Logout ──
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await context.read<AuthProvider>().logout();
                        if (!context.mounted) return;
                        Navigator.pushReplacementNamed(
                            context, '/consultant-login');
                      },
                      icon: const Icon(Icons.logout),
                      label: const Text('Logout'),
                    ),
                  ),
                ]),
          ),
        ),
      ),
    );
  }

  Widget _alertCard(BuildContext context, StudentData s) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child:
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            backgroundColor: const Color(0xFFFFEBEE),
            child: Text(s.initials,
                style: const TextStyle(
                    color: Colors.red, fontWeight: FontWeight.w700)),
          ),
          title: Text(s.name,
              style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text(
              'High Stress • BPM: ${s.bpm ?? "--"} • HRV: ${s.hrv ?? "--"}\n${s.lastReading != null ? StudentData._timeAgo(s.lastReading!) : ""}'),
          isThreeLine: true,
          trailing:
              const Icon(Icons.circle, color: Colors.red, size: 10),
        ),
        const Text('HRV VARIABILITY',
            style: TextStyle(fontSize: 11, color: Colors.black54)),
        const SizedBox(height: 8),
        SizedBox(
          height: 80,
          child: BarChart(
            BarChartData(
              borderData: FlBorderData(show: false),
              gridData: const FlGridData(show: false),
              titlesData: const FlTitlesData(show: false),
              barGroups: List.generate(
                7,
                (i) => BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: (s.hrv?.toDouble() ?? 20) *
                          (0.5 + i * 0.1),
                      color: i.isOdd
                          ? Colors.orange.shade200
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _showCallDialog(context, s.name),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white),
              icon: const Icon(Icons.call),
              label: Text('Call ${s.name.split(' ').first}'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MessagingScreen(
                    patientName: s.name,
                    patientInitials: s.initials,
                  ),
                ),
              ),
              icon: const Icon(Icons.message_outlined),
              label: const Text('Message'),
            ),
          ),
        ]),
      ]),
    );
  }

  Widget _studentTile(BuildContext context, StudentData s) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(10)),
      child: Row(children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: const Color(0xFFEDE9FE),
          child: Text(s.initials,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6C4FF6))),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                Row(children: [
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(right: 4),
                    decoration: BoxDecoration(
                        color: s.statusColor,
                        shape: BoxShape.circle),
                  ),
                  Text(s.statusDesc,
                      style: const TextStyle(
                          color: Colors.black54, fontSize: 12)),
                ]),
                if (s.bpm != null)
                  Text('BPM: ${s.bpm}  •  HRV: ${s.hrv}',
                      style: const TextStyle(
                          color: Colors.black38, fontSize: 11)),
              ]),
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.black54),
          onSelected: (val) {
            if (val == 'call') {
              _showCallDialog(context, s.name);
            } else if (val == 'message') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MessagingScreen(
                    patientName: s.name,
                    patientInitials: s.initials,
                  ),
                ),
              );
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(
                value: 'call',
                child: Row(children: [
                  Icon(Icons.phone, size: 18),
                  SizedBox(width: 8),
                  Text('Call'),
                ])),
            PopupMenuItem(
                value: 'message',
                child: Row(children: [
                  Icon(Icons.message, size: 18),
                  SizedBox(width: 8),
                  Text('Message'),
                ])),
          ],
        ),
      ]),
    );
  }
}