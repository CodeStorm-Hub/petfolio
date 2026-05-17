import 'package:freezed_annotation/freezed_annotation.dart';

part 'matching_discovery_row.freezed.dart';

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

@Freezed(fromJson: false, toJson: false)
abstract class MatchingDiscoveryOwner with _$MatchingDiscoveryOwner {
  const factory MatchingDiscoveryOwner({
    required String id,
    String? username,
    String? displayName,
  }) = _MatchingDiscoveryOwner;

  factory MatchingDiscoveryOwner.fromJson(Map<String, dynamic> json) {
    return MatchingDiscoveryOwner(
      id: json['id'] as String,
      username: json['username'] as String?,
      displayName: json['display_name'] as String?,
    );
  }
}

@Freezed(fromJson: false, toJson: false)
abstract class MatchingDiscoveryRow with _$MatchingDiscoveryRow {
  const factory MatchingDiscoveryRow({
    required String id,
    required String ownerId,
    required String name,
    required String species,
    String? breed,
    DateTime? dateOfBirth,
    String? avatarUrl,
    String? bio,
    double? distanceMeters,
    @Default(false) bool isDiscoverable,
    MatchingDiscoveryOwner? owner,
  }) = _MatchingDiscoveryRow;

  factory MatchingDiscoveryRow.fromJson(Map<String, dynamic> json) {
    final ownerJson = json['owner'];
    return MatchingDiscoveryRow(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      name: json['name'] as String,
      species: json['species'] as String,
      breed: json['breed'] as String?,
      dateOfBirth: _dateTimeFromJson(json['date_of_birth']),
      avatarUrl: json['avatar_url'] as String?,
      bio: json['bio'] as String?,
      distanceMeters: _numToDouble(json['distance_meters']),
      isDiscoverable: json['is_discoverable'] as bool? ?? true,
      owner: ownerJson == null
          ? null
          : MatchingDiscoveryOwner.fromJson(
              Map<String, dynamic>.from(ownerJson as Map),
            ),
    );
  }
}
