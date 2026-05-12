import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/discovery_candidate.dart';
import '../../data/repositories/matching_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Swipe action
// ─────────────────────────────────────────────────────────────────────────────

enum SwipeAction { pass, greet, match, superPaw }

// ─────────────────────────────────────────────────────────────────────────────
// State
// ─────────────────────────────────────────────────────────────────────────────

class DiscoveryState {
  const DiscoveryState({
    required this.petId,
    required this.deck,
    this.dragOffset = Offset.zero,
    this.exitAction,
    this.isExpanded = false,
  });

  final String petId;
  final List<DiscoveryCandidate> deck;

  /// Live pan offset for the top card transform.
  /// Updated on every GestureDetector.onPanUpdate event.
  final Offset dragOffset;

  /// Non-null while the top card is playing its exit animation.
  final SwipeAction? exitAction;

  /// Whether the info panel on the top card is expanded.
  final bool isExpanded;

  bool get isExiting => exitAction != null;

  DiscoveryCandidate? get topCard   => deck.isEmpty    ? null : deck[0];
  DiscoveryCandidate? get nextCard  => deck.length < 2 ? null : deck[1];
  DiscoveryCandidate? get afterCard => deck.length < 3 ? null : deck[2];

  DiscoveryState copyWith({
    List<DiscoveryCandidate>? deck,
    Offset? dragOffset,
    SwipeAction? exitAction,
    bool clearExit = false,
    bool? isExpanded,
  }) =>
      DiscoveryState(
        petId: petId,
        deck: deck ?? this.deck,
        dragOffset: dragOffset ?? this.dragOffset,
        exitAction: clearExit ? null : (exitAction ?? this.exitAction),
        isExpanded: isExpanded ?? this.isExpanded,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────────────────────

final discoveryControllerProvider =
    NotifierProvider.family<DiscoveryNotifier, DiscoveryState, String>(
  DiscoveryNotifier.new,
);

// ─────────────────────────────────────────────────────────────────────────────
// Notifier
// ─────────────────────────────────────────────────────────────────────────────

/// Manages the discovery card deck AND the swipe gesture state in Riverpod.
///
/// Gesture events come from the widget layer and update [dragOffset] directly.
/// When a threshold is crossed (or a dock button is pressed), [swipe] is called
/// which:
///   1. Sets [exitAction] → triggers the exit animation in the widget.
///   2. After 310 ms (animation + buffer), removes the card from [deck].
///   3. Fires [MatchingRepository.recordSwipe] in the background.
class DiscoveryNotifier extends FamilyNotifier<DiscoveryState, String> {
  @override
  DiscoveryState build(String petId) =>
      DiscoveryState(petId: petId, deck: _sampleDeck());

  MatchingRepository get _repo => ref.read(matchingRepositoryProvider);

  // ── Gesture API ───────────────────────────────────────────────────────────

  void onDragUpdate(Offset delta) {
    if (state.isExiting) return;
    state = state.copyWith(dragOffset: state.dragOffset + delta);
  }

  void onDragEnd() {
    if (state.isExiting) return;
    final dx = state.dragOffset.dx;
    final dy = state.dragOffset.dy;
    if (dx > 90)       { swipe(SwipeAction.match); }
    else if (dx < -90) { swipe(SwipeAction.pass); }
    else if (dy < -90) { swipe(SwipeAction.greet); }
    else               { state = state.copyWith(dragOffset: Offset.zero); }
  }

  void onDragCancel() {
    if (!state.isExiting) state = state.copyWith(dragOffset: Offset.zero);
  }

  // ── Action dock API ───────────────────────────────────────────────────────

  void swipe(SwipeAction action) {
    if (state.isExiting || state.topCard == null) return;
    final top = state.topCard!;

    // 1. Trigger exit animation immediately — widget watches exitAction.
    state = state.copyWith(exitAction: action, dragOffset: Offset.zero);

    // 2. After animation + buffer, advance the deck.
    Future.delayed(const Duration(milliseconds: 310), () {
      final remaining = state.deck.skip(1).toList();
      // Refill if running low to keep the stack always full.
      if (remaining.length < 3) {
        final extra = _sampleDeck()
            .where((c) => !remaining.any((r) => r.petId == c.petId))
            .take(3 - remaining.length)
            .toList();
        state = DiscoveryState(
            petId: state.petId, deck: [...remaining, ...extra]);
      } else {
        state = DiscoveryState(petId: state.petId, deck: remaining);
      }
    });

    // 3. Background Supabase sync — silently drops demo pet IDs.
    unawaited(_repo.recordSwipe(
      swiperPetId: arg,
      swipedPetId: top.petId,
      action: action.name,
    ));
  }

  void toggleExpand() =>
      state = state.copyWith(isExpanded: !state.isExpanded);

  // ── Sample deck ───────────────────────────────────────────────────────────
  // Used until real discovery profiles exist in the database.

  static List<DiscoveryCandidate> _sampleDeck() => const [
        DiscoveryCandidate(
          petId: 'demo-pixel',
          name: 'Pixel',
          age: '3 yr',
          species: 'dog',
          breed: 'Australian Shepherd',
          distance: 'Within 2 miles',
          ownerInitial: 'J',
          verified: true,
          traits: ['Loves fetch', 'Calm energy', 'Good with cats'],
          bio: 'Trail buddy who collapses in a heap after 4pm. Sniff-walks always welcome.',
          playStyle: 'Parallel — side-by-side hikes',
          energy: 'Medium · 60 min daily',
          bestWith: 'Calm, similar-size dogs',
          vaccinated: true,
          gradientColors: [Color(0xFFF4B57A), Color(0xFFE89669), Color(0xFFBC6249)],
          subjectColor: Color(0xFF6B3F2A),
        ),
        DiscoveryCandidate(
          petId: 'demo-juniper',
          name: 'Juniper',
          age: '5 yr',
          species: 'dog',
          breed: 'Cavalier Spaniel',
          distance: 'Within 1 mile',
          ownerInitial: 'A',
          verified: true,
          traits: ['Loves cuddles', 'Park days', 'Low energy'],
          bio: 'Senior softie. Will accept all the gentle ear scratches you have.',
          playStyle: 'Loose lead pottering, no zoomies',
          energy: 'Low · 30 min strolls',
          bestWith: 'Calm pups, kids welcome',
          vaccinated: true,
          gradientColors: [Color(0xFFE9C9A5), Color(0xFFC99B6F), Color(0xFF8B6442)],
          subjectColor: Color(0xFF7A4E2F),
        ),
        DiscoveryCandidate(
          petId: 'demo-mochi',
          name: 'Mochi',
          age: '2 yr',
          species: 'cat',
          breed: 'Domestic Shorthair',
          distance: 'Within 3 miles',
          ownerInitial: 'M',
          verified: false,
          traits: ['Indoor', 'Window adventures', 'Treat-motivated'],
          bio: 'Looking for a chill cat-cam pen-pal. Naps loudly.',
          playStyle: 'Wand toys, gentle chase',
          energy: 'Low',
          bestWith: 'Other cats via video',
          vaccinated: true,
          gradientColors: [Color(0xFFDDD3C3), Color(0xFFB8A78F), Color(0xFF7C6750)],
          subjectColor: Color(0xFF5C4A36),
        ),
      ];
}
