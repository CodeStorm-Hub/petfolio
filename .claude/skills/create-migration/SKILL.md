---
name: create-migration
description: Scaffold a new Supabase migration file with a correct timestamp name and a commented RLS template. Use when the user asks to create a migration, add a table, or modify the schema.
disable-model-invocation: true
---

# Create Supabase Migration

## Steps

1. Ask the user for a migration name if not provided via args (use snake_case, e.g. `add_notifications_table`).

2. Generate the current timestamp in `yyyyMMddHHmmss` format using PowerShell:
   ```powershell
   Get-Date -Format 'yyyyMMddHHmmss'
   ```

3. Create the file at `supabase/migrations/<timestamp>_<name>.sql` with this template:
   ```sql
   -- ============================================================
   -- Migration: <name>
   -- Created:   <timestamp>
   -- ============================================================

   -- TABLE DEFINITION
   -- create table public.<name> (
   --   id uuid primary key default gen_random_uuid(),
   --   created_at timestamptz not null default now()
   -- );

   -- RLS
   -- alter table public.<name> enable row level security;

   -- POLICIES
   -- create policy "Users can read own rows"
   --   on public.<name> for select
   --   using (auth.uid() = user_id);
   ```

4. Print: "Migration created: supabase/migrations/<filename>. Edit the SQL, then run: npx supabase db reset"

5. Update `progress.md` — append under the current phase:
   - `Schema: <name> migration scaffolded`

6. Remind the user: "Phase update logged — run /remember to save tokens before continuing."
