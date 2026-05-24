-- ================================================================
-- 20260524000000_performance_security_fixes.sql
--
-- Addresses four categories of security/performance findings:
--   1. Wrap bare auth.uid() in (SELECT auth.uid()) across all RLS
--      policies (public schema + storage.objects) to allow Postgres
--      to cache execution plans.
--   2. REVOKE ALL ... FROM PUBLIC and GRANT EXECUTE ... TO authenticated
--      on every SECURITY DEFINER function so implicit public access
--      is removed.
--   3. Replace bucket-level SELECT policies on marketplace-images and
--      post-images with path-scoped policies that prevent full-bucket
--      enumeration via the storage API. Drop legacy duplicate policies.
--   4. Add an explicit RESTRICTIVE deny-all policy on
--      inventory_reservations (RLS enabled, zero policies).
-- ================================================================


-- ----------------------------------------------------------------
-- SECTION 1: Replace bare auth.uid() with (SELECT auth.uid()) in
--             RLS policies to enable Postgres plan-cache reuse
-- ----------------------------------------------------------------

-- ── chat_threads ─────────────────────────────────────────────────
-- SELECT policy
ALTER POLICY "Users can read their own chat threads"
  ON public.chat_threads
  USING (
    ((SELECT auth.uid()) = participant_1_id)
    OR ((SELECT auth.uid()) = participant_2_id)
  );

-- INSERT policy (only WITH CHECK applies for INSERT)
ALTER POLICY "Users can insert their own chat threads"
  ON public.chat_threads
  WITH CHECK (
    ((SELECT auth.uid()) = participant_1_id)
    OR ((SELECT auth.uid()) = participant_2_id)
  );

-- ── comments ─────────────────────────────────────────────────────
ALTER POLICY "comments_delete_policy"
  ON public.comments
  USING (author_id = (SELECT auth.uid()));

ALTER POLICY "comments_insert_policy"
  ON public.comments
  WITH CHECK (author_id = (SELECT auth.uid()));

-- ── follows ──────────────────────────────────────────────────────
ALTER POLICY "Users can follow"
  ON public.follows
  WITH CHECK (follower_id = (SELECT auth.uid()));

ALTER POLICY "Users can unfollow"
  ON public.follows
  USING (follower_id = (SELECT auth.uid()));

-- ── notifications ────────────────────────────────────────────────
ALTER POLICY "notifications_select_policy"
  ON public.notifications
  USING (
    (recipient_pet_id IN (
      SELECT pets.id FROM public.pets
      WHERE pets.owner_id = (SELECT auth.uid())
    ))
    OR (recipient_user_id = (SELECT auth.uid()))
  );

-- UPDATE policy has only a USING clause (no WITH CHECK in source)
ALTER POLICY "notifications_update_policy"
  ON public.notifications
  USING (
    (recipient_pet_id IN (
      SELECT pets.id FROM public.pets
      WHERE pets.owner_id = (SELECT auth.uid())
    ))
    OR (recipient_user_id = (SELECT auth.uid()))
  );

-- ── pet_follows ──────────────────────────────────────────────────
-- Legacy "public" INSERT/DELETE pair
ALTER POLICY "Pets can follow"
  ON public.pet_follows
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.pets
      WHERE pets.id = pet_follows.follower_pet_id
        AND pets.owner_id = (SELECT auth.uid())
    )
  );

ALTER POLICY "Pets can unfollow"
  ON public.pet_follows
  USING (
    EXISTS (
      SELECT 1 FROM public.pets
      WHERE pets.id = pet_follows.follower_pet_id
        AND pets.owner_id = (SELECT auth.uid())
    )
  );

-- Authenticated INSERT/DELETE pair
ALTER POLICY "pet_follows_insert_policy"
  ON public.pet_follows
  WITH CHECK (
    follower_pet_id IN (
      SELECT pets.id FROM public.pets
      WHERE pets.owner_id = (SELECT auth.uid())
    )
  );

ALTER POLICY "pet_follows_delete_policy"
  ON public.pet_follows
  USING (
    follower_pet_id IN (
      SELECT pets.id FROM public.pets
      WHERE pets.owner_id = (SELECT auth.uid())
    )
  );

