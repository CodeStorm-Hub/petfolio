# PetFolio Pet Profile Feature Audit

## Architecture & UI/UX

### Feature-First Architecture
The `pet_profile` feature is fully implemented according to Feature-First principles under `lib/features/pet_profile/` and contains the following structure:
- **Presentation**: Screen files (`edit_profile_screen.dart`, `manage_pets_screen.dart`, `onboarding_screen.dart`, and `pet_profile_screen.dart`), controllers (`active_pet_controller.dart`, `breed_identifier_controller.dart`, `discovery_visibility_controller.dart`, `edit_profile_controller.dart`, and `pet_list_controller.dart`), and custom widgets (`breed_identifier_widget.dart`, `pet_activity_options.dart`, and `pet_switcher_sheet.dart`).
- **Domain**: Domain services like `breed_identification_service.dart` which encapsulates pet breed recognition.
- **Data**: Data repository `pet_repository.dart` for DB CRUD and storage actions, and entities (`activity_level.dart`, `pet.dart`, `pet_gender.dart`, and `pet_species.dart`).

### State Management & Riverpod
- Utilizes Riverpod extensively.
- key providers include:
  - `petRepositoryProvider`: Injecting the `PetRepository`.
  - `petListProvider`: An `AsyncNotifierProvider` that fetches and manages the user's pet list.
  - `activePetControllerProvider`: A `NotifierProvider` that maintains the active pet state, synced with `SharedPreferences` to preserve the selection across application sessions.
  - `activePetIdProvider`: A derived provider exposing only the active pet ID to optimize rebuild performance in dependent widgets.
  - `editProfileControllerProvider`: A `NotifierProvider` that orchestrates edit profile submissions.
  - `breedIdentifierControllerProvider`: A `NotifierProvider` that handles photo picking and AI breed classification state.
- No legacy `provider` packages are used. While manual providers (`AsyncNotifierProvider`, `NotifierProvider`) are used, code generation (Riverpod annotation) is not implemented here.

### Widget Structure & UX
- Screens use `ConsumerStatefulWidget` or `ConsumerWidget` where appropriate.
- Local UI state is handled correctly (e.g. input verification, loading overlays).
- Navigation is handled through declarative `GoRouter` in `pet_profile_routes.dart`.
- The `BreedIdentifierWidget` integrates an external vision-language model (`nvidia/llama-3.2-90b-vision-instruct` via the NVIDIA API) to classify pet breed from photos picked from the camera/gallery using the system image picker.
- Image uploads are validated client-side in the repository (checking format, sizing constraints like 5MB limits).
- Reordering pets has an optimistic UI update that reverts if the database update fails.
- Discoverable toggling has optimistic updates via `PetListNotifier.setDiscoverable`.

---

## Supabase & Data Integration

### Schema & Indexes
- Table `public.pets` is defined in `supabase/schema.sql`. It has foreign keys to `public.users(id) ON DELETE CASCADE`.
- The query `fetchPets()` retrieves pets filtering by `owner_id` and `archived_at` (excluding soft-archived pets) and orders them by `display_order` and `created_at`.
- Optimization: Index `pets_owner_archived_display_idx` on `(owner_id, archived_at, display_order, created_at)` is a covering index that matches this query exactly, preventing full table scans.
- Optimization: Spatial index `pets_location_gist_idx` is created `USING gist (location)` to optimize radius searches in matching/discovery.

### Row Level Security (RLS)
- RLS is enabled on `public.pets`.
- Policies verify owner check constraints using `(select auth.uid()) = owner_id` (subselect wrapped to allow PG plan-caching).
- When reordering pets, the repository updates each row individually using an explicit `.eq('owner_id', userId)` filter to preserve RLS guarantees.

### N+1 Query Risks (Database Joins / RPCs)
- The matching discovery system needs to pull candidates and join them with their owner's username and display name.
- Optimization: In `20260531000000_audit_fixes.sql`, the correlated subquery inside the `matching_discovery_candidates` RPC was replaced with a `LEFT JOIN LATERAL` block on the database. This allows Postgres to do a single-pass join on the server, avoiding N+1 correlated queries.
- Pagination in discovery is optimized: Offset-based pagination was replaced with keyset cursor pagination (`created_at`, `id`) to ensure stable pagination.
- Species filtering utilizes `= ANY()` array checks instead of unnesting.
