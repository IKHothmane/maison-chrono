class AppEnv {
  static const debugLogsEnabled = true;

  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://rzobrdlvvkscpjvgyxrl.supabase.co',
  );

  static const _supabaseAnonKeyEnv = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJ6b2JyZGx2dmtzY3Bqdmd5eHJsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzYzMDUyNTQsImV4cCI6MjA5MTg4MTI1NH0.Oq-HtYvwgvjkl4ekSSgJFms5B3va4mRlRczwu-RHYX0',
  );

  static const autoLoginEnabled = bool.fromEnvironment('AUTO_LOGIN', defaultValue: false);
  static const _adminEmailEnv = String.fromEnvironment('ADMIN_EMAIL', defaultValue: 'admin@mero.ma');
  static const _adminPasswordEnv =
      String.fromEnvironment('ADMIN_PASSWORD', defaultValue: '123123');

  static const useHardcodedSecrets = false;
  static const _supabaseAnonKeyHardcoded = '';
  static const _adminEmailHardcoded = '';
  static const _adminPasswordHardcoded = '';

  static String get supabaseAnonKey =>
      useHardcodedSecrets ? _supabaseAnonKeyHardcoded : _supabaseAnonKeyEnv;
  static String get adminEmail => useHardcodedSecrets ? _adminEmailHardcoded : _adminEmailEnv;
  static String get adminPassword =>
      useHardcodedSecrets ? _adminPasswordHardcoded : _adminPasswordEnv;

  static bool get isSupabaseConfigured => supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
