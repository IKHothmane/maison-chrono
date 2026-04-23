import 'dart:io';

import 'package:image_picker_android/image_picker_android.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_env.dart';
import '../logging/app_log.dart';

Future<bool> initSupabase() async {
  if (Platform.isAndroid) {
    final impl = ImagePickerPlatform.instance;
    if (impl is ImagePickerAndroid) {
      impl.useAndroidPhotoPicker = true;
    }
  }

  final isConfigured = AppEnv.isSupabaseConfigured;
  appLog(
    'Boot: configured=$isConfigured url=${AppEnv.supabaseUrl.isEmpty ? 'EMPTY' : AppEnv.supabaseUrl} anonKeyLen=${AppEnv.supabaseAnonKey.length} keySource=${AppEnv.useHardcodedSecrets ? 'hardcoded' : 'env'} autoLogin=${AppEnv.autoLoginEnabled} email=${maskEmail(AppEnv.adminEmail)}',
  );
  if (!isConfigured) return false;

  await Supabase.initialize(url: AppEnv.supabaseUrl, anonKey: AppEnv.supabaseAnonKey);
  appLog('Supabase init completed');
  return true;
}
