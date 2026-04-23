import 'package:supabase_flutter/supabase_flutter.dart';

class ProductImagesRepository {
  const ProductImagesRepository();

  Future<List<String>?> tryLoadPublicUrls(String productId) async {
    try {
      final rows = await Supabase.instance.client
          .from('product_images')
          .select('public_url')
          .eq('product_id', productId)
          .order('sort_order', ascending: true)
          .order('created_at', ascending: true);
      return (rows as List)
          .map((r) => (r as Map)['public_url']?.toString() ?? '')
          .where((v) => v.isNotEmpty)
          .toList();
    } catch (_) {
      return null;
    }
  }

  Future<void> tryInsert({
    required String productId,
    required String publicUrl,
    String? storagePath,
    required int sortOrder,
  }) async {
    try {
      await Supabase.instance.client.from('product_images').insert({
        'product_id': productId,
        'public_url': publicUrl,
        'storage_path': storagePath,
        'sort_order': sortOrder,
      });
    } catch (_) {}
  }

  Future<void> tryPersistSortOrder({required String productId, required List<String> urls}) async {
    for (var i = 0; i < urls.length; i++) {
      try {
        await Supabase.instance.client
            .from('product_images')
            .update({'sort_order': i})
            .eq('product_id', productId)
            .eq('public_url', urls[i]);
      } catch (_) {}
    }
  }

  Future<String?> tryGetStoragePath({required String productId, required String publicUrl}) async {
    try {
      final row = await Supabase.instance.client
          .from('product_images')
          .select('storage_path')
          .eq('product_id', productId)
          .eq('public_url', publicUrl)
          .maybeSingle();
      return row?['storage_path']?.toString();
    } catch (_) {
      return null;
    }
  }

  Future<void> tryDeleteRow({required String productId, required String publicUrl}) async {
    try {
      await Supabase.instance.client
          .from('product_images')
          .delete()
          .eq('product_id', productId)
          .eq('public_url', publicUrl);
    } catch (_) {}
  }

  Future<void> tryRemoveStoragePath(String storagePath) async {
    try {
      await Supabase.instance.client.storage.from('product-images').remove([storagePath]);
    } catch (_) {}
  }
}
