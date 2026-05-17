enum PetGender {
  male,
  female,
  unknown;

  String get dbValue => switch (this) {
        PetGender.male => 'male',
        PetGender.female => 'female',
        PetGender.unknown => 'unknown',
      };

  String get label => switch (this) {
        PetGender.male => 'Male',
        PetGender.female => 'Female',
        PetGender.unknown => 'Not specified',
      };

  static PetGender fromDb(String? value) => switch (value) {
        'male' => PetGender.male,
        'female' => PetGender.female,
        _ => PetGender.unknown,
      };
}
