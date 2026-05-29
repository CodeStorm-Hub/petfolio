// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comment_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Manages the comment list for a single post (identified by [postId]).
///
/// Optimistic UI pattern on [delete] and [toggleLike].
///
/// [add] is non-optimistic because we need the server-generated
/// timestamp and ID to display the comment correctly.

@ProviderFor(CommentList)
final commentListProvider = CommentListFamily._();

/// Manages the comment list for a single post (identified by [postId]).
///
/// Optimistic UI pattern on [delete] and [toggleLike].
///
/// [add] is non-optimistic because we need the server-generated
/// timestamp and ID to display the comment correctly.
final class CommentListProvider
    extends $AsyncNotifierProvider<CommentList, List<Comment>> {
  /// Manages the comment list for a single post (identified by [postId]).
  ///
  /// Optimistic UI pattern on [delete] and [toggleLike].
  ///
  /// [add] is non-optimistic because we need the server-generated
  /// timestamp and ID to display the comment correctly.
  CommentListProvider._({
    required CommentListFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'commentListProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$commentListHash();

  @override
  String toString() {
    return r'commentListProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  CommentList create() => CommentList();

  @override
  bool operator ==(Object other) {
    return other is CommentListProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$commentListHash() => r'06ceff73ae29048bd53cf1b02ae5ff42df3df486';

/// Manages the comment list for a single post (identified by [postId]).
///
/// Optimistic UI pattern on [delete] and [toggleLike].
///
/// [add] is non-optimistic because we need the server-generated
/// timestamp and ID to display the comment correctly.

final class CommentListFamily extends $Family
    with
        $ClassFamilyOverride<
          CommentList,
          AsyncValue<List<Comment>>,
          List<Comment>,
          FutureOr<List<Comment>>,
          String
        > {
  CommentListFamily._()
    : super(
        retry: null,
        name: r'commentListProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Manages the comment list for a single post (identified by [postId]).
  ///
  /// Optimistic UI pattern on [delete] and [toggleLike].
  ///
  /// [add] is non-optimistic because we need the server-generated
  /// timestamp and ID to display the comment correctly.

  CommentListProvider call(String postId) =>
      CommentListProvider._(argument: postId, from: this);

  @override
  String toString() => r'commentListProvider';
}

/// Manages the comment list for a single post (identified by [postId]).
///
/// Optimistic UI pattern on [delete] and [toggleLike].
///
/// [add] is non-optimistic because we need the server-generated
/// timestamp and ID to display the comment correctly.

abstract class _$CommentList extends $AsyncNotifier<List<Comment>> {
  late final _$args = ref.$arg as String;
  String get postId => _$args;

  FutureOr<List<Comment>> build(String postId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<Comment>>, List<Comment>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Comment>>, List<Comment>>,
              AsyncValue<List<Comment>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
