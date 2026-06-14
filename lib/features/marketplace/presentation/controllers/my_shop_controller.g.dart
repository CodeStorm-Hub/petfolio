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

String _$myShopHash() => r'42ad8cf4a6a68f22cf2cc2ba7f74ab9b5e395050';

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
