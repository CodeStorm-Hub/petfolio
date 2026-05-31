-- ================================================================
-- 20260531000000_audit_fixes.sql
--
-- Addresses code-review findings:
--   C-1  chat_messages: ensure RLS + strict participant policies
--   C-2  matching_discovery_candidates: remove N+1 correlated subquery
--   H-2  matching_discovery_candidates: keyset cursor replaces OFFSET
--   H-3  swipes: protect LIKE→PASS downgrade; fire match trigger on UPDATE
--   M-5  matching_discovery_candidates: = ANY() replaces unnest/EXISTS
-- ================================================================


-- ----------------------------------------------------------------
-- C-1: chat_messages RLS
-- Ensures the table has RLS on and exactly the two policies
-- needed for safe participant-only access.
-- ----------------------------------------------------------------

ALTER TABLE public.chat_messages ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'chat_messages' AND policyname = 'chat_messages: select by participant'
  ) THEN
    EXECUTE $policy$
      CREATE POLICY "chat_messages: select by participant"
        ON public.chat_messages FOR SELECT TO authenticated
        USING (
          thread_id IN (
            SELECT id FROM public.chat_threads
            WHERE participant_1_id = (SELECT auth.uid())
               OR participant_2_id = (SELECT auth.uid())
          )
        )
    $policy$;
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'chat_messages' AND policyname = 'chat_messages: insert by participant'
  ) THEN
    EXECUTE $policy$
      CREATE POLICY "chat_messages: insert by participant"
        ON public.chat_messages FOR INSERT TO authenticated
        WITH CHECK (
          sender_id = (SELECT auth.uid())
          AND thread_id IN (
            SELECT id FROM public.chat_threads
            WHERE participant_1_id = (SELECT auth.uid())
               OR participant_2_id = (SELECT auth.uid())
          )
        )
    $policy$;
  END IF;
END $$;


-- ----------------------------------------------------------------
-- C-2 + H-2 + M-5:
--  * Replace correlated owner subquery with LEFT JOIN LATERAL
--  * Replace OFFSET with keyset cursor (created_at, id)
--  * Return created_at for cursor use by the client
--  * Replace unnest/EXISTS species filter with = ANY()
-- ----------------------------------------------------------------

-- Drop the previous 7-parameter overload so only the new signature exists.
DROP FUNCTION IF EXISTS public.matching_discovery_candidates(
  uuid, double precision, integer, integer, text[], integer, integer
);

