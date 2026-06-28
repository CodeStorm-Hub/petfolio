// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'saved_posts_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SavedPosts)
final savedPostsProvider = SavedPostsProvider._();

final class SavedPostsProvider
    extends $AsyncNotifierProvider<SavedPosts, List<FeedPost>> {
  SavedPostsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'savedPostsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$savedPostsHash();

  @$internal
  @override
  SavedPosts create() => SavedPosts();
}

String _$savedPostsHash() => r'd519c40e38791cd90552b057ee7803c5a2df6b04';

abstract class _$SavedPosts extends $AsyncNotifier<List<FeedPost>> {
  FutureOr<List<FeedPost>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<FeedPost>>, List<FeedPost>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<FeedPost>>, List<FeedPost>>,
              AsyncValue<List<FeedPost>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(isPostSaved)
final isPostSavedProvider = IsPostSavedFamily._();

final class IsPostSavedProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
  IsPostSavedProvider._({
    required IsPostSavedFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'isPostSavedProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$isPostSavedHash();

  @override
  String toString() {
    return r'isPostSavedProvider'
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
    return isPostSaved(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is IsPostSavedProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$isPostSavedHash() => r'f75335a20e1086f5989094bceb798f883d39a77f';

final class IsPostSavedFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<bool>, String> {
  IsPostSavedFamily._()
    : super(
        retry: null,
        name: r'isPostSavedProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  IsPostSavedProvider call(String postId) =>
      IsPostSavedProvider._(argument: postId, from: this);

  @override
  String toString() => r'isPostSavedProvider';
}
