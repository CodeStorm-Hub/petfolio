import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/pet.dart';

class PetRepository {
  const PetRepository(this._client);

  final SupabaseClient _client;

  /// Fetches all pets owned by the currently authenticated user.
  ///
  /// The `pets` SELECT RLS policy allows `is_public = true` rows as well as
  /// owner rows, so we MUST add an explicit [owner_id] filter — otherwise we
  /// would receive every public pet in the database, not just the user's own.
  Future<List<Pet>> fetchPets() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final rows = await _client
        .from('pets')
        .select()
        .eq('owner_id', userId)
        .order('created_at', ascending: true);
    return rows.map(Pet.fromJson).toList();
  }

  Future<Pet> createPet({
    required String name,
    required String species,
    String? breed,
    String? avatarUrl,
    String? bio,
    DateTime? dateOfBirth,
    double? weightKg,
    String? activityLevel,
  }) async {
    final userId = _client.auth.currentUser!.id;
    final row = await _client.from('pets').insert({
      'owner_id': userId,
      'name': name,
      'species': species,
      // ignore: use_null_aware_elements
      if (breed != null && !breed.startsWith("Don't")) 'breed': breed,
      // ignore: use_null_aware_elements
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      // ignore: use_null_aware_elements
      if (bio != null) 'bio': bio,
      // ignore: use_null_aware_elements
      if (dateOfBirth != null)
        'date_of_birth': dateOfBirth.toIso8601String().split('T').first,
      // ignore: use_null_aware_elements
      if (weightKg != null) 'weight_kg': weightKg,
      // ignore: use_null_aware_elements
      if (activityLevel != null) 'activity_level': activityLevel,
    }).select().single();
    return Pet.fromJson(row);
  }

  Future<Pet> updatePet({
    required String id,
    String? name,
    String? breed,
    String? avatarUrl,
    String? bio,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (breed != null) updates['breed'] = breed;
    if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
    if (bio != null) updates['bio'] = bio;
    
    if (updates.isEmpty) throw Exception('No fields to update');
    
    final row = await _client.from('pets').update(updates).eq('id', id).select().single();
    return Pet.fromJson(row);
  }

  Future<void> writeTargetWeight(String petId, double targetWeightKg) async {
    final userId = _client.auth.currentUser!.id;
    await _client.from('health_vitals').insert({
      'pet_id': petId,
      'recorded_by': userId,
      'vital_type': 'weight',
      'value': targetWeightKg,
      'unit': 'kg',
      'notes': 'goal',
    });
  }

  Future<void> updateAvatarUrl(String petId, String avatarUrl) async {
    await _client
        .from('pets')
        .update({'avatar_url': avatarUrl})
        .eq('id', petId);
  }

  /// Uploads [bytes] to Supabase Storage under the `pets` bucket and returns
  /// the public URL. The `pets` bucket must be created in the Supabase dashboard
  /// with public read access enabled.
  Future<String> uploadAvatar(Uint8List bytes, String petId) async {
    final path = '$petId/avatar.jpg';
    await _client.storage.from('pets').uploadBinary(
      path,
      bytes,
      fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
    );
    return _client.storage.from('pets').getPublicUrl(path);
  }
}
