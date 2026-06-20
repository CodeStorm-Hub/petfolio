import 'package:flutter_riverpod/flutter_riverpod.dart';

mixin RefreshableListNotifier<T> on AsyncNotifier<List<T>> {
  Future<List<T>> fetch();

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(fetch);
  }
}
