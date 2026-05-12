import 'package:flutter/material.dart';

/// Immutable model for a pet profile shown in the discovery (Playdates) deck.
///
/// Populated from the `pets` table (or a dedicated `discovery_profiles` view)
/// filtered to exclude the user's own pets and already-swiped profiles.
/// The sample deck in [DiscoveryNotifier._sampleDeck] is used until the
/// database has enough real profiles.
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
  });

  final String petId;
  final String name;

  /// Human-readable age string, e.g. "3 yr".
  final String age;

  /// Lowercase species string: "dog" | "cat" | etc.
  final String species;

  final String breed;

  /// Always a fuzzy bucket, e.g. "Within 2 miles" — never an address.
  final String distance;

  /// Single letter initial for the safety chip, e.g. "J."
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
}
