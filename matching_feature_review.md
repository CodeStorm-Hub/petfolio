# Petfolio — Matching/Discovery Feature: Code Review

**Reviewer:** Senior Staff Mobile Engineer & Backend Architect  
**Branch:** `afsan-final-check`  
**Scope:** `lib/features/matching/`, `supabase/migrations/` (matching-related)  
**Date:** 2026-05-30

---

## Executive Summary

The matching feature is architecturally sound and shows a mature grasp of Riverpod's concurrency primitives. The epoch-guard in `DiscoveryCandidatesController`, the `_replenishLocked` mutex, and proper `ref.onDispose` cleanup are genuine highlights. The PostGIS schema is well-indexed, the `LEAST/GREATEST` canonical-pair constraint is correct, and the `ON CONFLICT DO NOTHING` fix in `ensure_chat_thread_for_match` is the right approach for race conditions.

That said, there are **two production-blocking issues** (one a data-integrity gap, one a performance N+1 in every discovery call), plus **one high-severity UI bug** (a double-reversal in chat that wastes O(n) allocations per frame). Several medium issues — hardcoded vaccination status shown to users, an unbounded location cache, and silent send-failures — should be fixed before launch.

---

## Critical & High Priority Issues

---

### 🔴 CRITICAL-1 — `chat_messages` table is absent from version-controlled migrations

**File:** `supabase/migrations/` (all 60+ files)

**Problem:**  
No migration file contains `CREATE TABLE chat_messages` or `ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY`. The table is referenced by `handle_new_chat_message()` (cleaned up in `20260524000000`) and by the `chat_messages` index in `20260518170000`, but its DDL and RLS policies do not exist in the repository.

This means the INSERT and SELECT RLS posture for chat messages **cannot be audited or reproduced** from the migration history. If RLS is disabled or the INSERT policy allows `thread_id` to be forged (no `thread_id` ownership check), any authenticated user can write messages into any thread they know the UUID of.

**Fix:**  
Add a migration that at minimum documents (and ideally creates) the table with its RLS policies:

```sql
-- Ensure RLS is on (idempotent)
ALTER TABLE public.chat_messages ENABLE ROW LEVEL SECURITY;

-- Only thread participants can read messages
CREATE POLICY "chat_messages: select by participant"
  ON public.chat_messages FOR SELECT TO authenticated
  USING (
    thread_id IN (
      SELECT id FROM public.chat_threads
      WHERE participant_1_id = (SELECT auth.uid())
         OR participant_2_id = (SELECT auth.uid())
    )
  );

-- Only thread participants can insert, and only as themselves
CREATE POLICY "chat_messages: insert by participant"
  ON public.chat_messages FOR INSERT TO authenticated
  WITH CHECK (
    sender_id = (SELECT auth.uid())
    AND thread_id IN (
      SELECT id FROM public.chat_threads
      WHERE participant_1_id = (SELECT auth.uid())
         OR participant_2_id = (SELECT auth.uid())
    )
  );
```

---

### 🔴 CRITICAL-2 — N+1 correlated subquery per candidate row in `matching_discovery_candidates`

**File:** `supabase/migrations/20260525200000_pr10_security_fixes.sql` (lines 168–177)

**Problematic code:**
```sql
SELECT
  c.id,
  ...
  (                              -- ← runs once per returned row
    SELECT jsonb_build_object(
      'id',           u.id,
      'username',     u.username,
      'display_name', u.display_name
    )
    FROM public.users u
    WHERE u.id = c.owner_id
  ) AS owner
FROM origin o
CROSS JOIN public.pets c
...
LIMIT 20;
```

With `p_limit = 20`, this executes **21 queries per discovery call** (1 outer + 20 correlated subqueries). At 10 concurrent users actively swiping, that's 200 queries/second against `public.users` for owner lookups alone. The function is `STABLE SECURITY DEFINER`, so Postgres cannot benefit from row-level plan caching across different callers.

**Fix:** Replace the correlated subquery with a LATERAL join that the planner can hash-join in a single pass:

```sql
FROM origin o
CROSS JOIN public.pets c
LEFT JOIN public.swipes s
  ON s.actor_id = p_actor_pet_id AND s.target_id = c.id
LEFT JOIN LATERAL (
  SELECT jsonb_build_object(
    'id',           u.id,
    'username',     u.username,
    'display_name', u.display_name
  ) AS owner_json
  FROM public.users u
  WHERE u.id = c.owner_id
  LIMIT 1
) owner_sub ON true
WHERE ...
```

Then reference `owner_sub.owner_json AS owner` in the SELECT list.

---

