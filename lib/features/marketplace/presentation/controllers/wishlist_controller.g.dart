// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wishlist_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(WishlistItems)
final wishlistItemsProvider = WishlistItemsProvider._();

final class WishlistItemsProvider
    extends $AsyncNotifierProvider<WishlistItems, List<WishlistProduct>> {
  WishlistItemsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'wishlistItemsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$wishlistItemsHash();

  @$internal
  @override
  WishlistItems create() => WishlistItems();
}

String _$wishlistItemsHash() => r'aef045ebe39bdd35b4630f9e1f0aae79d4374b88';

abstract class _$WishlistItems extends $AsyncNotifier<List<WishlistProduct>> {
  FutureOr<List<WishlistProduct>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<List<WishlistProduct>>, List<WishlistProduct>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<WishlistProduct>>,
                List<WishlistProduct>
              >,
              AsyncValue<List<WishlistProduct>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(isWishlisted)
final isWishlistedProvider = IsWishlistedFamily._();

final class IsWishlistedProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
  IsWishlistedProvider._({
    required IsWishlistedFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'isWishlistedProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$isWishlistedHash();

  @override
  String toString() {
    return r'isWishlistedProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<bool> create(Ref ref) {
    final argument = this.argument as String;
    return isWishlisted(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is IsWishlistedProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$isWishlistedHash() => r'bc70e1cd55db10d5d32ef348a8f1ef0efbaaf9ca';

final class IsWishlistedFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<bool>, String> {
  IsWishlistedFamily._()
    : super(
        retry: null,
        name: r'isWishlistedProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  IsWishlistedProvider call(String productId) =>
      IsWishlistedProvider._(argument: productId, from: this);

  @override
  String toString() => r'isWishlistedProvider';
}
