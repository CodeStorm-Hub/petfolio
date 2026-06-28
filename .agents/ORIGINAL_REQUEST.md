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
