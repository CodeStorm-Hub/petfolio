# Handoff

## State
Phase 1 (security lockdown) of the marketplace audit plan is complete:
- `process_checkout` 4-arg RPC fixed live + via migration `supabase/migrations/20260620000000_fix_process_checkout_promo_overload_security.sql` (search_path pinned, anon revoked, authenticated-only).
- KYC doc links in `petfolio-dashboard/app/admin/vendors/page.tsx` + `components/admin/vendors-view.tsx` now use signed URLs via admin client.
- `SUPABASE_SERVICE_ROLE_KEY` in `petfolio-dashboard/.env` deliberately left for the user to fill in themselves — do not touch.

## Next
Phase 2 (functional gaps), not started:
1. Missing dashboard pages: `/admin/vendors/[id]`, `/vendor/orders/[id]`, `/admin/orders/[id]`, `/unauthorized`.
2. Supabase fixes: dedupe `shop_deletion_requests` policies, add 11 missing FK indexes, consolidate multiple_permissive_policies, wrap `auth.uid()` in `(select ...)` on `user_addresses`.
3. Flutter: error state in `ProductListNotifier.loadMore()`; retry/backoff in `pollOrderConfirmation()` instead of hard 15s timeout.
4. Ask user whether mobile vendor flow (`/seller/*` routes currently redirect to web) is in-scope before touching it.

Full plan: `C:\Users\syedr\.claude\plans\for-the-petfolio-whole-snuggly-cupcake.md` (Phases 3-4 are UX polish, lower priority).

## Context
User wants live-DB migrations confirmed via AskUserQuestion before applying. PowerShell sandboxes `npx`/tsc — use the Bash tool (Git Bash) for those instead.
