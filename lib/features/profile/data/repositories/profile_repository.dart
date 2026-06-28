import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/user_profile.dart';

final profileRepositoryProvider = Provider<ProfileRepository>(
  (_) => ProfileRepository(Supabase.instance.client),
);

class ProfileRepository {
  const ProfileRepository(this._client);

  final SupabaseClient _client;

  Future<UserProfile> fetchProfile(String userId) async {
    final data = await _client
        .from('users')
        .select()
        .eq('id', userId)
        .single();
    return UserProfile.fromJson(data);
  }

  Future<UserProfile> updateProfile(UserProfile profile) async {
    final data = await _client
        .from('users')
        .update({
          'username': profile.username,
          'display_name': profile.displayName,
          'avatar_url': profile.avatarUrl,
          'bio': profile.bio,
          'location': profile.location,
        })
        .eq('id', profile.id)
        .select()
        .single();
    return UserProfile.fromJson(data);
  }
}
