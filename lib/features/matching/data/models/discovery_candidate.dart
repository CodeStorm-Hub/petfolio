import 'package:flutter/material.dart';

/// Immutable model for a pet profile shown in the discovery (Playdates) deck.
///
/// Populated from the `pets` table joined with `users` (for [ownerUserId] and
/// [ownerInitial]) and filtered to exclude the active pet and already-swiped
/// profiles.  [_sampleDeck] in [DiscoveryNotifier] is used as a warm fallback
/// while the real data loads or when the DB has no qualifying profiles.
class DiscoveryCandidate {
  const DiscoveryCandidate({
    required this.petId,
    required this.name,
    required this.age,
    required this.species,
    required this.breed,
    required this.distance,
    required this.ownerInitial,
    required this.verified,
    required this.traits,
    required this.bio,
    required this.playStyle,
    required this.energy,
    required this.bestWith,
    required this.vaccinated,
    required this.gradientColors,
    required this.subjectColor,
    this.avatarUrl,
    this.ownerUserId,
  });

  final String petId;
  final String name;

  /// Human-readable age string, e.g. "3yr" or "8mo".
  final String age;

  /// Lowercase species string: "dog" | "cat" | "rabbit" | etc.
  final String species;

  final String breed;

  /// Always a fuzzy bucket — never an address.
  /// e.g. "Within 2 miles", "Within 5 miles".
  /// Derived deterministically from [petId] so no location data is stored.
  final String distance;

  /// Single letter initial for the safety chip, e.g. "J".
  final String ownerInitial;

  /// Whether this profile has been vet-verified.
  final bool verified;

  final List<String> traits;
  final String bio;
  final String playStyle;
  final String energy;
  final String bestWith;
  final bool vaccinated;

  /// Three colours used for the card's gradient background: [start, mid, end].
  final List<Color> gradientColors;

  /// Base colour for the pet illustration (body blob + ear tints).
  final Color subjectColor;

  final String? avatarUrl;

  /// The Supabase `auth.users.id` of this pet's owner.
  /// Populated from the `users` join in [MatchingRepository.fetchCandidates].
  /// Required when inserting into `match_requests.target_id`; null for demo
  /// cards that never hit the database.
  final String? ownerUserId;
}
