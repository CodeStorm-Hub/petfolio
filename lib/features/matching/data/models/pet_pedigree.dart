import 'package:freezed_annotation/freezed_annotation.dart';

part 'pet_pedigree.freezed.dart';

@Freezed(fromJson: false, toJson: false)
abstract class PetPedigree with _$PetPedigree {
  const factory PetPedigree({
    required String petId,
    String? sireRef,
    String? damRef,
    String? registryName,
    String? registryId,
    String? titles,
  }) = _PetPedigree;

  const PetPedigree._();

  factory PetPedigree.fromJson(Map<String, dynamic> json) => PetPedigree(
        petId: json['pet_id'] as String,
        sireRef: json['sire_ref'] as String?,
        damRef: json['dam_ref'] as String?,
        registryName: json['registry_name'] as String?,
        registryId: json['registry_id'] as String?,
        titles: json['titles'] as String?,
      );

  Map<String, dynamic> toUpsert() => {
        'pet_id': petId,
        'sire_ref': sireRef,
        'dam_ref': damRef,
        'registry_name': registryName,
        'registry_id': registryId,
        'titles': titles,
      };
}
