# Social / PawsFeed Module Audit

> Generated from full source review of `lib/features/social/` (39 files, ~4 500 lines of hand-written Dart).  
> Every issue is pinned to a specific file and line range.

---

## Directory snapshot

```
lib/features/social/
├── data/
│   ├── models/          feed_post, comment, story, hashtag, saved_post,
│   │                    pet_stats, pet_search_result, app_notification
│   └── repositories/    social_repository (617 L), comment_repository,
│                        story_repository, notification_repository,
│                        social_dm_repository
├── presentation/
│   ├── controllers/     social, comment, create_post, story, notification,
│   │                    saved_posts, hashtag, follow, social_profile, social_dm
│   ├── screens/         social_screen (1 654 L), post_detail, create_content,
│   │                    social_profile, notifications, story_viewer,
│   │                    saved_posts, hashtag, hashtag_search, social_dm,
│   │                    create_post, create_story
│   └── widgets/         post_comments_bottom_sheet, reaction_burst
├── social_routes.dart
└── index.dart
```

---

## Issues by severity

### P0 — Crash / Data-loss risk

| ID | File | Lines | Issue |
|----|------|-------|-------|
| **P0-1** | `create_content_screen.dart` | 47–56, 126–144 | **Mock Unsplash images ship to production.** The `_mockPetImages` list and `_selectMockImage()` are real, navigable code paths — users can pick third-party pet photos and post them as their own. This is both a copyright violation and a data-integrity problem. Must be removed before release. |
| **P0-2** | `create_content_screen.dart` | 129 | `http.get(Uri.parse(url))` uses the `http` package to download the mock image; even though the URLs are HTTPS strings, the raw http package doesn't enforce pinning and can be downgraded. More importantly, any HTTP (non-S) redirect would be silently followed. Use `https` enforcement or remove the code path. |
| **P0-3** | `social_controller.dart` | 78–109 | Realtime subscription **only handles `UPDATE` events**. New posts (`INSERT`) never appear in the feed without a manual pull-to-refresh; deleted posts (`DELETE`) remain visible until a refresh. Both are user-visible data integrity failures. |
| **P0-4** | `notifications_screen.dart` | 387–411 | **"Copy code" button copies nothing.** `onTap` fires only `HapticFeedback.selectionClick()`. The promo code is never written to the clipboard. Users see confirmation haptic but their paste buffer is empty — high confusion, zero utility. |

---

### P1 — Broken feature

| ID | File | Lines | Issue |
|----|------|-------|-------|
| **P1-1** | `social_screen.dart` | 1 382–1 388 | **Save button on PostCard is dead UI.** `onTap` shows a `SnackBar('Saved posts coming soon')`. The `SavedPostsScreen`, `SavedPostsController`, and repository methods (`savePost`, `unsavePost`) are fully implemented; only the PostCard's "Save" action remains unwired. |
| **P1-2** | `social_screen.dart` | 1 288–1 295 | **`_EmojiCircle` `index` argument is always `0` for all three circles** in the reaction stack visualiser. The `Transform.translate` in `_EmojiCircle.build` only executes when `index != 0` (line 1458–1 463), so the overlapping-circles effect never renders — all three circles stack at position 0. |
| **P1-3** | `social_screen.dart` | 251–268 | **No wave header widget is rendered.** `headerHeight` is calculated and used to push feed content down, but there is no widget in the `Stack` that actually draws the wave header above the feed. The reserved space is blank. |
| **P1-4** | `social_controller.dart` | 154–160 | `loadMore()` swallows its error silently — the catch block only resets `isLoadingMore`. There is no user-facing error; if pagination fails the user sees the list stop growing with no explanation and no retry affordance. |
| **P1-5** | `post_detail_screen.dart` | 150–163 | Error state for a failed post load shows `Text('Failed to load post.')` with no retry button. Users are stuck with a back button as their only escape. |
| **P1-6** | `post_detail_screen.dart` | 655–680 | **`_BookmarkButton` calls the repository directly** (`ref.read(socialRepositoryProvider)`) then manually invalidates a provider. This bypasses the controller layer (breaks architecture rule in `.claude/rules/flutter-architecture.md`) and means optimistic state, error handling, and analytics hooks are absent. |
| **P1-7** | `post_detail_screen.dart` | 1 332–1 358 | **Edit Caption dialog has no `maxLength`** constraint on its `TextField`. A user can submit a 10 000-character caption, which will reach the DB and break the feed card layout on the next render. |
| **P1-8** | `post_detail_screen.dart` | 1 348–1 357 | After editing a caption via `PostOptionsSheet`, `updateCaption` updates the feed controller's in-memory state but **`postDetailProvider` is never invalidated**. If the user navigated to the detail view via deep link (no feed backing), the caption stays stale. |
| **P1-9** | `social_profile_screen.dart` | 63 | `resolvedPet = pet ?? (isOwnProfile ? activePet : null)` — when `petByIdProvider` returns `null` for a valid petId (profile not yet indexed or deleted), the screen silently renders the **active pet's** profile instead of showing an error. Followers/following taps would interact with the wrong profile. |
| **P1-10** | `social_profile_screen.dart` | 325–329 | Followers and Following columns show a `SnackBar('…coming soon')` on tap. These are primary social metrics — tapping them is a natural, expected interaction. Stale "coming soon" messaging in a shipped feature is a P1 UX regression. |
| **P1-11** | `social_repository.dart` | 499–515 | `attachHashtagsToPost` silently swallows `PostgrestException`. A hashtag indexing failure produces no log, no error surface, and no retry. Posts silently lose all hashtag associations; hashtag discovery is broken for affected posts. |
| **P1-12** | `notifications_screen.dart` | 38–40 | `markAllRead()` is called unconditionally in `initState` via `addPostFrameCallback`. Unread badges are cleared the instant the user navigates to the screen, **before they scroll to and read the notifications**. Unread state is effectively meaningless. |
| **P1-13** | `create_content_screen.dart` | 158–178 | After a successful post, `context.pop()` is called but `refresh()` only runs for `ContentMode.post`. For `ContentMode.story`, the stories list is never refreshed; the new story doesn't appear until the user leaves and returns to the feed. |

