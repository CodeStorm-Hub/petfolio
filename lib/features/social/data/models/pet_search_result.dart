import 'package:flutter/material.dart';

/// Lightweight data model for a pet returned by a search query.
///
/// Used in the Explore screen's search results list.
class PetSearchResult {
  const PetSearchResult({
    required this.petId,
    required this.handle,
    required this.petName,
    required this.species,
    required this.accentColor,
    this.breed,
    this.avatarUrl,
  });

  final String petId;

  /// The unique @handle (e.g. "biscuit_paws")
  final String handle;

  /// Display name (e.g. "Biscuit")
  final String petName;

  /// Species (e.g. "dog", "cat")
  final String species;

  /// The brand colour used for avatar background and story rings.
  final Color accentColor;

  final String? breed;
  final String? avatarUrl;

  factory PetSearchResult.fromJson(Map<String, dynamic> json) {
    return PetSearchResult(
      petId: json['id'] as String,
      handle: '@${json['handle'] ?? 'unknown'}',
      petName: json['name'] as String? ?? 'Unknown',
      species: json['species'] as String? ?? 'dog',
      accentColor: Color(
        int.parse(
          (json['accent_color'] as String? ?? 'FF6B9D').replaceFirst('#', 'FF'),
          radix: 16,
        ),
      ),
      breed: json['breed'] as String?,
      avatarUrl: json['avatar_url'] as String?,
    );
  }
}
