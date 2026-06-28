# PetFolio Activity Feature Audit

## Architecture & UI/UX

### Feature-First Architecture
The `activity` feature resides under `lib/features/activity/` and is purely presentation-focused:
- `activity_routes.dart`
- `presentation/screens/activity_screen.dart`
It has no data or domain layers of its own. Instead, it aggregates details and services from other features:
- `buyerOrdersProvider` (and `MarketplaceOrder` models) from `lib/features/marketplace/`
- `appointmentControllerProvider` (and `Appointment` models) from `lib/features/appointments/`.

### State Management & Riverpod
- Utilizes Riverpod for dependency injection and state management.
- It watches `buyerOrdersProvider` and `appointmentControllerProvider` asynchronously.
- State is combined dynamically in the widget tree.
- It uses manual Riverpod providers.

### Widget Structure & UX
- `ActivityScreen` is a `ConsumerStatefulWidget` displaying a unified date-grouped vertical timeline of vet appointments and marketplace orders (resembling a Pathao timeline/history card list).
- It features robust filter chips (All, Orders, Appointments) with selection haptic feedback.
- It features partial failure states: if only one of the two providers (appointments or orders) fails to load, it displays the valid data alongside a subtle orange alert banner, rather than crashing or showing a full-screen blank error. If both fail, it displays a full-screen retry prompt.
- Loading states render a custom `TailWagLoader`.
- Cards render indicators for statuses (Upcoming, Missed, Completed for appointments; Pending, Processing, Shipped, Delivered, Cancelled for orders).
- The timelines are sorted chronologically (newest first) and grouped by date headers (e.g. 'Today', 'Yesterday', 'Jan 12, 2026').
- Custom transitions (`pfFadeThroughPage`) are used.
- Import paths do not introduce circular dependencies.

---

## Supabase & Data Integration

### Schema & RLS
- The `activity` feature has no associated database tables, schemas, or migrations.
- The underlying tables (`marketplace_orders` and `appointments`) are protected under their own RLS policies.
- RLS rules on those tables utilize plan-cached `(select auth.uid())` subselects to verify the authenticated owner before returning results.

### Client-Side Join Risk (N+1 Query)
- Relational mapping from IDs to model objects is pushed to the respective features.
- Since it relies on the pre-fetched lists from `buyerOrdersProvider` and `appointmentControllerProvider`, it performs no direct joins or database queries. No N+1 queries or client-side joins are executed.
