import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'active_pet_controller.dart';
import 'pet_list_controller.dart';

final discoveryVisibilityControllerProvider =
    NotifierProvider<DiscoveryVisibilityController, bool>(
  DiscoveryVisibilityController.new,
);

class DiscoveryVisibilityController extends Notifier<bool> {
  @override
  bool build() => false;

  Future<void> setDiscoverable(bool discoverable) async {
    final pet = ref.read(activePetControllerProvider);
    if (pet == null) return;

    state = true;
    try {
      await ref.read(petListProvider.notifier).setDiscoverable(
            petId: pet.id,
            discoverable: discoverable,
          );
    } finally {
      state = false;
    }
  }
}
