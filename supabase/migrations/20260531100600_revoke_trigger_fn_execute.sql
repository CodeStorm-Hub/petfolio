-- handle_comment_like_sync is a trigger function (invoked as table owner) and
-- should never be RPC-callable. It still carried a PUBLIC EXECUTE grant, so
-- anon/authenticated could invoke it directly (advisor 0028/0029). Triggers
-- fire regardless of EXECUTE grants, so revoking PUBLIC is safe.
-- The sibling trigger functions already lack a PUBLIC grant.

revoke execute on function public.handle_comment_like_sync() from public;
