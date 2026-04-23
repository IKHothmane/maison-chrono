import 'package:flutter/material.dart';

class SupabaseConfigMissingScreen extends StatelessWidget {
  const SupabaseConfigMissingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configuration requise')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Supabase n’est pas configuré.',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 10),
                Text(
                  'Lance l’app avec :\n'
                  'flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...',
                ),
                SizedBox(height: 10),
                Text(
                  'Ou renseigne directement la valeur de SUPABASE_ANON_KEY dans lib/main.dart (const supabaseAnonKey).',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
