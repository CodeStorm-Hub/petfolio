import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/models/shop.dart';
import '../../data/repositories/shop_repository.dart';
import 'my_shop_controller.dart';

final editShopControllerProvider =
    AsyncNotifierProvider.autoDispose<EditShopNotifier, Shop>(
  EditShopNotifier.new,
);

class EditShopNotifier extends AsyncNotifier<Shop> {
  ShopRepository get _repo => ref.read(shopRepositoryProvider);
  SupabaseClient get _client => Supabase.instance.client;

  @override
  Future<Shop> build() async {
    // ref.read — not ref.watch — so invalidating myShopProvider after a
    // successful save does NOT trigger this build() to re-run and overwrite
    // the freshly-saved state.
    final shop = await ref.read(myShopProvider.future);
    if (shop == null) throw StateError('No shop found for current user');
    return shop;
  }

  Future<void> saveShopDetails({
    required Shop updatedShop,
    Uint8List? newLogo,
    Uint8List? newBanner,
  }) async {
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      String? logoUrl;
      String? bannerUrl;

      if (newLogo != null) {
        logoUrl = await _uploadShopAsset(
          bytes: newLogo,
          shopId: updatedShop.id,
          filename: 'logo',
        );
      }

      if (newBanner != null) {
        bannerUrl = await _uploadShopAsset(
          bytes: newBanner,
          shopId: updatedShop.id,
          filename: 'banner',
        );
      }

      final merged = updatedShop.copyWith(
        logoUrl:   logoUrl   ?? updatedShop.logoUrl,
        bannerUrl: bannerUrl ?? updatedShop.bannerUrl,
      );

      // saveShopProfile always writes every profile field — including nulls —
      // so clearing a contact/policy field actually clears it in the DB.
      return _repo.saveShopProfile(merged);
    });

    // Invalidate the global shop cache ONLY on success, and OUTSIDE the guard
    // so it cannot trigger a rebuild of this notifier's build() mid-save.
    if (!state.hasError) {
      ref.invalidate(myShopProvider);
    }
  }

  Future<String> _uploadShopAsset({
    required Uint8List bytes,
    required String shopId,
    required String filename,
  }) async {
    final path = '$shopId/$filename';
    await _client.storage
        .from('shops')
        .uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(upsert: true, contentType: 'image/jpeg'),
        );
    return _client.storage.from('shops').getPublicUrl(path);
  }
}
