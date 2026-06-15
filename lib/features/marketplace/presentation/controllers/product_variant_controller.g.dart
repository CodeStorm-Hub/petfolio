// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_variant_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(productVariants)
final productVariantsProvider = ProductVariantsFamily._();

final class ProductVariantsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ProductVariant>>,
          List<ProductVariant>,
          FutureOr<List<ProductVariant>>
        >
    with
        $FutureModifier<List<ProductVariant>>,
        $FutureProvider<List<ProductVariant>> {
  ProductVariantsProvider._({
    required ProductVariantsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'productVariantsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$productVariantsHash();

  @override
  String toString() {
    return r'productVariantsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<ProductVariant>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<ProductVariant>> create(Ref ref) {
    final argument = this.argument as String;
    return productVariants(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ProductVariantsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$productVariantsHash() => r'3fd98f4767aca37f9738e8c745f3678eb2f75f37';

final class ProductVariantsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<ProductVariant>>, String> {
  ProductVariantsFamily._()
    : super(
        retry: null,
        name: r'productVariantsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ProductVariantsProvider call(String productId) =>
      ProductVariantsProvider._(argument: productId, from: this);

  @override
  String toString() => r'productVariantsProvider';
}
