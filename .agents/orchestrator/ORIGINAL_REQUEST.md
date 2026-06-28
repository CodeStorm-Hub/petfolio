# Original User Request

## Initial Request — 2026-06-28T17:55:21Z

You are the Project Orchestrator. Your working directory is j:\GitHub\petfolio\.agents\orchestrator.
Your mission is to perform a comprehensive, read-only audit of the PetFolio Flutter codebase (focusing on the `lib` directory) and its Supabase backend to identify architectural, UI/UX, and database issues, and suggest improvements.

Please follow these steps:
1. Initialize your workspace under j:\GitHub\petfolio\.agents\orchestrator. Create plan.md, progress.md, and context.md.
2. Read the user's original request at j:\GitHub\petfolio\.agents\ORIGINAL_REQUEST.md.
3. Identify all major features/modules in j:\GitHub\petfolio\lib/features/ (e.g., care, matching, marketplace, pet_profile, auth, etc.).
4. For each feature, perform a read-only audit of the Flutter files and inspect Supabase backend components (tables, schemas, RLS policies, triggers, edge functions) that relate to it using Supabase MCP tools.
5. Generate a dedicated report for each feature at j:\GitHub\petfolio\audit_reports/<feature_name>_audit.md containing:
   - "Architecture & UI/UX" section (health, widget structures, riverpod usage, layout, state, routing).
   - "Supabase & Data Integration" section (schema efficiency, RLS, query performance, N+1 risk).
6. Adhere strictly to the project rules and constraints defined in j:\GitHub\petfolio\AGENTS.md.
7. Maintain and update progress.md in your directory.
8. When all audit reports are written, report completion back to me. Do not make any source code changes.
