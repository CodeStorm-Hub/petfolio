import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/pet_badge.dart';

final petBadgesProvider = FutureProvider.family<List<PetBadge>, String>((ref, petId) async {
  final res = await Supabase.instance.client
      .from('pet_badges')
      .select()
      .eq('pet_id', petId)
      .order('unlocked_at', ascending: false);

  return (res as List<dynamic>)
      .map((e) => PetBadge.fromJson(e as Map<String, dynamic>))
      .toList();
});
