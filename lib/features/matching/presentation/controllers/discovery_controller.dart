import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/discovery_candidate.dart';
import '../../data/repositories/matching_repository.dart';
import 'discovery_candidates_controller.dart';

enum SwipeAction { pass, greet, match, superPaw }

class DiscoveryState {
  const DiscoveryState({
    required this.petId,
    this.dragOffset = Offset.zero,
    this.exitAction,
    this.exitingCard,
    this.exitDurationMs = 320,
    this.isExpanded = false,
  });

  final String petId;
  final Offset dragOffset;
  final SwipeAction? exitAction;
  final DiscoveryCandidate? exitingCard;
  final int exitDurationMs;
  final bool isExpanded;

  bool get isExiting => exitAction != null && exitingCard != null;

  DiscoveryState copyWith({
    Offset? dragOffset,
    SwipeAction? exitAction,
    DiscoveryCandidate? exitingCard,
    int? exitDurationMs,
    bool clearExit = false,
    bool? isExpanded,
  }) =>
      DiscoveryState(
        petId: petId,
        dragOffset: dragOffset ?? this.dragOffset,
        exitAction: clearExit ? null : (exitAction ?? this.exitAction),
        exitingCard: clearExit ? null : (exitingCard ?? this.exitingCard),
        exitDurationMs: clearExit ? 320 : (exitDurationMs ?? this.exitDurationMs),
        isExpanded: isExpanded ?? this.isExpanded,
      );
}

final discoveryControllerProvider =
    NotifierProvider.family<DiscoveryNotifier, DiscoveryState, String>(
  DiscoveryNotifier.new,
);

class DiscoveryNotifier extends Notifier<DiscoveryState> {
  DiscoveryNotifier(this.arg);
  final String arg;

  @override
  DiscoveryState build() => DiscoveryState(petId: arg);

  MatchingRepository get _repo => ref.read(matchingRepositoryProvider);

  void onDragUpdate(Offset delta) {
    if (state.isExiting) return;
    state = state.copyWith(dragOffset: state.dragOffset + delta);
  }

  void onDragEnd() {
    if (state.isExiting) return;
    final dx = state.dragOffset.dx;
    final dy = state.dragOffset.dy;
    if (dx > 90) {
      swipe(SwipeAction.match);
    } else if (dx < -90) {
      swipe(SwipeAction.pass);
    } else if (dy < -90) {
      swipe(SwipeAction.greet);
    } else {
      state = state.copyWith(dragOffset: Offset.zero);
    }
  }

  void onDragCancel() {
    if (!state.isExiting) state = state.copyWith(dragOffset: Offset.zero);
  }

  void swipe(SwipeAction action) {
    if (state.isExiting) return;
    final snap = ref.read(discoveryCandidatesControllerProvider);
    final deck = snap.asData?.value.candidates ?? const <DiscoveryCandidate>[];
    if (deck.isEmpty) return;
    final top = deck.first;
    final fast = ui.PlatformDispatcher.instance.accessibilityFeatures.disableAnimations;
    final ms = fast ? 80 : 320;

    state = state.copyWith(
      exitAction: action,
      exitingCard: top,
      dragOffset: Offset.zero,
      exitDurationMs: ms,
    );

    unawaited(
      ref.read(discoveryCandidatesControllerProvider.notifier).removeFront(),
    );

    _repo
        .recordSwipe(
          swiperPetId: arg,
          swipedPetId: top.petId,
          swipedOwnerUserId: top.ownerUserId ?? '',
          action: action.name,
        )
        .catchError((Object e) {
          debugPrint('[DiscoveryNotifier] swipe record failed: $e');
          if (ref.mounted) {
            ref.read(swipeErrorProvider.notifier).post(
              'Could not save swipe. Check your connection.',
            );
          }
        });

    Future.delayed(Duration(milliseconds: ms), () {
      if (!ref.mounted) return;
      state = state.copyWith(clearExit: true);
    });
  }

  void toggleExpand() =>
      state = state.copyWith(isExpanded: !state.isExpanded);
}
