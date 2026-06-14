import 'package:freezed_annotation/freezed_annotation.dart';

part 'verification.freezed.dart';

enum VerificationType {
  phone,
  id,
  photo;

  String get dbValue => switch (this) {
        VerificationType.phone => 'phone',
        VerificationType.id => 'id',
        VerificationType.photo => 'photo',
      };

  String get label => switch (this) {
        VerificationType.phone => 'Phone number',
        VerificationType.id => 'Government ID',
        VerificationType.photo => 'Photo / selfie',
      };

  static VerificationType fromDb(String? value) => switch (value) {
        'id' => VerificationType.id,
        'photo' => VerificationType.photo,
        _ => VerificationType.phone,
      };
}

enum VerificationStatus {
  pending,
  approved,
  rejected;

  String get label => switch (this) {
        VerificationStatus.pending => 'Pending review',
        VerificationStatus.approved => 'Approved',
        VerificationStatus.rejected => 'Rejected',
      };

  static VerificationStatus fromDb(String? value) => switch (value) {
        'approved' => VerificationStatus.approved,
        'rejected' => VerificationStatus.rejected,
        _ => VerificationStatus.pending,
      };
}

@Freezed(fromJson: false, toJson: false)
abstract class Verification with _$Verification {
  const factory Verification({
    required String id,
    required VerificationType type,
    @Default(VerificationStatus.pending) VerificationStatus status,
    DateTime? createdAt,
  }) = _Verification;

  const Verification._();

  factory Verification.fromJson(Map<String, dynamic> json) => Verification(
        id: json['id'] as String,
        type: VerificationType.fromDb(json['type'] as String?),
        status: VerificationStatus.fromDb(json['status'] as String?),
        createdAt: json['created_at'] == null
            ? null
            : DateTime.tryParse(json['created_at'].toString()),
      );
}
