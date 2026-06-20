-- Phase 6: Security Hardening
-- Addresses all Supabase security advisor warnings.

-- ── 1. Fix mutable search_path on private.fcm_data_to_text_map ───────────────
CREATE OR REPLACE FUNCTION private.fcm_data_to_text_map(p_data jsonb)
RETURNS jsonb
LANGUAGE sql
IMMUTABLE
SET search_path = ''
AS $$
  SELECT COALESCE(
    (
      SELECT jsonb_object_agg(key, value)
      FROM jsonb_each_text(COALESCE(p_data, '{}'::jsonb))
    ),
    '{}'::jsonb
  );
$$;

-- ── 2. fcm_push_outbox: server-only table — deny-all RLS policy ──────────────
-- RLS must stay enabled (PostgREST exposes public tables). Service_role
-- bypasses RLS, so Edge Functions still have full access. anon/authenticated
-- see no rows via the deny-all USING(false) policy.
ALTER TABLE public.fcm_push_outbox ENABLE ROW LEVEL SECURITY;

CREATE POLICY "fcm_push_outbox_no_direct_access" ON public.fcm_push_outbox
  USING (false);

-- ── 3. appointment-media: drop broad listing SELECT policy ────────────────────
-- Public buckets serve objects via signed/public URL without needing a storage
-- SELECT policy. This policy only enabled listing all objects in the bucket.
DROP POLICY IF EXISTS "appointment-media: public read" ON storage.objects;

-- ── 4. REVOKE anon EXECUTE from SECURITY DEFINER RPCs that require auth ───────
REVOKE EXECUTE ON FUNCTION public.dec_community_member_count()
  FROM anon;
REVOKE EXECUTE ON FUNCTION public.dec_community_post_count()
  FROM anon;
REVOKE EXECUTE ON FUNCTION public.get_care_dashboard_snapshot(
    uuid, date, date, date, date)
  FROM anon;
REVOKE EXECUTE ON FUNCTION public.get_or_create_social_thread(uuid)
  FROM anon;
REVOKE EXECUTE ON FUNCTION public.get_or_create_wishlist()
  FROM anon;
REVOKE EXECUTE ON FUNCTION public.inc_community_member_count()
  FROM anon;
REVOKE EXECUTE ON FUNCTION public.inc_community_post_count()
  FROM anon;
REVOKE EXECUTE ON FUNCTION public.matching_discovery_candidates(
    uuid, double precision, integer,
    timestamp with time zone, uuid,
    text[], integer, integer, text)
  FROM anon;
REVOKE EXECUTE ON FUNCTION public.refresh_product_rating_stats()
  FROM anon;
REVOKE EXECUTE ON FUNCTION public.toggle_care_task(
    text, uuid, text, boolean, date, timestamp with time zone)
  FROM anon;
REVOKE EXECUTE ON FUNCTION public.vendor_upsert_shipment(
    uuid, text, text, text, text, timestamp with time zone)
  FROM anon;

-- ── 5. REVOKE authenticated EXECUTE from admin-only / service-role-only RPCs ──

-- Admin-only (called via service role in admin tooling, never from the app)
REVOKE EXECUTE ON FUNCTION public.approve_vendor_kyc(uuid, uuid)
  FROM authenticated;
REVOKE EXECUTE ON FUNCTION public.reject_vendor_kyc(uuid, uuid, text)
  FROM authenticated;
REVOKE EXECUTE ON FUNCTION public.resolve_reported_post(uuid, text, boolean)
  FROM authenticated;
REVOKE EXECUTE ON FUNCTION public.resolve_shop_deletion(uuid, text, text)
  FROM authenticated;

-- Edge Function / trigger only (never called via user JWT from Flutter)
REVOKE EXECUTE ON FUNCTION public.confirm_order_inventory(uuid)
  FROM authenticated;
REVOKE EXECUTE ON FUNCTION public.refresh_product_rating_stats()
  FROM authenticated;

-- Trigger-driven counters — called by DB triggers, not via RPC
REVOKE EXECUTE ON FUNCTION public.dec_community_member_count()
  FROM authenticated;
REVOKE EXECUTE ON FUNCTION public.dec_community_post_count()
  FROM authenticated;
REVOKE EXECUTE ON FUNCTION public.inc_community_member_count()
  FROM authenticated;
REVOKE EXECUTE ON FUNCTION public.inc_community_post_count()
  FROM authenticated;

-- Internal helper called by vendor_update_order (SECURITY DEFINER), not directly
REVOKE EXECUTE ON FUNCTION public.vendor_upsert_shipment(
    uuid, text, text, text, text, timestamp with time zone)
  FROM authenticated;

-- ── 6. Hashtags: drop dead UPDATE policy (no code path uses it) ──────────────
DROP POLICY IF EXISTS "hashtags_auth_update" ON public.hashtags;

-- ── 7. post_hashtags: restrict INSERT to own posts only ──────────────────────
DROP POLICY IF EXISTS "post_hashtags_auth_insert" ON public.post_hashtags;
CREATE POLICY "post_hashtags_auth_insert" ON public.post_hashtags
  FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.posts
      WHERE id = post_id AND author_id = auth.uid()
    )
  );

-- ── 8. Hashtag post_count trigger ─────────────────────────────────────────────
-- Manages hashtags.post_count automatically when post_hashtags rows are
-- inserted or deleted. This replaces the now-dropped UPDATE policy.
CREATE OR REPLACE FUNCTION private.manage_hashtag_post_count()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    INSERT INTO public.hashtags (tag, post_count)
    VALUES (NEW.tag, 1)
    ON CONFLICT (tag)
    DO UPDATE SET post_count = public.hashtags.post_count + 1;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE public.hashtags
    SET post_count = GREATEST(0, post_count - 1)
    WHERE tag = OLD.tag;
    RETURN OLD;
  END IF;
  RETURN NULL;
END;
$$;

DROP TRIGGER IF EXISTS post_hashtags_manage_count ON public.post_hashtags;
CREATE TRIGGER post_hashtags_manage_count
  AFTER INSERT OR DELETE ON public.post_hashtags
  FOR EACH ROW EXECUTE FUNCTION private.manage_hashtag_post_count();
