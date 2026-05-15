# Petfolio — Full Codebase & Database Review

**Date:** 2026-05-15  
**Reviewer:** AI-assisted codebase audit  
**Scope:** All files under `lib/` + Supabase database (17 tables, RLS, migrations, extensions)

---

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [Codebase Architecture](#2-codebase-architecture)
3. [Core Layer Review](#3-core-layer-review)
4. [Feature: Auth](#4-feature-auth)
5. [Feature: Pet Profile](#5-feature-pet-profile)
6. [Feature: Care](#6-feature-care)
7. [Feature: Marketplace](#7-feature-marketplace)
8. [Feature: Matching](#8-feature-matching)
9. [Feature: Social](#9-feature-social)
10. [Database Review](#10-database-review)
11. [Security Lints](#11-security-lints)
12. [Performance Lints](#12-performance-lints)
13. [Critical Bugs](#13-critical-bugs)
14. [Missing Features vs Database Schema](#14-missing-features-vs-database-schema)
15. [Strengths](#15-strengths)
16. [Recommendations](#16-recommendations)

---

## 1. Project Overview

Petfolio is a **Flutter + Supabase** mobile application combining:
- **Social network** for pet owners (posts, likes, follows)
- **Pet discovery platform** (swipe-based matching with playdates/breeding/adoption)
- **Health tracker** (care tasks, medical vault, health logs, vitals, streaks/badges)
- **E-commerce marketplace** (products, cart, Stripe payments, subscriptions)

### Tech Stack
| Layer | Technology |
|-------|-----------|
| Frontend | Flutter 3.11.5+, Dart 3.11.5+ |
| State Management | Riverpod (hand-written providers) |
| Navigation | Go Router |
| Backend/Database | Supabase (PostgreSQL 17) |
| Payments | Stripe (via `flutter_stripe`) |
| Code Generation | Freezed + JsonSerializable |
| Fonts | Google Fonts (Inter, Sora) |

### File Count

| Directory | Files |
|-----------|-------|
| `lib/core/` | 13 |
| `lib/features/auth/` | 5 |
| `lib/features/care/` | 19 |
| `lib/features/marketplace/` | 16 |
| `lib/features/matching/` | 6 |
| `lib/features/pet_profile/` | 8 |
| `lib/features/social/` | 4 |
| `lib/main.dart` | 1 |
| **Total** | **~72 Dart source files** |

---

## 2. Codebase Architecture

### 2.1 Layered Structure

Every feature follows a clean **data/presentation** split:

```
features/{feature}/
├── data/
│   ├── models/             # Freezed + JsonSerializable data classes
│   └── repositories/       # Supabase DB access layer
└── presentation/
    ├── controllers/         # Riverpod providers (Notifier, StreamNotifier, Provider)
    ├── screens/             # Full-screen widgets
    └── widgets/             # Reusable UI components
```

### 2.2 Theme Compliance

**Verdict: ✅ Pass.** No hardcoded `Colors.*` or raw `TextStyle` in any feature file. All widgets consume:
- `Theme.of(context).extension<PetfolioThemeExtension>()` (with `final pt = ...`)
- `Theme.of(context).colorScheme` (with `final cs = ...`)
- `AppColors` constants for colors outside the theme extension

### 2.3 Dependency Injection

- Repositories are exposed via `Provider<{RepoClass}>` singletons
- Controllers use family/non-family `NotifierProvider`, `StreamNotifierProvider`, `AsyncNotifierProvider`
- `ref.watch()` for reactive rebuilds, `ref.read()` for one-shot calls

### 2.4 Routing

- `GoRouter` with `ShellRoute` for 5 bottom tabs
- `_RouterNotifier` for auth guard: redirects unauthenticated → `/login`, no-pet users → `/onboarding`
- Sub-routes: `/care/nutrition`, `/care/medical-vault`, `/marketplace/product/:id`, `/marketplace/cart`, `/marketplace/order/:id`

### 2.5 Main Entry Point (`lib/main.dart`)

- Marionette Binding for debug mode widget testing
- Stripe initialized with `--dart-define` publishable key
- Google Fonts runtime fetching **disabled** (`allowRuntimeFetching = false`) to avoid DNS failures on emulators
- Supabase initialized with `--dart-define` URL + anon key
- `MaterialApp.router` with `scaffoldMessengerKey` for snackbar system

---

## 3. Core Layer Review

### 3.1 Theme (`lib/core/theme/`)

| File | Lines | Role |
|------|-------|------|
| `app_colors.dart` | ~250 | Raw design-token constants. Blue primary ramp, neutral/grey ramp, semantic colors, shadow tokens |
| `app_theme.dart` | ~400 | `AppTheme.light()` / `.dark()` factories. `PetfolioThemeExtension` with 50+ tokens |
| `theme.dart` | 3 | Barrel export |

**Findings:** ✅ Design system is comprehensive with light/dark mode, species-specific accent colors, shadow hierarchy.

### 3.2 Router (`lib/core/router.dart`)

| Aspect | Status |
|--------|--------|
| Auth redirect | ✅ `_RouterNotifier` watches `isLoggedInProvider` |
| Onboarding redirect | ✅ Redirects to `/onboarding` if no pets exist |
| Deep linking | ✅ Product detail, cart, order, nutrition, medical vault |
| Adaptive shell | ✅ `AppShell` switches between `NavigationRail` (≥600dp) and `NavigationBar` |
| Circular imports | ✅ Uses literal paths for deep links to screens that `router.dart` already imports |

### 3.3 Core Widgets (`lib/core/widgets/`)

| Widget | Purpose |
|--------|---------|
| `AppSnackBar` | Error/info snackbar using `appSnackBarMessengerKey` |
| `AppBottomSheet` | Styled modal bottom sheet |
| `GlassCard` | Frosted glass container decoration |
| `PetAvatar` | Circular avatar with initials fallback, species accent border |
| `PetfolioEmptyState` | Illustration + message + optional action |
| `PrimaryPillButton` | Rounded primary action button |
| `SkeletonLoader` | Shimmer loading placeholder |
| `widgets.dart` | Barrel export of all widgets |

### 3.4 Error Handling (`lib/core/errors/`)

| Class | Purpose |
|-------|---------|
| `AppException` | Base exception (abstract) |
| `NotAuthenticatedException` | Auth guard failure |
| `NotFoundException` | Row not found |
| `DatabaseException` | `PostgrestException` wrapper |
| `NetworkException` | Network/generic failures |

---

## 4. Feature: Auth

**Files:** 5 (`lib/features/auth/`)

### 4.1 File-by-File Review

| File | Lines | Review |
|------|-------|--------|
| `auth_repository.dart` | ~80 | Wraps `Supabase.instance.client.auth`. `signUp()` auto-creates `public.users` row via DB trigger. `signIn()`, `signOut()`, `authStateChanges()`, `sessionStream()` |
| `auth_controller.dart` | ~60 | `StreamNotifierProvider<AsyncValue<User?>>`. Exposes `isLoggedIn`, `currentUser`. Streams from `authRepository.authStateChanges` |
| `login_screen.dart` | ~150 | Email + password form with validation. Uses `PrimaryPillButton`. Redirects to `/` on success |
| `registration_screen.dart` | ~200 | Username + email + password + confirm. Client-side validation. Calls `signUp()` |
| `auth_widgets.dart` | ~50 | `_AuthField` reusable text field with design system styling |

### 4.2 Findings

| Severity | Issue | Recommendation |
|----------|-------|---------------|
| ⚠ MISSING | No OAuth providers (Google/Apple) | Add social sign-in buttons; Supabase Auth supports OAuth |
| ⚠ MISSING | No password reset flow | Add "Forgot password?" link → `supabase.auth.resetPasswordForEmail()` |
| ℹ INFO | No loading indicator during sign-up | Button disables but no spinner shown |

---

## 5. Feature: Pet Profile

**Files:** 8 (`lib/features/pet_profile/`)

### 5.1 Models

| File | Content |
|------|---------|
| `pet.dart` | Freezed `Pet` model with fields: id, ownerId, name, species, breed, dateOfBirth, gender, weightKg, avatarUrl, bio, isPublic, activityLevel |
| `pet_species.dart` | Enum: `Dog`, `Cat`, `Bird`, `Fish`, `Reptile`, `SmallMammal`, `Other`. Each has accent color, label, plural, icon |

### 5.2 Repository

| File | Role |
|------|------|
| `pet_repository.dart` | CRUD on `pets` table. `getPets()` filters by `owner_id`. No RLS issues |

### 5.3 Controllers

| File | Type | Role |
|------|------|------|
| `active_pet_controller.dart` | `NotifierProvider<Pet?>` | Stores selected pet. Persists `active_pet_id` to SharedPreferences |
| `pet_list_controller.dart` | `AsyncNotifierProvider<List<Pet>>` | Fetches all pets for current user |

### 5.4 Screens

| File | Review |
|------|--------|
| `onboarding_screen.dart` | Multi-step wizard: pet name → species → breed → DOB → complete. Clean stepper UX |
| `pet_profile_screen.dart` | Shows active pet's profile details |
| `pet_switcher_sheet.dart` | Bottom sheet listing all user's pets; tap to switch active |

### 5.5 Findings

| Severity | Issue | Recommendation |
|----------|-------|---------------|
| ⚠ BUG | `active_pet_controller.dart` persists pet ID without auth user scoping | Add user ID to SharedPreferences key (e.g., `active_pet_id_{userId}`) |
| ⚠ MISSING | No avatar photo upload UI | Pet model has `avatarUrl` but no image picker/camera integration |
| ℹ INFO | `pet_switcher_sheet.dart` uses `Pet` from `pet_profile/data/models/pet.dart` — correct |

---

## 6. Feature: Care

**Files:** 19 — Most feature-complete module (`lib/features/care/`)

### 6.1 Models

| File | Lines | Freezed | Fields |
|------|-------|---------|--------|
| `care_task.dart` | ~120 | ✅ | id, petId, taskType, title, frequency, scheduledTime, isCompleted, completedAt, gamificationPoints, notes |
| `care_task_log.dart` | ~50 | No | id, careType, petId, loggedBy, notes, durationMinutes, occurredAt |
| `care_task_type.dart` | ~60 | Enum | 11 types: feeding, walk, grooming, medication, vetVisit, training, playtime, dental, nailTrim, bath, other |
| `care_streak.dart` | ~40 | No | petId, currentStreak, lastCompletionDate, bestStreak |
| `health_log.dart` | ~100 | ✅ | id, petId, logType, title, description, weightKg, severity, vetName, clinic, diagnosis, treatment, followUpDate |
| `medical_record.dart` | ~80 | ✅ | id, petId, recordType, name, description, administeredAt, expiresAt, nextDueAt, dosage, frequency. **Has computed `renewalDate` + `isExpiringSoon`** |

### 6.2 Repositories

| File | Lines | Review |
|------|-------|--------|
| `pet_care_repository.dart` | 590 | **Core repository.** CRUD for care_tasks, fetchTasksForDate (with care_logs merge), toggleCompletion (writes care_logs), streak/badge RPC, frequency scheduling logic |
| `checklist_repository.dart` | 174 | **Offline-first.** SharedPreferences cache + Supabase sync. 7-day sliding window. Pattern: load local → refresh remote → merge |
| `health_repository.dart` | 328 | Two repositories: `HealthRepository` (health_logs) and `MedicalVaultRepository` (medical_vault). ⚠ Hard `throw` on delete — no error recovery |
| `care_repository.dart` | 1 | Barrel export |

**Key Implementation Details in `pet_care_repository.dart`:**
- `fetchTasksForDate()`: Fetches task definitions + care_logs for a day, merges them, creates synthetic log-derived tasks
- `toggleCompletion()`: For `daily`/`twice_daily`/recurring tasks → upserts `care_logs` on `(pet_id, care_type, logged_date)` conflict. For `once` tasks → updates `care_tasks.is_completed` + writes/removes care_log
- `deleteTask()`: Handles `log:` prefixed synthetic IDs by deleting from `care_logs` instead of `care_tasks`
- `getPetStreak()`: Fetches from `care_streaks` table; returns zeroed default if no row
- `check_daily_completion` RPC: Called after toggle to update streak + potentially unlock badge

### 6.3 Controllers

| File | Type | Role |
|------|------|------|
| `care_dashboard_controller.dart` | Notifier | Aggregates tasks + goals + streak into `CareDashboardData` |
| `care_controller.dart` | Family Notifier | Handles task toggling with **optimistic UI** (revert on failure + `AppSnackBar.showError`) |
| `care_streak_stream_provider.dart` | StreamNotifier | Realtime listener on `care_streaks` table for immediate streak UI sync |
| `health_vault_controller.dart` | Family AsyncNotifier | Fetches medical records for active pet |
| `nutrition_controller.dart` | Family Notifier | Weight goals + meal plans |

### 6.4 Screens

| File | Review |
|------|--------|
| `care_screen.dart` | Dashboard with StreakBanner (dual-ring progress), horizontal date picker, daily tasks list, nutrition/medical vault banners. ⚠ Uses `Pet` from `pet_profile/data/models/pet.dart` (fragile cross-feature import) |
| `medical_vault_screen.dart` | Expiry-warning cards, record list with add/edit/delete |
| `nutrition_screen.dart` | Weight tracking + meal suggestions |

### 6.5 Findings

| Severity | Issue | Recommendation |
|----------|-------|---------------|
| ⚠ BUG | `pet_care_repository.dart` catches `PostgrestException` with code `PGRST116` — this code may not exist in all Supabase versions | Use `e.details` or check `e.message` instead; `PGRST116` means "JSON object requested, multiple (or no) rows returned" |
| ⚠ WARN | `check_daily_completion` RPC is SECURITY DEFINER (can run as postgres). Called from Dart client with `target_pet_id` parameter | Ensure RPC validates the caller owns the pet. Currently runs as postgres — user could pass any pet ID |
| ⚠ WARN | `health_repository.dart` hard `throw` on medical record delete | Wrap in try/catch and return result type |
| ℹ INFO | `care_controller.dart` calls both `ref.invalidate(careDashboardProvider)` AND `ref.invalidate(todaysTasksProvider)` on toggle — potential double-refetch | Consolidate into single invalidation |
| ℹ INFO | `medical_vault_screen.dart` imports `Pet` from `pet_profile/data/models/pet.dart` | Consider extracting `Pet` to shared core model or use interface |
| ⚠ MISSING | No Dart model/controller for `health_vitals` table (exists in DB with 0 rows) | Create `HealthVital` model + repository + controller |
| ℹ INFO | `toggleCompletion()` RPC call catches all errors silently `catch (_) {}` | Log the error or surface to user |

---

## 7. Feature: Marketplace

**Files:** 16 (`lib/features/marketplace/`)

### 7.1 Models

| File | Content |
|------|---------|
| `product.dart` | id, name, brand, variant, category (enum: food/gear/toys/treats/health/grooming), priceCents, currency, subscribable, glyph, gradientStart/End, active |
| `cart_item.dart` | Extends product with quantity (int) + isSubscription (bool) |

### 7.2 Repositories

| File | Lines | Review |
|------|-------|--------|
| `product_repository.dart` | ~60 | Fetches `products` where `active = true`. Supports `.in()` category filter. ⚠ No error states surfaced |
| `order_repository.dart` | ~100 | Creates `marketplace_orders` row with `stripe_payment_intent_id`. Creates Stripe PaymentIntent via backend call |

### 7.3 Controllers

| File | Type | Review |
|------|------|--------|
| `cart_controller.dart` | Notifier | **⚠ Stub/fake.** In-memory cart only (lost on restart). `shippingCost` hardcoded `4.99`. `_calculateTax()` returns `0`. Cart item quantity capped at 99 |
| `checkout_controller.dart` | Family AsyncNotifier | Stripe PaymentSheet flow. Creates PaymentIntent + order in DB |
| `product_list_controller.dart` | Family AsyncNotifier | Fetches products, watches `selectedCategoryProvider` |

### 7.4 Screens

| File | Review |
|------|--------|
| `marketplace_screen.dart` | Category chips (horizontal scroll) + product grid (vertical). Uses `productGlyphAsset()` for visual icons |
| `product_detail_screen.dart` | Product card with subscribe toggle, add-to-cart button |
| `cart_screen.dart` | Cart line items, subtotal/shipping/tax/total summary, checkout button → Stripe |
| `order_confirmation_screen.dart` | "Thank you" screen with order ID, amount, status |

### 7.5 Widgets

| File | Review |
|------|--------|
| `cart_line_item.dart` | Cart item row with quantity controls, price |
| `product_card.dart` | Product grid card with gradient background, glyph, price |
| `product_glyph.dart` | Asset path builder for product category glyphs |
| `subscription_toggle.dart` | UI-only toggle — subscriptions are **not actually processed** via Stripe recurring |

### 7.6 Findings

| Severity | Issue | Recommendation |
|----------|-------|---------------|
| ⚠ BUG | Cart is **in-memory only** — lost on app restart | Persist cart to SharedPreferences or Supabase |
| ⚠ BUG | Tax calculation returns `$0` | Implement proper tax logic or connect to Stripe tax API |
| ⚠ WARN | Shipping cost hardcoded `$4.99` | Make configurable or weight-based |
| ⚠ WARN | **No Stripe webhook** — order confirmation is client-side. A user who closes the app before success won't have an order created | Server-side webhook for payment confirmation |
| ⚠ WARN | Subscribe toggle is UI-only — no recurring Stripe PaymentIntent created | Implement Stripe subscription API |
| ⚠ MISSING | No visible error states for failed product fetches | `.when(data: ..., error: ...)` should show error UI with retry button |
| ℹ INFO | No checkout loading indicator while Stripe sheet processes | Add overlay or button loading state |

---

## 8. Feature: Matching

**Files:** 6 (`lib/features/matching/`)

### 8.1 Models

| File | Lines | Review |
|------|-------|--------|
| `chat_thread.dart` | 43 | **⚠ BUG:** Comment says table uses `pet_id_1`/`pet_id_2` but actual DB columns are `participant_1_id`/`participant_2_id` (user IDs). `fromJson` looks for `pet_id_1`/`pet_id_2` — will always fail |
| `discovery_candidate.dart` | 73 | Rich immutable model: petId, ownerUserId, name, age, species, breed, distance bucket, ownerInitial, verified, traits, bio, playStyle, energy, bestWith, vaccinated, gradientColors, subjectColor, avatarUrl |

**DB Schema (confirmed via MCP):**
```sql
chat_threads (
  id               uuid,
  match_request_id uuid,
  participant_1_id uuid NOT NULL REFERENCES public.users(id),  -- user ID, not pet ID
  participant_2_id uuid NOT NULL REFERENCES public.users(id),  -- user ID, not pet ID
  last_message_at  timestamptz,
  created_at       timestamptz
)
```

### 8.2 Repository

| File | Lines | Review |
|------|-------|--------|
| `matching_repository.dart` | 280 | `fetchCandidates()`: Queries public pets excluding already-swiped (via `match_requests`). Uses embedded resource syntax `owner:users!pets_owner_id_fkey`. `recordSwipe()`: Inserts `match_requests` rows with `match_type: 'playdate'` (✅ correct string). `chatThreadStream()`: Supabase Realtime stream on `chat_threads` |

### 8.3 Controllers

| File | Review |
|------|--------|
| `discovery_controller.dart` | Manages swipe deck state (current index, candidates list, animation triggers) |
| `chat_threads_controller.dart` | Streams chat threads via `matchingRepository.chatThreadStream()`. Filters to user's threads client-side |

### 8.4 Screen

| File | Review |
|------|--------|
| `matching_screen.dart` | Tinder-style swipe cards with match/greet/pass buttons |

### 8.5 Findings

| Severity | Issue | Recommendation |
|----------|-------|---------------|
| 🔴 **BUG** | `chat_thread.dart` resolves `pet_id_1`/`pet_id_2` but DB uses `participant_1_id`/`participant_2_id` (user IDs). `fromJson` will return null/garbage for `myPetId`/`otherPetId` | Change `fromJson` to look up user ID instead, then resolve pet IDs via a join or secondary query. Or change DB schema to include `pet_id_1`/`pet_id_2` columns |
| ⚠ WARN | `chat_threads_controller.dart` filters threads client-side from Realtime stream — no WHERE clause in stream | Use `.eq()` filter on stream with user ID for server-side filtering |
| ℹ INFO | Distance is deterministic per UUID (`_fuzzyDistance()` using `codeUnits.fold`), not real geolocation | Add location to pet profile + PostGIS extension for actual proximity queries |
| ℹ INFO | `recordSwipe()` catches all errors silently (`catch (e) { debugPrint(...) }`) | Surface errors to user via snackbar |

---

## 9. Feature: Social

**Files:** 4 (`lib/features/social/`)

### 9.1 Model

| File | Content |
|------|---------|
| `feed_post.dart` | id, authorId, petId, content, imageUrls, visibility (public/followers/private), likeCount, commentCount, createdAt |

### 9.2 Repository

| File | Review |
|------|--------|
| `social_repository.dart` | Fetches public posts with `author:users!posts_author_id_fkey` and `pet:pets!posts_pet_id_fkey` joins. Visibility filter: `public` posts (followers = owner-only until follow system exists) |

### 9.3 Controllers

| File | Review |
|------|--------|
| `social_controller.dart` | `AsyncNotifierProvider`. Fetches feed on build, supports `refresh()` |

### 9.4 Screen

| File | Review |
|------|--------|
| `social_screen.dart` | Feed list with refresh. Shows post content, author, pet, images, timestamps |

### 9.5 Findings

| Severity | Issue | Recommendation |
|----------|-------|---------------|
| ⚠ MISSING | **No post creation UI** — social is read-only | Add "Create Post" screen with image upload |
| ⚠ MISSING | **No like/unlike toggle** | Implement `post_likes` insert/delete with optimistic UI |
| ⚠ MISSING | **No comment functionality** | `comment_count` column exists but no comment model/screen/controller |
| ⚠ MISSING | **No user profile page** — posts show author name but no profile link | Add user profile screen with their posts |

---

## 10. Database Review

All database information obtained via **Supabase MCP** (`list_projects`, `list_tables` verbosed, `list_extensions`, `list_migrations`).

### 10.1 Project

| Property | Value |
|----------|-------|
| Project ID | `jqyjvhwlcqcsuwcqgcwf` |
| Name | petfolio |
| Region | `ap-northeast-1` |
| Status | `ACTIVE_HEALTHY` |
| Database | PostgreSQL 17.6.1 |
| Created | 2026-05-11 |

### 10.2 All 17 Tables (Verbose Schema)

#### `public.users` — 5 rows
| Column | Type | Constraints |
|--------|------|-------------|
| id | uuid | PK → `auth.users.id` |
| username | text | UNIQUE NOT NULL |
| display_name | text | DEFAULT '' |
| avatar_url | text | nullable |
| bio | text | nullable |
| location | text | nullable |
| created_at | timestamptz | DEFAULT now() |
| updated_at | timestamptz | DEFAULT now() |

**RLS:** ✅ Enabled  
**Child FK refs:** 14 tables reference this

#### `public.pets` — 4 rows
| Column | Type | Constraints |
|--------|------|-------------|
| id | uuid | PK DEFAULT gen_random_uuid() |
| owner_id | uuid | NOT NULL → users.id |
| name | text | NOT NULL |
| species | text | NOT NULL |
| breed | text | nullable |
| date_of_birth | date | nullable |
| gender | text | CHECK (male/female/unknown) DEFAULT unknown |
| weight_kg | numeric(5,2) | nullable |
| avatar_url | text | nullable |
| bio | text | nullable |
| is_public | boolean | DEFAULT true |
| activity_level | text | CHECK (sedentary/low/moderate/high/very_high), nullable |
| created_at | timestamptz | DEFAULT now() |
| updated_at | timestamptz | DEFAULT now() |

**RLS:** ✅ Enabled  
**Child FK refs:** 13 tables reference this

#### `public.care_tasks` — 13 rows
| Column | Type | Constraints |
|--------|------|-------------|
| id | uuid | PK DEFAULT gen_random_uuid() |
| pet_id | uuid | NOT NULL → pets.id |
| task_type | text | CHECK (11 types: feeding/walk/grooming/medication/vet_visit/training/playtime/dental/nail_trim/bath/other) |
| title | text | NOT NULL |
| frequency | text | CHECK (once/daily/twice_daily/weekly/biweekly/monthly/as_needed) |
| scheduled_time | time | nullable |
| is_completed | boolean | DEFAULT false |
| completed_at | timestamptz | nullable |
| gamification_points | integer | DEFAULT 10, CHECK ≥ 0 |
| notes | text | nullable |
| created_at | timestamptz | DEFAULT now() |
| updated_at | timestamptz | DEFAULT now() |

**RLS:** ✅ Enabled

#### `public.care_logs` — 4 rows
| Column | Type | Constraints |
|--------|------|-------------|
| id | uuid | PK DEFAULT gen_random_uuid() |
| pet_id | uuid | NOT NULL → pets.id |
| logged_by | uuid | NOT NULL → users.id |
| care_type | text | CHECK (11 types including dental/nail_trim/bath) |
| notes | text | nullable |
| duration_minutes | integer | CHECK > 0, nullable |
| occurred_at | timestamptz | DEFAULT now() |
| created_at | timestamptz | DEFAULT now() |
| logged_date | date | DEFAULT CURRENT_DATE, nullable |

**Unique constraint:** `(pet_id, care_type, logged_date)`  
**RLS:** ✅ Enabled

#### `public.care_streaks` — 0 rows
| Column | Type | Constraints |
|--------|------|-------------|
| pet_id | uuid | PK → pets.id |
| current_streak | integer | DEFAULT 0, CHECK ≥ 0 |
| last_completion_date | date | nullable |
| best_streak | integer | DEFAULT 0, CHECK ≥ 0 |

**RLS:** ✅ Enabled  
**Note:** Composite PK = pet_id only (1:1 with pets)

#### `public.health_logs` — 3 rows
| Column | Type | Constraints |
|--------|------|-------------|
| id | uuid | PK DEFAULT gen_random_uuid() |
| pet_id | uuid | NOT NULL → pets.id |
| recorded_by | uuid | NOT NULL → users.id |
| log_type | text | CHECK (symptom/weight/vet_visit/medication/allergy/injury/general) |
| title | text | NOT NULL |
| description | text | nullable |
| weight_kg | numeric | CHECK > 0, nullable |
| severity | text | CHECK (mild/moderate/severe/critical), nullable |
| vet_name | text | nullable |
| vet_clinic | text | nullable |
| diagnosis | text | nullable |
| treatment | text | nullable |
| follow_up_date | date | nullable |
| occurred_at | timestamptz | DEFAULT now() |
| created_at | timestamptz | DEFAULT now() |
| updated_at | timestamptz | DEFAULT now() |

**RLS:** ✅ Enabled

#### `public.health_vitals` — 0 rows
| Column | Type | Constraints |
|--------|------|-------------|
| id | uuid | PK DEFAULT gen_random_uuid() |
| pet_id | uuid | NOT NULL → pets.id |
| recorded_by | uuid | NOT NULL → users.id |
| vital_type | text | CHECK (weight/temperature/heart_rate/blood_pressure/glucose/other) |
| value | numeric | NOT NULL |
| unit | text | NOT NULL |
| notes | text | nullable |
| recorded_at | timestamptz | DEFAULT now() |
| created_at | timestamptz | DEFAULT now() |

**RLS:** ✅ Enabled  
**Note:** 0 rows — no Dart model or controller exists for this table

#### `public.medical_vault` — 1 row
| Column | Type | Constraints |
|--------|------|-------------|
| id | uuid | PK DEFAULT gen_random_uuid() |
| pet_id | uuid | NOT NULL → pets.id |
| record_type | text | CHECK (vaccine/medication/allergy/surgery/parasite_prevention/other) |
| name | text | NOT NULL |
| description | text | nullable |
| administered_by | text | nullable |
| administered_at | date | nullable |
| expires_at | date | nullable |
| next_due_at | date | nullable |
| batch_number | text | nullable |
| dosage | text | nullable |
| frequency | text | nullable |
| is_active | boolean | DEFAULT true |
| reminder_enabled | boolean | DEFAULT true |
| document_url | text | nullable |
| notes | text | nullable |
| created_at | timestamptz | DEFAULT now() |
| updated_at | timestamptz | DEFAULT now() |

**RLS:** ✅ Enabled

#### `public.pet_badges` — 0 rows
| Column | Type | Constraints |
|--------|------|-------------|
| pet_id | uuid | PK → pets.id |
| badge_type | text | PK |
| unlocked_at | timestamptz | DEFAULT now() |

**Composite PK:** `(pet_id, badge_type)`  
**RLS:** ✅ Enabled

#### `public.posts` — 1 row
| Column | Type | Constraints |
|--------|------|-------------|
| id | uuid | PK DEFAULT gen_random_uuid() |
| author_id | uuid | NOT NULL → users.id |
| pet_id | uuid | nullable → pets.id (ON DELETE SET NULL) |
| content | text | NOT NULL |
| image_urls | text[] | DEFAULT '{}' |
| visibility | text | CHECK (public/followers/private), DEFAULT 'public' |
| like_count | integer | DEFAULT 0, CHECK ≥ 0 |
| comment_count | integer | DEFAULT 0, CHECK ≥ 0 |
| created_at | timestamptz | DEFAULT now() |
| updated_at | timestamptz | DEFAULT now() |

**RLS:** ✅ Enabled

#### `public.post_likes` — 1 row
| Column | Type | Constraints |
|--------|------|-------------|
| id | uuid | PK DEFAULT gen_random_uuid() |
| post_id | uuid | NOT NULL → posts.id |
| pet_id | uuid | NOT NULL → pets.id |
| user_id | uuid | NOT NULL → users.id |
| created_at | timestamptz | DEFAULT now() |

**RLS:** ✅ Enabled

#### `public.pet_follows` — 0 rows
| Column | Type | Constraints |
|--------|------|-------------|
| id | uuid | PK DEFAULT gen_random_uuid() |
| follower_pet_id | uuid | nullable → pets.id |
| following_pet_id | uuid | nullable → pets.id |
| created_at | timestamptz | nullable DEFAULT now() |

**RLS:** ✅ Enabled  
⚠ Both FK columns are **nullable** — should be NOT NULL

#### `public.match_requests` — 3 rows
| Column | Type | Constraints |
|--------|------|-------------|
| id | uuid | PK DEFAULT gen_random_uuid() |
| requester_id | uuid | NOT NULL → users.id |
| target_id | uuid | NOT NULL → users.id |
| requester_pet_id | uuid | NOT NULL → pets.id |
| target_pet_id | uuid | NOT NULL → pets.id |
| match_type | text | CHECK (playdate/breeding/adoption) |
| status | text | CHECK (pending/accepted/rejected/cancelled), DEFAULT 'pending' |
| message | text | nullable |
| created_at | timestamptz | DEFAULT now() |
| updated_at | timestamptz | DEFAULT now() |

**Check:** `no_self_match` (requester_id != target_id)  
**RLS:** ✅ Enabled

#### `public.chat_threads` — 0 rows
| Column | Type | Constraints |
|--------|------|-------------|
| id | uuid | PK DEFAULT gen_random_uuid() |
| match_request_id | uuid | UNIQUE, nullable → match_requests.id (ON DELETE SET NULL) |
| participant_1_id | uuid | NOT NULL → users.id |
| participant_2_id | uuid | NOT NULL → users.id |
| last_message_at | timestamptz | nullable |
| created_at | timestamptz | DEFAULT now() |

**Check:** `no_self_thread` (participant_1_id != participant_2_id)  
**RLS:** ✅ Enabled  
**Note:** INSERT is trigger-only (no user INSERT grant). Trigger `private.handle_match_accepted()` creates thread when match is accepted.

#### `public.chat_messages` — 0 rows
| Column | Type | Constraints |
|--------|------|-------------|
| id | uuid | PK DEFAULT gen_random_uuid() |
| thread_id | uuid | NOT NULL → chat_threads.id |
| sender_id | uuid | NOT NULL → users.id |
| content | text | NOT NULL |
| is_read | boolean | DEFAULT false |
| created_at | timestamptz | DEFAULT now() |

**RLS:** ✅ Enabled  
**Trigger:** `on_chat_message_sent` updates `chat_threads.last_message_at`

#### `public.products` — 8 rows
| Column | Type | Constraints |
|--------|------|-------------|
| id | uuid | PK DEFAULT gen_random_uuid() |
| name | text | NOT NULL |
| brand | text | NOT NULL |
| variant | text | DEFAULT '' |
| category | text | CHECK (food/gear/toys/treats/health/grooming) |
| price_cents | integer | CHECK > 0 |
| currency | text | DEFAULT 'usd' |
| subscribable | boolean | DEFAULT false |
| glyph | text | DEFAULT 'bag' |
| gradient_start | text | DEFAULT '#F4B57A' |
| gradient_end | text | DEFAULT '#C46A4F' |
| active | boolean | DEFAULT true |
| created_at | timestamptz | DEFAULT now() |

**RLS:** ✅ Enabled  
**Note:** Standalone table — no foreign keys

#### `public.marketplace_orders` — 2 rows
| Column | Type | Constraints |
|--------|------|-------------|
| id | uuid | PK DEFAULT gen_random_uuid() |
| buyer_id | uuid | NOT NULL → users.id |
| seller_id | uuid | nullable → users.id |
| title | text | NOT NULL |
| description | text | nullable |
| amount_cents | bigint | CHECK > 0 |
| currency | text | DEFAULT 'usd' |
| status | text | CHECK (pending/confirmed/shipped/delivered/cancelled/refunded), DEFAULT 'pending' |
| shipping_address | jsonb | nullable |
| created_at | timestamptz | DEFAULT now() |
| updated_at | timestamptz | DEFAULT now() |
| stripe_payment_intent_id | text | nullable, UNIQUE index |
| line_items | jsonb | DEFAULT '[]' |

**Check:** `no_self_order` (buyer_id != seller_id)  
**RLS:** ✅ Enabled  
**Note:** `seller_id` made nullable by migration, `stripe_payment_intent_id` added for Stripe integration

### 10.3 Installed Extensions

| Extension | Version | Schema | Purpose |
|-----------|---------|--------|---------|
| pgcrypto | 1.3 | extensions | Cryptographic functions |
| uuid-ossp | 1.1 | extensions | UUID generation |
| supabase_vault | 0.3.1 | vault | Secret management |
| pg_stat_statements | 1.11 | extensions | Query performance tracking |

**Available (not installed)** — useful for future features:
- `pg_graphql` (1.5.11) — GraphQL endpoint
- `vector` (0.8.0) — Embeddings/AI search
- `pgmq` (1.5.1) — Message queue
- `pg_net` (0.20.0) — Async HTTP requests
- `http` (1.6) — HTTP client in SQL
- `postgis` (3.3.7) — Geospatial queries
- `pgroonga` (3.2.5) — Full-text search

### 10.4 Applied Migrations

| Version | Name | Purpose |
|---------|------|---------|
| `20260512000000` | marketplace | Products table (8 seeded), orders with Stripe columns (`stripe_payment_intent_id`, `line_items`), make `seller_id` nullable |
| `20260514195223` | care_streaks_badges | `care_streaks`, `pet_badges` tables, `check_daily_completion` RPC, `set_updated_at` trigger function |
| `20260514201737` | care_streaks_realtime | Realtime publication on `care_streaks` |
| `20260514205350` | care_logs_type_day | Added `logged_date` column + unique constraint `(pet_id, care_type, logged_date)` to `care_logs` |

**Note:** `20260513192825_pet_care_health.sql` exists in migration files but is **not applied** to the database. The `care_tasks`, `health_logs`, `medical_vault` tables it creates were likely created via the original schema.sql instead.

### 10.5 RLS Policy Design Summary

The schema uses a consistent pattern:
- `(SELECT auth.uid())` subselect syntax (cache per statement, not per row) ✅
- All policies target `TO authenticated` first (stops anon early) ✅
- UPDATE policies have both `USING` and `WITH CHECK` ✅
- Convention: "own data only" for INSERT/UPDATE/DELETE; broader SELECT for discoverability

**Notable policies:**
- **pets**: SELECT allows public pets OR own pets. INSERT/UPDATE/DELETE restricted to owner
- **chat_threads**: SELECT only for participants. **No INSERT grant** — trigger-only creation
- **chat_messages**: SELECT if user is a participant in the thread. INSERT requires sender to be thread participant
- **match_requests**: Both requester and target can SELECT/UPDATE. Only requester can INSERT/DELETE

---

## 11. Security Lints

From Supabase Advisor (`get_advisors` type=security):

| Severity | ID | Issue | Fix |
|----------|-----|-------|-----|
| ⚠ WARN | `public_bucket_allows_listing` | Public bucket `pets` has broad SELECT policy on `storage.objects` | Remove or restrict the SELECT policy (public buckets don't need listing for URL access) |
| ⚠ WARN | `public_bucket_allows_listing` | Public bucket `post-images` has broad SELECT policy | Same as above |
| ⚠ WARN | `anon_security_definer_function_executable` | `check_daily_completion(target_pet_id uuid)` is SECURITY DEFINER and callable by `anon` role via REST API | Revoke EXECUTE from anon, or switch to SECURITY INVOKER |
| ⚠ WARN | `authenticated_security_definer_function_executable` | Same function callable by `authenticated` role as SECURITY DEFINER | Review — may be intentional (needs RLS check inside function) |
| ⚠ WARN | `auth_leaked_password_protection` | Leaked password protection (HaveIBeenPwned check) is disabled | Enable in Auth settings → Password Security |

---

## 12. Performance Lints

From Supabase Advisor (`get_advisors` type=performance):

| Severity | ID | Issue | Location | Fix |
|----------|-----|-------|----------|-----|
| ⚠ WARN | `duplicate_index` | **Duplicate indexes** on `care_logs` | `care_logs_pet_care_day_uix` ≡ `care_logs_pet_care_type_logged_date_uq` | Drop `care_logs_pet_care_day_uix` |
| ⚠ WARN | `auth_rls_initplan` | `auth.uid()` re-evaluated per row in RLS | `pet_follows` policy "Pets can follow" | Wrap `auth.uid()` in `(SELECT auth.uid())` |
| ⚠ WARN | `auth_rls_initplan` | Same issue | `pet_follows` policy "Pets can unfollow" | Same fix |
| ℹ INFO | `unindexed_foreign_keys` | No covering index for FK | `match_requests.requester_pet_id_fkey` | CREATE INDEX |
| ℹ INFO | `unindexed_foreign_keys` | No covering index for FK | `match_requests.target_pet_id_fkey` | CREATE INDEX |
| ℹ INFO | `unindexed_foreign_keys` | No covering index for FK | `pet_follows.following_pet_id_fkey` | CREATE INDEX |
| ℹ INFO | `unindexed_foreign_keys` | No covering index for FK | `post_likes.pet_id_fkey` | CREATE INDEX |
| ℹ INFO | `unindexed_foreign_keys` | No covering index for FK | `post_likes.user_id_fkey` | CREATE INDEX |
| ℹ INFO | `unused_index` | 13 indexes never used | Across `care_logs`(2), `health_vitals`(2), `posts`(2), `match_requests`(1), `chat_threads`(2), `chat_messages`(2), `marketplace_orders`(3), `care_tasks`(1), `health_logs`(2), `medical_vault`(2) | Review — some may be pre-created for future queries |

---

## 13. Critical Bugs

### 🔴 Bug 1: `chat_thread.dart` — Wrong column names

**File:** `lib/features/matching/data/models/chat_thread.dart`  
**Issue:** The `fromJson` factory resolves `pet_id_1` / `pet_id_2` from the JSON, but the database `chat_threads` table stores `participant_1_id` / `participant_2_id` (which are **user IDs**, not pet IDs).  
**Impact:** `ChatThread` instances will have null `myPetId`/`otherPetId` fields. Cross-feature resolution (which pet belongs to which user in the thread) is broken.

```dart
// Current (broken):
final isPet1 = json['pet_id_1'] == myPetId;
// Should be:
// Need to first find which pet the current user owns that's in this thread
```

**Fix options:**
1. **Schema change:** Add `pet_id_1` / `pet_id_2` columns to `chat_threads` table  
2. **Code fix:** Look up the user's pets that match the participant IDs, then determine which pet is "mine" vs "other"

### 🔴 Bug 2: `active_pet_controller.dart` — Cross-session pet ID leak

**File:** `lib/features/pet_profile/presentation/controllers/active_pet_controller.dart`  
**Issue:** Persisted `active_pet_id` in SharedPreferences is not scoped to the authenticated user. If User A logs out and User B logs in on the same device, User B might see User A's pet data.  
**Fix:** Include `userId` in the SharedPreferences key: `active_pet_id_{userId}`.

### ⚠ Bug 3: `health_repository.dart` — Hard throw on delete

**File:** `lib/features/care/data/repositories/health_repository.dart`  
**Issue:** Medical record delete uses a bare `throw` without wrapping in `AppException`.  
**Fix:** Wrap `throw` in try/catch → throw `DatabaseException` or return result type.

### ⚠ Bug 4: `pet_care_repository.dart` — Silent catch on RPC

**File:** `lib/features/care/data/repositories/pet_care_repository.dart` (lines 560-573)  
**Issue:** `check_daily_completion` RPC call has `catch (_) {}` — any failure is silently swallowed. User won't know if streak/badge update failed.  
**Fix:** Log the error or surface via return type.

### ⚠ Bug 5: `pet_care_repository.dart` — PGRST116 magic string

**File:** `lib/features/care/data/repositories/pet_care_repository.dart` (lines 406, 432)  
**Issue:** Catches `e.code == 'PGRST116'` which is a Supabase REST-specific error code that may not exist in all Supabase versions.  
**Fix:** Use more robust checks or rely on `PostgrestException` type directly.

### ⚠ Bug 6: Marketplace — In-memory cart with no persistence

**File:** `lib/features/marketplace/presentation/controllers/cart_controller.dart`  
**Issue:** Cart state is completely in-memory (no SharedPreferences, no Supabase storage). Lost on app restart.  
**Fix:** Persist to SharedPreferences or Supabase (create a `carts` table).

### ⚠ Bug 7: Marketplace — Tax = $0

**File:** `lib/features/marketplace/presentation/controllers/cart_controller.dart`  
**Issue:** `_calculateTax()` returns 0.  
**Fix:** Implement tax calculation or connect to Stripe Tax API.

---

## 14. Missing Features vs Database Schema

| DB Table/Column | DB Has Data? | Dart Implementation |
|----------------|--------------|-------------------|
| `health_vitals` | 0 rows | ❌ No model, no repository, no controller, no UI |
| Post creation (`posts` INSERT) | 1 row | ❌ No "Create Post" screen or widget |
| Like/unlike (`post_likes`) | 1 row | ❌ No toggle implementation |
| Comments (`posts.comment_count` column exists) | — | ❌ No comment model/screen/controller |
| Real geolocation matching | — | ❌ Distance is UUID-deterministic, not real |
| OAuth sign-in (Google/Apple) | `auth.identities` table exists | ❌ Only email/password wired |
| Password reset | — | ❌ No reset flow |
| Photo upload (pet avatar) | — | ❌ No image picker integrated |
| Stripe subscriptions (recurring) | — | ❌ Subscribe toggle is UI-only |
| Stripe webhook | — | ❌ Order confirmation is client-side only |

---

## 15. Strengths

- **Theme-first architecture** is consistently applied across all features. No hardcoded colors or text styles.
- **Offline-first pattern** in `checklist_repository.dart` (SharedPreferences cache + Supabase sync with 7-day window)
- **Optimistic UI with error reversion** in `care_controller.dart` — toggles task state immediately, reverts on failure, shows `AppSnackBar.showError`
- **Realtime streak sync** via `care_streak_realtime_provider`
- **Medical record computed properties** (`isExpiringSoon` computed from `expires_at`, `renewalDate`)
- **Auth guard pattern** in router via `_RouterNotifier` with proper redirects
- **RLS best practices**: All policies use `(SELECT auth.uid())` syntax, target `TO authenticated` first, have both USING/WITH CHECK for UPDATE
- **Trigger-based architecture**: `private.handle_new_user()` auto-creates public profiles, `private.handle_match_accepted()` auto-creates chat threads — no user INSERT grant on `chat_threads`
- **Proper barrel exports** (`widgets.dart`, `theme.dart`) for clean imports
- **No `.g.dart`/`.freezed.dart` imports** from outside model directories
- **Consistent error handling hierarchy**: `NotAuthenticatedException → DatabaseException → NetworkException`
- **Schema.sql-based grants**: Explicit GRANT per table to anon/authenticated

---

## 16. Recommendations

### Immediate (Bugs)
1. Fix `chat_thread.dart` column mapping (`pet_id_1/pet_id_2` → `participant_1_id/participant_2_id`)
2. Fix `active_pet_controller.dart` cross-session leak (scope SharedPreferences key to userId)
3. Add cart persistence (SharedPreferences or DB table)
4. Implement real tax calculation or Stripe Tax API

### Short-term (Missing Core Features)
5. Add OAuth sign-in (Google/Apple) — Supabase Auth supports this natively
6. Enable leaked password protection in Auth settings
7. Add `HealthVital` model + repository + controller + UI for `health_vitals` table
8. Implement post creation UI in Social
9. Add like/unlike toggle for posts
10. Add Stripe webhook endpoint for payment confirmation

### Medium-term (Quality & Performance)
11. Drop duplicate index `care_logs_pet_care_day_uix` on `care_logs`
12. Fix `auth_rls_initplan` warning on `pet_follows` — wrap `auth.uid()` in subselect
13. Add covering indexes for unindexed foreign keys (4 on `match_requests`, `pet_follows`, `post_likes`)
14. Fix `pet_care_repository.dart` silent catch on RPC failure
15. Add proper error states to marketplace product/order screens
16. Restrict `storage.objects` SELECT policies on public buckets `pets` and `post-images`

### Long-term (Architecture)
17. Extract shared `Pet` model to a core location instead of cross-feature imports
18. Consider switching to `@riverpod` annotations with code generation for provider boilerplate
19. Add location/geospatial data to `pets` table + enable PostGIS extension for real proximity matching
20. Build a proper follow/friend system (currently `followers` visibility = owner-only)
21. Implement comment system with `chat_messages`-like pattern for posts
22. Consider Stripe subscriptions with proper webhook handling
23. Review 13 unused indexes and clean up; some may be pre-created for future feature wins