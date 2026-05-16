import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../theme/app_colors.dart';

class Message {
  final String text;
  final bool isMe;
  final DateTime time;
  Message({required this.text, required this.isMe, required this.time});
}

class MessagingScreen extends StatefulWidget {
  final String patientName;
  final String patientInitials;
  const MessagingScreen(
      {super.key, required this.patientName, required this.patientInitials});

  @override
  State<MessagingScreen> createState() => _MessagingScreenState();
}

class _MessagingScreenState extends State<MessagingScreen> {
  // ── Paste your Google AI Studio key here ──────────────────
  static const String _geminiKey = 'AIzaSyDjMMSZGTWwZYWpGZxQUvplG_uMr1T6zoM';
  static const String _geminiUrl =
    'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';

  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  bool _aiTyping = false;

 final List<Message> _msgs = [
  Message(
    text: "Hello! I'm here to help. How are you feeling today?",
    isMe: false,
    time: DateTime.now().subtract(const Duration(minutes: 1)),
  ),
];
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

  Future<String> _getAIReply(String userMessage) async {
    try {
      final history = _buildGeminiHistory();
      history.add({
        'role': 'user',
        'parts': [
          {'text': userMessage}
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
          '''You are Dr. Ghulam, a compassionate and experienced university mental health consultant chatting with a stressed student.

Your role:
- Read the student's message carefully and respond DIRECTLY to what they said
- Give specific, relevant advice based on their exact concern
- Ask follow-up questions to better understand their situation
- Be empathetic, warm, and professional
- Keep replies to 2-3 sentences maximum
- Never give the same generic response — always address their specific words
- If they mention exams → talk about study stress strategies
- If they mention sleep → address sleep hygiene
- If they mention anxiety → suggest breathing or grounding techniques
- If they mention family/relationship issues → offer emotional support
- If they seem in crisis → recommend immediate help resources
- Never give harmful advice or medication recommendations'''
    }
  ]
},
          'contents': history,
          'generationConfig': {
            'maxOutputTokens': 200,
            'temperature': 0.7,
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['candidates'][0]['content']['parts'][0]['text'];
      } else {
        debugPrint('Gemini error: ${response.statusCode} ${response.body}');
        return "I'm sorry, I didn't catch that. Could you tell me more about what you're going through?";
      }
    } catch (e) {
      debugPrint('Network error: $e');
      return "I understand how you're feeling. Please know that support is always here for you.";
    }
  }

  void _sendMessage() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _aiTyping) return;

    setState(() {
      _msgs.add(Message(text: text, isMe: true, time: DateTime.now()));
      _ctrl.clear();
      _aiTyping = true;
    });

    _scrollToBottom();

    final reply = await _getAIReply(text);

    if (mounted) {
      setState(() {
        _aiTyping = false;
        _msgs.add(Message(text: reply, isMe: false, time: DateTime.now()));
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        titleSpacing: 0,
        title: Row(children: [
          CircleAvatar(
            backgroundColor: const Color(0xFFEDE9FE),
            child: Text(widget.patientInitials,
                style: const TextStyle(
                    color: Color(0xFF6C4FF6),
                    fontWeight: FontWeight.w600,
                    fontSize: 14)),
          ),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.patientName,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700)),
            const Text('Online',
                style: TextStyle(fontSize: 12, color: Colors.green)),
          ]),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.phone_outlined, color: Color(0xFF6C4FF6)),
            onPressed: () => _showCallConfirm(context),
          ),
        ],
      ),
      body: Column(children: [
        Expanded(
          child: ListView.builder(
            controller: _scroll,
            padding: const EdgeInsets.all(16),
            itemCount: _msgs.length + (_aiTyping ? 1 : 0),
            itemBuilder: (ctx, i) {
              if (_aiTyping && i == _msgs.length) {
                return Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      _dot(),
                      _dot(),
                      _dot(),
                    ]),
                  ),
                );
              }

              final m = _msgs[i];
              return Align(
                alignment:
                    m.isMe ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.72),
                  decoration: BoxDecoration(
                    color: m.isMe ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(m.isMe ? 16 : 4),
                      bottomRight: Radius.circular(m.isMe ? 4 : 16),
                    ),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4)
                    ],
                  ),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(m.text,
                            style: TextStyle(
                                color:
                                    m.isMe ? Colors.white : Colors.black87,
                                fontSize: 13)),
                        const SizedBox(height: 4),
                        Text(
                          '${m.time.hour}:${m.time.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(
                              fontSize: 10,
                              color: m.isMe
                                  ? Colors.white70
                                  : Colors.black38),
                        ),
                      ]),
                ),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
          ),
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: _ctrl,
                onSubmitted: (_) => _sendMessage(),
                enabled: !_aiTyping,
                decoration: InputDecoration(
                  hintText: _aiTyping
                      ? 'Dr. Jenkins is typing...'
                      : 'Type a message...',
                  hintStyle: const TextStyle(fontSize: 13),
                  filled: true,
                  fillColor: const Color(0xFFF5F5F5),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _aiTyping ? null : _sendMessage,
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                    color: _aiTyping
                        ? Colors.grey.shade300
                        : AppColors.primary,
                    shape: BoxShape.circle),
                child: const Icon(Icons.send_rounded,
                    color: Colors.white, size: 20),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _dot() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 3),
      width: 8,
      height: 8,
      decoration: const BoxDecoration(
          color: Colors.black38, shape: BoxShape.circle),
    );
  }

  void _showCallConfirm(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.phone_in_talk, color: Colors.green, size: 40),
          const SizedBox(height: 10),
          Text('Call ${widget.patientName}?',
              style: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 16)),
        ]),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text('Calling ${widget.patientName}...')),
              );
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white),
            child: const Text('Call'),
          ),
        ],
      ),
    );
  }
}