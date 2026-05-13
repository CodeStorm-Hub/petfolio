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
    this.dateOfBirth,
    this.activityLevel,
    required this.createdAt,
  });

  final String id;
  final String ownerId;
  final String name;
  final String species;
  final String? breed;
  final String? avatarUrl;
  final DateTime? dateOfBirth;
  final ActivityLevel? activityLevel;
  final DateTime createdAt;

  PetSpecies get speciesEnum => PetSpecies.fromId(species) ?? PetSpecies.dog;

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
    return (now.year - dateOfBirth!.year) * 12 + (now.month - dateOfBirth!.month);
  }

  Pet copyWith({
    String? name,
    String? breed,
    String? avatarUrl,
    DateTime? dateOfBirth,
    ActivityLevel? activityLevel,
  }) =>
      Pet(
        id: id,
        ownerId: ownerId,
        name: name ?? this.name,
        species: species,
        breed: breed ?? this.breed,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        dateOfBirth: dateOfBirth ?? this.dateOfBirth,
        activityLevel: activityLevel ?? this.activityLevel,
        createdAt: createdAt,
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
        dateOfBirth: json['date_of_birth'] == null
            ? null
            : DateTime.parse(json['date_of_birth'] as String),
        activityLevel: _activityLevelFromJson(json['activity_level'] as String?),
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'owner_id': ownerId,
        'name': name,
        'species': species,
        if (breed != null) 'breed': breed,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
        if (dateOfBirth != null) 'date_of_birth': dateOfBirth!.toIso8601String(),
        if (activityLevel != null) 'activity_level': _activityLevelToJson(activityLevel),
        'created_at': createdAt.toIso8601String(),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Pet && id == other.id);

  @override
  int get hashCode => id.hashCode;
}
