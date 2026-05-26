# Architecture Blueprint: Clean Feature-First Framework

## 1. Feature Configurations & Structural Dependencies

The application is currently structured into the following feature modules within `lib/features/`:
- **admin**
- **auth**
- **care**
- **marketplace**
- **matching**
- **pet_profile**
- **social**

### Identified Cross-Feature Dependencies & Boundary Leaks
An analysis of import paths reveals tight coupling and several circular dependencies between features. Controllers and repositories are leaking boundaries by directly importing logic from other features:

1. **`admin` → `marketplace` & `auth`**
   - `admin` controllers (e.g., `cod_orders_controller.dart`, `kyc_review_controller.dart`, `ledger_controller.dart`) directly import `marketplace` models and repositories.
   - `admin_auth_controller.dart` directly imports `auth_controller.dart`.

2. **`care` ↔ `pet_profile` (Circular Coupling)**
   - `care_dashboard_controller.dart` and `care_screen.dart` directly import `active_pet_controller.dart` and `pet_list_controller.dart` from `pet_profile`.
   - `pet_list_controller.dart` and `pet_profile_screen.dart` import `pet_care_repository.dart` and `care_dashboard_controller.dart` from `care`.

3. **`pet_profile` ↔ `matching` (Circular Coupling)**
   - `edit_profile_controller.dart` inside `pet_profile` imports `matching_repository.dart`.
   - `match_preferences_sheet.dart` inside `matching` imports `pet_species.dart` from `pet_profile`.

4. **`pet_profile` → `auth`**
   - `pet_list_controller.dart` imports `auth_controller.dart`.

## 2. Declarative Architectural Specification (Inversion Patterns)

To resolve circular dependencies and boundary leaks, we will enforce the following Clean Architecture Inversion Patterns via Riverpod:

### A. Shared Domain Entities (`lib/core/domain/models/`)
- Cross-cutting domain models (e.g., `Pet`, `AuthUser`, `CareTask`) will be extracted into a central `lib/core/domain/models/` directory.
- **Rule**: Feature models can import from `core`, but features must never import models directly from another feature. This breaks model-level coupling.

### B. Global Provider Observation for State Orchestration
- Shared core states (e.g., `activePetProvider`) will be extracted into a core provider module or a designated shared provider layer.
- **Rule**: Features will rely on Global Provider Observation (`ref.watch` or `ref.listen`). For instance, `care_dashboard` will simply `ref.watch(activePetProvider)` and rebuild automatically when `pet_profile` mutates the active pet. No orchestrator classes or direct controller method calls across boundaries are allowed.

### C. Shared UI Components (`lib/core/presentation/widgets/`)
- Cross-feature Widgets and overlays (like `pet_switcher_sheet.dart`) will be relocated to `lib/core/presentation/widgets/`.
- **Rule**: A feature's presentation layer must exclusively contain widgets strictly relevant to that feature. Any widget required by two or more features is immediately promoted to `core`.

## 3. Performance & UI Constraints (`m3_performance_rules.md`)

As part of this architectural framework, the following rules will be strictly enforced via CI/CD and linting:

1. **Theme Standardization**: Never use direct hex colors or raw `Colors.*` constants in features. Force usage of `Theme.of(context).colorScheme` or custom theme extensions.
2. **Dynamic Collections**: All dynamic arrays or scrollable collections MUST use `ListView.builder` or Slivers. Flat `Column` maps are strictly banned for variable data.
3. **Heavy Payloads**: Heavy JSON payloads from Supabase queries MUST be offloaded to `Isolate.run()` to keep the UI thread completely unblocked.
4. **Const Widgets**: Every widget configuration that doesn't depend on runtime mutable states MUST be strictly declared with `const`.
5. **Animation Optimization**: All background animations must map explicitly inside a `RepaintBoundary`.

---
*Status: Pending User Verification and Review*
