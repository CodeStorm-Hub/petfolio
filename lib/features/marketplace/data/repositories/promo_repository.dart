import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/promo.dart';

final promoRepositoryProvider = Provider<PromoRepository>(
  (_) => PromoRepository(Supabase.instance.client),
);

class PromoRepository {
  const PromoRepository(this._client);

  final SupabaseClient _client;

  Future<List<Promo>> fetchActivePromos() async {
    final data = await _client
        .from('promos')
        .select()
        .eq('is_active', true)
        .order('created_at', ascending: false);
    return (data as List)
        .map((e) => Promo.fromJson(e))
        .where((p) => !p.isExpired)
        .toList();
  }

  Future<Promo?> validateCode(String code, {String? shopId}) async {
    final data = await _client
        .from('promos')
        .select()
        .eq('code', code.toUpperCase().trim())
        .eq('is_active', true)
        .maybeSingle();
    if (data == null) return null;
    final promo = Promo.fromJson(data);
    if (promo.isExpired) return null;
    if (shopId != null && promo.shopId != null && promo.shopId != shopId) {
      return null;
    }
    return promo;
  }
}