---

### P2 — UX gap / incorrect behaviour

| ID | File | Lines | Issue |
|----|------|-------|-------|
| **P2-1** | `social_screen.dart` | 116 | Scroll threshold for `loadMore()` is hardcoded at `300` px regardless of screen height. On tall devices this triggers too early; on short screens it may never trigger before the user hits the list bottom. Use `pos.pixels >= pos.maxScrollExtent - (pos.viewportDimension * 0.5)`. |
| **P2-2** | `social_screen.dart` | 43–48 | `_SocialView` is keyed by `petId`. When the active pet changes, the **entire widget subtree (scroll position, loaded pages, realtime subscription) is torn down and rebuilt** from scratch — a jarring flash and wasted network traffic. A pet-switch should trigger `notifier.refresh()` within the existing view instead. |
| **P2-3** | `social_screen.dart` | 996–998 | `_handleShortTap()` toggles the like on every short tap of the like button area, but the `_reacted` local state and the `post.isLiked` server state can desync: if a re-render arrives between the optimistic update and the callback, `_reacted` is reset but `onLike()` is called again — double-toggling the like. |
| **P2-4** | `post_detail_screen.dart` | 73 | Comment reply logic: `parentId: _replyingToComment?.parentId ?? _replyingToComment?.id`. This intentionally collapses reply-of-reply into a 2-level thread, which is correct UX-wise — but there is no inline indication to the user that their reply will attach to the root comment rather than the comment they tapped. |
| **P2-5** | `post_detail_screen.dart` | 86–91 | `Future.delayed(100ms)` before scrolling to new comment has no cancellation if the widget is disposed mid-delay. Though a mount check exists, the delay is unnecessary — use `WidgetsBinding.instance.addPostFrameCallback` instead. |
| **P2-6** | `post_detail_screen.dart` | 94–102 | Comment send error uses a raw `ScaffoldMessenger.showSnackBar(SnackBar(...))` with a manual background colour. Every other screen in the app uses `AppSnackBar.showError(e)`. Inconsistent error presentation. |
| **P2-7** | `create_content_screen.dart` | 162–177 | Success notification after post creation uses a raw `ScaffoldMessenger.showSnackBar(...)`. Same inconsistency as P2-6. |
| **P2-8** | `social_repository.dart` | 308–309 | `uploadPostImage` returns a **public URL** from the `post-images` bucket. If the bucket requires authentication (signed URLs), this breaks. If it is intentionally public, there is no CDN transform URL (resizing, format conversion). Document the intent or switch to signed URLs. |
| **P2-9** | `social_repository.dart` | 210–232 | Species palette only covers `dog`, `cat`, and `rabbit`. All other species (bird, hamster, fish, reptile, etc.) fall through to the dog default (blue palette), giving them an inaccurate brand colour. Add a generic `other` entry or derive colour from the species string hash. |
| **P2-10** | `story_viewer_screen.dart` | 219 | `_floatingEmojis.removeWhere((e) => e.emoji == emoji)` removes **all** items with that emoji, not just the one that finished animating. If the user taps 🐾 twice rapidly, both burst animations disappear when the first one finishes. Use the unique `key` field for removal: `removeWhere((e) => e.key == data.key)`. |
| **P2-11** | `story_viewer_screen.dart` | 325–370 | Story images have no caption/text overlay support. Instagram-style text and stickers are table-stakes for stories; this is a feature gap. |
| **P2-12** | `story_viewer_screen.dart` | 550–556 | Profile navigation from within the story viewer cancels the timer but uses `.then((_) => _startStory(...))` to resume. If the user swipes to a different app while the profile is open, the story restarts from the saved position — possibly at the wrong story if the page controller moved. Consider pausing and tracking resume position via `WidgetsBindingObserver`. |
| **P2-13** | `social_profile_screen.dart` | 742–753 | "Share Profile" URL is hardcoded to `https://petfolio.app/social/profile/{id}`. This won't deep-link correctly unless the production domain is confirmed. Extract to a constant or `AppConfig`. |
| **P2-14** | `social_profile_screen.dart` | 162–258 | Profile posts grid has **no pagination**. `socialProfilePostsProvider` fetches all posts for a pet in one request (`limit: 30`). A pet with many posts hits this cap silently — the grid stops at 30 with no "load more". |
| **P2-15** | `notifications_screen.dart` | 260–266 | Promotions tab shows the same `PetfolioEmptyState` for both `error` and `data([])` states. An error should show a retry option; an empty list should show the empty-state copy. |
| **P2-16** | `notifications_screen.dart` | 55–60 | Unread badge count is computed inline in `build()` from the full notification list on every rebuild. Extract to a derived provider (e.g. `unreadCountProvider`) so the badge doesn't cause the entire screen to rebuild when a single notification arrives via realtime. |
| **P2-17** | `social_dm_screen.dart` | — | The DM screen delegates to `UnifiedChatScreen` correctly, but there is no entry point from the social feed or profile to start a DM with a post author (only from the profile page). "Message" on the PostCard is absent. |
| **P2-18** | `hashtag_screen.dart` | — | Hashtag feed does not reset `_hasMore` or clear posts when the tag query parameter changes (e.g. deep link to a new tag). Stale "no more posts" state is surfaced for the new tag. |
| **P2-19** | `create_content_screen.dart` | 93–108 | `_pickFromCamera()` calls the platform camera without checking or requesting camera permission first. On Android 13+ and iOS, this surfaces a system dialog mid-flow; a denied permission leaves the user stranded with no explanation. Use `permission_handler` or `image_picker`'s built-in permission handling with an explicit pre-check. |
| **P2-20** | `social_repository.dart` | 440–453 | `searchHashtags` strips `#` before querying but doesn't trim trailing punctuation (`#cute!` → `cute!`). A tag like `#cute!` reaches the DB as `cute!`, matching nothing and silently returning an empty list. Apply `RegExp(r'[^a-zA-Z0-9_]')` strip after trimming. |

