// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shipment_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(shipment)
final shipmentProvider = ShipmentFamily._();

final class ShipmentProvider
    extends
        $FunctionalProvider<
          AsyncValue<Shipment?>,
          Shipment?,
          FutureOr<Shipment?>
        >
    with $FutureModifier<Shipment?>, $FutureProvider<Shipment?> {
  ShipmentProvider._({
    required ShipmentFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'shipmentProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$shipmentHash();

  @override
  String toString() {
    return r'shipmentProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Shipment?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Shipment?> create(Ref ref) {
    final argument = this.argument as String;
    return shipment(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ShipmentProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$shipmentHash() => r'd1b4ef1ece963d1c818a178f6e4268c99c5c3e24';

final class ShipmentFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Shipment?>, String> {
  ShipmentFamily._()
    : super(
        retry: null,
        name: r'shipmentProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ShipmentProvider call(String orderId) =>
      ShipmentProvider._(argument: orderId, from: this);

  @override
  String toString() => r'shipmentProvider';
}
