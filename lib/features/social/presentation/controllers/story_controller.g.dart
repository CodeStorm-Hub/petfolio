// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'story_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(Stories)
final storiesProvider = StoriesProvider._();

final class StoriesProvider
    extends $AsyncNotifierProvider<Stories, List<Story>> {
  StoriesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'storiesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$storiesHash();

  @$internal
  @override
  Stories create() => Stories();
}

String _$storiesHash() => r'0578eff4c01db5148fbbc9d146c83992530401e1';

abstract class _$Stories extends $AsyncNotifier<List<Story>> {
  FutureOr<List<Story>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<Story>>, List<Story>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Story>>, List<Story>>,
              AsyncValue<List<Story>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
