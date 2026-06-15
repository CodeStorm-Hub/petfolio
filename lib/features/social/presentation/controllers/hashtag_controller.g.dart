// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hashtag_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(HashtagSearch)
final hashtagSearchProvider = HashtagSearchProvider._();

final class HashtagSearchProvider
    extends $NotifierProvider<HashtagSearch, List<Hashtag>> {
  HashtagSearchProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'hashtagSearchProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$hashtagSearchHash();

  @$internal
  @override
  HashtagSearch create() => HashtagSearch();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<Hashtag> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<Hashtag>>(value),
    );
  }
}

String _$hashtagSearchHash() => r'869527fe635a70366845422119f54ec45a58789c';

abstract class _$HashtagSearch extends $Notifier<List<Hashtag>> {
  List<Hashtag> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<List<Hashtag>, List<Hashtag>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<Hashtag>, List<Hashtag>>,
              List<Hashtag>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(HashtagFeed)
final hashtagFeedProvider = HashtagFeedFamily._();

final class HashtagFeedProvider
    extends $AsyncNotifierProvider<HashtagFeed, List<FeedPost>> {
  HashtagFeedProvider._({
    required HashtagFeedFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'hashtagFeedProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$hashtagFeedHash();

  @override
  String toString() {
    return r'hashtagFeedProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  HashtagFeed create() => HashtagFeed();

  @override
  bool operator ==(Object other) {
    return other is HashtagFeedProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$hashtagFeedHash() => r'810dc17e1a65e839b2a81417da3ecab1e588aea0';

final class HashtagFeedFamily extends $Family
    with
        $ClassFamilyOverride<
          HashtagFeed,
          AsyncValue<List<FeedPost>>,
          List<FeedPost>,
          FutureOr<List<FeedPost>>,
          String
        > {
  HashtagFeedFamily._()
    : super(
        retry: null,
        name: r'hashtagFeedProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  HashtagFeedProvider call(String tag) =>
      HashtagFeedProvider._(argument: tag, from: this);

  @override
  String toString() => r'hashtagFeedProvider';
}

abstract class _$HashtagFeed extends $AsyncNotifier<List<FeedPost>> {
  late final _$args = ref.$arg as String;
  String get tag => _$args;

  FutureOr<List<FeedPost>> build(String tag);
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
    element.handleCreate(ref, () => build(_$args));
  }
}
