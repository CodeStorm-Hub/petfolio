# Appointments Audit Report

**Audit Summary**: The appointments feature is built using feature-first and Riverpod conventions. The media storage policies are correctly optimized, but the main appointments table RLS policies violate project guidelines by using bare, uncached `auth.uid()` checks.

## Architecture & UI/UX

- **Feature-First Architecture**: Organized under `lib/features/appointments/` with:
  - `data/`: Contains models (`appointment.dart`, `vet_clinic.dart`, `vet_service.dart`) and repositories (`appointment_repository.dart`, `vet_repository.dart`).
  - `presentation/`: Contains controllers (e.g., `appointment_controller.dart`, `vet_booking_controller.dart`) and screens/sheets (e.g., `vet_hub_screen.dart`, `booking_confirmation_sheet.dart`).
- **Riverpod State Management**: Providers like `availableSlotsProvider` and `clinicListProvider` drive slot selection and vet clinic retrieval without manual provider calls.
- **Routing & Import Hygiene**: Configured cleanly in `appointment_routes.dart` using modular route definitions.

## Supabase & Data Integration

- **Uncached Table RLS Policies (Critical Rule Violation)**: In `20260608010000_appointments.sql`, all RLS policies (`appointments_select`, `appointments_insert`, `appointments_update`, `appointments_delete`) check `auth.uid() = owner_id` directly. They do not wrap `auth.uid()` in a subselect, which violates `AGENTS.md` rules and causes database performance degradation.
- **Optimized Storage RLS Policies**: Unlike the table policies, the storage policies for the `appointment-media` bucket (added in `20260611000000_enhance_appointments.sql`) correctly wrap checks in a subselect: `(SELECT auth.uid())::text = (string_to_array(name, '/'))[1]`.
- **Indexing**: Database indexes exist for `idx_appointments_pet_id`, `idx_appointments_scheduled_at`, and `idx_appointments_clinic_id`.
- **Automated Cron Reminders**: Integrates with pg_cron via the `appointment_reminders` job scheduled to run hourly. This securely invokes the `/appointment-reminders` Edge Function using a secret key stored in `private.fcm_internal_config`.
