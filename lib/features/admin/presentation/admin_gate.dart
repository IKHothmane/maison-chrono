import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/logging/app_log.dart';
import '../../../core/services/admin_service.dart';
import '../../auth/presentation/access_denied_screen.dart';
import '../../auth/presentation/login_screen.dart';
import '../../shell/presentation/home_shell.dart';

class AdminGate extends StatefulWidget {
  const AdminGate({super.key});

  @override
  State<AdminGate> createState() => _AdminGateState();
}

class _AdminGateState extends State<AdminGate> {
  final _adminService = const AdminService();
  StreamSubscription<dynamic>? _authSub;

  @override
  void initState() {
    super.initState();
    appLog('AdminGate init');
    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((event) {
      final hasSession = event.session != null;
      final userId = event.session?.user.id;
      appLog('Auth changed: hasSession=$hasSession userId=${userId == null ? '' : maskId(userId)}');
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;
    appLog('AdminGate build: session=${session == null ? 'null' : 'present'}');
    if (session == null) return const LoginScreen();

    return FutureBuilder<bool>(
      future: _isAdmin(session.user.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (snapshot.hasError) {
          return AccessDeniedScreen(
            title: 'Erreur',
            message: snapshot.error.toString(),
          );
        }

        final isAdmin = snapshot.data == true;
        appLog('AdminGate admin check: userId=${maskId(session.user.id)} isAdmin=$isAdmin');
        if (!isAdmin) {
          return const AccessDeniedScreen(
            title: 'Accès refusé',
            message: 'Ce compte n’est pas autorisé à utiliser le back-office.',
          );
        }

        return const HomeShell();
      },
    );
  }

  Future<bool> _isAdmin(String userId) async {
    try {
      final ok = await _adminService.isAdmin(userId);
      appLog('AdminGate _isAdmin: userId=${maskId(userId)} ok=$ok');
      return ok;
    } catch (e) {
      appLog('AdminGate _isAdmin error: userId=${maskId(userId)} error=$e');
      rethrow;
    }
  }
}
