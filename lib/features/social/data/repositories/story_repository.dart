import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/app_exception.dart';

import '../models/story.dart';

final storyRepositoryProvider = Provider<StoryRepository>(
  (ref) => StoryRepository(Supabase.instance.client),
);

class StoryRepository {
  final SupabaseClient _client;

  StoryRepository(this._client);

  String get _uid {
    final id = _client.auth.currentUser?.id;
    if (id == null) throw const NotAuthenticatedException();
    return id;
  }

  /// Fetches active stories from the last 24 hours.
  Future<List<Story>> fetchActiveStories() async {
    final cutoff = DateTime.now().subtract(const Duration(hours: 24)).toUtc().toIso8601String();

    try {
      final rows = await _client
          .from('stories')
          .select('''
            id,
            pet_id,
            image_url,
            created_at,
            viewed_by_users,
            pet:pets(id, name, avatar_url, species)
          ''')
          .gte('created_at', cutoff)
          .order('created_at', ascending: false);

      final list = (rows as List).cast<Map<String, dynamic>>();
      return list.map((r) => Story.fromJson(r)).toList();
    } on PostgrestException catch (e) {
      throw DatabaseException.fromPostgrest(e);
    }
  }

  /// Marks a story as viewed by appending the current user's ID.
  Future<void> markStoryViewed(String storyId) async {
    try {
      await _client.rpc(
        'mark_story_viewed',
        params: {'p_story_id': storyId},
      );
    } on PostgrestException catch (e) {
      throw DatabaseException.fromPostgrest(e);
    }
  }

  /// Creates a new story slide for a pet.
  Future<Story> createStory({
    required String petId,
    required String imageUrl,
  }) async {
    try {
      final row = await _client.from('stories').insert({
        'pet_id': petId,
        'image_url': imageUrl,
      }).select('''
        id,
        pet_id,
        image_url,
        created_at,
        viewed_by_users,
        pet:pets(id, name, avatar_url, species)
      ''').single();

      return Story.fromJson(row);
    } on PostgrestException catch (e) {
      throw DatabaseException.fromPostgrest(e);
    }
  }

  // ── Image Upload ──────────────────────────────────────────────────────────
  static const _allowedExtensions = {'jpg', 'jpeg', 'png', 'webp', 'gif', 'heic'};
  static const _maxImageBytes = 10 * 1024 * 1024; // 10 MB
  static const _mimeTypes = {
    'jpg':  'image/jpeg',
    'jpeg': 'image/jpeg',
    'png':  'image/png',
    'webp': 'image/webp',
    'gif':  'image/gif',
    'heic': 'image/heic',
  };

  /// Uploads an image to the post-images bucket and returns the public URL.
  Future<String> uploadStoryImage(XFile file) async {
    final ext = file.name.split('.').last.toLowerCase();
    if (!_allowedExtensions.contains(ext)) {
      throw const ValidationException(message: 'Unsupported image format. Use JPG, PNG, WebP, GIF, or HEIC.');
    }

    final bytes = await file.readAsBytes();
    if (bytes.length > _maxImageBytes) {
      throw const ValidationException(message: 'Image must be under 10 MB.');
    }

    final path = '$_uid/${DateTime.now().millisecondsSinceEpoch}.$ext';
    try {
      await _client.storage.from('post-images').uploadBinary(
        path,
        bytes,
        fileOptions: FileOptions(contentType: _mimeTypes[ext] ?? 'image/$ext'),
      );
    } on StorageException catch (e) {
      throw NetworkException(message: 'Image upload failed: ${e.message}');
    }
    return _client.storage.from('post-images').getPublicUrl(path);
  }
}
