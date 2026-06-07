import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/weight_log.dart';

final vitalsRepositoryProvider = Provider<VitalsRepository>(
  (_) => VitalsRepository(Supabase.instance.client),
);

class VitalsRepository {
  const VitalsRepository(this._client);

  final SupabaseClient _client;

  Future<List<WeightLog>> fetchWeightLogs(String petId, {int limit = 30}) async {
    final rows = await _client
        .from('pet_weight_logs')
        .select()
        .eq('pet_id', petId)
        .order('recorded_at', ascending: false)
        .limit(limit);
    return rows.map((r) => WeightLog.fromJson(r)).toList();
  }

  Future<WeightLog> addWeightLog({
    required String petId,
    required double weightKg,
    required DateTime recordedAt,
    String? notes,
  }) async {
    final row = await _client.from('pet_weight_logs').insert({
      'pet_id': petId,
      'weight_kg': weightKg,
      'recorded_at': recordedAt.toIso8601String(),
      // ignore: use_null_aware_elements
      if (notes != null) 'notes': notes,
    }).select().single();
    return WeightLog.fromJson(row);
  }

  Future<void> deleteWeightLog(String id) async {
    await _client.from('pet_weight_logs').delete().eq('id', id);
  }
}
