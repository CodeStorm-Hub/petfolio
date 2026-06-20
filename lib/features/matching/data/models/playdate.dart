import 'package:freezed_annotation/freezed_annotation.dart';

part 'playdate.freezed.dart';

enum PlaydateStatus {
  proposed,
  confirmed,
  done,
  cancelled;

  String get dbValue => switch (this) {
        PlaydateStatus.proposed => 'proposed',
        PlaydateStatus.confirmed => 'confirmed',
        PlaydateStatus.done => 'done',
        PlaydateStatus.cancelled => 'cancelled',
      };

  String get label => switch (this) {
        PlaydateStatus.proposed => 'Proposed',
        PlaydateStatus.confirmed => 'Confirmed',
        PlaydateStatus.done => 'Done',
        PlaydateStatus.cancelled => 'Cancelled',
      };

  static PlaydateStatus fromDb(String? value) => switch (value) {
        'confirmed' => PlaydateStatus.confirmed,
        'done' => PlaydateStatus.done,
        'cancelled' => PlaydateStatus.cancelled,
        _ => PlaydateStatus.proposed,
      };
}

@Freezed(fromJson: false, toJson: false)
abstract class Playdate with _$Playdate {
  const factory Playdate({
    required String id,
    required String matchId,
    required String proposedByPetId,
    required DateTime scheduledAt,
    String? locationName,
    @Default(PlaydateStatus.proposed) PlaydateStatus status,
    DateTime? createdAt,
  }) = _Playdate;

  const Playdate._();

  factory Playdate.fromJson(Map<String, dynamic> json) => Playdate(
        id: json['id'] as String,
        matchId: json['match_id'] as String,
        proposedByPetId: json['proposed_by_pet_id'] as String,
        scheduledAt: DateTime.parse(json['scheduled_at'].toString()),
        locationName: json['location_name'] as String?,
        status: PlaydateStatus.fromDb(json['status'] as String?),
        createdAt: json['created_at'] == null
            ? null
            : DateTime.tryParse(json['created_at'].toString()),
      );
}
