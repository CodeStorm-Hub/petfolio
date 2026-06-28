// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'social_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SocialController)
final socialControllerProvider = SocialControllerFamily._();

final class SocialControllerProvider
    extends $AsyncNotifierProvider<SocialController, SocialFeedState> {
  SocialControllerProvider._({
    required SocialControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'socialControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$socialControllerHash();

  @override
  String toString() {
    return r'socialControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  SocialController create() => SocialController();

  @override
  bool operator ==(Object other) {
    return other is SocialControllerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$socialControllerHash() => r'973d150e08057e21730ec1c15fc1b9bf5873ce2a';

final class SocialControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          SocialController,
          AsyncValue<SocialFeedState>,
          SocialFeedState,
          FutureOr<SocialFeedState>,
          String
        > {
  SocialControllerFamily._()
    : super(
        retry: null,
        name: r'socialControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  SocialControllerProvider call(String petId) =>
      SocialControllerProvider._(argument: petId, from: this);

  @override
  String toString() => r'socialControllerProvider';
}

abstract class _$SocialController extends $AsyncNotifier<SocialFeedState> {
  late final _$args = ref.$arg as String;
  String get petId => _$args;

  FutureOr<SocialFeedState> build(String petId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<SocialFeedState>, SocialFeedState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<SocialFeedState>, SocialFeedState>,
              AsyncValue<SocialFeedState>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}

@ProviderFor(postDetail)
final postDetailProvider = PostDetailFamily._();

final class PostDetailProvider
    extends
        $FunctionalProvider<
          AsyncValue<FeedPost?>,
          FeedPost?,
          FutureOr<FeedPost?>
        >
    with $FutureModifier<FeedPost?>, $FutureProvider<FeedPost?> {
  PostDetailProvider._({
    required PostDetailFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'postDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$postDetailHash();

  @override
  String toString() {
    return r'postDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<FeedPost?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<FeedPost?> create(Ref ref) {
    final argument = this.argument as String;
    return postDetail(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PostDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$postDetailHash() => r'1cf9945c782e27e96b76e6092df4b286799a2621';

final class PostDetailFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<FeedPost?>, String> {
  PostDetailFamily._()
    : super(
        retry: null,
        name: r'postDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  PostDetailProvider call(String postId) =>
      PostDetailProvider._(argument: postId, from: this);

  @override
  String toString() => r'postDetailProvider';
}

@ProviderFor(post)
final postProvider = PostFamily._();

final class PostProvider
    extends $FunctionalProvider<FeedPost?, FeedPost?, FeedPost?>
    with $Provider<FeedPost?> {
  PostProvider._({
    required PostFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'postProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$postHash();

  @override
  String toString() {
    return r'postProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<FeedPost?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  FeedPost? create(Ref ref) {
    final argument = this.argument as String;
    return post(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FeedPost? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FeedPost?>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is PostProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$postHash() => r'06f8a0e7821b3ba0ef0ca3ce9f1b215b7ace91ce';

final class PostFamily extends $Family
    with $FunctionalFamilyOverride<FeedPost?, String> {
  PostFamily._()
    : super(
        retry: null,
        name: r'postProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  PostProvider call(String postId) =>
      PostProvider._(argument: postId, from: this);

  @override
  String toString() => r'postProvider';
}
