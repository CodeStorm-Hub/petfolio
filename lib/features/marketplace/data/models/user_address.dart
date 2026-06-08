import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_address.freezed.dart';
part 'user_address.g.dart';

@JsonEnum()
enum AddressLabel { home, work, campus, other }

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

  String get labelEmoji => switch (label) {
        AddressLabel.home => '🏠',
        AddressLabel.work => '💼',
        AddressLabel.campus => '🎓',
        AddressLabel.other => '📍',
      };

  String get labelName => switch (label) {
        AddressLabel.home => 'Home',
        AddressLabel.work => 'Work',
        AddressLabel.campus => 'Campus',
        AddressLabel.other => 'Other',
      };

  String get displayLine1 => labelName;

  String get displayLine2 {
    final parts = [fullAddress, area, zone, city]
        .where((p) => p.trim().isNotEmpty)
        .toList();
    return parts.join(', ');
  }
}
