-- ================================================================
-- 20260524000001_function_grants_fix.sql
--
-- Supabase's default privilege configuration grants EXECUTE on all
-- public-schema functions to both `anon` and `authenticated` when
-- the function is created. REVOKE ALL FROM PUBLIC (in the previous
-- migration) removes only the PUBLIC pseudo-role grant; the
-- explicit anon / authenticated grants survive.
--
-- This migration:
--   a) Explicitly REVOKEs EXECUTE from `anon` on every SECURITY
--      DEFINER function (anon users must never call these directly).
--   b) Explicitly REVOKEs EXECUTE from `authenticated` on trigger
--      and management functions that must not be user-callable.
--   c) Confirms EXECUTE is GRANTed to `authenticated` on all
--      legitimate user-facing RPCs (idempotent re-grant).
-- ================================================================


-- ----------------------------------------------------------------
-- Trigger / internal functions — no role should call these directly
-- ----------------------------------------------------------------
REVOKE EXECUTE ON FUNCTION public.handle_new_chat_message()  FROM anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.handle_post_comment_sync() FROM anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.handle_post_like_sync()    FROM anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.rls_auto_enable()          FROM anon, authenticated;


-- ----------------------------------------------------------------
-- User-facing RPCs — revoke anon, keep / re-grant authenticated
-- ----------------------------------------------------------------

REVOKE EXECUTE ON FUNCTION public.approve_vendor_kyc(uuid, uuid) FROM anon;
GRANT  EXECUTE ON FUNCTION public.approve_vendor_kyc(uuid, uuid) TO authenticated;

REVOKE EXECUTE ON FUNCTION public.cancel_order(uuid) FROM anon;
GRANT  EXECUTE ON FUNCTION public.cancel_order(uuid) TO authenticated;

REVOKE EXECUTE ON FUNCTION public.check_daily_completion(uuid, date) FROM anon;
GRANT  EXECUTE ON FUNCTION public.check_daily_completion(uuid, date) TO authenticated;

REVOKE EXECUTE ON FUNCTION public.confirm_order_inventory(uuid) FROM anon;
GRANT  EXECUTE ON FUNCTION public.confirm_order_inventory(uuid) TO authenticated;

REVOKE EXECUTE ON FUNCTION public.ensure_chat_thread_for_match(uuid, uuid) FROM anon;
GRANT  EXECUTE ON FUNCTION public.ensure_chat_thread_for_match(uuid, uuid) TO authenticated;

REVOKE EXECUTE ON FUNCTION public.get_or_create_social_thread(uuid) FROM anon;
GRANT  EXECUTE ON FUNCTION public.get_or_create_social_thread(uuid) TO authenticated;

REVOKE EXECUTE ON FUNCTION public.process_checkout(uuid, uuid, jsonb) FROM anon;
GRANT  EXECUTE ON FUNCTION public.process_checkout(uuid, uuid, jsonb) TO authenticated;

REVOKE EXECUTE ON FUNCTION public.reject_vendor_kyc(uuid, uuid, text) FROM anon;
GRANT  EXECUTE ON FUNCTION public.reject_vendor_kyc(uuid, uuid, text) TO authenticated;

REVOKE EXECUTE ON FUNCTION public.release_order_inventory(uuid) FROM anon;
GRANT  EXECUTE ON FUNCTION public.release_order_inventory(uuid) TO authenticated;

REVOKE EXECUTE ON FUNCTION public.request_shop_deletion(uuid, text) FROM anon;
GRANT  EXECUTE ON FUNCTION public.request_shop_deletion(uuid, text) TO authenticated;

REVOKE EXECUTE ON FUNCTION public.resolve_reported_post(uuid, text, boolean) FROM anon;
GRANT  EXECUTE ON FUNCTION public.resolve_reported_post(uuid, text, boolean) TO authenticated;

REVOKE EXECUTE ON FUNCTION public.resolve_shop_deletion(uuid, text, text) FROM anon;
GRANT  EXECUTE ON FUNCTION public.resolve_shop_deletion(uuid, text, text) TO authenticated;

REVOKE EXECUTE ON FUNCTION public.vendor_update_order(uuid, text, text, text, text) FROM anon;
GRANT  EXECUTE ON FUNCTION public.vendor_update_order(uuid, text, text, text, text) TO authenticated;
