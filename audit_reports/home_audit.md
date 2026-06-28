# Home Audit Report

**Audit Summary**: The home feature functions as a presentation-only dashboard hub that aggregates metrics from other features. It contains no database schema or repositories, acting as a clean entry point that watches optimized, realtime-enabled state providers.

## Architecture & UI/UX

- **Feature-First Architecture**: Located under `lib/features/home/`. It is a presentation-only module, containing only a `presentation/` directory (`hub_home_screen.dart`, `all_features_sheet.dart`). It has no `data/` or `domain/` folders.
- **Aggregated Riverpod State**: Instead of managing its own state, it watches state providers from other features to build its dashboard elements:
  - Watches `activePetControllerProvider` (from `pet_profile`) to identify the currently active pet.
  - Watches `careDashboardProvider` (from `care`) to track completed and pending care tasks.
  - Watches `careStreakRealtimeProvider` (from `care`) to display active user care streaks.
- **Bento Grid Layout**: Implements a Pathao-inspired bento-box grid that displays a high-level overview of different aspects of the application (Care status, Pet level progress, and feature shortcuts).
- **Navigation & Routing**: Integrates with GoRouter at `/home` to serve as the default launch screen inside the core application shell.

## Supabase & Data Integration

- **No Schema Overhead**: There are no database tables, triggers, indexes, or custom RPC functions specifically associated with the home feature.
- **Realtime Integration**: Watches the `careStreakRealtimeProvider`, which subscribes to changes on the database `care_streaks` table via Supabase Realtime, enabling instantaneous UI updates when tasks are completed.
- **Optimized Sub-queries**: Leverages pre-optimized database queries written in other feature repositories (like `CareRepository` and `PetRepository`), keeping the home page load lightweight and avoiding redundant table joins.
