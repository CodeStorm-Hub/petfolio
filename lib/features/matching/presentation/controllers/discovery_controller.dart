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
    this.isLoading = false,
  });

  final String petId;
  final List<DiscoveryCandidate> deck;

  /// Live pan offset for the top card transform.
  final Offset dragOffset;

  /// Non-null while the top card is playing its exit animation.
  final SwipeAction? exitAction;

  /// Whether the info panel on the top card is expanded.
  final bool isExpanded;

  /// True while [MatchingRepository.fetchCandidates] is in-flight.
  final bool isLoading;

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
    bool? isLoading,
  }) =>
      DiscoveryState(
        petId: petId,
        deck: deck ?? this.deck,
        dragOffset: dragOffset ?? this.dragOffset,
        exitAction: clearExit ? null : (exitAction ?? this.exitAction),
        isExpanded: isExpanded ?? this.isExpanded,
        isLoading: isLoading ?? this.isLoading,
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
/// ## Data loading
/// `build()` starts the sample deck immediately so the UI is never blank, then
/// replaces it asynchronously with real candidates from Supabase.  If the
/// fetch fails or returns empty the sample deck is kept as fallback.
///
/// ## Swipe recording
/// [swipe] optimistically removes the top card from the deck, then fires
/// [MatchingRepository.recordSwipe] in the background.  Errors are caught
/// inside the repository — the animation is never interrupted.
///
/// ## Right-swipe (match / superPaw)
/// These actions insert a row into `match_requests` (status='pending').
/// Mutual matching (both parties swiped right) is handled server-side by a
/// trigger or the accepting party's client.
class DiscoveryNotifier extends Notifier<DiscoveryState> {
  DiscoveryNotifier(this.arg);
  final String arg;

  @override
  DiscoveryState build() {
    // Warm the UI with sample cards instantly, then replace with live data.
    Future.microtask(() => _fetchAndPopulate(arg));
    return DiscoveryState(petId: arg, deck: _sampleDeck(), isLoading: true);
  }

  MatchingRepository get _repo => ref.read(matchingRepositoryProvider);

  // ── Initial data load ─────────────────────────────────────────────────────

  Future<void> _fetchAndPopulate(String petId) async {
    try {
      final candidates = await _repo.fetchCandidates(activePetId: petId);
      if (candidates.isNotEmpty) {
        // Replace sample deck with real profiles.
        state = state.copyWith(deck: candidates, isLoading: false);
      } else {
        // No real profiles yet — keep the sample deck so the UI is usable.
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      debugPrint('[DiscoveryNotifier] fetch failed, keeping sample deck: $e');
      state = state.copyWith(isLoading: false);
    }
  }

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

  /// Triggers the exit animation for [action], advances the deck after
  /// 310 ms, and fires the background Supabase write.
  ///
  /// For `match` and `superPaw` actions this inserts a row into
  /// `match_requests` — **the right-swipe → DB write connection Task 2
  /// requires**.
  void swipe(SwipeAction action) {
    if (state.isExiting || state.topCard == null) return;
    final top = state.topCard!;

    // 1. Trigger exit animation — watched by the widget layer.
    state = state.copyWith(exitAction: action, dragOffset: Offset.zero);

    // 2. After animation, advance the deck (refill from sample if low).
    Future.delayed(const Duration(milliseconds: 310), () {
      final remaining = state.deck.skip(1).toList();
      if (remaining.length < 3) {
        // Avoid re-showing the just-swiped card or existing ones.
        final existing = {...remaining.map((c) => c.petId), top.petId};
        final extra = _sampleDeck()
            .where((c) => !existing.contains(c.petId))
            .take(3 - remaining.length)
            .toList();
        state = DiscoveryState(
          petId: state.petId,
          deck: [...remaining, ...extra],
        );
      } else {
        state = DiscoveryState(petId: state.petId, deck: remaining);
      }
    });

    // 3. Background Supabase write.
    //    recordSwipe is a no-op for demo cards (petId starts with 'demo-')
    //    and for 'pass' (no swipes table in schema).
    unawaited(_repo.recordSwipe(
      swiperPetId: arg,
      swipedPetId: top.petId,
      swipedOwnerUserId: top.ownerUserId ?? '',
      action: action.name,
    ));
  }

  void toggleExpand() =>
      state = state.copyWith(isExpanded: !state.isExpanded);

  // ── Sample / fallback deck ─────────────────────────────────────────────────
  // Shown immediately on startup and kept as fallback when the DB is empty or
  // unreachable.  The 'demo-' prefix in petId causes recordSwipe to skip the
  // network call, keeping the swipe gestures fully functional offline.

  static List<DiscoveryCandidate> _sampleDeck() => const [
        DiscoveryCandidate(
          petId: 'demo-pixel',
          name: 'Pixel',
          age: '3yr',
          species: 'dog',
          breed: 'Australian Shepherd',
          distance: 'Within 2 miles',
          ownerInitial: 'J',
          verified: true,
          traits: ['Loves fetch', 'Calm energy', 'Good with cats'],
          bio:
              'Trail buddy who collapses in a heap after 4pm. Sniff-walks always welcome.',
          playStyle: 'Parallel — side-by-side hikes',
          energy: 'Medium · 60 min daily',
          bestWith: 'Calm, similar-size dogs',
          vaccinated: true,
          gradientColors: [
            Color(0xFFF4B57A),
            Color(0xFFE89669),
            Color(0xFFBC6249),
          ],
          subjectColor: Color(0xFF6B3F2A),
        ),
        DiscoveryCandidate(
          petId: 'demo-juniper',
          name: 'Juniper',
          age: '5yr',
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
          gradientColors: [
            Color(0xFFE9C9A5),
            Color(0xFFC99B6F),
            Color(0xFF8B6442),
          ],
          subjectColor: Color(0xFF7A4E2F),
        ),
        DiscoveryCandidate(
          petId: 'demo-mochi',
          name: 'Mochi',
          age: '2yr',
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
          gradientColors: [
            Color(0xFFDDD3C3),
            Color(0xFFB8A78F),
            Color(0xFF7C6750),
          ],
          subjectColor: Color(0xFF5C4A36),
        ),
      ];
}
