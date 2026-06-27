import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/app_exception.dart';
import '../models/walk_log.dart';

final walkRepositoryProvider = Provider<WalkRepository>(
  (_) => WalkRepository(Supabase.instance.client),
);

class WalkRepository {
  WalkRepository(this._client);

  final SupabaseClient _client;

  Future<void> saveWalk({
    required String petId,
    required DateTime startedAt,
    required DateTime endedAt,
    required int durationSeconds,
    required double distanceMeters,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw const NotAuthenticatedException();
    try {
      await _client.from('walk_logs').insert({
        'pet_id': petId,
        'user_id': userId,
        'started_at': startedAt.toUtc().toIso8601String(),
        'ended_at': endedAt.toUtc().toIso8601String(),
        'duration_seconds': durationSeconds,
        'distance_meters': distanceMeters,
      });
    } on PostgrestException catch (e) {
      throw DatabaseException.fromPostgrest(e);
    }
  }

  Future<List<WalkLog>> fetchRecentWalks(String petId, {int limit = 20}) async {
    try {
      final rows = await _client
          .from('walk_logs')
          .select()
          .eq('pet_id', petId)
          .order('started_at', ascending: false)
          .limit(limit);
      return (rows as List).map((r) => WalkLog.fromMap(r as Map<String, dynamic>)).toList();
    } on PostgrestException catch (e) {
      throw DatabaseException.fromPostgrest(e);
    }
  }
}
