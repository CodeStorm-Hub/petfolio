import 'package:freezed_annotation/freezed_annotation.dart';

part 'shop.freezed.dart';
part 'shop.g.dart';

@JsonEnum()
enum PayoutMethod { stripe, manual }

@JsonEnum()
enum KycStatus { pending, submitted, approved, rejected }

@freezed
abstract class Shop with _$Shop {
  const Shop._();

  const factory Shop({
    required String id,
    required String ownerId,
    required String shopName,
    required String slug,
    String? description,
    String? logoUrl,
    String? bannerUrl,
    required bool isActive,
    required bool isVerified,
    String? stripeConnectAccountId,
    required bool stripeOnboardingComplete,
    required int platformFeePercent,
    required PayoutMethod payoutMethod,
    required KycStatus kycStatus,
    String? tradeLicenseUrl,
    String? nationalIdUrl,
    String? rejectionReason,
    Map<String, dynamic>? bankAccountDetails,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Shop;

  factory Shop.fromJson(Map<String, dynamic> json) => _$ShopFromJson(json);

  bool get needsOnboarding =>
      payoutMethod == PayoutMethod.stripe && stripeConnectAccountId == null;

  bool get canAcceptPayments {
    if (!isVerified) return false;
    if (payoutMethod == PayoutMethod.manual) return true;
    return stripeConnectAccountId != null || platformFeePercent == 0;
  }

  bool get kycApproved => kycStatus == KycStatus.approved;
}
