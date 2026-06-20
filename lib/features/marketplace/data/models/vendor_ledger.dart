import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/services/currency_formatter.dart';

part 'vendor_ledger.freezed.dart';
part 'vendor_ledger.g.dart';

@JsonEnum()
enum LedgerStatus { pendingClearance, available, paid }

@freezed
abstract class VendorLedger with _$VendorLedger {
  const VendorLedger._();

  const factory VendorLedger({
    required String id,
    required String shopId,
    required String orderId,
    required int orderTotalCents,
    required int platformFeeCents,
    required int vendorEarningsCents,
    required LedgerStatus status,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _VendorLedger;

  factory VendorLedger.fromJson(Map<String, dynamic> json) =>
      _$VendorLedgerFromJson(json);

  String get earningsFormatted => formatCents(vendorEarningsCents);
}
