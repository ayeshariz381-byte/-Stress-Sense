import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class ConsultantLoginScreen extends StatefulWidget {
  const ConsultantLoginScreen({super.key});
  @override
  State<ConsultantLoginScreen> createState() => _ConsultantLoginScreenState();
}

class _ConsultantLoginScreenState extends State<ConsultantLoginScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _obscure    = true;
  bool _rememberMe = true;
  bool _loading    = false;

  // Set your primary color here or import it correctly
  final Color primaryColor = const Color(0xFF1F6F5F);

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email is required';
    final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!regex.hasMatch(v.trim())) return 'Enter a valid email address';
    return null;
  }

  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Password is required';
    if (v.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    // Ensure loginAsConsultant exists in your AuthProvider
    final error = await context.read<AuthProvider>().loginAsConsultant(
      email:      _emailCtrl.text.trim(),
      password:   _passCtrl.text.trim(),
      rememberMe: _rememberMe,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
    } else {
      // Make sure this route is defined in main.dart
      Navigator.pushReplacementNamed(context, '/consultant-dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back)),
                const Text('StressSense',
                    style: TextStyle(
                        fontSize: 24, fontWeight: FontWeight.w700)),
              ]),
              const SizedBox(height: 10),
              Container(
                height: 140,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFEDE9FE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(Icons.psychology,
                      size: 64, color: primaryColor),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Consultant Login',
                  style: TextStyle(
                      fontSize: 30, fontWeight: FontWeight.w700)),
              const Text('Securely access student insights',
                  style: TextStyle(color: Colors.black54)),
              const SizedBox(height: 16),
              
              // Demo helper box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Text(
                  'Demo: sarah.jenkins@university.edu\nPassword: any (min 6 chars)',
                  style: TextStyle(fontSize: 13, color: Colors.blue.shade800),
                ),
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                validator: _validateEmail,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _passCtrl,
                obscureText: _obscure,
                validator: _validatePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => _obscure = !_obscure),
                    icon: Icon(_obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined),
                  ),
                ),
              ),

              Row(children: [
                Checkbox(
                  value: _rememberMe,
                  onChanged: (v) => setState(() => _rememberMe = v ?? false),
                  activeColor: primaryColor,
                ),
                const Text('Remember me'),
                const Spacer(),
                TextButton(
                  onPressed: () async {
                    final email = _emailCtrl.text.trim();
                    if (email.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter email first')),
                      );
                      return;
                    }
                    await context.read<AuthProvider>().resetPassword(email);
                  },
                  child: const Text('Forgot password?'),
                ),
              ]),

              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: _loading
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.lock_outline),
                  label: Text(_loading ? 'Logging in...' : 'Secure Login',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              
              const SizedBox(height: 24),
              const Center(
                child: Text(
                  'Unauthorised access is strictly prohibited.',
                  style: TextStyle(fontSize: 11, color: Colors.black38),
                ),
              ),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                  child: const Text('Switch to Student Login'),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}