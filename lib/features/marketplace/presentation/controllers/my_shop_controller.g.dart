// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'my_shop_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(MyShop)
final myShopProvider = MyShopProvider._();

final class MyShopProvider extends $AsyncNotifierProvider<MyShop, Shop?> {
  MyShopProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'myShopProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$myShopHash();

  @$internal
  @override
  MyShop create() => MyShop();
}

String _$myShopHash() => r'aafbe492b2e171dab745289dc0e2f29964b93814';

abstract class _$MyShop extends $AsyncNotifier<Shop?> {
  FutureOr<Shop?> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<Shop?>, Shop?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<Shop?>, Shop?>,
              AsyncValue<Shop?>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