-- ── reported_posts ───────────────────────────────────────────────
ALTER POLICY "authenticated users can report posts"
  ON public.reported_posts
  WITH CHECK (reporter_id = (SELECT auth.uid()));

ALTER POLICY "reporters can view own reports"
  ON public.reported_posts
  USING (reporter_id = (SELECT auth.uid()));

-- ── vendor_ledgers ───────────────────────────────────────────────
ALTER POLICY "shop_owner_select_ledger"
  ON public.vendor_ledgers
  USING (
    EXISTS (
      SELECT 1 FROM public.shops
      WHERE shops.id  = vendor_ledgers.shop_id
        AND shops.owner_id = (SELECT auth.uid())
    )
  );

-- ── storage.objects: kyc-documents ───────────────────────────────
ALTER POLICY "kyc_owner_read"
  ON storage.objects
  USING (
    (bucket_id = 'kyc-documents')
    AND ((SELECT auth.uid())::text = (storage.foldername(name))[1])
  );

-- UPDATE — has both USING and WITH CHECK
ALTER POLICY "kyc_owner_update"
  ON storage.objects
  USING (
    (bucket_id = 'kyc-documents')
    AND ((SELECT auth.uid())::text = (storage.foldername(name))[1])
  )
  WITH CHECK (
    (bucket_id = 'kyc-documents')
    AND ((SELECT auth.uid())::text = (storage.foldername(name))[1])
  );

-- INSERT — only WITH CHECK
ALTER POLICY "kyc_owner_upload"
  ON storage.objects
  WITH CHECK (
    (bucket_id = 'kyc-documents')
    AND ((SELECT auth.uid())::text = (storage.foldername(name))[1])
  );

-- ── storage.objects: shops ───────────────────────────────────────
-- UPDATE — only USING
ALTER POLICY "Shop owners can replace shop assets"
  ON storage.objects
  USING (
    (bucket_id = 'shops')
    AND (EXISTS (
      SELECT 1 FROM public.shops s
      WHERE s.owner_id = (SELECT auth.uid())
        AND objects.name LIKE (s.id::text || '/%')
    ))
  );

-- INSERT — only WITH CHECK
ALTER POLICY "Shop owners can upload shop assets"
  ON storage.objects
  WITH CHECK (
    (bucket_id = 'shops')
    AND (EXISTS (
      SELECT 1 FROM public.shops s
      WHERE s.owner_id = (SELECT auth.uid())
        AND objects.name LIKE (s.id::text || '/%')
    ))
  );


-- ----------------------------------------------------------------
-- SECTION 2: Lock down SECURITY DEFINER functions
--             REVOKE ALL ... FROM PUBLIC
--             GRANT EXECUTE ... TO authenticated  (where applicable)
-- ----------------------------------------------------------------

-- Trigger functions — invoked by DB triggers, never directly by a
-- user session. Revoke public access only; no user grant needed.
REVOKE ALL ON FUNCTION public.handle_new_chat_message() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.handle_post_comment_sync() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.handle_post_like_sync() FROM PUBLIC;

-- Internal management function — called by superuser / migrations only.
REVOKE ALL ON FUNCTION public.rls_auto_enable() FROM PUBLIC;

-- ── RPCs callable by authenticated clients ───────────────────────
REVOKE ALL ON FUNCTION public.approve_vendor_kyc(uuid, uuid) FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION public.approve_vendor_kyc(uuid, uuid) TO authenticated;

REVOKE ALL ON FUNCTION public.cancel_order(uuid) FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION public.cancel_order(uuid) TO authenticated;

REVOKE ALL ON FUNCTION public.check_daily_completion(uuid, date) FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION public.check_daily_completion(uuid, date) TO authenticated;

REVOKE ALL ON FUNCTION public.confirm_order_inventory(uuid) FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION public.confirm_order_inventory(uuid) TO authenticated;

REVOKE ALL ON FUNCTION public.ensure_chat_thread_for_match(uuid, uuid) FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION public.ensure_chat_thread_for_match(uuid, uuid) TO authenticated;

REVOKE ALL ON FUNCTION public.get_or_create_social_thread(uuid) FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION public.get_or_create_social_thread(uuid) TO authenticated;

