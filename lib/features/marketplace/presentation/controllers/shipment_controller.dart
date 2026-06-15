import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/models/shipment.dart';
import '../../data/repositories/shipment_repository.dart';

part 'shipment_controller.g.dart';

@riverpod
Future<Shipment?> shipment(Ref ref, String orderId) =>
    ref.read(shipmentRepositoryProvider).fetchShipment(orderId);
