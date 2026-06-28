# Project: PetFolio Core Features Optimization

## Architecture
PetFolio follows a feature-first architecture where features are placed under `lib/features/<feature_name>/` and divided into `presentation`, `domain`, and `data` layers.

## Code Layout
- `lib/features/auth/`: Contains user authentication screens, controller, and repository.
- `lib/features/profile/`: Contains profile, account, and me screen.
- `lib/features/home/`: Contains home dashboard hub screen and all features bento sheets.

## Milestones
| # | Name | Scope | Dependencies | Status |
|---|---|---|---|---|
| 1 | Exploration & Refactoring Plan | Run diagnostics, analyze providers, analyze UX/UI, define detailed refactoring plan | None | DONE |
| 2 | Auth Migration | Migrate Riverpod manual providers to code-generated notifiers, centralize Supabase client provider, and consolidate friendly auth errors | M1 | DONE |
| 3 | Profile Optimization | Fix widescreen alignment between AppShellHeader and AccountScreen, delete obsolete SettingsScreen, establish Profile model, repository, and controller layers, and fix the syntax typo in section_header.dart | M2 | DONE |
| 4 | Home Dashboard Optimization | Optimize home screen rebuilds by watching activePetIdProvider, remove duplicate realtime subscriptions, implement responsive 3-column bento grid for widescreen, and fix scrolling in All Features Sheet | M3 | DONE |
| 5 | Validation & Hardening | Run all tests (unit, widget, integration) and static analysis, run forensic auditor | M4 | BLOCKED |

## Interface Contracts
### Auth ↔ Profile ↔ Home
- Auth provides current user, session, and logged-in states to the rest of the application via Riverpod.
- Profile and Home watch Auth and other feature providers (e.g. `activePetControllerProvider`, `careDashboardProvider`, `careStreakRealtimeProvider`) to display user/pet specific details.
