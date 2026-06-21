import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final careRecommendationRepositoryProvider =
    Provider<CareRecommendationRepository>(
  (_) => CareRecommendationRepository(Supabase.instance.client),
);

class CareRecommendationRepository {
  const CareRecommendationRepository(this._client);

  final SupabaseClient _client;

  Future<List<Map<String, dynamic>>> fetchActiveMedicalVault(String petId) async {
    final rows = await _client
        .from('medical_vault')
        .select('record_type, name, frequency, next_due_at')
        .eq('pet_id', petId)
        .eq('is_active', true)
        .limit(10);
    return (rows as List).map((r) => Map<String, dynamic>.from(r as Map)).toList();
  }

  Future<List<Map<String, dynamic>>> fetchRecentHealthLogs(String petId) async {
    final rows = await _client
        .from('health_logs')
        .select('log_type, weight_kg, severity, diagnosis')
        .eq('pet_id', petId)
        .order('created_at', ascending: false)
        .limit(5);
    return (rows as List).map((r) => Map<String, dynamic>.from(r as Map)).toList();
  }

  Future<List<Map<String, dynamic>>> fetchExistingTasks(String petId) async {
    final rows = await _client
        .from('care_tasks')
        .select('task_type, title')
        .eq('pet_id', petId)
        .limit(50);
    return (rows as List)
        .map((r) => {'type': r['task_type'] as String?, 'title': r['title'] as String?})
        .toList();
  }

  Future<FunctionResponse> invokeRecommendCareTasks(String prompt) =>
      _client.functions
          .invoke('recommend-care-tasks', body: {'prompt': prompt})
          .timeout(const Duration(seconds: 60));
}
