import 'package:petfolio/features/pet_profile/data/models/pet_species.dart';

/// Immutable domain model for a pet.
///
/// Maps 1-to-1 with the `pets` table in Supabase.
/// Use [copyWith] for local updates; call PetRepository to persist.
class Pet {
  const Pet({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.species,
    this.breed,
    this.avatarUrl,
    this.bio,
    required this.createdAt,
  });

  final String id;
  final String ownerId;
  final String name;

  /// Matches [PetSpecies.name] — stored as a plain string in the DB.
  final String species;

  final String? breed;
  final String? avatarUrl;
  final String? bio;
  final DateTime createdAt;

  PetSpecies get speciesEnum => PetSpecies.fromId(species) ?? PetSpecies.dog;

  Pet copyWith({String? name, String? breed, String? avatarUrl, String? bio}) => Pet(
        id: id,
        ownerId: ownerId,
        name: name ?? this.name,
        species: species,
        breed: breed ?? this.breed,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        bio: bio ?? this.bio,
        createdAt: createdAt,
      );

  factory Pet.fromJson(Map<String, dynamic> json) => Pet(
        id: json['id'] as String,
        ownerId: json['owner_id'] as String,
        name: json['name'] as String,
        species: json['species'] as String,
        breed: json['breed'] as String?,
        avatarUrl: json['avatar_url'] as String?,
        bio: json['bio'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'owner_id': ownerId,
        'name': name,
        'species': species,
        if (breed != null) 'breed': breed,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
        if (bio != null) 'bio': bio,
        'created_at': createdAt.toIso8601String(),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Pet && id == other.id);

  @override
  int get hashCode => id.hashCode;
}
