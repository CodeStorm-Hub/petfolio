import 'package:freezed_annotation/freezed_annotation.dart';

part 'pet_health_cert.freezed.dart';

enum HealthCertType {
  vaccination,
  genetic,
  vet;

  String get dbValue => switch (this) {
        HealthCertType.vaccination => 'vaccination',
        HealthCertType.genetic => 'genetic',
        HealthCertType.vet => 'vet',
      };

  String get label => switch (this) {
        HealthCertType.vaccination => 'Vaccination',
        HealthCertType.genetic => 'Genetic test',
        HealthCertType.vet => 'Vet record',
      };

  static HealthCertType fromDb(String? value) => switch (value) {
        'genetic' => HealthCertType.genetic,
        'vet' => HealthCertType.vet,
        _ => HealthCertType.vaccination,
      };
}

@Freezed(fromJson: false, toJson: false)
abstract class PetHealthCert with _$PetHealthCert {
  const factory PetHealthCert({
    required String id,
    required String petId,
    required HealthCertType certType,
    required String filePath,
    @Default(false) bool verified,
    DateTime? expiresAt,
    DateTime? createdAt,
  }) = _PetHealthCert;

  const PetHealthCert._();

  factory PetHealthCert.fromJson(Map<String, dynamic> json) => PetHealthCert(
        id: json['id'] as String,
        petId: json['pet_id'] as String,
        certType: HealthCertType.fromDb(json['cert_type'] as String?),
        filePath: json['file_path'] as String,
        verified: json['verified'] as bool? ?? false,
        expiresAt: json['expires_at'] == null
            ? null
            : DateTime.tryParse(json['expires_at'].toString()),
        createdAt: json['created_at'] == null
            ? null
            : DateTime.tryParse(json['created_at'].toString()),
      );
}
