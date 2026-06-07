import 'package:supabase_flutter/supabase_flutter.dart';

class FakeSupabaseClient implements SupabaseClient {
  FakeSupabaseClient({this.user});

  final User? user;

  @override
  GoTrueClient get auth => _FakeGoTrueClient(user);

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #channel) {
      return _FakeRealtimeChannel();
    }
    return null;
  }
}

class _FakeGoTrueClient implements GoTrueClient {
  _FakeGoTrueClient(this.user);

  final User? user;

  @override
  User? get currentUser => user;

  @override
  Session? get currentSession => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeRealtimeChannel implements RealtimeChannel {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #onPostgresChanges) return this;
    if (invocation.memberName == #subscribe) return this;
    if (invocation.memberName == #unsubscribe) return Future.value('');
    return null;
  }
}