---

### P3 — Polish / maintainability

| ID | File | Lines | Issue |
|----|------|-------|-------|
| **P3-1** | `social_screen.dart` | 1 063–1 435 | `PostCard` is a 370-line `StatefulWidget`. Its gesture state, like/reaction state, burst animation, and picker state should be extracted into at minimum two classes: `_PostCardReactionLayer` and `_PostCardActions`. The current size makes refactoring and testing difficult. |
| **P3-2** | `social_screen.dart` | 912–999 | Pointer tracking in `_onPointerMove` uses **hardcoded pixel offsets** (`y >= cardHeight - 140`, `relativeX <= 192`) that assume a fixed card height and picker width. On large text/accessibility scale these offsets are wrong and the hover effect breaks. Use `RenderBox.localToGlobal` on the picker container instead. |
| **P3-3** | `post_detail_screen.dart` | 559–586 | `_TappableHashtagText` creates and lays out a `TextPainter` on every `onTapUp`. For long captions with many hashtags this is expensive on the main thread. Cache the painter or use `TextSpan.recognizer` (a `TapGestureRecognizer` per hashtag span) — the standard Flutter approach that avoids layout on tap. |
| **P3-4** | `story_viewer_screen.dart` | 36–37 | `_tickMs = 50` (20 fps progress updates) runs a `Timer.periodic` that calls `setState` 20 times per second, triggering a full subtree rebuild including the progress bars, pet info, and reaction overlay. Extract the progress bars into a separate `StatefulWidget` or use `AnimationController` with `AnimatedBuilder` — a zero-rebuild approach. |
| **P3-5** | `social_repository.dart` | 278–309 | `uploadPostImage` and story upload both use the `post-images` bucket. Stories and posts have different retention, RLS, and CDN requirements; separate buckets (`story-images`) improve policy clarity and allow independent expiry rules. |
| **P3-6** | `social_repository.dart` | 463–493 | `fetchPostsForHashtag` makes **two sequential round-trips**: one to `post_hashtags` for IDs, then a second to `posts` for the full rows. A single `post_hashtags` join query or a Postgres view/RPC would halve latency. |
| **P3-7** | `social_controller.dart` | 78–109 | The realtime channel name includes `petId`: `'social_feed_$petId'`. When the user switches pets, the old channel is disposed but the channel name changes — creating a new subscription without cleaning up the old one until the provider is fully disposed. Unsubscribe explicitly before re-subscribing. |
| **P3-8** | `notifications_screen.dart` | 86–87 | `GoogleFonts.sora(...)` is called directly in `build()` without caching. Every rebuild re-instantiates the `TextStyle`. Use `Theme.of(context).textTheme` or a pre-cached constant from the app theme. |
| **P3-9** | `create_content_screen.dart` | 39–41 | `_pulseController` repeats indefinitely even when the story mode camera tile is not visible (e.g. after switching to post mode). Pause the controller when `_mode != ContentMode.story`. |
| **P3-10** | `social_screen.dart` | 808 | `_StoryItem` creates an `AnimationController` in `initState` and a second one in `didUpdateWidget` if the widget switches from static to animated. If `didUpdateWidget` fires before the first frame the second controller is created before the first is disposed, leaking a ticker. Guard with `_ringCtrl != null` before creating a replacement. |
| **P3-11** | Multiple screens | — | `Semantics(button: true, child: GestureDetector(...))` is used throughout instead of wrapping with `InkWell`. `GestureDetector` inside `Semantics` doesn't produce a `MaterialButton` semantics node — screen readers announce "button" but won't get the activated/focused visual feedback. Prefer `InkWell` with a custom `borderRadius` when a ripple is acceptable, or `GestureDetector` + explicit `Semantics(onTap: ...)`. |
| **P3-12** | `social_screen.dart` | 228–229 | "You're all caught up 🐾" footer is rendered unconditionally, even when `hasMore` is still true. It should only appear after `!hasMore`. |

