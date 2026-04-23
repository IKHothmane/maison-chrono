import 'package:supabase_flutter/supabase_flutter.dart';

class ProductsRepository {
  const ProductsRepository();

  Future<List<Map<String, dynamic>>> listForSelection({
    required String search,
    int limit = 500,
    int offset = 0,
  }) async {
    final client = Supabase.instance.client;
    final q = search.trim();
    var query = client.from('products').select('id,name');
    if (q.isNotEmpty) query = query.ilike('name', '%$q%');
    final ordered = query.order('name', ascending: true);
    final from = offset < 0 ? 0 : offset;
    final to = from + (limit <= 0 ? 0 : limit) - 1;
    final res = await ordered.range(from, to);
    return (res as List).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> listForAdmin({required String search}) async {
    final client = Supabase.instance.client;
    Future<List<Map<String, dynamic>>> run(String selectList) async {
      final base = client.from('products').select(selectList);
      final filtered = search.isNotEmpty ? base.ilike('name', '%$search%') : base;
      final res = await filtered.order('created_at', ascending: false);
      return (res as List).cast<Map<String, dynamic>>();
    }

    try {
      return await run(
        'id,name,price,compare_at_price,is_published,images,in_stock,is_featured,brands(name),categories(name)',
      );
    } catch (e) {
      final code = e is PostgrestException ? e.code : null;
      if (code == '42703') {
        return await run('id,name,price,images,in_stock,is_featured,brands(name),categories(name)');
      }
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> listForClient({required String search}) async {
    final client = Supabase.instance.client;
    Future<List<Map<String, dynamic>>> run(String selectList) async {
      final base = client.from('products').select(selectList);
      final filtered = search.isNotEmpty ? base.ilike('name', '%$search%') : base;
      final res = await filtered.order('created_at', ascending: false);
      return (res as List).cast<Map<String, dynamic>>();
    }

    try {
      return await run('id,name,price,compare_at_price,is_published,images,in_stock,brands(name),categories(name)');
    } catch (e) {
      final code = e is PostgrestException ? e.code : null;
      if (code == '42703') {
        return await run('id,name,price,images,in_stock,brands(name),categories(name)');
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getById(String productId) async {
    final client = Supabase.instance.client;
    try {
      return await client
          .from('products')
          .select('id,name,price,compare_at_price,is_published,description,images,in_stock,brands(name),categories(name)')
          .eq('id', productId)
          .maybeSingle();
    } catch (e) {
      final code = e is PostgrestException ? e.code : null;
      if (code == '42703') {
        return await client
            .from('products')
            .select('id,name,price,description,images,in_stock,brands(name),categories(name)')
            .eq('id', productId)
            .maybeSingle();
      }
      rethrow;
    }
  }

  Future<void> deleteById(String productId) async {
    await Supabase.instance.client.from('products').delete().eq('id', productId);
  }

  Future<Map<String, dynamic>> insertReturningId(Map<String, dynamic> payload) async {
    final client = Supabase.instance.client;
    try {
      return await client.from('products').insert(payload).select('id').single();
    } catch (e) {
      final code = e is PostgrestException ? e.code : null;
      if (code == '42703') {
        final fallback = Map<String, dynamic>.from(payload)
          ..remove('compare_at_price')
          ..remove('is_published')
          ..remove('best_seller_rank');
        return await client.from('products').insert(fallback).select('id').single();
      }
      rethrow;
    }
  }

  Future<void> update(String productId, Map<String, dynamic> payload) async {
    final client = Supabase.instance.client;
    try {
      await client.from('products').update(payload).eq('id', productId);
    } catch (e) {
      final code = e is PostgrestException ? e.code : null;
      if (code == '42703') {
        final fallback = Map<String, dynamic>.from(payload)
          ..remove('compare_at_price')
          ..remove('is_published')
          ..remove('best_seller_rank');
        await client.from('products').update(fallback).eq('id', productId);
        return;
      }
      rethrow;
    }
  }

  Future<void> updateImages(String productId, List<String> urls) async {
    await Supabase.instance.client.from('products').update({'images': urls}).eq('id', productId);
  }

  Future<void> setPublished(String productId, bool isPublished) async {
    final client = Supabase.instance.client;
    try {
      await client.from('products').update({'is_published': isPublished}).eq('id', productId);
    } catch (e) {
      final code = e is PostgrestException ? e.code : null;
      if (code == '42703') return;
      rethrow;
    }
  }
}
