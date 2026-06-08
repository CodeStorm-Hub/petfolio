import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/user_address.dart';
import '../../data/repositories/address_repository.dart';

// ── Selected address (auto-defaults to the marked-default; overridable) ──────

class SelectedAddressNotifier extends Notifier<UserAddress?> {
  @override
  UserAddress? build() {
    final list = ref.watch(addressListProvider).value ?? [];
    if (list.isEmpty) return null;
    try {
      return list.firstWhere((a) => a.isDefault);
    } catch (_) {
      return list.first;
    }
  }

  void select(UserAddress? address) => state = address;
}

final selectedAddressProvider =
    NotifierProvider<SelectedAddressNotifier, UserAddress?>(
      SelectedAddressNotifier.new,
    );

// ── Address list ──────────────────────────────────────────────────────────────

final addressListProvider =
    AsyncNotifierProvider<AddressListNotifier, List<UserAddress>>(
      AddressListNotifier.new,
    );

class AddressListNotifier extends AsyncNotifier<List<UserAddress>> {
  @override
  Future<List<UserAddress>> build() =>
      ref.read(addressRepositoryProvider).fetchAddresses();

  Future<void> addAddress({
    required AddressLabel label,
    required String fullAddress,
    required String city,
    required String zone,
    required String area,
    required bool isDefault,
  }) async {
    final repo = ref.read(addressRepositoryProvider);
    await repo.insertAddress(
      label: label,
      fullAddress: fullAddress,
      city: city,
      zone: zone,
      area: area,
      isDefault: isDefault,
    );
    ref.invalidateSelf();
  }

  Future<void> setDefault(String addressId) async {
    await ref.read(addressRepositoryProvider).setDefault(addressId);
    ref.invalidateSelf();
  }

  Future<void> deleteAddress(String addressId) async {
    await ref.read(addressRepositoryProvider).deleteAddress(addressId);
    state = AsyncData(
      (state.value ?? []).where((a) => a.id != addressId).toList(),
    );
  }
}
