import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../matching/data/models/chat_message.dart';
import 'social_repository.dart';

final socialDmRepositoryProvider = Provider<SocialDmRepository>(
  (ref) => SocialDmRepository(
    Supabase.instance.client,
    ref.read(socialRepositoryProvider),
  ),
);

class SocialDmRepository {
  const SocialDmRepository(this._client, this._social);

  final SupabaseClient _client;
  final SocialRepository _social;

  String get _uid {
    final id = _client.auth.currentUser?.id;
    if (id == null) throw const NotAuthenticatedException();
    return id;
  }

  Future<String> getOrCreateThread(String otherUserId) =>
      _social.getOrCreateSocialThread(otherUserId);

  Future<List<ChatMessage>> fetchMessages(String threadId, {int limit = 50}) async {
    try {
      final rows = await _client
          .from('chat_messages')
          .select()
          .eq('thread_id', threadId)
          .order('created_at', ascending: false)
          .limit(limit);
      return (rows as List)
          .cast<Map<String, dynamic>>()
          .map(ChatMessage.fromJson)
          .toList();
    } on PostgrestException catch (e) {
      throw DatabaseException.fromPostgrest(e);
    }
  }

  Future<ChatMessage> sendMessage({
    required String threadId,
    required String content,
  }) async {
    try {
      final row = await _client.from('chat_messages').insert({
        'thread_id': threadId,
        'sender_id': _uid,
        'content': content,
      }).select().single();
      return ChatMessage.fromJson(Map<String, dynamic>.from(row as Map));
    } on PostgrestException catch (e) {
      throw DatabaseException.fromPostgrest(e);
    }
  }

  Stream<List<ChatMessage>> streamMessages(String threadId) {
    return _client
        .from('chat_messages')
        .stream(primaryKey: ['id'])
        .eq('thread_id', threadId)
        .order('created_at', ascending: false)
        .limit(60)
        .map((rows) => rows
            .cast<Map<String, dynamic>>()
            .map(ChatMessage.fromJson)
            .toList());
  }
}