---

## Architecture observations

### Strengths
- Clean feature-first folder structure adhering to the project rules.
- Consistent optimistic UI across likes, comments, and follows with proper rollback on error.
- `select()`-optimised Riverpod consumers (`_SocialPostListSliver`, `_LoadMoreSliver`) prevent unnecessary rebuilds — good pattern.
- `SocialController.loadMore()` deduplicates by existing IDs before appending — prevents duplicates during scroll.
- `StoryViewerScreen.dispose()` correctly cancels the timer — no leak.
- `PostCard` correctly respects `didUpdateWidget` to sync `_reacted` with server state.
- `fetchPetStats` uses a single RPC instead of three parallel queries — good.

### Weaknesses
- **No realtime INSERT/DELETE handling**: the feed is stale until manual refresh.
- **Repository called from widget** (`_BookmarkButton`) — violates layering rules.
- **Mock data in production code** (`_mockPetImages`) — should be feature-flagged or removed.
- **Hardcoded magic numbers** for gesture hit areas and scroll thresholds.
- **No retry logic** for any network failure except feed load and story load.
- **No request debouncing** on the reaction picker — rapid taps can fire multiple `toggleLike` calls.
- **Two-query pattern** for hashtag posts where one query (join/view) would suffice.
- `loadMore()` error is silently dropped, violating the project's "don't fail silently" principle.

---

## Screen-by-screen UI/UX review

