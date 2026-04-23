import 'package:supabase_flutter/supabase_flutter.dart';

class PromosRepository {
  const PromosRepository();

  Future<List<Map<String, dynamic>>> listPromoCodes() async {
    final client = Supabase.instance.client;
    Future<List<Map<String, dynamic>>> run(String selectList) async {
      final res = await client.from('promo_codes').select(selectList).order('created_at', ascending: false);
      return (res as List).cast<Map<String, dynamic>>();
    }
    try {
      return await run(
        'id,code,discount_percent,discount_amount,is_active,starts_at,ends_at,max_uses,used_count,created_at',
      );
    } catch (e) {
      final code = e is PostgrestException ? e.code : null;
      if (code == '42703') {
        return await run('id,code,discount_percent,discount_amount,is_active,starts_at,ends_at,created_at');
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createPromoCode({
    required String code,
    int? discountPercent,
    num? discountAmount,
    required int maxUses,
    DateTime? startsAt,
    DateTime? endsAt,
    required bool isActive,
  }) async {
    final payload = <String, dynamic>{
      'code': code.trim().toUpperCase(),
      'discount_percent': discountPercent,
      'discount_amount': discountAmount,
      'max_uses': maxUses,
      'is_active': isActive,
      'starts_at': startsAt?.toIso8601String(),
      'ends_at': endsAt?.toIso8601String(),
    };
    final client = Supabase.instance.client;
    try {
      return await client.from('promo_codes').insert(payload).select('id,code').single();
    } catch (e) {
      final code = e is PostgrestException ? e.code : null;
      if (code == '42703') {
        final fallback = Map<String, dynamic>.from(payload)..remove('max_uses');
        return await client.from('promo_codes').insert(fallback).select('id,code').single();
      }
      rethrow;
    }
  }

  Future<void> setPromoProducts({required String promoCodeId, required List<String> productIds}) async {
    final client = Supabase.instance.client;
    try {
      await client.from('promo_code_products').delete().eq('promo_code_id', promoCodeId);
      if (productIds.isEmpty) return;
      final rows = productIds.map((pid) => {'promo_code_id': promoCodeId, 'product_id': pid}).toList();
      await client.from('promo_code_products').insert(rows);
    } catch (_) {}
  }

  Future<void> setActive({required String promoCodeId, required bool isActive}) async {
    await Supabase.instance.client.from('promo_codes').update({'is_active': isActive}).eq('id', promoCodeId);
  }

  Future<void> deletePromo(String promoCodeId) async {
    await Supabase.instance.client.from('promo_codes').delete().eq('id', promoCodeId);
  }
}
