import 'package:supabase_flutter/supabase_flutter.dart';

class InquiriesRepository {
  const InquiriesRepository();

  Future<List<Map<String, dynamic>>> listInquiries() async {
    final client = Supabase.instance.client;
    Future<List<Map<String, dynamic>>> run(String selectList) async {
      final res = await client.from('inquiries').select(selectList).order('created_at', ascending: false);
      return (res as List).cast<Map<String, dynamic>>();
    }

    try {
      return await run('id,created_at,name,email,phone,city,address,product_id');
    } catch (e) {
      final code = e is PostgrestException ? e.code : null;
      if (code == '42703') {
        return await run('id,created_at,name,email,phone,product_id');
      }
      rethrow;
    }
  }

  Future<int> countInquiries() async {
    final res = await Supabase.instance.client.from('inquiries').select('id');
    return (res as List).length;
  }
}
