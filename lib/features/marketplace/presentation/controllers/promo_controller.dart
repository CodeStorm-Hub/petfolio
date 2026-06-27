import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/promo.dart';
import '../../data/repositories/promo_repository.dart';

// ── Promo filter ──────────────────────────────────────────────────────────────

class PromoFilterNotifier extends Notifier<String> {
  @override
  String build() => 'all';

  void setFilter(String filter) => state = filter;
  void reset() => state = 'all';
}

final promoFilterProvider =
    NotifierProvider<PromoFilterNotifier, String>(PromoFilterNotifier.new);

// ── Promo list ────────────────────────────────────────────────────────────────

final promoListProvider =
    AsyncNotifierProvider<PromoListNotifier, List<Promo>>(
      PromoListNotifier.new,
    );

final filteredPromosProvider = Provider<List<Promo>>((ref) {
  final allPromos = ref.watch(promoListProvider).value ?? [];
  final filter = ref.watch(promoFilterProvider);
  if (filter == 'all') return allPromos;
  return allPromos.where((p) => p.category == filter).toList();
});

class PromoListNotifier extends AsyncNotifier<List<Promo>> {
  @override
  Future<List<Promo>> build() =>
      ref.read(promoRepositoryProvider).fetchActivePromos();
}
