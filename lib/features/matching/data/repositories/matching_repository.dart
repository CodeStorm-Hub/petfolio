import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/discovery_candidate.dart';

final matchingRepositoryProvider = Provider<MatchingRepository>(
  (ref) => MatchingRepository(Supabase.instance.client),
);

/// Repository for the Playdates (Discovery) feature.
///
/// ## Candidate fetch
/// [fetchCandidates] runs two queries:
///   1. Collect all `target_pet_id` values from `match_requests` where
///      `requester_pet_id = activePetId` — these are already-swiped pets.
///   2. Fetch public `pets` rows, excluding the active pet and the swiped set,
///      joined with `users` to get the owner's display info.
///
/// ## Swipe recording
/// Right swipes (`match`, `superPaw`) and wave swipes (`greet`) insert a row
/// into `match_requests` (status = 'pending', match_type = 'playdate').
/// Pass swipes are intentionally not written — there is no `swipes` table in
/// the schema, and recording rejections is a separate product decision.
///
/// ## Realtime
/// [chatThreadStream] subscribes to `chat_threads` via Supabase Realtime.
class MatchingRepository {
  MatchingRepository(this._client);

  final SupabaseClient _client;

  String? get _uid => _client.auth.currentUser?.id;

  // ── Candidate fetch ───────────────────────────────────────────────────────

  /// Returns up to [limit] discovery candidates for [activePetId].
  ///
  /// Candidates are public pets that the active pet has not yet swiped on
  /// (i.e., no row in `match_requests` with `requester_pet_id = activePetId`
  /// and `target_pet_id = candidate.id`).
  Future<List<DiscoveryCandidate>> fetchCandidates({
    required String activePetId,
    int limit = 20,
  }) async {
    if (_uid == null) return [];

    // 1. Collect already-swiped target IDs so we can exclude them.
    final swipedRows = await _client
        .from('match_requests')
        .select('target_pet_id')
        .eq('requester_pet_id', activePetId);

    final swipedIds = (swipedRows as List)
        .cast<Map<String, dynamic>>()
        .map((r) => r['target_pet_id'] as String)
        .toSet();

    // 2. Fetch qualifying pets joined with their owner's user record.
    //    PostgREST embedded resource syntax: `owner:users!pets_owner_id_fkey`
    var query = _client.from('pets').select(
          'id, owner_id, name, species, breed, date_of_birth, avatar_url, bio, '
          'owner:users!pets_owner_id_fkey(id, username, display_name)',
        );

    query = query.eq('is_public', true).neq('id', activePetId);

    // NOT IN filter — PostgREST syntax: .not('col', 'in', '(v1,v2,...)')
    if (swipedIds.isNotEmpty) {
      query = query.not('id', 'in', '(${swipedIds.join(',')})');
    }

    final rows = await query
        .order('created_at', ascending: false)
        .limit(limit);

    return (rows as List)
        .cast<Map<String, dynamic>>()
        .map(_rowToCandidate)
        .toList(growable: false);
  }

  DiscoveryCandidate _rowToCandidate(Map<String, dynamic> r) {
    final owner = (r['owner'] as Map?)?.cast<String, dynamic>() ?? const {};
    final ownerName =
        (owner['display_name'] as String?) ?? (owner['username'] as String?) ?? '?';
    final ownerInitial = ownerName.isNotEmpty ? ownerName[0].toUpperCase() : '?';

    final species = (r['species'] as String? ?? 'dog').toLowerCase();
    final (gradient, subject) = _paletteFor(species);

    return DiscoveryCandidate(
      petId: r['id'] as String,
      ownerUserId: owner['id'] as String?,
      name: (r['name'] as String?) ?? 'Unknown',
      age: _ageString(r['date_of_birth'] as String?),
      species: species,
      breed: (r['breed'] as String?) ?? _defaultBreed(species),
      // Task 3 — fuzzy location: deterministic bucket from the UUID, never an
      // address.  The pets table has no location column; even if it did we
      // would not expose it here.
      distance: _fuzzyDistance(r['id'] as String),
      ownerInitial: ownerInitial,
      verified: false, // no verified column yet; extend when available
      traits: _traitsFor(species),
      bio: (r['bio'] as String?) ?? _defaultBio(species),
      playStyle: _defaultPlayStyle(species),
      energy: _defaultEnergy(species),
      bestWith: _defaultBestWith(species),
      vaccinated: true,
      gradientColors: gradient,
      subjectColor: subject,
      avatarUrl: r['avatar_url'] as String?,
    );
  }

  // ── Swipe recording ───────────────────────────────────────────────────────

