import 'package:supabase_flutter/supabase_flutter.dart';

class AdminService {
  const AdminService();

  Future<bool> isAdmin(String userId) async {
    final res = await Supabase.instance.client
        .from('admin_users')
        .select('user_id')
        .eq('user_id', userId)
        .maybeSingle();
    return res != null;
  }
}
