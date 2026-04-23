import 'package:supabase_flutter/supabase_flutter.dart';

class ProductVideosRepository {
  const ProductVideosRepository();

  String _resolvePublicUrl(Map<String, dynamic> row) {
    final publicUrl = row['public_url']?.toString().trim() ?? '';
    if (publicUrl.isNotEmpty) return publicUrl;
    final storagePath = row['storage_path']?.toString().trim() ?? '';
    if (storagePath.isEmpty) return '';
    return Supabase.instance.client.storage.from('product-videos').getPublicUrl(storagePath);
  }

  Future<List<String>> loadPublicUrls(String productId) async {
    final rows = await Supabase.instance.client
        .from('product_videos')
        .select('public_url, storage_path')
        .eq('product_id', productId)
        .order('sort_order', ascending: true)
        .order('created_at', ascending: true);

    final urls = (rows as List).map((r) {
      final row = (r as Map).cast<String, dynamic>();
      return _resolvePublicUrl(row);
    }).where((v) => v.isNotEmpty).toList();
    return urls;
  }

  Future<List<Map<String, dynamic>>> listAllVideosWithProducts({required bool includeShowOnHome}) async {
    final client = Supabase.instance.client;

    Future<List<Map<String, dynamic>>> runSelect({required bool withShowOnHome}) async {
      final selectList = withShowOnHome
          ? 'id, public_url, storage_path, product_id, sort_order, created_at, show_on_home, products(id, name)'
          : 'id, public_url, storage_path, product_id, sort_order, created_at, products(id, name)';

      var q = client.from('product_videos').select(selectList);
      if (includeShowOnHome && withShowOnHome) {
        q = q.eq('show_on_home', true);
      }
      final rows = await q.order('sort_order', ascending: true).order('created_at', ascending: false);
      return (rows as List)
          .map((r) => (r as Map).cast<String, dynamic>())
          .map((row) {
            final resolved = _resolvePublicUrl(row);
            return {...row, 'public_url': resolved};
          })
          .where((row) => (row['public_url']?.toString().trim() ?? '').isNotEmpty)
          .toList();
    }

    try {
      return await runSelect(withShowOnHome: true);
    } catch (e) {
      final code = e is PostgrestException ? e.code : null;
      if (code == '42703') {
        return await runSelect(withShowOnHome: false);
      }
      rethrow;
    }
  }

  Future<void> persistGlobalSortOrderByIds({required List<String> ids}) async {
    final client = Supabase.instance.client;
    for (var i = 0; i < ids.length; i += 1) {
      final id = ids[i].trim();
      if (id.isEmpty) continue;
      await client.from('product_videos').update({'sort_order': i}).eq('id', id);
    }
  }

  Future<Map<String, bool>?> loadShowOnHomeFlags(String productId) async {
    try {
      final rows = await Supabase.instance.client
          .from('product_videos')
          .select('public_url, show_on_home')
          .eq('product_id', productId);

      final map = <String, bool>{};
      for (final r in (rows as List)) {
        final row = (r as Map).cast<String, dynamic>();
        final url = row['public_url']?.toString().trim() ?? '';
        if (url.isEmpty) continue;
        map[url] = row['show_on_home'] == true;
      }
      return map;
    } catch (e) {
      final code = e is PostgrestException ? e.code : null;
      if (code == '42703') return null;
      rethrow;
    }
  }

  Future<bool> trySetShowOnHome({
    required String productId,
    required String publicUrl,
    required bool showOnHome,
  }) async {
    try {
      await Supabase.instance.client
          .from('product_videos')
          .update({'show_on_home': showOnHome})
          .eq('product_id', productId)
          .eq('public_url', publicUrl);
      return true;
    } catch (e) {
      final code = e is PostgrestException ? e.code : null;
      if (code == '42703') return false;
      rethrow;
    }
  }

  Future<void> insertVideo({
    required String productId,
    required String publicUrl,
    String? storagePath,
    required int sortOrder,
  }) async {
    await Supabase.instance.client.from('product_videos').insert({
      'product_id': productId,
      'public_url': publicUrl,
      'storage_path': storagePath,
      'sort_order': sortOrder,
    });
  }

  Future<void> persistSortOrder({required String productId, required List<String> urls}) async {
    for (var i = 0; i < urls.length; i += 1) {
      final url = urls[i];
      await Supabase.instance.client
          .from('product_videos')
          .update({'sort_order': i})
          .eq('product_id', productId)
          .eq('public_url', url);
    }
  }

  Future<String?> getStoragePath({required String productId, required String publicUrl}) async {
    final row = await Supabase.instance.client
        .from('product_videos')
        .select('storage_path')
        .eq('product_id', productId)
        .eq('public_url', publicUrl)
        .maybeSingle();
    return row?['storage_path']?.toString();
  }

  Future<void> deleteRow({required String productId, required String publicUrl}) async {
    await Supabase.instance.client
        .from('product_videos')
        .delete()
        .eq('product_id', productId)
        .eq('public_url', publicUrl);
  }

  Future<void> removeStoragePath(String storagePath) async {
    await Supabase.instance.client.storage.from('product-videos').remove([storagePath]);
  }
}
