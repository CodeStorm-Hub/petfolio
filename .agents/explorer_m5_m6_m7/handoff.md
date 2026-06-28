# Handoff Report — Explorer M5 M6 M7

## 1. Observation

Direct observations made during the read-only audit of the 7 features:

- **Communities RLS Policy**: In `supabase/migrations/20260608000000_communities.sql`, the RLS policies use bare `auth.uid()` checks.
  - Line 92: `create policy "communities_insert" on public.communities for insert with check (auth.uid() = created_by);`
  - Line 96: `with check (exists (select 1 from public.pets where id = pet_id and owner_id = auth.uid()));`
- **Communities Missing Indexes**: In `supabase/migrations/20260608000000_communities.sql`, no index statement exists for:
  - `community_members(pet_id)`
  - `community_posts(community_id)`
  - `community_posts(author_pet_id)`
  - `community_post_likes(pet_id)`
- **Appointments RLS Policy**: In `supabase/migrations/20260608010000_appointments.sql`, all RLS policies use bare `auth.uid()`.
  - Line 18: `create policy "appointments_select" on public.appointments for select using (auth.uid() = owner_id);`
- **Admin Client-Side Aggregation**: In `lib/features/admin/data/repositories/admin_repository.dart` (lines 53-62), platform revenue is aggregated on the client:
  ```dart
  Future<int> fetchPlatformRevenueCents() async {
    final rows = await _client
        .from('vendor_ledgers')
        .select('platform_fee_cents')
        .eq('status', LedgerStatus.paid.name);
    return (rows as List).fold<int>(
      0,
      (sum, r) => sum + (r['platform_fee_cents'] as int),
    );
  }
  ```
- **Offers Screen Shared Dependencies**: In `lib/features/offers/presentation/screens/offers_screen.dart`, imports include:
  - `import '../../../marketplace/data/models/promo.dart';` (line 11)
  - `import '../../../marketplace/presentation/controllers/promo_controller.dart';` (line 12)
- **Home Screen Presentation-Only**: `lib/features/home/presentation/screens/hub_home_screen.dart` is a UI screen aggregating state from other features (such as `careDashboardProvider` and `activePetControllerProvider`) without owning any database tables.

## 2. Logic Chain

1. **Bare Auth Checks**: The project instructions in `AGENTS.md` explicitly state: "When writing Row Level Security (RLS) policies, always wrap authentication checks in a subselect, such as `(select auth.uid())`, to force the Postgres optimizer to cache the result and prevent severe performance degradation." Since the `communities` and `appointments` migrations use `auth.uid()` directly (without subselect wrapping), they violate this performance optimization constraint.
2. **Missing Indexes**: In Postgres, searching or joining on unindexed foreign keys (like the relations in `community_members` and `community_posts`) forces the database to perform sequential scans on those tables on every select/filter query, causing performance bottlenecks as rows scale.
3. **In-Memory Calculation**: Querying all vendor ledger items to calculate revenue in `admin_repository.dart` sends unnecessary data rows across the network and handles the sum calculation in Dart memory. This scales poorly compared to database-level aggregation queries like `SUM(...)`.
4. **Architectural Conformity**: All Flutter screen layouts correctly implement the Riverpod generated notifiers (avoiding legacy `provider` package imports) and organize code via feature-first structure (presentation/data separation). Routing definitions avoid circular imports.

## 3. Caveats

- **External Integrations**: We did not execute live Supabase calls, Stripe merchant onboarding webhooks, or SSLCommerz payment processors since this was a read-only investigation.
- **Project Scope**: Restricted analysis to the seven requested features. Legacy features (e.g. matching, care/nutrition) were only examined where imported as dependencies.

## 4. Conclusion

- **Marketplace, Social, Offers, Home** are architecturally compliant with the project rules.
- **Communities & Appointments** violate performance guidelines due to bare `auth.uid()` checks in their RLS migration files. Additionally, the communities tables lack indexing on key foreign relation lookups.
- **Admin Repository** contains a client-side aggregation issue on platform revenue calculation that should be moved database-side.

## 5. Verification Method

- **RLS Inspection**: Verify the migration definitions using `view_file` on `supabase/migrations/20260608000000_communities.sql` (lines 91-110) and `supabase/migrations/20260608010000_appointments.sql` (lines 18-28).
- **Static Analysis**: Verify there are no compilation warnings by running `dart analyze` inside the workspace.