CREATE OR REPLACE FUNCTION public.matching_discovery_candidates(
  p_actor_pet_id      UUID,
  p_radius_meters     DOUBLE PRECISION  DEFAULT 80467,
  p_limit             INTEGER           DEFAULT 20,
  p_cursor_created_at TIMESTAMPTZ       DEFAULT NULL,
  p_cursor_pet_id     UUID              DEFAULT NULL,
  p_species           TEXT[]            DEFAULT NULL,
  p_min_age_years     INTEGER           DEFAULT NULL,
  p_max_age_years     INTEGER           DEFAULT NULL
) RETURNS TABLE(
  id               UUID,
  owner_id         UUID,
  name             TEXT,
  species          TEXT,
  breed            TEXT,
  date_of_birth    DATE,
  avatar_url       TEXT,
  bio              TEXT,
  distance_meters  DOUBLE PRECISION,
  is_discoverable  BOOLEAN,
  created_at       TIMESTAMPTZ,
  owner            JSONB
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, extensions
AS $$
  WITH origin AS (
    SELECT p.location AS loc, p.owner_id
    FROM   public.pets p
    WHERE  p.id              = p_actor_pet_id
      AND  (SELECT auth.uid()) = p.owner_id
      AND  p.is_discoverable IS TRUE
  )
  SELECT
    c.id,
    c.owner_id,
    c.name,
    c.species,
    c.breed,
    c.date_of_birth,
    c.avatar_url,
    c.bio,
    ST_Distance(o.loc, c.location)::double precision AS distance_meters,
    c.is_discoverable,
    c.created_at,
    owner_sub.owner_json AS owner
  FROM   origin o
  CROSS  JOIN public.pets c
  LEFT   JOIN public.swipes s
    ON   s.actor_id  = p_actor_pet_id
   AND   s.target_id = c.id
  -- Single LATERAL join replaces the N+1 correlated subquery (C-2)
  LEFT   JOIN LATERAL (
    SELECT jsonb_build_object(
      'id',           u.id,
      'username',     u.username,
      'display_name', u.display_name
    ) AS owner_json
    FROM public.users u
    WHERE u.id = c.owner_id
    LIMIT 1
  ) owner_sub ON true
  WHERE  NOT (c.id = p_actor_pet_id)
    AND  c.owner_id       != o.owner_id
    AND  c.is_public       IS TRUE
    AND  c.is_discoverable IS TRUE
    AND  c.archived_at     IS NULL
    AND  c.location        IS NOT NULL
    AND  o.loc             IS NOT NULL
    AND  ST_DWithin(o.loc, c.location, p_radius_meters)
    AND  s.id IS NULL
    -- Keyset cursor: stable pagination, no skipped/duplicated rows (H-2)
    AND (
      p_cursor_created_at IS NULL
      OR c.created_at < p_cursor_created_at
      OR (c.created_at = p_cursor_created_at AND c.id < p_cursor_pet_id)
    )
    -- = ANY() replaces unnest/EXISTS (M-5)
    AND (
      p_species IS NULL
      OR cardinality(p_species) = 0
      OR lower(trim(c.species)) = ANY(
           SELECT lower(trim(s2)) FROM unnest(p_species) s2
         )
    )
    AND (
      c.date_of_birth IS NULL
      OR (
        (p_min_age_years IS NULL
          OR date_part('year', age(current_date, c.date_of_birth))::int >= p_min_age_years)
        AND (p_max_age_years IS NULL
          OR date_part('year', age(current_date, c.date_of_birth))::int <= p_max_age_years)
      )
    )
  ORDER  BY c.created_at DESC, c.id DESC
  LIMIT  greatest(coalesce(nullif(p_limit, 0), 20), 1);
$$;

REVOKE ALL     ON FUNCTION public.matching_discovery_candidates(uuid, double precision, integer, timestamptz, uuid, text[], integer, integer) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.matching_discovery_candidates(uuid, double precision, integer, timestamptz, uuid, text[], integer, integer) FROM anon;
GRANT  EXECUTE ON FUNCTION public.matching_discovery_candidates(uuid, double precision, integer, timestamptz, uuid, text[], integer, integer) TO authenticated;


-- ----------------------------------------------------------------
-- H-3a: Prevent LIKE → PASS downgrade when a mutual match exists.
-- A BEFORE UPDATE trigger raises an exception so the upsert
-- path cannot silently invalidate an existing match record.
-- ----------------------------------------------------------------

CREATE OR REPLACE FUNCTION private.swipes_before_update_downgrade_check()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NEW.action = 'PASS'
    AND OLD.action IN ('LIKE', 'GREET', 'SUPER_PAW')
  THEN
    IF EXISTS (
      SELECT 1 FROM public.matches
      WHERE pet_a_id = LEAST(OLD.actor_id, OLD.target_id)
        AND pet_b_id = GREATEST(OLD.actor_id, OLD.target_id)
    ) THEN
      RAISE EXCEPTION 'cannot_downgrade_matched_swipe'
        USING HINT = 'A mutual match already exists for this pair';
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

REVOKE ALL ON FUNCTION private.swipes_before_update_downgrade_check() FROM PUBLIC;

DROP TRIGGER IF EXISTS swipes_before_update_downgrade_check ON public.swipes;
CREATE TRIGGER swipes_before_update_downgrade_check
  BEFORE UPDATE OF action ON public.swipes
  FOR EACH ROW
  EXECUTE FUNCTION private.swipes_before_update_downgrade_check();


-- ----------------------------------------------------------------
-- H-3b: Fire the mutual-match check on UPDATE when a swipe is
-- upgraded from PASS → LIKE/GREET/SUPER_PAW.
-- The existing AFTER INSERT trigger only fires on INSERT; this
-- companion AFTER UPDATE trigger covers the upsert UPDATE path.
-- ----------------------------------------------------------------

DROP TRIGGER IF EXISTS swipes_after_update_mutual_match ON public.swipes;
CREATE TRIGGER swipes_after_update_mutual_match
  AFTER UPDATE OF action ON public.swipes
  FOR EACH ROW
  WHEN (
    OLD.action NOT IN ('LIKE', 'GREET', 'SUPER_PAW')
    AND NEW.action IN ('LIKE', 'GREET', 'SUPER_PAW')
  )
  EXECUTE FUNCTION private.swipes_after_insert_mutual_match();
