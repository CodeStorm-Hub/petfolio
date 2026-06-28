# Care Feature Audit Report

## Architecture & UI/UX

### Feature-First Conformity
The `care` feature follows the standard Feature-First Architecture:
- **Presentation Layer**: 
  - Controllers like `CareDashboard` (Riverpod generator `@Riverpod`) and `HealthVaultController` (Riverpod `StreamNotifier`) manage state and business logic.
  - Screens like `CareScreen`, `NutritionScreen`, `MedicalVaultScreen`, `MedicationsScreen`, `SymptomCheckerScreen`, and `WalkTrackingScreen` render UI components.
  - Reusable components are co-located in `presentation/widgets/` (e.g., `CareTaskCard`, `VitalsChartWidget`).
- **Domain Layer**: 
  - Business rules are encapsulated in services such as `CareRecommendationService`.
- **Data Layer**: 
  - Data models are defined using `freezed` and `json_serializable` (e.g., `CareTask`, `CareStreak`, `MedicalRecord`).
  - Repositories like `PetCareRepository`, `HealthRepository`, `VitalsRepository`, and `WalkRepository` handle remote data operations using the Supabase client.

### Riverpod State Management
- Riverpod generator annotations are used for controllers like `CareDashboard` (`careDashboardProvider`).
- `healthVaultControllerProvider` is implemented using `StreamNotifierProvider.autoDispose` to listen to realtime data changes.
- **Rule Verification**: The non-family providers `careDashboardProvider` and `healthVaultControllerProvider` correctly watch `activePetIdProvider`. If `activePetIdProvider` is null, they immediately yield empty tasks/lists and skip remote data loads, conforming to the project preferences.
- State-changing methods optimistic UI updates are handled elegantly (e.g., toggling task completion, adding/deactivating medical records), reverting the local state and displaying errors using `AppSnackBar.showError` if the remote call fails.

### Widgets, Layout, and Routing
- Routing is split between full-screen routes (`/care/medications` and `/care/symptoms` defined in `lib/features/care/care_routes.dart` with custom page transitions using the `rootNavigatorKey`) and shell branches (`/care`, `/care/nutrition`, `/care/health`, `/care/walk`, and `/care/appointments` defined in `lib/core/navigation/app_shell_routes.dart` using `careBranchKey`). This prevents bottom navigation visibility issues on full-screen care pages.
- Circular imports are prevented by keeping routes isolated and referencing paths rather than importing screens circularity.

---

## Supabase & Data Integration

### Database Schema & Performance
- **Tables**: `care_tasks`, `care_logs`, `care_streaks`, `pet_badges`, `medical_vault`.
- **Foreign Key Indexes**:
  - `care_tasks_pet_id_idx` on `care_tasks(pet_id)`
  - `care_tasks_scheduled_idx` on `care_tasks(pet_id, scheduled_time)`
  - `health_logs_pet_id_idx` on `health_logs(pet_id)`
  - `health_logs_timeline_idx` composite index on `health_logs(pet_id, occurred_at DESC)` for timeline sorting.
  - `medical_vault_pet_id_idx` on `medical_vault(pet_id)`
  - Partial indexes `medical_vault_due_idx` and `medical_vault_expiry_idx` on `medical_vault` for columns `next_due_at` and `expires_at` (where not null) optimized for alert queries.
  These indexes prevent full table scans when filtering care tasks and logs for a specific pet.

### Row Level Security (RLS) Policies
- All RLS policies on the Care tables (`care_tasks`, `health_logs`, `medical_vault`, `care_streaks`, `pet_badges`) enforce ownership checks by wrapping the current user check in a subselect:
  `((SELECT auth.uid()) IN (SELECT owner_id FROM public.pets WHERE id = <table_name>.pet_id))`
- Wrapping `auth.uid()` in a subselect `(SELECT auth.uid())` forces Postgres to cache the query plan and user context evaluation, avoiding massive performance degradation when executing RLS policies across multiple rows.

### Prevention of N+1 Query Risks
- **Single-RPC Collapsing**: The dashboard replaces 4 parallel client queries (for tasks, logs, badges, and streaks) with a single RPC function `get_care_dashboard_snapshot`. This function aggregates care data into a single `jsonb` object, eliminating N+1 query hazards.
- **Idempotent Toggles**: Toggling a task is pushed to the database via `toggle_care_task` RPC. This method validates status and updates streaks/badges inside a single transaction, returning updated models and unlocked badges in one roundtrip.
