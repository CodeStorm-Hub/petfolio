// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'care_dashboard_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CareDashboard)
final careDashboardProvider = CareDashboardProvider._();

final class CareDashboardProvider
    extends $NotifierProvider<CareDashboard, DailyRoutineState> {
  CareDashboardProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'careDashboardProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$careDashboardHash();

  @$internal
  @override
  CareDashboard create() => CareDashboard();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DailyRoutineState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DailyRoutineState>(value),
    );
  }
}

String _$careDashboardHash() => r'ef47a56c09e6fe876bde1709b75771f5ac05f410';

abstract class _$CareDashboard extends $Notifier<DailyRoutineState> {
  DailyRoutineState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<DailyRoutineState, DailyRoutineState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DailyRoutineState, DailyRoutineState>,
              DailyRoutineState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
