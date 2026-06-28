# BRIEFING — 2026-06-28T18:11:17+06:00

## Mission
Investigate the 'home' feature under j:\GitHub\petfolio\lib\features\home\ and read audit_reports/home_audit.md to identify architectural, database, and UI/UX improvements.

## 🔒 My Identity
- Archetype: explorer
- Roles: Home Feature Explorer
- Working directory: j:\GitHub\petfolio\.agents\explorer_exploration_3
- Original parent: Project Orchestrator (9023a2a1-598d-4024-a77b-b352452ad4aa)
- Milestone: Home Feature Audit & Optimization Plan

## 🔒 Key Constraints
- Read-only investigation — do NOT implement
- Limit edits only to agent folder files

## Current Parent
- Conversation ID: 9023a2a1-598d-4024-a77b-b352452ad4aa
- Updated: 2026-06-28T18:25:00+06:00

## Investigation State
- **Explored paths**:
  - `lib/features/home/presentation/screens/hub_home_screen.dart`
  - `lib/features/home/presentation/widgets/all_features_sheet.dart`
  - `lib/features/pet_profile/presentation/controllers/active_pet_controller.dart`
  - `lib/features/care/presentation/controllers/care_dashboard_controller.dart`
  - `lib/features/care/presentation/controllers/care_streak_stream_provider.dart`
  - `lib/features/care/data/repositories/pet_care_repository.dart`
  - `lib/core/navigation/router_notifier.dart`
  - `lib/core/navigation/app_shell_routes.dart`
  - `lib/features/appointments/appointment_routes.dart`
  - `lib/features/appointments/presentation/screens/appointments_screen.dart`
- **Key findings**:
  - `HubHomeScreen` over-watches root providers (`activePetControllerProvider`, `careStreakRealtimeProvider`, and `careDashboardProvider` select `todayTasks`) causing full-screen rebuilds on minor state updates.
  - Redundant WebSocket subscription in `HubHomeScreen` for `careStreakRealtimeProvider`, which is already managed and exposed by `CareDashboard`.
  - Lack of error recovery UI when `petListProvider` fails, causing a permanent loading screen spinner.
  - Asymmetric Bento Grid has hardcoded heights and 2-column constraints, ignoring wider screens.
  - `AllFeaturesSheet` has scroll overflow issues under height constraints due to `NeverScrollableScrollPhysics` and rigid column count.
- **Unexplored areas**: None

## Key Decisions Made
- Suggested architectural improvements to isolate widget rebuilds.
- Designed 3-column responsive layout for widescreen bento grids.
- Outlined a plan to remove duplicate stream subscriptions and add error-fallback UI.

## Artifact Index
- j:\GitHub\petfolio\.agents\explorer_exploration_3\handoff.md — Handoff Report with findings and migration plan
