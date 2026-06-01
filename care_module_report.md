# Petfolio Care Module Audit Report

## 1. Overview and Objective
The **Care Module** (`lib/features/care`) serves as the central hub for managing a pet's daily wellness and long-term health. Its primary objective is to make pet care engaging, structured, and informed by combining daily routine tracking with gamification, secure medical document storage, health trend analysis (like nutrition), and AI-generated personalized care plans.

---

## 2. Key Features and Functionalities

### A. Daily Routine & Dashboard
- **Location:** `CareScreen`, `CareDashboardController`
- **Functionality:** Users can track various care tasks (Feeding, Walk, Medication, Grooming, etc.). Tasks can be recurring (daily, weekly, monthly, once) or ad-hoc.
- **UI:** A robust dashboard displaying today's quests, a weekly completion chart, and animated task cards that provide visual feedback upon completion.
- **Database Backend:** 
  - `care_tasks`: Stores task definitions and recurrence rules.
  - `care_logs`: Records the actual completion events.
  - **Optimization:** To prevent N+1 queries, the app utilizes a highly optimized Supabase RPC function (`get_care_dashboard_snapshot`) to pull all tasks, logs, streaks, and badges in a single network request.

### B. Gamification (Trophy Room, Streaks, Badges)
- **Location:** `care_dashboard_controller.dart`, `gamified_care_ui.dart`, Supabase RPC `check_daily_completion`
- **Functionality:** Encourages consistent pet care. Completing tasks yields XP points. If a user completes all daily required tasks (e.g., feeding, walking, medication), their daily streak increments. Reaching milestones unlocks badges (e.g., `7_day_hero`).
- **Database Backend:** 
  - `care_streaks`: Tracks `current_streak`, `best_streak`, and `last_completion_date`.
  - `pet_badges`: Stores unlocked achievements.
  - **Realtime:** Uses Supabase realtime listeners (`careStreakRealtimeProvider`) to instantly update the UI when a streak increments from another device or background process.

### C. Medical Vault
- **Location:** `MedicalVaultScreen`, `HealthVaultController`
- **Functionality:** A secure place to store structured medical records such as vaccines, medications, allergies, and surgeries. 
- **Features:** 
  - Expiration and "Next Due" date tracking.
  - Document attachments (e.g., uploading vaccine certificates to Supabase Storage).
  - A planned "Share with vet" feature to generate temporary, 24-hour expiring QR codes.
- **Database Backend:** `medical_vault` table with specific RLS policies restricting access to the pet owner.

### D. Nutrition & Health Tracking
- **Location:** `NutritionScreen`, `NutritionController`
- **Functionality:** Tracks weight and caloric needs.
- **Features:** 
  - **Weight Trend Chart:** Visualizes weight history over time using `fl_chart`.
  - **Smart Nutrition Calculator:** Dynamically computes daily caloric needs (MER - metabolic energy requirements) based on the pet's species, weight, and activity level.
- **Database Backend:** `health_logs` table. This table handles narrative health events, symptoms, vet visits, and weight logs.

### E. AI Routine Generation
- **Location:** `CareRecommendationService`, `RoutineRecommendationSheet`
- **Functionality:** Users can request an AI-generated, personalized care plan.
- **Mechanics:** It gathers the pet's profile, recent medical vault data, and health logs, sending them as context to an NVIDIA API running the `google/gemma-3n-e4b-it` model. The AI returns a structured JSON payload of recommended daily, weekly, and monthly tasks tailored to the pet's specific breed, age, and health conditions.

---

## 3. Database Schema Overview (Supabase)

The Care module utilizes several heavily interconnected tables, all secured via **Row Level Security (RLS)** ensuring users only access their own pets' data:

- **`care_tasks`**: `(id, pet_id, task_type, title, frequency, scheduled_time, gamification_points)`
- **`care_logs`**: `(id, pet_id, logged_by, care_type, logged_date, occurred_at)`
- **`care_streaks`**: `(pet_id, current_streak, last_completion_date, best_streak)`
- **`pet_badges`**: `(pet_id, badge_type, unlocked_at)`
- **`health_logs`**: `(id, pet_id, log_type, weight_kg, severity, diagnosis, description)`
- **`medical_vault`**: `(id, pet_id, record_type, name, expires_at, next_due_at, document_url)`

**Notable Database Features:**
- **Trigger Functions:** Uses triggers like `public.set_updated_at()` to auto-update timestamps.
- **RPCs:** Heavy business logic (like verifying if all daily tasks are done to award a streak) is pushed to Postgres via RPCs (`check_daily_completion`) to maintain high performance.

---

## 4. Connected Modules and Dependencies

1. **Pet Profile Module (`lib/features/pet_profile`)**
   - The entire Care Module revolves around the `activePetControllerProvider`. 
   - Metadata from the `pets` table (e.g., `activity_level`, `species`, `weight`) is crucial for the Smart Nutrition calculations and the AI Routine Generation prompt.
2. **Core Module (`lib/core`)**
   - **UI/UX:** Relies heavily on `PetfolioThemeExtension` and `AppColors` for its distinct, premium look.
   - **Widgets:** Uses shared components like `TailWagLoader`, `SkeletonLoader`, `AppSnackBar`, and `AppBottomSheet`.
   - **Routing:** Handled via `GoRouter` in `router.dart`, with specific deep-link handling for onboarding success banners.
3. **Authentication & Storage**
   - **Supabase Auth:** Used extensively in RLS policies `(SELECT auth.uid())`.
   - **Supabase Storage:** Used by the Medical Vault for uploading and retrieving attached documents and prescriptions.
4. **Notifications**
   - Integrates with `NotificationService` to schedule local push notifications for tasks with a `scheduled_time`.