### 🔴 HIGH-1 — Double-reversal in chat burns O(n) allocation on every build

**File:** `lib/features/matching/presentation/screens/chat_screen.dart` (lines 145–156)

**Problematic code:**
```dart
data: (messages) {
  final reversedMessages = messages.reversed.toList(); // ← O(n) copy every rebuild
  return ListView.builder(
    controller: _scrollController,
    reverse: true,                                       // ← reverses again
    itemCount: reversedMessages.length,
    itemBuilder: (context, index) {
      final msg = reversedMessages[index];
```

`messages` is already in ascending chronological order (datasource fetches with `ascending: true`). `ListView(reverse: true)` renders index 0 at the bottom and index n-1 at the top. So passing the ascending list directly produces newest-at-bottom — the desired behavior. The `.reversed.toList()` creates a redundant reversed copy on every rebuild (every keystroke, every incoming Realtime message).

**Fix:**
```dart
data: (messages) {
  return ListView.builder(
    controller: _scrollController,
    reverse: true,
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
    itemCount: messages.length,
    itemBuilder: (context, index) {
      // reverse:true → index 0 is bottom (newest); read ascending list from end
      final msg = messages[messages.length - 1 - index];
      final isMine = msg.senderId == myUserId;
      return _MessageBubble(message: msg, isMine: isMine);
    },
  );
},
```

---

### 🔴 HIGH-2 — OFFSET-based pagination with `ORDER BY created_at DESC` is unstable

**File:** `supabase/migrations/20260525200000_pr10_security_fixes.sql` (lines 210–212); consumed in `lib/features/matching/presentation/controllers/discovery_candidates_controller.dart` (lines 266–287)

**Problematic code:**
```sql
ORDER BY c.created_at DESC
OFFSET greatest(coalesce(p_offset, 0), 0)
LIMIT  greatest(coalesce(nullif(p_limit, 0), 20), 1);
```

