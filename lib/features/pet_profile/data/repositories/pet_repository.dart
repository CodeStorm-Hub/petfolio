import 'dart:typed_data';

import 'package:petfolio/core/errors/app_exception.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/pet.dart';
import '../models/pet_gender.dart';

class PetRepository {
  const PetRepository(this._client);

  final SupabaseClient _client;

  /// Fetches active (non-archived) pets owned by the currently authenticated user.
  ///
  /// The `pets` SELECT RLS policy allows `is_public = true` rows as well as
  /// owner rows, so we MUST add an explicit [owner_id] filter — otherwise we
  /// would receive every public pet in the database, not just the user's own.
  ///
  /// Pets are ordered by [display_order] (set via [reorderPets]), then by
  /// creation date as a stable tiebreaker.
  Future<List<Pet>> fetchPets({bool includeArchived = false}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    var query = _client.from('pets').select().eq('owner_id', userId);
    if (!includeArchived) {
      query = query.filter('archived_at', 'is', null);
    }
    final rows = await query
        .order('display_order', ascending: true)
        .order('created_at', ascending: true);
    return rows.map(Pet.fromJson).toList();
  }

  /// Persists a new ordering for the user's pets. Caller passes pet IDs in the
  /// order they should appear; the index becomes [display_order].
  ///
  /// Updates each row individually rather than via a CTE so RLS continues to
  /// scope the change to the current user.
  Future<void> reorderPets(List<String> orderedPetIds) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    for (var i = 0; i < orderedPetIds.length; i++) {
      await _client
          .from('pets')
          .update({'display_order': i})
          .eq('id', orderedPetIds[i])
          .eq('owner_id', userId);
    }
  }

  /// Soft-archive a pet. Sets [archived_at] to NOW so the row is filtered out
  /// of [fetchPets] but care history is preserved for audit/recovery.
  Future<Pet> archivePet(String petId) async {
    final row = await _client
        .from('pets')
        .update({'archived_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', petId)
        .select()
        .single();
    return Pet.fromJson(row);
  }

  /// Restore a previously-archived pet.
  Future<Pet> unarchivePet(String petId) async {
    final row = await _client
        .from('pets')
        .update({'archived_at': null})
        .eq('id', petId)
        .select()
        .single();
    return Pet.fromJson(row);
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

  Future<Pet> updateDiscoverable({
    required String petId,
    required bool discoverable,
  }) async {
    final row = await _client
        .from('pets')
        .update({'is_discoverable': discoverable})
        .eq('id', petId)
        .select()
        .single();
    return Pet.fromJson(row);
  }

  Future<Pet> updatePetProfile({
    required String id,
    required String name,
    String? breed,
    String? avatarUrl,
    String? bio,
    DateTime? dateOfBirth,
    required PetGender gender,
    double? weightKg,
    String? activityLevel,
    required bool isPublic,
  }) async {
    final updates = <String, dynamic>{
      'name': name.trim(),
      'breed': breed?.trim().isEmpty ?? true ? null : breed!.trim(),
      'bio': bio?.trim().isEmpty ?? true ? null : bio!.trim(),
      'date_of_birth':
          dateOfBirth?.toIso8601String().split('T').first,
      'gender': gender.dbValue,
      'weight_kg': weightKg,
      'activity_level':
          activityLevel == null || activityLevel.isEmpty ? null : activityLevel,
      'is_public': isPublic,
    };
    if (avatarUrl != null) {
      updates['avatar_url'] = avatarUrl;
    }

    final row =
        await _client.from('pets').update(updates).eq('id', id).select().single();
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
  static const _maxAvatarBytes = 5 * 1024 * 1024;
  static const _allowedExtensions = {'jpg', 'jpeg', 'png', 'webp', 'heic', 'heif'};
  static const _mimeTypes = {
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'png': 'image/png',
    'webp': 'image/webp',
    'heic': 'image/heic',
    'heif': 'image/heic',
  };

  Future<String> uploadAvatar(
    Uint8List bytes,
    String petId, {
    String? fileName,
  }) async {
    if (bytes.isEmpty) {
      throw const ValidationException(message: 'Image file is empty.');
    }
    if (bytes.length > _maxAvatarBytes) {
      throw const ValidationException(message: 'Image must be under 5 MB.');
    }

    final ext = _avatarExtension(fileName);
    if (!_allowedExtensions.contains(ext)) {
      throw const ValidationException(
        message: 'Unsupported image format. Use JPG, PNG, WebP, or HEIC.',
      );
    }

    final path = '$petId/avatar.$ext';
    try {
      await _client.storage.from('pets').uploadBinary(
        path,
        bytes,
        fileOptions: FileOptions(
          contentType: _mimeTypes[ext] ?? 'image/jpeg',
          upsert: true,
        ),
      );
    } on StorageException catch (e) {
      throw NetworkException(message: 'Photo upload failed: ${e.message}');
    }
    return _client.storage.from('pets').getPublicUrl(path);
  }

  static String _avatarExtension(String? fileName) {
    if (fileName != null && fileName.contains('.')) {
      final ext = fileName.split('.').last.toLowerCase();
      if (_allowedExtensions.contains(ext)) return ext == 'jpeg' ? 'jpg' : ext;
    }
    return 'jpg';
  }
}
