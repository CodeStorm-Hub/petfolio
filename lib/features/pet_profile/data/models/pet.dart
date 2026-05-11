import 'package:petfolio/features/pet_profile/data/models/pet_species.dart';

/// Immutable domain model for a pet.
///
/// Maps 1-to-1 with the `pets` table in Supabase.
/// Use [copyWith] for local updates; call PetRepository to persist.
class Pet {
  const Pet({
    required this.id,
    required this.userId,
    required this.name,
    required this.species,
    this.breed,
    this.avatarUrl,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String name;

  /// Matches [PetSpecies.name] — stored as a plain string in the DB.
  final String species;

  final String? breed;
  final String? avatarUrl;
  final DateTime createdAt;

  PetSpecies get speciesEnum => PetSpecies.fromId(species) ?? PetSpecies.dog;

  Pet copyWith({String? name, String? breed, String? avatarUrl}) => Pet(
        id: id,
        userId: userId,
        name: name ?? this.name,
        species: species,
        breed: breed ?? this.breed,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        createdAt: createdAt,
      );

  factory Pet.fromJson(Map<String, dynamic> json) => Pet(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        name: json['name'] as String,
        species: json['species'] as String,
        breed: json['breed'] as String?,
        avatarUrl: json['avatar_url'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'name': name,
        'species': species,
        if (breed != null) 'breed': breed,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
        'created_at': createdAt.toIso8601String(),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Pet && id == other.id);

  @override
  int get hashCode => id.hashCode;
}
