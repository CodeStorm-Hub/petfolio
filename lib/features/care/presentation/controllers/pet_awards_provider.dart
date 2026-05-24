import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/models/pet_awards_summary.dart';

final petAwardsSummaryProvider =
    FutureProvider.autoDispose.family<PetAwardsSummary, String>((ref, petId) async {
  final client = Supabase.instance.client;
  final raw = await client.rpc(
    'get_pet_awards_summary',
    params: {'p_pet_id': petId},
  );
  if (raw == null) return PetAwardsSummary.empty;
  return PetAwardsSummary.fromJson(Map<String, dynamic>.from(raw as Map));
});
