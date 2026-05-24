-- ================================================================
-- 20260525200000_pr10_security_fixes.sql
--
-- Addresses security findings from PR #10 review:
--
--   1. get_pet_stats            – SECURITY DEFINER → INVOKER so RLS on
--                                 posts/pet_follows is respected; explicit
--                                 REVOKE from anon.
--
--   2. get_care_dashboard_snapshot – same treatment; care data (tasks,
--                                 logs, badges) now filtered by the
--                                 caller's own RLS policies.
--
--   3. matching_discovery_candidates – was missing SET search_path
--                                 (object-shadowing risk); add it.
--                                 Also add explicit REVOKE from anon.
-- ================================================================


-- ----------------------------------------------------------------
-- 1. get_pet_stats  (SECURITY INVOKER)
-- ----------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_pet_stats(p_pet_id uuid)
RETURNS TABLE(
  post_count      bigint,
  follower_count  bigint,
  following_count bigint
)
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = public
AS $$
  SELECT
    (SELECT COUNT(*) FROM public.posts
      WHERE pet_id = p_pet_id)::bigint,
    (SELECT COUNT(*) FROM public.pet_follows
      WHERE following_pet_id = p_pet_id)::bigint,
    (SELECT COUNT(*) FROM public.pet_follows
      WHERE follower_pet_id = p_pet_id)::bigint;
$$;

REVOKE ALL     ON FUNCTION public.get_pet_stats(uuid) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.get_pet_stats(uuid) FROM anon;
GRANT  EXECUTE ON FUNCTION public.get_pet_stats(uuid) TO authenticated;


-- ----------------------------------------------------------------
-- 2. get_care_dashboard_snapshot  (SECURITY INVOKER)
-- ----------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_care_dashboard_snapshot(
  p_pet_id        uuid,
  p_selected_date date,
  p_week_start    date,
  p_week_end      date
)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY INVOKER
SET search_path = public
AS $$
DECLARE
  v_tasks          jsonb;
  v_logs_selected  jsonb;
  v_logs_today     jsonb;
  v_logs_week      jsonb;
  v_badge_types    jsonb;
BEGIN
  SELECT jsonb_agg(to_jsonb(ct) ORDER BY ct.created_at)
  INTO   v_tasks
  FROM   public.care_tasks ct
  WHERE  ct.pet_id = p_pet_id;

  SELECT jsonb_agg(to_jsonb(cl))
  INTO   v_logs_selected
  FROM   public.care_logs cl
  WHERE  cl.pet_id      = p_pet_id
    AND  cl.logged_date = p_selected_date;

  IF CURRENT_DATE != p_selected_date THEN
    SELECT jsonb_agg(to_jsonb(cl))
    INTO   v_logs_today
    FROM   public.care_logs cl
    WHERE  cl.pet_id      = p_pet_id
      AND  cl.logged_date = CURRENT_DATE;
  ELSE
    v_logs_today := '[]'::jsonb;
  END IF;

  SELECT jsonb_agg(to_jsonb(cl))
  INTO   v_logs_week
  FROM   public.care_logs cl
  WHERE  cl.pet_id      = p_pet_id
    AND  cl.logged_date >= p_week_start
    AND  cl.logged_date <= p_week_end;

  SELECT jsonb_agg(pb.badge_type)
  INTO   v_badge_types
  FROM   public.pet_badges pb
  WHERE  pb.pet_id = p_pet_id;

  RETURN jsonb_build_object(
    'tasks',         COALESCE(v_tasks,         '[]'::jsonb),
    'logs_selected', COALESCE(v_logs_selected, '[]'::jsonb),
    'logs_today',    COALESCE(v_logs_today,    '[]'::jsonb),
    'logs_week',     COALESCE(v_logs_week,     '[]'::jsonb),
    'badge_types',   COALESCE(v_badge_types,   '[]'::jsonb)
  );
END;
$$;

REVOKE ALL     ON FUNCTION public.get_care_dashboard_snapshot(uuid, date, date, date) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.get_care_dashboard_snapshot(uuid, date, date, date) FROM anon;
GRANT  EXECUTE ON FUNCTION public.get_care_dashboard_snapshot(uuid, date, date, date) TO authenticated;


-- ----------------------------------------------------------------
-- 3. matching_discovery_candidates
--    Add SET search_path and explicit REVOKE from anon.
--    Kept SECURITY DEFINER because the function must cross RLS
--    boundaries to join swipes/users; the actor-ownership guard
--    (auth.uid() = p.owner_id in the CTE) already enforces authz.
-- ----------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.matching_discovery_candidates(
  p_actor_pet_id  UUID,
  p_radius_meters DOUBLE PRECISION DEFAULT 80467,
  p_limit         INTEGER          DEFAULT 20,
  p_offset        INTEGER          DEFAULT 0,
  p_species       TEXT[]           DEFAULT NULL,
  p_min_age_years INTEGER          DEFAULT NULL,
  p_max_age_years INTEGER          DEFAULT NULL
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
  owner            JSONB
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, extensions   -- extensions required for PostGIS (ST_Distance, ST_DWithin)
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
    (
      SELECT jsonb_build_object(
        'id',           u.id,
        'username',     u.username,
        'display_name', u.display_name
      )
      FROM public.users u
      WHERE u.id = c.owner_id
    ) AS owner
  FROM   origin o
  CROSS  JOIN public.pets c
  LEFT   JOIN public.swipes s
    ON   s.actor_id  = p_actor_pet_id
   AND   s.target_id = c.id
  WHERE  NOT (c.id = p_actor_pet_id)
    AND  c.owner_id       != o.owner_id
    AND  c.is_public       IS TRUE
    AND  c.is_discoverable IS TRUE
    AND  c.archived_at     IS NULL
    AND  c.location        IS NOT NULL
    AND  o.loc             IS NOT NULL
    AND  ST_DWithin(o.loc, c.location, p_radius_meters)
    AND  s.id IS NULL
    AND (
      p_species IS NULL
      OR cardinality(p_species) = 0
      OR EXISTS (
        SELECT 1
        FROM   unnest(p_species) AS u(species_text)
        WHERE  lower(trim(species_text)) = lower(trim(c.species))
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
  ORDER  BY c.created_at DESC
  OFFSET greatest(coalesce(p_offset, 0), 0)
  LIMIT  greatest(coalesce(nullif(p_limit, 0), 20), 1);
$$;

REVOKE ALL     ON FUNCTION public.matching_discovery_candidates(uuid, double precision, integer, integer, text[], integer, integer) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.matching_discovery_candidates(uuid, double precision, integer, integer, text[], integer, integer) FROM anon;
GRANT  EXECUTE ON FUNCTION public.matching_discovery_candidates(uuid, double precision, integer, integer, text[], integer, integer) TO authenticated;
