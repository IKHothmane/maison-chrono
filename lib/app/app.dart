import 'package:flutter/material.dart';

import '../features/admin/presentation/admin_gate.dart';
import '../features/auth/presentation/supabase_config_missing_screen.dart';
import 'theme.dart';

class MaisonChronoAdminApp extends StatelessWidget {
  const MaisonChronoAdminApp({super.key, required this.isConfigured});

  final bool isConfigured;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MAISON CHRONO',
      theme: buildAppTheme(),
      home: isConfigured ? const AdminGate() : const SupabaseConfigMissingScreen(),
    );
  }
}
