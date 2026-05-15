import 'package:petfolio/features/pet_profile/data/models/pet_species.dart';

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
    this.dateOfBirth,
    this.weightKg,
    this.activityLevel,
    this.displayOrder = 0,
    this.archivedAt,
  });

  final String id;
  final String ownerId;
  final String name;
  final String species;
  final String? breed;
  final String? avatarUrl;
  final String? bio;
  final DateTime createdAt;
  final DateTime? dateOfBirth;
  final double? weightKg;
  final String? activityLevel;

  /// Position in the switcher / manage list. Lower comes first.
  final int displayOrder;

  /// Soft-archive timestamp. When non-null, the pet is hidden everywhere by
  /// default; care_logs history is preserved.
  final DateTime? archivedAt;

  PetSpecies get speciesEnum => PetSpecies.fromId(species) ?? PetSpecies.dog;

  bool get isArchived => archivedAt != null;

  Pet copyWith({
    String? name,
    String? breed,
    String? avatarUrl,
    String? bio,
    DateTime? dateOfBirth,
    double? weightKg,
    String? activityLevel,
    int? displayOrder,
    Object? archivedAt = _sentinel,
  }) =>
      Pet(
        id: id,
        ownerId: ownerId,
        name: name ?? this.name,
        species: species,
        breed: breed ?? this.breed,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        bio: bio ?? this.bio,
        createdAt: createdAt,
        dateOfBirth: dateOfBirth ?? this.dateOfBirth,
        weightKg: weightKg ?? this.weightKg,
        activityLevel: activityLevel ?? this.activityLevel,
        displayOrder: displayOrder ?? this.displayOrder,
        archivedAt: identical(archivedAt, _sentinel)
            ? this.archivedAt
            : archivedAt as DateTime?,
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
        dateOfBirth: json['date_of_birth'] != null
            ? DateTime.parse(json['date_of_birth'] as String)
            : null,
        weightKg: json['weight_kg'] != null
            ? (json['weight_kg'] as num).toDouble()
            : null,
        activityLevel: json['activity_level'] as String?,
        displayOrder: (json['display_order'] as num?)?.toInt() ?? 0,
        archivedAt: json['archived_at'] != null
            ? DateTime.parse(json['archived_at'] as String)
            : null,
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
        if (dateOfBirth != null)
          'date_of_birth': dateOfBirth!.toIso8601String().split('T').first,
        if (weightKg != null) 'weight_kg': weightKg,
        if (activityLevel != null) 'activity_level': activityLevel,
        'display_order': displayOrder,
        if (archivedAt != null) 'archived_at': archivedAt!.toIso8601String(),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Pet && id == other.id);

  @override
  int get hashCode => id.hashCode;
}

const _sentinel = Object();
