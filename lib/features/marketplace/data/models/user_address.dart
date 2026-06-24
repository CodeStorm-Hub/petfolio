import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_address.freezed.dart';
part 'user_address.g.dart';

@JsonEnum()
enum AddressLabel { home, work, campus, other }

extension AddressLabelDisplay on AddressLabel {
  String get emoji => switch (this) {
        AddressLabel.home => '🏠',
        AddressLabel.work => '💼',
        AddressLabel.campus => '🎓',
        AddressLabel.other => '📍',
      };

  String get displayName => switch (this) {
        AddressLabel.home => 'Home',
        AddressLabel.work => 'Work',
        AddressLabel.campus => 'Campus',
        AddressLabel.other => 'Other',
      };
}

@freezed
abstract class UserAddress with _$UserAddress {
  const UserAddress._();

  const factory UserAddress({
    required String id,
    required String userId,
    @JsonKey(name: 'label') required AddressLabel label,
    @JsonKey(name: 'full_address') required String fullAddress,
    required String city,
    required String zone,
    required String area,
    @JsonKey(name: 'is_default') required bool isDefault,
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _UserAddress;

  factory UserAddress.fromJson(Map<String, dynamic> json) =>
      _$UserAddressFromJson(json);

  String get labelEmoji => label.emoji;

  String get labelName => label.displayName;

  String get displayLine1 => labelName;

  String get displayLine2 {
    final parts = [fullAddress, area, zone, city]
        .where((p) => p.trim().isNotEmpty)
        .toList();
    return parts.join(', ');
  }
}