If a new pet registers (or becomes discoverable) between page-1 and page-2 fetches, the entire result set shifts by one row. This causes:
- **Skipped candidates** — a pet straddles the page boundary and is never shown
- **Duplicates** — a pet appears on two consecutive pages (mitigated by the controller's `existing` dedup set, but skips are invisible)

**Fix:** Replace `OFFSET` with keyset/cursor pagination:

```sql
-- New parameter: p_cursor_created_at timestamptz DEFAULT NULL
WHERE ...
  AND (p_cursor_created_at IS NULL OR c.created_at < p_cursor_created_at)
ORDER BY c.created_at DESC
LIMIT ...;
```

The controller returns `lastCandidate.createdAt` as the cursor for the next `_fetchPage` call instead of `nextOffset`.

---

### 🔴 HIGH-3 — Swipe upsert can silently downgrade LIKE → PASS while match record persists

**File:** `lib/features/matching/data/datasources/matching_supabase_data_source.dart` (lines 69–82)

**Problematic code:**
```dart
await _client.from('swipes').upsert(
  {
    'actor_id': actorPetId,
    'target_id': targetPetId,
    'action': action.dbValue,
  },
  onConflict: 'actor_id,target_id', // ← any action, any direction
);
```

The mutual-match trigger fires only `AFTER INSERT`, not after UPDATE. If Actor A previously sent LIKE for Pet B (creating a match), and the app re-submits a PASS for the same pair (e.g., duplicate drag event), the `onConflict` UPDATE path overwrites the swipe row to `PASS` while the `matches` row persists unchanged. The database is now inconsistent: the match record is valid but the underlying swipe says PASS.

The inverse race is also possible: two concurrent LIKEs for a new pair both hit `ON CONFLICT DO UPDATE`, only one path triggers the AFTER INSERT trigger, and no match is created.

**Fix:** Make swipes write-once at the application layer. Use `INSERT ... ON CONFLICT DO NOTHING`:

```dart
await _client.from('swipes').insert(
  {
    'actor_id': actorPetId,
    'target_id': targetPetId,
    'action': action.dbValue,
  },
).onConflict('actor_id,target_id').doNothing();
```

If LIKE-upgrade semantics are ever needed, handle it explicitly with a separate UPDATE path that also fires a stored procedure to check for the resulting mutual match.

---

### 🟠 HIGH-4 — `AppLifecycleState.resumed` triggers full GPS + DB reload on every foreground

**File:** `lib/features/matching/presentation/screens/matching_screen.dart` (lines 128–139)

**Problematic code:**
```dart
@override
void didChangeAppLifecycleState(AppLifecycleState state) {
  if (state == AppLifecycleState.resumed) {
    _refreshLocationState(); // invalidates GPS fix + full candidate RPC
  }
}
```

On Android, `resumed` fires on every permission-dialog dismiss, notification-shade open, and app-switch. During the location-permission onboarding flow this fires 2–3 times in rapid succession, each acquiring a GPS fix and re-querying the PostGIS RPC. This also means returning from the Chat screen to the Matching screen triggers a full deck reload.

**Fix:** Track the previous location access state and only invalidate `discoveryCandidatesControllerProvider` when access transitions from blocked → granted:

```dart
LocationAccessState? _prevAccess;

@override
void didChangeAppLifecycleState(AppLifecycleState state) {
  if (state != AppLifecycleState.resumed) return;
  ref.invalidate(locationAccessProvider);
  ref.invalidate(deviceLatLngProvider);
  final current = ref.read(locationAccessProvider).asData?.value;
  if (_isLocationBlocked(_prevAccess) && current == LocationAccessState.granted) {
    ref.invalidate(discoveryCandidatesControllerProvider);
  }
  _prevAccess = current;
}
```

---

## Medium & Low Priority Issues

---

### 🟡 MEDIUM-1 — `vaccinated: true` is hardcoded for every discovery candidate

**File:** `lib/features/matching/presentation/controllers/discovery_candidates_controller.dart` (line 320)

```dart
return DiscoveryCandidate(
  ...
  vaccinated: true,  // ← always true regardless of DB
```

If this field is displayed as a "Vaccinated ✓" badge, it misleads users. Either add a `vaccinated` column to the `pets` table (with a migration and toggle in the pet-edit flow), or set this to `false` / remove the field until it's backed by real data.

---

### 🟡 MEDIUM-2 — `send()` errors are silently swallowed; user sees no feedback

**File:** `lib/features/matching/presentation/screens/chat_screen.dart` (lines 49–67)

```dart
Future<void> _send() async {
  ...
  try {
    await ref.read(...).send(text);
    _textController.clear();
  } finally {
    if (mounted) setState(() => _sending = false);
  }
  // no catch block — network errors bubble to Flutter's unhandled handler
```

A network failure or RLS violation surfaces silently. The send button re-enables with no message.

**Fix:**
```dart
} catch (e) {
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Message failed to send. Try again.')),
    );
  }
} finally {
  if (mounted) setState(() => _sending = false);
}
```

---

### 🟡 MEDIUM-3 — `_petLocationCache` is unbounded and returns stale `true` forever

**File:** `lib/features/matching/data/repositories/matching_repository.dart` (lines 29–38)

```dart
final Map<String, bool> _petLocationCache = {};

Future<bool> actorPetHasLocation(String petId) async {
  if (_petLocationCache.containsKey(petId)) {
    return _petLocationCache[petId]!; // never re-validates
  }
```

Once a pet's location is cached as `true`, it is never re-checked. If the location row is removed from the DB (e.g., the user resets their location or the GPS write failed silently and the cache was incorrectly primed), the cache returns stale `true`. The discovery RPC's `origin` CTE then finds no point and the CROSS JOIN produces zero rows — the user sees an empty deck with no explanation.

**Fix:** Only cache `true` (a set location is stable). Do not cache `false` — or cache it with a 60-second TTL so stale negative results are re-checked after a brief sync.

---

### 🟡 MEDIUM-4 — `locationSyncErrorProvider` may auto-clear before the snackbar renders

**File:** `lib/features/matching/presentation/controllers/discovery_candidates_controller.dart` (lines 34–39)

```dart
void post(AppException e) {
  state = e;
  Future.microtask(() {      // clears before next frame
    if (ref.mounted) state = null;
  });
}
```

`Future.microtask` schedules in the same event-loop turn, before the next frame paint. The `ref.listen` callback fires, schedules a `showSnackBar`, then by the time that snackbar is rendered, `state` is already null. In practice the snackbar is queued and shown regardless, but the timing is fragile and will fail if the listen callback itself is async.

**Fix:** Use `addPostFrameCallback` to clear after one frame:
```dart
WidgetsBinding.instance.addPostFrameCallback((_) {
  if (ref.mounted) state = null;
});
```

---

### 🟡 MEDIUM-5 — Species filter uses `unnest/EXISTS` instead of simpler `= ANY`

**File:** `supabase/migrations/20260525200000_pr10_security_fixes.sql` (lines 192–200)

```sql
OR EXISTS (
  SELECT 1
  FROM unnest(p_species) AS u(species_text)
  WHERE lower(trim(species_text)) = lower(trim(c.species))
)
```

This is evaluated once per candidate row. A simpler and planner-friendly form:

```sql
OR lower(trim(c.species)) = ANY(
  SELECT lower(trim(s)) FROM unnest(p_species) s
)
```

If species values are pre-normalized in Dart before being sent, this reduces further to `c.species = ANY(p_species)`.

---

### 🔵 LOW-1 — Bone and Rewind dock buttons are permanently disabled stubs

**File:** `lib/features/matching/presentation/screens/matching_screen.dart` (lines 1057–1077)

```dart
const _DockButton(label: '🦴', onTap: null),  // no tooltip, no affordance
const _DockButton(label: '↺', onTap: null),
```

Users will tap these repeatedly with no feedback. Either show a "Coming soon" `Tooltip`, or remove them from the layout until the feature ships.

---

### 🔵 LOW-2 — Chat has no date separators; every bubble renders a timestamp

**File:** `lib/features/matching/presentation/screens/chat_screen.dart` (lines 229–237)

Every `_MessageBubble` renders its own `_formatTime` stamp. For a conversation with 50 messages this creates 50 timestamps. Group consecutive messages from the same sender within a 60-second window, and insert a date separator when the calendar day changes. This is a significant UX improvement with minimal complexity.

---

### 🔵 LOW-3 — Discovery candidate traits, energy, and play-style are entirely fabricated

**File:** `lib/features/matching/presentation/controllers/discovery_candidates_controller.dart` (lines 382–404)

Fields like `traits`, `playStyle`, `energy`, `bestWith` are generated purely from the species string — not from any database column. Every dog in the app shows "Medium · 45–60 min daily" energy. Before launch, these should either map to real `pets` table columns (add a migration) or be removed from `DiscoveryCandidate`.

---

### 🔵 LOW-4 — `chatThreadStream()` is dead code with no consumer

**File:** `lib/features/matching/data/datasources/matching_supabase_data_source.dart` (lines 125–130); `lib/features/matching/data/repositories/matching_repository.dart` (lines 146–148)

`chatThreadStream()` creates a Supabase `.stream()` subscription on `chat_threads`. The deleted `chat_threads_controller.dart` (shown as `D` in git status) was the sole consumer. Remove this method from the datasource and repository to prevent an accidental dangling Realtime subscription.

---

## Positive Highlights

These are genuinely well-engineered; preserve them in future refactors.

**1. Epoch-guard concurrency pattern** (`discovery_candidates_controller.dart:71, 92, 136`): The `_epoch` counter discards stale async results when preferences change mid-fetch — a clean, non-racy approach to async cancellation in Riverpod.

**2. `_replenishLocked` mutex prevents stampeding on rapid swipes** (`discovery_candidates_controller.dart:177`): The boolean lock ensures only one `for(;;)` replenishment loop runs at a time, even when `removeFront()` is called in rapid succession.

**3. `ref.onDispose` cleanup on all Realtime channels**: Both `ChatConversationController` (line 73) and `mutualMatchInsertStreamProvider` (line 29) properly `unawaited(channel.unsubscribe())` on dispose, preventing Supabase connection count from leaking across navigations.

**4. `ON CONFLICT DO NOTHING` + re-SELECT in `ensure_chat_thread_for_match`** (`20260518180000_chat_threads_race_condition.sql`): The function correctly handles the concurrent-creation race by attempting INSERT, then re-SELECTing on conflict. This avoids advisory locks and is the correct PL/pgSQL UPSERT idiom.

**5. `LEAST/GREATEST` canonical pair ordering in `matches`** (`20260517010000`, lines 87–88): Storing `(LEAST(a,b), GREATEST(a,b))` with a `CHECK (pet_a_id < pet_b_id)` and `UNIQUE (pet_a_id, pet_b_id)` constraint ensures the pair is always stored deterministically regardless of which pet triggers the match. The `ON CONFLICT DO NOTHING` in the trigger is then sufficient to prevent duplicates.

**6. Debounced preference invalidation** (`discovery_candidates_controller.dart:83–88`): The 450ms `Timer` debounce on preference changes prevents a full candidate reload on every slider tick — correct pattern for high-frequency UI driving expensive async operations.

**7. `CachedNetworkImage` for all avatar URLs** (`matching_screen.dart:823`): Avatar images are properly disk-cached with both placeholder and error-fallback states, avoiding redundant network requests during rapid swiping.

**8. `SECURITY INVOKER` on `get_match_inbox`**: The inbox RPC correctly uses `SECURITY INVOKER` so the caller's RLS policies on `matches` and `chat_threads` are enforced without superuser bypass. The `matching_discovery_candidates` SECURITY DEFINER is now documented with explicit justification and has proper `REVOKE ALL FROM PUBLIC` + `GRANT TO authenticated` guards.
