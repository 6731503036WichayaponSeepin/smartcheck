import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();

  final _auth = AuthService();
  final _fs = FirestoreService();

  bool _loading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final cred = await _auth.register(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );

      await _fs.createUserProfile(
        uid: cred.user!.uid,
        email: cred.user!.email ?? _emailCtrl.text.trim(),
        displayName: _nameCtrl.text.trim(),
      );

      if (!mounted) return;
      Navigator.of(context).pop(); // กลับไปหน้า login
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Register success. Please login.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Register error: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: ListView(
            padding: const EdgeInsets.all(16),
            shrinkWrap: true,
            children: [
              const Text('Create an account', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Display name'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _emailCtrl,
                      decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Email'),
                      validator: (v) => (v == null || !v.contains('@')) ? 'Invalid email' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passCtrl,
                      obscureText: true,
                      decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Password (min 6 chars)'),
                      validator: (v) => (v == null || v.length < 6) ? 'Too short' : null,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loading ? null : _submit,
                      child: Text(_loading ? 'Creating...' : 'Register'),
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}