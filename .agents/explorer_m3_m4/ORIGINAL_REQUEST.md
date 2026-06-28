## 2026-06-28T11:56:19Z
You are a teamwork_preview_explorer subagent.
Your working directory is j:\GitHub\petfolio\.agents\explorer_m3_m4.
Your mission is to perform a comprehensive, read-only audit of the following features in the PetFolio project:
1. care
2. matching
3. messaging

For each of these features, you must:
1. Examine the corresponding Flutter files under `lib/features/<feature_name>/`. Check if they conform to:
   - Feature-First Architecture (clean division into presentation, domain, and data layers).
   - Riverpod state management (use of generated notifiers, avoid old 'provider' package).
   - Widget structures, layout, state, routing, and checking for circular imports.
2. Inspect the Supabase database migrations under `supabase/migrations/` that define tables, schemas, triggers, and functions related to these features. Look for:
   - Row Level Security (RLS) policies and check if auth checks are wrapped in a subselect e.g., `(select auth.uid())` to optimize query execution.
   - Schema efficiency, foreign key indexes, and any queries or conditions that might cause full table scans.
   - N+1 query risks in Flutter data retrieval (check repositories for client-side joins vs database joins/RPCs/views).
3. Generate a dedicated report for each feature at `j:\GitHub\petfolio\audit_reports/<feature_name>_audit.md` containing:
   - "Architecture & UI/UX" section
   - "Supabase & Data Integration" section
   - Adhere strictly to the project rules and constraints defined in `j:\GitHub\petfolio\AGENTS.md`.

Do not modify any source code files. Update your `progress.md` after completing each audit. When done, write `handoff.md` and send a message to parent (id: 8b12160e-9da0-4002-a568-233777fda1f8) reporting your findings and the paths of the written reports.
