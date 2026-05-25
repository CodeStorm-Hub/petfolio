-- ================================================================
-- 20260525210000_add_pet_stories.sql
--
-- Implements the stories table, RLS policies, RPC for tracking views,
-- and automated cleanup for expired stories.
-- ================================================================

-- ── 1. Create stories table ──────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.stories (
  id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  pet_id          UUID        NOT NULL REFERENCES public.pets(id) ON DELETE CASCADE,
  image_url       TEXT        NOT NULL,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  viewed_by_users UUID[]      NOT NULL DEFAULT '{}'::UUID[]
);

COMMENT ON TABLE public.stories IS 'Instagram-like active stories for pets (24-hour lifetime).';

-- ── 2. Create indexes ────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_stories_pet_id ON public.stories(pet_id);
CREATE INDEX IF NOT EXISTS idx_stories_created_at ON public.stories(created_at);

-- ── 3. Enable RLS ────────────────────────────────────────────────
ALTER TABLE public.stories ENABLE ROW LEVEL SECURITY;

-- ── 4. RLS Policies ──────────────────────────────────────────────

-- SELECT policy: Authenticated users can view active stories (<= 24 hours old)
-- from public pets OR pets they follow (via public.pet_follows).
CREATE POLICY "stories_select_policy"
  ON public.stories FOR SELECT TO authenticated
  USING (
    created_at >= now() - interval '24 hours'
    AND (
      EXISTS (
        SELECT 1 FROM public.pets p
        WHERE p.id = stories.pet_id
          AND (p.is_public = true OR p.owner_id = (SELECT auth.uid()))
      )
      OR EXISTS (
        SELECT 1 FROM public.pet_follows pf
        WHERE pf.following_pet_id = stories.pet_id
          AND pf.follower_pet_id IN (
            SELECT p.id FROM public.pets p
            WHERE p.owner_id = (SELECT auth.uid())
          )
      )
    )
  );

-- INSERT policy: Authenticated users can insert stories for pets they own.
CREATE POLICY "stories_insert_policy"
  ON public.stories FOR INSERT TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.pets p
      WHERE p.id = pet_id
        AND p.owner_id = (SELECT auth.uid())
    )
  );

-- DELETE policy: Authenticated users can delete stories for pets they own.
CREATE POLICY "stories_delete_policy"
  ON public.stories FOR DELETE TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.pets p
      WHERE p.id = pet_id
        AND p.owner_id = (SELECT auth.uid())
    )
  );

-- ── 5. RPC to mark story as viewed ──────────────────────────────
-- SECURITY DEFINER allows updating the viewed_by_users array
-- securely without giving users direct UPDATE grants on the table.
CREATE OR REPLACE FUNCTION public.mark_story_viewed(p_story_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Verify the caller has select access (view permission) to this story
  IF EXISTS (
    SELECT 1 FROM public.stories s
    WHERE s.id = p_story_id
      AND s.created_at >= now() - interval '24 hours'
      AND (
        EXISTS (
          SELECT 1 FROM public.pets p
          WHERE p.id = s.pet_id
            AND (p.is_public = true OR p.owner_id = (SELECT auth.uid()))
        )
        OR EXISTS (
          SELECT 1 FROM public.pet_follows pf
          WHERE pf.following_pet_id = s.pet_id
            AND pf.follower_pet_id IN (
              SELECT p.id FROM public.pets p
              WHERE p.owner_id = (SELECT auth.uid())
            )
        )
      )
  ) THEN
    UPDATE public.stories
    SET viewed_by_users = array_append(viewed_by_users, (SELECT auth.uid()))
    WHERE id = p_story_id
      AND NOT ((SELECT auth.uid()) = ANY(viewed_by_users));
  END IF;
END;
$$;

REVOKE ALL ON FUNCTION public.mark_story_viewed(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.mark_story_viewed(UUID) TO authenticated;

-- ── 6. Cleanup expired stories ───────────────────────────────────
CREATE OR REPLACE FUNCTION public.cleanup_expired_stories()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  DELETE FROM public.stories
  WHERE created_at < now() - interval '24 hours';
END;
$$;

-- To schedule with pg_cron (if available, run in dashboard or uncomment):
-- SELECT cron.schedule('cleanup-expired-stories', '0 * * * *', 'SELECT public.cleanup_expired_stories()');

-- ── 7. Grants ────────────────────────────────────────────────────
GRANT SELECT, INSERT, DELETE ON public.stories TO authenticated;
