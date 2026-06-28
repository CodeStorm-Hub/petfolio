# Messaging Feature Audit Report

## Architecture & UI/UX

### Feature-First Conformity
The `messaging` feature has a clean separation of concerns:
- **Presentation Layer**: 
  - `UnifiedChatScreen` in `lib/features/messaging/presentation/screens/chat_screen.dart` is the primary screen for all text conversations.
  - `chatConversationControllerProvider` (Riverpod `AsyncNotifier.family`) manages message fetching, sending, and real-time subscription.
  - `chatTypingStateProvider` tracks remote participant typing states.
- **Pragmatic Data Sharing**: The messaging feature relies on data models (`ChatMessage`, `ChatThread`) and repositories (`MatchingRepository` and `MatchingSupabaseDataSource`) defined in the `matching` feature. This cross-feature dependency is highly logical since matching and messaging are tightly coupled (mutual matches are the primary vehicle for text conversations).
- **Matching Reuse**: The matching feature's chat screen (`lib/features/matching/presentation/screens/chat_screen.dart`) is a thin wrapper that directly imports and delegates rendering to `UnifiedChatScreen`, preventing duplicate code.

### Riverpod State Management
- `chatConversationControllerProvider` is configured as a Riverpod `family` notifier parameterized by `ChatConversationArgs` (threadId, matchId, actorPetId, otherPetId).
- **Rule Verification**: Riverpod notifiers are used for state management. Old `provider` package is completely avoided.
- Safe state mutation: Sends and updates immediately alter the local messages list using `AsyncData`, while handling errors with local SnackBars on failures.

### Widgets, Layout, and Routing
- Routing is defined via `/matching/chat/:threadId` with a transition mapped via the `rootNavigatorKey`. This provides a full-screen chat interface that slides on top of the tab bar.
- Layout features a reverse `ListView.builder` for messages with keyset scroll listeners (`loadOlderMessages()`) to fetch older conversation history smoothly.
- Beautiful custom UI animations for typing indicators (`_DotDotDot` with fade-in/out phases).

---

## Supabase & Data Integration

### Database Schema & Performance
- **Tables**: `chat_threads`, `chat_messages`.
- **Foreign Key Indexes**:
  - `idx_chat_threads_p1` on `chat_threads(participant_1_id)`
  - `idx_chat_threads_p2` on `chat_threads(participant_2_id)`
  - `chat_threads_dm_pets_uidx` on `chat_threads(dm_pet_a_id, dm_pet_b_id) WHERE mutual_match_id IS NULL` prevents duplicate threads for the same ordered pair of pets.
  - `idx_chat_messages_thread` on `chat_messages(thread_id)`
  - `idx_chat_messages_sender` on `chat_messages(sender_id)`
  - `idx_chat_messages_thread_created_at` on `chat_messages(thread_id, created_at DESC)` optimizes pagination sorting.
  These indexes prevent full table scans when querying message threads and messages.

### Row Level Security (RLS) policies
- **Enforcement**: Row Level Security is active on both `chat_threads` and `chat_messages`.
- **Optimization**: Participant verification is wrapped in `(SELECT auth.uid())` subselects to enable planning cache optimization:
  - `chat_threads` select policy:
    `((SELECT auth.uid()) = participant_1_id OR (SELECT auth.uid()) = participant_2_id)`
  - `chat_messages` select/insert policy:
    `((SELECT auth.uid()) IN (SELECT participant_1_id FROM public.chat_threads WHERE id = chat_messages.thread_id UNION ALL SELECT participant_2_id FROM public.chat_threads WHERE id = chat_messages.thread_id))`

### Prevention of N+1 Query Risks & Real-Time Sync
- **Unified Inbox Fetch**: The `get_chat_inbox` RPC consolidates matches, DMs, thread status, and the most recent chat message (retrieved via a lateral query `LEFT JOIN LATERAL`) into a single query. It returns a combined list of active chats sorted by activity date in one database roundtrip, preventing client-side looping.
- **Idempotent Resolvers**: `ensure_chat_thread_for_match` and `ensure_direct_chat_thread` RPCs are used to safely retrieve or create threads server-side without causing race conditions.
- **Real-Time Subscription**: Instead of periodic polling, the client subscribes to Postgres change events on `chat_messages` table matching the current `thread_id`.
- **Typing Indicator Broadcast**: Real-time typing indicators use lightweight Supabase broadcast channels (`typing:$threadId`) that bypass the database entirely to minimize write overhead.