### `SocialScreen` / Feed
| Area | Status | Notes |
|------|--------|-------|
| Empty state | ✅ Good | Relevant CTA, correct icon |
| Loading skeleton | ✅ Good | 2 skeleton cards + 5 story skeletons |
| Error state | ✅ Good | Retry button present |
| Stories row | ⚠️ Gap | No label for the overall row (accessibility); no "view all" entry |
| Wave header | ❌ Missing | Space is reserved but no header widget is rendered |
| Infinite scroll | ⚠️ Gap | Threshold hardcoded; end-of-feed message shown prematurely (P3-12) |
| Wide layout | ✅ Good | Constrained to 560 px for tablets |
| FAB | ✅ Good | Correct label, correct route, sets `isStory: false` |

### `PostCard`
| Area | Status | Notes |
|------|--------|-------|
| Reaction picker | ✅ Good | Long-press, hover, slide-to-select — polished interaction |
| Reaction burst animation | ✅ Good | Random count, correct cleanup |
| Emoji stack visualiser | ❌ Broken | All circles render at position 0 (P1-2) |
| Share action | ✅ Good | Uses `SharePlus` |
| Save action | ❌ Dead | "Coming soon" snackbar despite full implementation existing |
| Caption hashtags | ✅ Good | Highlighted but not tappable on the card (tappable on detail) |
| Video player | ✅ Good | Muted auto-play, mute toggle |
| Image loading | ✅ Good | Memory + disk cache, shimmer placeholder, paw fallback |
| Accessibility | ⚠️ Partial | Semantic labels on all zones; `GestureDetector + Semantics` pattern (P3-11) |

### `StoryViewerScreen`
| Area | Status | Notes |
|------|--------|-------|
| Progress bars | ✅ Good | Segmented per story, smooth fill |
| Pet navigation | ✅ Good | PageView + tap zones for prev/next |
| Pause on long-press | ✅ Good | `_isPaused` flag, correct resume |
| Reactions | ⚠️ Gap | Emoji removal bug (P2-10); no persistence of who sent what reaction |
| Caption/text on story | ❌ Missing | No text overlay capability |
| Timer performance | ⚠️ Gap | 20 fps setState rebuilds entire screen (P3-4) |
| Duplicate emoji burst removal | ❌ Bug | By emoji value, not key (P2-10) |

### `CreateContentScreen`
| Area | Status | Notes |
|------|--------|-------|
| Post mode image well | ✅ Good | Aspect ratio locked, memory preview, remove button |
| Story mode camera tile | ✅ Good | Animated viewfinder, pulse, grid overlay |
| Story gallery | ❌ Mock data | 9 hardcoded Unsplash images (P0-1) |
| Caption character counter | ✅ Good | Near-limit and at-limit colour changes |
| Visibility selector | ⚠️ Gap | "Public post" row has a chevron but no action — misleading |
| Upload overlay | ✅ Good | Step-labelled spinner, blocks interaction |
| Camera permission | ❌ Missing | No pre-check before picker opens (P2-19) |
| Success snackbar | ⚠️ Gap | Raw SnackBar instead of AppSnackBar (P2-7) |

### `PostDetailScreen`
| Area | Status | Notes |
|------|--------|-------|
| Multi-image carousel | ✅ Good | PageView + animated dots |
| Comment thread | ✅ Good | O(n) grouping, 2-level nesting |
| Reply banner | ✅ Good | Shows target handle, dismissible |
| Comment input | ✅ Good | Animated focus ring, character counter on approach |
| Save button | ✅ Wired | `_BookmarkButton` works (but wrong layer — P1-6) |
| Error state | ⚠️ Gap | No retry (P1-5) |
| Edit caption dialog | ⚠️ Gap | No `maxLength` (P1-7) |
| Report flow | ✅ Good | Radio group, loading state, duplicate detection |
| Hashtag tap in caption | ✅ Good | `TextPainter` hit-test → push hashtag route |
| Error snackbar | ⚠️ Gap | Raw SnackBar instead of AppSnackBar (P2-6) |

### `SocialProfileScreen`
| Area | Status | Notes |
|------|--------|-------|
| Avatar + gradient ring | ✅ Good | Subtle tangerine→violet gradient |
| Stats row | ⚠️ Gap | Followers/following taps show "coming soon" (P1-10) |
| Care & achievements | ✅ Good | Stat cards + badge strip |
| Follow / unfollow | ✅ Good | Optimistic toggle with AnimatedSwitcher |
| Message button | ✅ Good | Delegates to `openDirectChat` |
| Profile posts grid | ⚠️ Gap | No pagination beyond 30 posts (P2-14) |
| Fallback to wrong profile | ❌ Bug | Silently shows active pet's profile (P1-9) |
| Own profile: share | ⚠️ Gap | Hardcoded URL (P2-13) |

