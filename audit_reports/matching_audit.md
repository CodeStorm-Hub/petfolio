# Matching Feature Audit Report

## Architecture & UI/UX

### Feature-First Conformity
The `matching` feature is structured according to Feature-First principles:
- **Presentation Layer**: 
  - Notifiers like `DiscoveryCandidatesController` (Riverpod `AsyncNotifier` buffering candidates), `MatchPreferenceController` (Riverpod `Notifier`), and `MatchesInboxController` control matching views and state.
  - Screens like `MatchingScreen` (cards discovery interface), `MatchesInboxScreen` (inbound matches list), `MatchLikedScreen`, and `VerificationCenterScreen`.
- **Data Layer**:
  - Models like `DiscoveryCandidate`, `MatchingDiscoveryRow`, `PetMutualMatch`, `PetSwipe`, `Playdate`, and `Verification`.
  - `MatchingRepository` and `MatchingSupabaseDataSource` aggregate data fetching logic.

### Riverpod State Management
- `discoveryCandidatesControllerProvider` utilizes `AsyncNotifier` to maintain a pre-loaded local buffer of candidates (refilled when below 5 items) for smooth UI card swipes.
- Debounced preferences: The preference watcher debounces slider drag adjustments for 450ms (`_prefsDebounceDuration = Duration(milliseconds: 450)`) before triggering `ref.invalidateSelf()` on candidates, preventing excessive database queries during user slider adjustments.
- Temporary error channels (like `locationSyncErrorProvider` and `swipeErrorProvider`) handle optimistic failure feedback to the user via post-frame snackbars (`AppSnackBar.showError`) rather than corrupting the long-lived candidate list state.

### Widgets, Layout, and Routing
- Bottom-bar matching screens (`/matching`, `/matching/inbox`, `/matching/liked`) use the shell branches (`matchingBranchKey`).
- Full-screen transition overlays and settings/verification/chat screens route through the `rootNavigatorKey` with custom transitions (`pfSharedAxisPage`).
- Denied/services-off location permission renders a dedicated empty state widget gracefully on the `MatchingScreen`.

---

## Supabase & Data Integration

### Database Schema & Geolocation
- **Tables**: `swipes`, `matches`, `match_profiles`, `pet_pedigree`, `pet_health_certs`, `playdates`, `verifications`.
- **PostGIS Location Integration**:
  - `pets.location` column is defined as `extensions.geography(POINT, 4326)`.
  - A spatial GiST index `pets_location_gix` is declared on `public.pets USING gist (location) WHERE location IS NOT NULL` for fast geographic queries.
- **Foreign Key Indexes**:
  - Indexes like `matches_pet_a_idx` on `matches(pet_a_id)` and `matches_pet_b_idx` on `matches(pet_b_id)` optimize mutual match retrieval.
  - An index on `swipes(actor_id)` and a partial index `swipes_target_actor_like_idx` on `swipes(target_id, actor_id) WHERE action = 'LIKE'` speed up match-checking queries.

### Row Level Security (RLS) policies
- Tables (`swipes`, `matches`, `match_profiles`, etc.) enforce access boundaries using `(SELECT auth.uid())` subselects (e.g., matching target or actor owner ids).
- The `matching_discovery_candidates` RPC runs as `SECURITY DEFINER` (to query across matching and users tables bypasses RLS) but explicitly verifies that `(SELECT auth.uid())` owns the requesting `p_actor_pet_id` inside its initial CTE to prevent spoofing. It has search_path secured (`SET search_path = public, extensions`) and anon execute access revoked.

### Prevention of N+1 Query Risks & Optimizations
- **Single-Query LATERAL Join**: The `matching_discovery_candidates` RPC replaces the N+1 correlated owner user subquery with a single `LEFT JOIN LATERAL` join to fetch the owner's basic profile details (username, display name) together with pet candidate results in one database call.
- **Keyset Cursor Pagination**: The discovery RPC utilizes key-based cursors (`c.created_at < p_cursor_created_at OR (c.created_at = p_cursor_created_at AND c.id < p_cursor_pet_id)`) rather than high-offset pagination (`OFFSET`), which keeps pagination queries at constant `O(1)` time complexity.
- **Triggers**: Match generation and protection against downgrade (e.g., preventing a liked swipe from being overwritten with a pass swipe if a mutual match exists) are processed transactionally inside the database via `swipes_before_update_downgrade_check` and `swipes_after_insert_mutual_match` triggers.
- **Batching**: Pet profiles needed by matches/chats are fetched in batches using `inFilter` rather than separate singular calls.
