import 'package:freezed_annotation/freezed_annotation.dart';

part 'prescription.freezed.dart';
part 'prescription.g.dart';

enum PrescriptionStatus {
  pending,
  approved,
  rejected;

  String get label => switch (this) {
        PrescriptionStatus.pending  => 'Pending Review',
        PrescriptionStatus.approved => 'Approved',
        PrescriptionStatus.rejected => 'Rejected',
      };

  static PrescriptionStatus fromString(String s) => switch (s) {
        'approved' => PrescriptionStatus.approved,
        'rejected' => PrescriptionStatus.rejected,
        _          => PrescriptionStatus.pending,
      };
}

PrescriptionStatus _rxStatusFromJson(String s) =>
    PrescriptionStatus.fromString(s);
String _rxStatusToJson(PrescriptionStatus s) => s.name;

@freezed
abstract class Prescription with _$Prescription {
  const factory Prescription({
    required String id,
    @JsonKey(name: 'order_id') required String orderId,
    @JsonKey(name: 'file_path') required String filePath,
    @JsonKey(name: 'vet_name') String? vetName,
    @JsonKey(
      name: 'status',
      fromJson: _rxStatusFromJson,
      toJson: _rxStatusToJson,
    )
    @Default(PrescriptionStatus.pending)
    PrescriptionStatus status,
    @JsonKey(name: 'reviewed_at') DateTime? reviewedAt,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _Prescription;

  factory Prescription.fromJson(Map<String, dynamic> json) =>
      _$PrescriptionFromJson(json);
}
