import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/models/pet_mutual_match.dart';

final mutualMatchInsertStreamProvider =
    StreamProvider.family<PetMutualMatch, String>((ref, petId) {
  final client = Supabase.instance.client;
  final controller = StreamController<PetMutualMatch>();

  final channel = client
      .channel('public:matches:inserts:$petId')
      .onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'matches',
        callback: (payload) {
          final row = Map<String, dynamic>.from(payload.newRecord);
          final a = row['pet_a_id'] as String?;
          final b = row['pet_b_id'] as String?;
          if (a != petId && b != petId) return;
          controller.add(PetMutualMatch.fromJson(row));
        },
      )
      .subscribe();

  ref.onDispose(() {
    unawaited(channel.unsubscribe());
    unawaited(controller.close());
  });

  return controller.stream;
});
