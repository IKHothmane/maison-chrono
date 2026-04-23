import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardRepository {
  const DashboardRepository();

  Future<Map<String, int>> loadCounts() async {
    final client = Supabase.instance.client;
    final products = await client.from('products').select('id');
    final inquiries = await client.from('inquiries').select('id');
    return {
      'products': (products as List).length,
      'inquiries': (inquiries as List).length,
    };
  }
}
