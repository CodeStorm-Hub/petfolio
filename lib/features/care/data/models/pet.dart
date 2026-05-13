import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:petfolio/features/pet_profile/data/models/pet_species.dart';

part 'pet.freezed.dart';
part 'pet.g.dart';

@JsonEnum(fieldRename: FieldRename.snake)
enum ActivityLevel { sedentary, low, moderate, high, veryHigh }

@freezed
@JsonSerializable(fieldRename: FieldRename.snake)
class Pet with _$Pet {
  const Pet._();

  const factory Pet({
    required String id,
    required String ownerId,
    required String name,
    required String species,
    String? breed,
    String? avatarUrl,
    DateTime? dateOfBirth,
    ActivityLevel? activityLevel,
    required DateTime createdAt,
  }) = _Pet;

  factory Pet.fromJson(Map<String, dynamic> json) => _$PetFromJson(json);

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
    return (now.year - dateOfBirth!.year) * 12 +
        (now.month - dateOfBirth!.month);
  }
}