  /// Records a swipe and, for positive actions, inserts a `match_requests` row.
  ///
  /// * `match` / `superPaw` → INSERT into `match_requests` (status='pending').
  /// * `greet`              → INSERT with a 👋 message.
  /// * `pass`               → no DB write (no rejections table in schema).
  ///
  /// Errors are caught and logged so a failed network call never crashes the
  /// swipe animation.
  Future<void> recordSwipe({
    required String swiperPetId,
    required String swipedPetId,
    required String swipedOwnerUserId,
    required String action,
  }) async {
    try {
      final uid = _uid;
      if (uid == null) return;

      // Skip demo cards — their IDs are not real UUIDs in the database.
      if (swipedPetId.startsWith('demo-') || swipedOwnerUserId.isEmpty) return;

      switch (action) {
        case 'match':
        case 'superPaw':
          await _client.from('match_requests').insert({
            'requester_id': uid,
            'target_id': swipedOwnerUserId,
            'requester_pet_id': swiperPetId,
            'target_pet_id': swipedPetId,
            'match_type': 'playdate',
            'status': 'pending',
            if (action == 'superPaw') 'message': '⭐ Super Paw!',
          });

        case 'greet':
          await _client.from('match_requests').insert({
            'requester_id': uid,
            'target_id': swipedOwnerUserId,
            'requester_pet_id': swiperPetId,
            'target_pet_id': swipedPetId,
            'match_type': 'playdate',
            'status': 'pending',
            'message': '👋 Wave',
          });

        default: // 'pass' — no write
          break;
      }
    } catch (e) {
      debugPrint('[MatchingRepository] recordSwipe failed: $e');
    }
  }

  // ── Realtime stream ───────────────────────────────────────────────────────

  /// Live stream of all `chat_threads` rows, ordered newest-first.
  ///
  /// Rows use `participant_1_id` / `participant_2_id` (auth users). Consumers
  /// filter by current user and `match_requests` pet involvement.
  Stream<List<Map<String, dynamic>>> chatThreadStream() {
    return _client
        .from('chat_threads')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Task 3 — Fuzzy location bucket.
  ///
  /// Converts a UUID into one of five human-readable distance buckets.
  /// The result is deterministic per pet (same pet → same bucket) but reveals
  /// no real geographic data — the `pets` table stores no location column.
  static String _fuzzyDistance(String petId) {
    const buckets = [
      'Within 1 mile',
      'Within 2 miles',
      'Within 3 miles',
      'Within 5 miles',
      'Within 10 miles',
    ];
    final hash = petId.codeUnits.fold(0, (acc, c) => acc + c);
    return buckets[hash % buckets.length];
  }

  /// Converts a nullable ISO-8601 date string to a short age label.
  static String _ageString(String? dob) {
    if (dob == null) return '';
    final birth = DateTime.tryParse(dob);
    if (birth == null) return '';
    final now = DateTime.now();
    final years = now.year -
        birth.year -
        ((now.month < birth.month ||
                (now.month == birth.month && now.day < birth.day))
            ? 1
            : 0);
    if (years < 1) {
      final months = (now.year - birth.year) * 12 + now.month - birth.month;
      return '${months}mo';
    }
    return '${years}yr';
  }

  /// Deterministic gradient + subject colour per species.
  static (List<Color>, Color) _paletteFor(String species) {
    switch (species) {
      case 'cat':
        return (
          [const Color(0xFFDDD3C3), const Color(0xFFB8A78F), const Color(0xFF7C6750)],
          const Color(0xFF5C4A36),
        );
      case 'rabbit':
        return (
          [const Color(0xFFE3F1E9), const Color(0xFF9CCDB3), const Color(0xFF6BAF92)],
          const Color(0xFF4F8C72),
        );
      default: // dog + anything else
        return (
          [const Color(0xFFF4B57A), const Color(0xFFE89669), const Color(0xFFBC6249)],
          const Color(0xFF6B3F2A),
        );
    }
  }

  static String _defaultBreed(String species) => switch (species) {
        'cat' => 'Domestic Shorthair',
        'rabbit' => 'Mixed Breed',
        _ => 'Mixed Breed',
      };

  static String _defaultBio(String species) => switch (species) {
        'cat' => 'Loves sunny windowsills and the occasional treat.',
        'rabbit' => 'Binkies on demand. Very photogenic.',
        _ => 'Always ready for an adventure (and a nap after).',
      };

  static List<String> _traitsFor(String species) => switch (species) {
        'cat' => ['Indoor', 'Treat-motivated', 'Calm energy'],
        'rabbit' => ['Gentle', 'Curious', 'Kid-friendly'],
        _ => ['Friendly', 'Playful', 'Good on lead'],
      };

  static String _defaultPlayStyle(String species) => switch (species) {
        'cat' => 'Wand toys, gentle chase',
        'rabbit' => 'Explore and binky',
        _ => 'Fetch, chase, or parallel walks',
      };

  static String _defaultEnergy(String species) => switch (species) {
        'cat' => 'Low – Medium',
        'rabbit' => 'Medium · bursts of energy',
        _ => 'Medium · 45–60 min daily',
      };

  static String _defaultBestWith(String species) => switch (species) {
        'cat' => 'Other calm cats',
        'rabbit' => 'Calm pets, gentle kids',
        _ => 'Most dogs, supervised with small pets',
      };
}
