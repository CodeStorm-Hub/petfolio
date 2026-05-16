import 'package:freezed_annotation/freezed_annotation.dart';

part 'matching_discovery_row.freezed.dart';
part 'matching_discovery_row.g.dart';

double? _numToDouble(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}

DateTime? _dateTimeFromJson(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  if (v is String) return DateTime.tryParse(v);
  return null;
}

@freezed
abstract class MatchingDiscoveryOwner with _$MatchingDiscoveryOwner {
  const factory MatchingDiscoveryOwner({
    required String id,
    String? username,
    String? displayName,
  }) = _MatchingDiscoveryOwner;

  factory MatchingDiscoveryOwner.fromJson(Map<String, dynamic> json) =>
      _$MatchingDiscoveryOwnerFromJson(json);
}

@freezed
abstract class MatchingDiscoveryRow with _$MatchingDiscoveryRow {
  const factory MatchingDiscoveryRow({
    required String id,
    required String ownerId,
    required String name,
    required String species,
    String? breed,
    @JsonKey(fromJson: _dateTimeFromJson) DateTime? dateOfBirth,
    String? avatarUrl,
    String? bio,
    @JsonKey(fromJson: _numToDouble) double? distanceMeters,
    MatchingDiscoveryOwner? owner,
  }) = _MatchingDiscoveryRow;

  factory MatchingDiscoveryRow.fromJson(Map<String, dynamic> json) =>
      _$MatchingDiscoveryRowFromJson(json);
}
