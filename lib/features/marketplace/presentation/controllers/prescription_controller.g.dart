// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'prescription_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(PrescriptionUpload)
final prescriptionUploadProvider = PrescriptionUploadFamily._();

final class PrescriptionUploadProvider
    extends $AsyncNotifierProvider<PrescriptionUpload, Prescription?> {
  PrescriptionUploadProvider._({
    required PrescriptionUploadFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'prescriptionUploadProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$prescriptionUploadHash();

  @override
  String toString() {
    return r'prescriptionUploadProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  PrescriptionUpload create() => PrescriptionUpload();

  @override
  bool operator ==(Object other) {
    return other is PrescriptionUploadProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$prescriptionUploadHash() =>
    r'ecd881b1b66dbc04607755fe6829217472405b4d';

final class PrescriptionUploadFamily extends $Family
    with
        $ClassFamilyOverride<
          PrescriptionUpload,
          AsyncValue<Prescription?>,
          Prescription?,
          FutureOr<Prescription?>,
          String
        > {
  PrescriptionUploadFamily._()
    : super(
        retry: null,
        name: r'prescriptionUploadProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  PrescriptionUploadProvider call(String orderId) =>
      PrescriptionUploadProvider._(argument: orderId, from: this);

  @override
  String toString() => r'prescriptionUploadProvider';
}

abstract class _$PrescriptionUpload extends $AsyncNotifier<Prescription?> {
  late final _$args = ref.$arg as String;
  String get orderId => _$args;

  FutureOr<Prescription?> build(String orderId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<Prescription?>, Prescription?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<Prescription?>, Prescription?>,
              AsyncValue<Prescription?>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
