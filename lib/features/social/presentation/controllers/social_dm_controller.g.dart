// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'social_dm_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(socialDmThread)
final socialDmThreadProvider = SocialDmThreadFamily._();

final class SocialDmThreadProvider
    extends $FunctionalProvider<AsyncValue<String>, String, FutureOr<String>>
    with $FutureModifier<String>, $FutureProvider<String> {
  SocialDmThreadProvider._({
    required SocialDmThreadFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'socialDmThreadProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$socialDmThreadHash();

  @override
  String toString() {
    return r'socialDmThreadProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<String> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String> create(Ref ref) {
    final argument = this.argument as String;
    return socialDmThread(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is SocialDmThreadProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$socialDmThreadHash() => r'bce8183ad2ef14c6910a351b11685c0971c2696c';

final class SocialDmThreadFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<String>, String> {
  SocialDmThreadFamily._()
    : super(
        retry: null,
        name: r'socialDmThreadProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  SocialDmThreadProvider call(String otherUserId) =>
      SocialDmThreadProvider._(argument: otherUserId, from: this);

  @override
  String toString() => r'socialDmThreadProvider';
}

@ProviderFor(SocialDmConversation)
final socialDmConversationProvider = SocialDmConversationFamily._();

final class SocialDmConversationProvider
    extends $StreamNotifierProvider<SocialDmConversation, List<ChatMessage>> {
  SocialDmConversationProvider._({
    required SocialDmConversationFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'socialDmConversationProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$socialDmConversationHash();

  @override
  String toString() {
    return r'socialDmConversationProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  SocialDmConversation create() => SocialDmConversation();

  @override
  bool operator ==(Object other) {
    return other is SocialDmConversationProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$socialDmConversationHash() =>
    r'40342a427fb060f85fa532f8388e8bc727689306';

final class SocialDmConversationFamily extends $Family
    with
        $ClassFamilyOverride<
          SocialDmConversation,
          AsyncValue<List<ChatMessage>>,
          List<ChatMessage>,
          Stream<List<ChatMessage>>,
          String
        > {
  SocialDmConversationFamily._()
    : super(
        retry: null,
        name: r'socialDmConversationProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  SocialDmConversationProvider call(String threadId) =>
      SocialDmConversationProvider._(argument: threadId, from: this);

  @override
  String toString() => r'socialDmConversationProvider';
}

abstract class _$SocialDmConversation
    extends $StreamNotifier<List<ChatMessage>> {
  late final _$args = ref.$arg as String;
  String get threadId => _$args;

  Stream<List<ChatMessage>> build(String threadId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<ChatMessage>>, List<ChatMessage>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<ChatMessage>>, List<ChatMessage>>,
              AsyncValue<List<ChatMessage>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
