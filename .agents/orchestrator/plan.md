# Plan — PetFolio Codebase and Database Audit

## Objective
Perform a comprehensive, read-only audit of the PetFolio Flutter codebase and its Supabase backend, generating separate reports in `audit_reports/<feature>_audit.md`.

## Steps
1. **Initialize Workspace**: Create `plan.md`, `progress.md`, and `context.md` in `.agents/orchestrator/` (Completed).
2. **Identify Features**: Look in `lib/features/` to discover all major modules.
3. **Decompose & Schedule**:
   - Create directories under `.agents/` for each feature audit.
   - Design tasks for `teamwork_preview_explorer` subagents to perform read-only audits.
4. **Inspect Supabase Schema**:
   - Use Supabase MCP tools to retrieve table definitions, RLS policies, triggers, and functions.
   - Provide these schema files/details to the explorer subagents.
5. **Dispatch & Execute**:
   - Dispatch `teamwork_preview_explorer` subagents for each feature.
   - Ensure the prompt instructs the explorer to audit the corresponding directory in `lib/features/` and Supabase tables, and write `audit_reports/<feature_name>_audit.md`.
6. **Monitor & Verify**:
   - Check on progress of each subagent.
   - Re-spawn/escalate if any agent gets stuck.
7. **Synthesize & Complete**:
   - Review generated audit files for quality and consistency.
   - Report completion to parent.
