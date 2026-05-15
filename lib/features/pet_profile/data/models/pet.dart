import 'package:petfolio/features/pet_profile/data/models/pet_species.dart';

enum ActivityLevel { sedentary, low, moderate, high, veryHigh }

class Pet {
  const Pet({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.species,
    this.breed,
    this.avatarUrl,
    this.bio,
    this.dateOfBirth,
    this.weightKg,
    this.activityLevel,
    required this.createdAt,
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
  final DateTime? dateOfBirth;
  final double? weightKg;
  final ActivityLevel? activityLevel;
  final DateTime createdAt;
  final int displayOrder;
  final DateTime? archivedAt;

  PetSpecies get speciesEnum => PetSpecies.fromId(species) ?? PetSpecies.dog;

  String? get activityLevelSnakeCase => _activityLevelToJson(activityLevel);

  int? get ageInYears {
    if (dateOfBirth == null) return null;
    final now = DateTime.now();
    int years = now.year - dateOfBirth!.year;
    if (now.month < dateOfBirth!.month ||
        (now.month == dateOfBirth!.month && now.day < dateOfBirth!.day)) {
      years--;
    }
    return years < 0 ? 0 : years;
  }

  String get ageLabel {
    final years = ageInYears;
    if (years == null) return 'Age unknown';
    if (years == 0) {
      final months = _monthsSinceBirth;
      return months <= 1 ? '1 month' : '$months months';
    }
    return years == 1 ? '1 year' : '$years years';
  }

  int get _monthsSinceBirth {
    if (dateOfBirth == null) return 0;
    final now = DateTime.now();
    return (now.year - dateOfBirth!.year) * 12 +
        (now.month - dateOfBirth!.month);
  }

  bool get isArchived => archivedAt != null;

  Pet copyWith({
    String? name,
    String? breed,
    String? avatarUrl,
    String? bio,
    DateTime? dateOfBirth,
    double? weightKg,
    ActivityLevel? activityLevel,
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
        dateOfBirth: dateOfBirth ?? this.dateOfBirth,
        weightKg: weightKg ?? this.weightKg,
        activityLevel: activityLevel ?? this.activityLevel,
        createdAt: createdAt,
        displayOrder: displayOrder ?? this.displayOrder,
        archivedAt: identical(archivedAt, _sentinel)
            ? this.archivedAt
            : archivedAt as DateTime?,
      );

  static ActivityLevel? _activityLevelFromJson(String? value) {
    if (value == null) return null;
    const map = {
      'sedentary': ActivityLevel.sedentary,
      'low': ActivityLevel.low,
      'moderate': ActivityLevel.moderate,
      'high': ActivityLevel.high,
      'very_high': ActivityLevel.veryHigh,
    };
    return map[value];
  }

  static String? _activityLevelToJson(ActivityLevel? level) {
    if (level == null) return null;
    const map = {
      ActivityLevel.sedentary: 'sedentary',
      ActivityLevel.low: 'low',
      ActivityLevel.moderate: 'moderate',
      ActivityLevel.high: 'high',
      ActivityLevel.veryHigh: 'very_high',
    };
    return map[level];
  }

  factory Pet.fromJson(Map<String, dynamic> json) => Pet(
        id: json['id'] as String,
        ownerId: json['owner_id'] as String,
        name: json['name'] as String,
        species: json['species'] as String,
        breed: json['breed'] as String?,
        avatarUrl: json['avatar_url'] as String?,
        bio: json['bio'] as String?,
        dateOfBirth: json['date_of_birth'] != null
            ? DateTime.parse(json['date_of_birth'] as String)
            : null,
        weightKg: json['weight_kg'] != null
            ? (json['weight_kg'] as num).toDouble()
            : null,
        activityLevel: _activityLevelFromJson(json['activity_level'] as String?),
        createdAt: DateTime.parse(json['created_at'] as String),
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
        if (dateOfBirth != null)
          'date_of_birth': dateOfBirth!.toIso8601String().split('T').first,
        if (weightKg != null) 'weight_kg': weightKg,
        if (activityLevel != null)
          'activity_level': _activityLevelToJson(activityLevel),
        'created_at': createdAt.toIso8601String(),
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
