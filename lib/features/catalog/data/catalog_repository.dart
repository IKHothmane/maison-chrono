import 'package:supabase_flutter/supabase_flutter.dart';

class CatalogRepository {
  const CatalogRepository();

  Future<List<Map<String, dynamic>>> listBrandsForSelect() async {
    final res = await Supabase.instance.client.from('brands').select('id,name').order('name');
    return (res as List).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> listCategoriesForSelect() async {
    final res = await Supabase.instance.client.from('categories').select('id,name').order('name');
    return (res as List).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> listCategories() async {
    final res = await Supabase.instance.client.from('categories').select('id,name,slug').order('name');
    return (res as List).cast<Map<String, dynamic>>();
  }

  Future<void> createCategory({required String name, required String slug}) async {
    await Supabase.instance.client.from('categories').insert({
      'name': name.trim(),
      'slug': slug.trim(),
    });
  }

  Future<void> deleteCategoryById(String categoryId) async {
    await Supabase.instance.client.from('categories').delete().eq('id', categoryId);
  }
}
