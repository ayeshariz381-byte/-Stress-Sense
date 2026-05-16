import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../widgets/consultant_bottom_nav.dart';

class _Msg {
  final String text;
  final bool isMe; // true = consultant, false = patient (AI)
  final DateTime time;
  _Msg({required this.text, required this.isMe, required this.time});
}

class PatientConsultationScreen extends StatefulWidget {
  const PatientConsultationScreen({super.key});

  @override
  State<PatientConsultationScreen> createState() =>
      _PatientConsultationScreenState();
}

class _PatientConsultationScreenState
    extends State<PatientConsultationScreen> {
  // ── Paste your Google AI Studio key here ──────────────────
  static const String _geminiKey = 'AIzaSyDjMMSZGTWwZYWpGZxQUvplG_uMr1T6zoM';
  static const String _geminiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';

  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  final _medCtrl = TextEditingController();
  bool _aiTyping = false;

  // ── Medication suggestions ─────────────────────────────────
  final List<String> _allMeds = [
    'Ibuprofen 400mg',
    'Magnesium Citrate',
    'Melatonin 5mg',
    'Ashwagandha 300mg',
    'L-Theanine 200mg',
    'Omega-3 1000mg',
    'Vitamin D3',
    'Paracetamol 500mg',
  ];
  List<String> _filteredMeds = [];
  final List<String> _prescribed = [];

  final List<_Msg> _msgs = [
    _Msg(
      text:
          "I've been experiencing persistent headaches for the past two days. It feels like a lot of pressure behind my eyes.",
      isMe: false,
      time: DateTime.now().subtract(const Duration(minutes: 5)),
    ),
    _Msg(
      text:
          'I see. Does the pain worsen with bright light, and have you noticed any changes in your Stress Index today?',
      isMe: true,
      time: DateTime.now().subtract(const Duration(minutes: 4)),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _filteredMeds = List.from(_allMeds);
    _medCtrl.addListener(() {
      final q = _medCtrl.text.toLowerCase();
      setState(() {
        _filteredMeds =
            _allMeds.where((m) => m.toLowerCase().contains(q)).toList();
      });
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    _medCtrl.dispose();
    super.dispose();
  }

  /// Build Gemini-format conversation history
  List<Map<String, dynamic>> _buildGeminiHistory() {
    final history = <Map<String, dynamic>>[];
    for (final m in _msgs) {
      history.add({
        'role': m.isMe ? 'user' : 'model',
        'parts': [
          {'text': m.text}
        ],
      });
    }
    return history;
  }

  Future<String> _getAIReply(String consultantMsg) async {
    try {
      final history = _buildGeminiHistory();
      history.add({
        'role': 'user',
        'parts': [
          {'text': consultantMsg}
        ],
      });

      final response = await http.post(
        Uri.parse('$_geminiUrl?key=$_geminiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'system_instruction': {
            'parts': [
              {
                'text':
                    '''You are a university student with stress-related symptoms talking to your mental health consultant.
Respond naturally as a student describing your symptoms, feelings, and concerns.
Keep replies to 1-2 sentences. Be realistic — mention headaches, exam stress, sleep issues, or anxiety as appropriate.
Never break character. Never give medical advice.'''
              }
            ]
          },
          'contents': history,
          'generationConfig': {
            'maxOutputTokens': 150,
            'temperature': 0.8,
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['candidates'][0]['content']['parts'][0]['text'];
      } else {
        debugPrint('Gemini error: ${response.statusCode} ${response.body}');
        return "I've been feeling a bit better actually, but the headaches are still there when I stare at screens too long.";
      }
    } catch (e) {
      debugPrint('Network error: $e');
      return "Yes, the pain does get worse with light. My stress has been really high with exams coming up.";
    }
  }

  void _sendMessage() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _aiTyping) return;

    setState(() {
      _msgs.add(_Msg(text: text, isMe: true, time: DateTime.now()));
      _ctrl.clear();
      _aiTyping = true;
    });
    _scrollToBottom();

    final reply = await _getAIReply(text);

    if (mounted) {
      setState(() {
        _aiTyping = false;
        _msgs.add(_Msg(text: reply, isMe: false, time: DateTime.now()));
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut);
      }
    });
  }

  void _prescribeMed(String med) {
    if (!_prescribed.contains(med)) {
      setState(() => _prescribed.add(med));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$med prescribed to patient'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: const ConsultantBottomNav(currentIndex: 1),
      body: SafeArea(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // ── Header ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Row(children: [
                const BackButton(),
                const Expanded(
                  child: Text('Patient Consultation',
                      style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w700),
                      overflow: TextOverflow.ellipsis),
                ),
                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/emergency'),
                  child: const Text('Emergency',
                      style: TextStyle(color: Colors.red, fontSize: 12)),
                ),
              ]),
              const Row(children: [
                Icon(Icons.circle, color: Colors.green, size: 10),
                SizedBox(width: 4),
                Text('Active Session'),
              ]),
              const SizedBox(height: 8),
              const Text('REAL-TIME STRESS INDEX',
                  style: TextStyle(color: Colors.black54, fontSize: 12)),
              const Row(children: [
                Text('72',
                    style: TextStyle(
                        fontSize: 38, fontWeight: FontWeight.w700)),
                Text('/100'),
                Spacer(),
                Text('+12% vs last hour',
                    style: TextStyle(fontSize: 12)),
              ]),
              Row(
                children:
                    ['Voice Call', 'Video Call', 'Schedule'].map((label) {
                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(right: 6),
                      child: OutlinedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('$label tapped')),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          padding:
                              const EdgeInsets.symmetric(vertical: 6),
                          textStyle: const TextStyle(fontSize: 11),
                        ),
                        child: Text(label),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 6),
              const Center(
                  child: Text('TODAY',
                      style: TextStyle(
                          color: Colors.black45, fontSize: 12))),
            ]),
          ),

          // ── Chat + Medication scrollable area ───────────────
          Expanded(
            child: SingleChildScrollView(
              controller: _scroll,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                // Chat messages
                ..._msgs.map((m) => _chatBubble(m)),

                // Typing indicator
                if (_aiTyping)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F4F4),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [_dot(), _dot(), _dot()]),
                    ),
                  ),

                const SizedBox(height: 10),

                // ── Medication section ───────────────────────
                const Text('Recommend Medication',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                TextField(
                  controller: _medCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Search supplements or meds...',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
                const SizedBox(height: 8),

                // Filtered med chips
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: _filteredMeds
                      .map((med) => GestureDetector(
                            onTap: () => _prescribeMed(med),
                            child: Chip(
                              label: Text(med),
                              backgroundColor: _prescribed.contains(med)
                                  ? Colors.green.shade100
                                  : null,
                              avatar: _prescribed.contains(med)
                                  ? const Icon(Icons.check,
                                      size: 16, color: Colors.green)
                                  : null,
                            ),
                          ))
                      .toList(),
                ),

                // Prescribed list
                if (_prescribed.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text('Prescribed:',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.green)),
                  const SizedBox(height: 4),
                  ..._prescribed.map((m) => Padding(
                        padding:
                            const EdgeInsets.symmetric(vertical: 2),
                        child: Row(children: [
                          const Icon(Icons.check_circle,
                              color: Colors.green, size: 16),
                          const SizedBox(width: 6),
                          Text(m, style: const TextStyle(fontSize: 13)),
                        ]),
                      )),
                ],

                const SizedBox(height: 80),
              ]),
            ),
          ),

          // ── Message input ────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border:
                  Border(top: BorderSide(color: Color(0xFFEEEEEE))),
            ),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  onSubmitted: (_) => _sendMessage(),
                  enabled: !_aiTyping,
                  decoration: InputDecoration(
                    hintText: _aiTyping
                        ? 'Patient is typing...'
                        : 'Type a message...',
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    border: const OutlineInputBorder(
                        borderSide: BorderSide.none),
                    filled: true,
                    fillColor: const Color(0xFFF5F5F5),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                backgroundColor: _aiTyping
                    ? Colors.grey.shade300
                    : const Color(0xFF4A7C6F),
                child: IconButton(
                  onPressed: _aiTyping ? null : _sendMessage,
                  icon: const Icon(Icons.send, color: Colors.white),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _chatBubble(_Msg m) {
    return Align(
      alignment: m.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 290),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: m.isMe
              ? const Color(0xFFCEE5D6)
              : const Color(0xFFF4F4F4),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
          Text(m.text, style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 4),
          Text(
            '${m.time.hour}:${m.time.minute.toString().padLeft(2, '0')}',
            style:
                const TextStyle(fontSize: 10, color: Colors.black38),
          ),
        ]),
      ),
    );
  }

  Widget _dot() => Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
            color: Colors.black38, shape: BoxShape.circle),
      );
}