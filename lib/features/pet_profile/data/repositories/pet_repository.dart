import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/pet.dart';

class PetRepository {
  const PetRepository(this._client);

  final SupabaseClient _client;

  Future<List<Pet>> fetchPets() async {
    final rows = await _client
        .from('pets')
        .select()
        .order('created_at', ascending: true);
    return rows.map(Pet.fromJson).toList();
  }

  Future<Pet> createPet({
    required String name,
    required String species,
    String? breed,
    String? avatarUrl,
  }) async {
    final userId = _client.auth.currentUser!.id;
    final row = await _client.from('pets').insert({
      'owner_id': userId,
      'name': name,
      'species': species,
      if (breed != null && !breed.startsWith("Don't")) 'breed': breed,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
    }).select().single();
    return Pet.fromJson(row);
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
