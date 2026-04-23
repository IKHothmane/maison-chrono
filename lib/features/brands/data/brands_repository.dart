import 'package:supabase_flutter/supabase_flutter.dart';

class BrandsRepository {
  const BrandsRepository();

  Future<List<Map<String, dynamic>>> listBrands() async {
    final res = await Supabase.instance.client.from('brands').select('id,name,logo_url').order('name');
    return (res as List).cast<Map<String, dynamic>>();
  }

  Future<void> createBrand({
    required String name,
    String? logoUrl,
    String? description,
  }) async {
    final payload = <String, dynamic>{
      'name': name.trim(),
      'logo_url': (logoUrl ?? '').trim().isEmpty ? null : logoUrl!.trim(),
      'description': (description ?? '').trim().isEmpty ? null : description!.trim(),
    };
    await Supabase.instance.client.from('brands').insert(payload);
  }

  Future<void> deleteBrandById(String brandId) async {
    await Supabase.instance.client.from('brands').delete().eq('id', brandId);
  }
}
