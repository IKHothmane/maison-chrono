import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/app_env.dart';
import '../../../core/logging/app_log.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (_emailController.text.isEmpty && AppEnv.adminEmail.trim().isNotEmpty) {
      _emailController.text = AppEnv.adminEmail.trim();
    }
    if (_passwordController.text.isEmpty && AppEnv.adminPassword.isNotEmpty) {
      _passwordController.text = AppEnv.adminPassword;
    }

    if (AppEnv.autoLoginEnabled && AppEnv.adminEmail.trim().isNotEmpty && AppEnv.adminPassword.isNotEmpty) {
      appLog('Login init: autoLogin=true email=${maskEmail(AppEnv.adminEmail)}');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _signInWithCredentials(AppEnv.adminEmail.trim(), AppEnv.adminPassword);
      });
    } else {
      appLog(
        'Login init: autoLogin=false email=${maskEmail(AppEnv.adminEmail)} passLen=${AppEnv.adminPassword.length}',
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signInWithCredentials(String email, String password) async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      appLog('Login signIn(auto): email=${maskEmail(email)}');
      await Supabase.instance.client.auth.signInWithPassword(email: email, password: password);
      final userId = Supabase.instance.client.auth.currentSession?.user.id;
      appLog('Login signIn(auto) success: userId=${userId == null ? '' : maskId(userId)}');
    } catch (e) {
      appLog('Login signIn(auto) error: $e');
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signIn() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      appLog('Login signIn: email=${maskEmail(_emailController.text)}');
      await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      final userId = Supabase.instance.client.auth.currentSession?.user.id;
      appLog('Login signIn success: userId=${userId == null ? '' : maskId(userId)}');
    } catch (e) {
      appLog('Login signIn error: $e');
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Connexion admin')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'MAISON CHRONO',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: 0.8),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(labelText: 'Email'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      autofillHints: const [AutofillHints.password],
                      decoration: const InputDecoration(labelText: 'Mot de passe'),
                    ),
                    const SizedBox(height: 14),
                    if (_error != null)
                      Text(
                        _error!,
                        style: TextStyle(color: Theme.of(context).colorScheme.error),
                      ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _signIn,
                      child: Text(_isLoading ? 'Connexion…' : 'Se connecter'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
