# Handoff

## State
Branch `ui-fix-salman`. All P0 and most P1 items from Claude-Review.md are done. `flutter analyze` is clean (No issues found). Firebase fully wired: `GoogleService-Info.plist` created, `firebase.json` includes iOS, `firebase_core` 4.10.0 + `firebase_messaging` 16.3.0, `supabase_flutter` 2.14.2. FCM outbox has retry/dead-letter (migration applied, edge functions v9 deployed). `DarwinNotificationDetails` added to `scheduleTaskReminder`. iOS chat FCM now sends `content-available: 1`.

## Next
1. **P1 – Appointment notifications**: wire `scheduleTaskReminder()` + `fcm_push_outbox` insert on booking confirmation (check `lib/features/appointments/` booking flow).
2. **P1 – NVIDIA API proxy**: mobile calls NVIDIA API directly (key in binary); create Supabase Edge Function proxy, update `CareRecommendationService` to call it on non-web.
3. **P2 – Quick wins**: bento tile `InkWell` ripple fix in `hub_home_screen.dart`; Followers/Following tap navigation in `SocialProfileScreen`.

## Context
- Production bundle ID is still `com.example.petfolio` everywhere (Android + iOS + Firebase) — consistent but placeholder. Changing requires App Store/Play Store action; do not change in code without user confirming new ID.
- `Supabase.initialize` uses `publishableKey:` (not `anonKey:`) since supabase_flutter 2.14.2 — already fixed in `main.dart:101`.
- `AppThemeSpacing` now has `xxl/xxxl/xxxxl/xxxxxl` — use these instead of hardcoded values above 24dp.