### `NotificationsScreen`
| Area | Status | Notes |
|------|--------|-------|
| Tab bar | ✅ Good | Pathao-style underline indicator, unread badge |
| Mark all read | ❌ UX bug | Called on open, not on scroll/read (P1-12) |
| Updates list | ✅ Good | Slide-in animation, unread dot, correct empty state |
| Promotions tab | ❌ Bug | "Copy code" does nothing (P0-4); error shows empty state (P2-15) |
| Unread count | ⚠️ Gap | Derived inline, causes rebuild on every notification (P2-16) |

### `StoryViewerScreen` reactions / `_StoriesRow`
| Area | Status | Notes |
|------|--------|-------|
| Own story long-press | ✅ Good | Options sheet: view, add |
| Unviewed ring animation | ✅ Good | SweepGradient rotation |
| Sort by unviewed | ✅ Good | Unviewed stacks sorted first |
| Retry on story load error | ✅ Good | Inline retry link |
| Accessibility | ⚠️ Gap | `_StoryItem` uses `GestureDetector + Semantics` (P3-11) |

---

## Recommended fix order

### Immediate (before next release)
1. **P0-1 / P0-2** — Remove `_mockPetImages`, `_selectMockImage`, and the mock grid from `CreateContentScreen`.
2. **P0-4** — Wire "Copy code" button in `_PromoNotifCard` to `Clipboard.setData`.
3. **P1-1** — Wire `PostCard` Save button to `savePost` / `unsavePost` (the controller already exists).
4. **P0-3** — Add `INSERT` and `DELETE` event handlers in `_subscribeToRealtime`.
5. **P1-12** — Move `markAllRead` to a scroll listener or explicit "mark as read" per tile interaction.

### Short-term (next sprint)
6. **P1-2** — Fix `_EmojiCircle` `index` argument (`Positioned(left: 0/18/36)` already handles offsets; remove the `index` param or pass correct indices).
7. **P1-3** — Add the wave header widget to `_SocialViewState.build`.
8. **P1-7** — Add `maxLength: 500` (or configured limit) to the Edit Caption `TextField`.
9. **P1-9** — Show an error / empty state when `petByIdProvider` returns null instead of falling back to the active pet.
10. **P1-10** — Implement or remove the Followers/Following list; don't ship dead "coming soon" taps.
11. **P2-10** — Fix story floating emoji removal to use unique `key` field.
12. **P2-19** — Add camera permission pre-check before `pickImage(source: ImageSource.camera)`.
13. **P1-11** — Log hashtag attach failures via `developer.log` so they're diagnosable.

### Medium-term
14. **P1-4** — Surface pagination errors with a retry affordance at the end of the feed list.
15. **P1-6** — Move bookmark logic from `_BookmarkButton` into a dedicated controller method.
16. **P2-1** — Replace hardcoded 300 px scroll threshold with a viewport-relative calculation.
17. **P2-9** — Extend species palette or derive colour from species string hash.
18. **P3-4** — Replace `Timer.periodic` in `StoryViewerScreen` with `AnimationController` + `AnimatedBuilder` to eliminate 20 fps full-tree `setState`.
19. **P3-6** — Collapse the two-query hashtag fetch into a single joined query or RPC.
20. **P3-12** — Move "You're all caught up" footer behind a `!feedState.hasMore` guard.

---

## Quick-win checklist

```
[ ] Remove _mockPetImages from create_content_screen.dart
[ ] Fix _PromoNotifCard "Copy code" → Clipboard.setData(ClipboardData(text: promo.code))
[ ] Wire PostCard Save → SavedPostsController.save/unsave
[ ] Add INSERT + DELETE handlers to _subscribeToRealtime
[ ] Fix _EmojiCircle index argument (pass 0/1/2, not always 0)
[ ] Add wave header widget to SocialScreen Stack
[ ] Add maxLength to Edit Caption TextField
[ ] Guard "You're all caught up" footer behind !hasMore
[ ] Fix _FloatingEmojiData removal to use key, not emoji
[ ] Move markAllRead() out of initState → per-notification read or explicit CTA
[ ] Add camera permission check before pickImage
[ ] Fix P1-9 wrong-pet profile fallback
[ ] Log hashtag attach failures
[ ] Fix _StoryItem AnimationController double-create in didUpdateWidget
[ ] Remove hardcoded petfolio.app domain from share URLs → AppConfig constant
```

---

*Audit covers all 39 source files. Generated 2026-06-27.*
