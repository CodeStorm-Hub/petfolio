// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_post_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CreatePostController)
final createPostControllerProvider = CreatePostControllerProvider._();

final class CreatePostControllerProvider
    extends $NotifierProvider<CreatePostController, CreatePostState> {
  CreatePostControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'createPostControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$createPostControllerHash();

  @$internal
  @override
  CreatePostController create() => CreatePostController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CreatePostState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CreatePostState>(value),
    );
  }
}

String _$createPostControllerHash() =>
    r'97aca53e5f117541cddf102d3ca129abf079bcee';

abstract class _$CreatePostController extends $Notifier<CreatePostState> {
  CreatePostState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<CreatePostState, CreatePostState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<CreatePostState, CreatePostState>,
              CreatePostState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