REVOKE ALL ON FUNCTION public.process_checkout(uuid, uuid, jsonb) FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION public.process_checkout(uuid, uuid, jsonb) TO authenticated;

REVOKE ALL ON FUNCTION public.reject_vendor_kyc(uuid, uuid, text) FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION public.reject_vendor_kyc(uuid, uuid, text) TO authenticated;

REVOKE ALL ON FUNCTION public.release_order_inventory(uuid) FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION public.release_order_inventory(uuid) TO authenticated;

REVOKE ALL ON FUNCTION public.request_shop_deletion(uuid, text) FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION public.request_shop_deletion(uuid, text) TO authenticated;

REVOKE ALL ON FUNCTION public.resolve_reported_post(uuid, text, boolean) FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION public.resolve_reported_post(uuid, text, boolean) TO authenticated;

REVOKE ALL ON FUNCTION public.resolve_shop_deletion(uuid, text, text) FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION public.resolve_shop_deletion(uuid, text, text) TO authenticated;

REVOKE ALL ON FUNCTION public.vendor_update_order(uuid, text, text, text, text) FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION public.vendor_update_order(uuid, text, text, text, text) TO authenticated;


-- ----------------------------------------------------------------
-- SECTION 3: Path-level storage SELECT policies for
--             marketplace-images and post-images buckets
--
-- Both buckets remain public=true so existing direct CDN/signed
-- URLs continue to work. The policies below only govern the
-- storage JS/REST API (list, download-by-API), not direct URLs.
-- Restricting SELECT to path-prefix prevents any authenticated
-- user from listing the entire bucket via the API.
-- ----------------------------------------------------------------

-- ── marketplace-images ───────────────────────────────────────────
-- Drop the bucket-wide public SELECT
DROP POLICY IF EXISTS "marketplace-images: public read" ON storage.objects;

-- Path-scoped SELECT: only the uploader (first path segment = uid)
-- can list their own objects via the storage API.
CREATE POLICY "marketplace-images: path read"
  ON storage.objects
  FOR SELECT
  TO authenticated
  USING (
    bucket_id = 'marketplace-images'
    AND (SELECT auth.uid())::text = (string_to_array(name, '/'))[1]
  );

-- ── post-images ──────────────────────────────────────────────────
-- Drop broad bucket-wide SELECT policies (both the legacy one and
-- the newer duplicate introduced in 20260523110000).
DROP POLICY IF EXISTS "Public Post Images Access"    ON storage.objects;
DROP POLICY IF EXISTS "post-images: public read"     ON storage.objects;

-- Drop legacy broad INSERT/UPDATE policies that were superseded by
-- the path-enforced "post-images: authenticated upload" and
-- "post-images: owner update" policies added in later migrations.
DROP POLICY IF EXISTS "Authenticated Post Images Upload" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated Post Images Update" ON storage.objects;

-- Path-scoped SELECT: owner can list their own uploads via the API.
CREATE POLICY "post-images: path read"
  ON storage.objects
  FOR SELECT
  TO authenticated
  USING (
    bucket_id = 'post-images'
    AND (SELECT auth.uid())::text = (string_to_array(name, '/'))[1]
  );


-- ----------------------------------------------------------------
-- SECTION 4: Explicit deny-all RESTRICTIVE policy on
--             inventory_reservations
--
-- The table was created with RLS enabled but zero policies, which
-- already implicitly denies all access. This RESTRICTIVE policy
-- makes that intent permanent and explicit: even if a PERMISSIVE
-- policy is accidentally added in a future migration it cannot
-- open access because RESTRICTIVE policies are AND-ed in.
--
-- The SECURITY DEFINER functions (process_checkout,
-- confirm_order_inventory, release_order_inventory) run as the
-- postgres role, which bypasses RLS entirely, so they are
-- unaffected by this policy.
-- ----------------------------------------------------------------

CREATE POLICY "inventory_reservations: deny all direct access"
  ON public.inventory_reservations
  AS RESTRICTIVE
  FOR ALL
  TO authenticated, anon
  USING (false)
  WITH CHECK (false);
