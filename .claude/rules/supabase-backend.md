# Supabase Backend Rules — Petfolio

## Client

- Use the native `supabase_flutter` SDK (`Supabase.instance.client`) exclusively for all database, auth, storage, and realtime access. Never write raw REST/HTTP calls against Supabase endpoints.
- `Supabase.instance.client` is called only from `data/repositories/` (or `data/datasources/`) — never from a controller, screen, or widget. See `.claude/rules/flutter-architecture.md` for the layering rule.

## Security model — Postgres RLS is the only enforcement boundary

- Row Level Security (RLS) policies are the sole mechanism for data protection. Do not write Dart-side permission checks, custom auth middleware, or client-side filtering as a substitute for RLS — client code runs on the user's device and is not a trust boundary.
- Every new table must ship with RLS enabled and explicit, scoped policies. A table with RLS disabled, or with a blanket `USING (true)` policy where it isn't intentional, is a bug to flag, not a shortcut to take.
- Operations that need elevated privileges (bypassing RLS for a legitimate reason — e.g. checkout finalization, admin actions) go through a `SECURITY DEFINER` Postgres function (RPC) with the privilege escalation scoped inside the function body. Never grant the `anon` or `authenticated` role broad table access to work around RLS.
- Treat `get_advisors` (Supabase MCP) output on RLS/security as authoritative — fix flagged tables before considering a feature done.

## Sequencing for any feature touching the backend

Strict order, one step per session/confirmation per root `CLAUDE.md`:

1. SQL migration + RLS policies
2. Dart model (Freezed/JsonSerializable, `fieldRename: FieldRename.snake`)
3. Repository (Supabase calls, maps rows to model)
4. Riverpod controller
5. UI

## Realtime & Storage

- Subscribe to realtime channels and call storage APIs from within a repository method, not from a widget or controller — the controller observes a stream/future exposed by the repository.
- Signed URLs (not public URLs) for any storage bucket containing user-uploaded or sensitive documents (KYC, prescriptions, etc.).
