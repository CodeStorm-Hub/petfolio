import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/models/care_streak.dart';

final careStreakRealtimeProvider =
    StreamProvider.autoDispose.family<CareStreak, String>((ref, petId) {
  return Supabase.instance.client
      .from('care_streaks')
      .stream(primaryKey: ['pet_id'])
      .eq('pet_id', petId)
      .map((rows) {
        if (rows.isEmpty) {
          return CareStreak(
            petId: petId,
            currentStreak: 0,
            lastCompletionDate: null,
            bestStreak: 0,
          );
        }
        return CareStreak.fromJson(
          Map<String, dynamic>.from(rows.first as Map),
        );
      });
});
