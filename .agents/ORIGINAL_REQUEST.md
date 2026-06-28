# Original User Request

## Initial Request — 2026-06-28T11:55:01Z

A comprehensive, read-only audit of the PetFolio Flutter codebase (focusing on the `lib` directory) and its Supabase backend to identify architectural, UI/UX, and database issues, and suggest improvements.

Working directory: `j:\GitHub\petfolio`
Integrity mode: development

## Requirements

### R1. Codebase Audit
Analyze all modules, screens, and widgets in the `lib` directory. Evaluate the codebase against the architectural rules defined in `AGENTS.md` (e.g., Feature-First Architecture, Riverpod usage).

### R2. Supabase Integration Audit
Utilize the Supabase MCP to inspect the project's database schema, RLS policies, database triggers, and edge functions. Identify efficiency risks (e.g., N+1 queries, unoptimized RLS policies) and evaluate the Flutter-side data handling.

### R3. Output Generation
Generate separate markdown reports for each major feature/module (e.g., `audit_reports/<feature_name>_audit.md`). Each report must document identified issues and suggest concrete improvements without making source code changes.

## Acceptance Criteria

### Completeness
- [ ] A dedicated markdown report is created in the `audit_reports/` directory for each major feature/module discovered in the `lib` directory.

### Report Structure
- [ ] Every report includes an "Architecture & UI/UX" section detailing codebase health and presentation issues.
- [ ] Every report includes a "Supabase & Data Integration" section covering schema efficiency, RLS policies, and query performance.

### Alignment with Guidelines
- [ ] Suggested improvements explicitly adhere to the constraints listed in the repository's `AGENTS.md` file.

## Follow-up — 2026-06-28T12:09:55Z

Systematically implement the UI/UX, architectural, and database improvements identified in the audit reports, starting with a phased approach focused on core features.

Working directory: `j:\GitHub\petfolio`
Integrity mode: development

## Requirements

### R1. Phased Core Implementation
Begin by implementing the findings from `audit_reports/auth_audit.md`, `audit_reports/profile_audit.md`, and `audit_reports/home_audit.md`. Update the Flutter source code in `lib/features/` to resolve the identified UI/UX and architectural issues, ensuring strict compliance with `AGENTS.md` (e.g., proper Riverpod usage).

### R2. Supabase Migrations
For any database optimizations, RLS policy updates, or schema changes identified in those reports, generate proper SQL migration files in the `supabase/migrations/` directory. Apply these migrations using the Supabase CLI (`npx supabase db push`) or the Supabase MCP.

### R3. Quality Assurance
The modified features must remain fully compilable. You must run static analysis to ensure your changes do not introduce new regressions.

## Acceptance Criteria

### Codebase Health
- [ ] `dart analyze` returns no new errors or warnings for the `auth`, `profile`, and `home` feature directories.
- [ ] The Flutter app successfully compiles after your modifications.

### Database State
- [ ] Distinct, timestamped SQL migration files exist in `supabase/migrations/` for all applied database changes.

### Architectural Alignment
- [ ] All updated state management strictly utilizes Riverpod (no Provider or setState where Riverpod is appropriate).
- [ ] RLS policies include subselect optimizations as required by the architectural rules.
