import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_address.dart';

final addressRepositoryProvider = Provider<AddressRepository>(
  (_) => AddressRepository(Supabase.instance.client),
);

class AddressRepository {
  const AddressRepository(this._client);

  final SupabaseClient _client;

  Future<List<UserAddress>> fetchAddresses() async {
    final data = await _client
        .from('user_addresses')
        .select()
        .order('is_default', ascending: false)
        .order('created_at');
    return (data as List).map((e) => UserAddress.fromJson(e)).toList();
  }

  Future<UserAddress> insertAddress({
    required AddressLabel label,
    required String fullAddress,
    required String city,
    required String zone,
    required String area,
    required bool isDefault,
  }) async {
    final userId = _client.auth.currentUser!.id;
    if (isDefault) {
      await _client
          .from('user_addresses')
          .update({'is_default': false})
          .eq('user_id', userId);
    }
    final data = await _client
        .from('user_addresses')
        .insert({
          'user_id': userId,
          'label': label.name,
          'full_address': fullAddress,
          'city': city,
          'zone': zone,
          'area': area,
          'is_default': isDefault,
        })
        .select()
        .single();
    return UserAddress.fromJson(data);
  }

  Future<void> setDefault(String addressId) async {
    final userId = _client.auth.currentUser!.id;
    await _client
        .from('user_addresses')
        .update({'is_default': false})
        .eq('user_id', userId);
    await _client
        .from('user_addresses')
        .update({'is_default': true})
        .eq('id', addressId);
  }

  Future<void> deleteAddress(String addressId) async {
    await _client.from('user_addresses').delete().eq('id', addressId);
  }
}
