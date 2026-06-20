import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/shipment.dart';

final shipmentRepositoryProvider = Provider<ShipmentRepository>(
  (_) => ShipmentRepository(Supabase.instance.client),
);

class ShipmentRepository {
  const ShipmentRepository(this._client);

  final SupabaseClient _client;

  Future<Shipment?> fetchShipment(String orderId) async {
    final row = await _client
        .from('shipments')
        .select()
        .eq('order_id', orderId)
        .maybeSingle();
    if (row == null) return null;
    return Shipment.fromJson(row);
  }
}
