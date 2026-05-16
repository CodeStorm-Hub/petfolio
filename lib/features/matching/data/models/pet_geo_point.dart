import 'package:freezed_annotation/freezed_annotation.dart';

part 'pet_geo_point.freezed.dart';

@freezed
abstract class PetGeoPoint with _$PetGeoPoint {
  const factory PetGeoPoint({
    required double longitude,
    required double latitude,
  }) = _PetGeoPoint;

  factory PetGeoPoint.fromGeoJson(Map<String, dynamic> geoJson) {
    final coords = geoJson['coordinates'] as List<dynamic>?;
    if (coords == null || coords.length < 2) {
      throw FormatException('Invalid GeoJSON Point', geoJson.toString());
    }
    return PetGeoPoint(
      longitude: (coords[0] as num).toDouble(),
      latitude: (coords[1] as num).toDouble(),
    );
  }
}
