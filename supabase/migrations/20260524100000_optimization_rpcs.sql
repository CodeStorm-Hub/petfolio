-- ================================================================
-- 20260524100000_optimization_rpcs.sql
--
-- Two new RPCs that collapse multiple parallel client round-trips
-- into single server-side queries:
--
--   get_pet_stats            – replaces 3 parallel COUNT queries
--   get_care_dashboard_snapshot – replaces 4 concurrent fetches
--                                 (tasks, today-tasks, badges, week-goals)
-- ================================================================


-- ----------------------------------------------------------------
-- get_pet_stats
-- Replaces three Future.wait COUNT queries in fetchPetStats().
-- Returns one row with post_count, follower_count, following_count.
-- ----------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_pet_stats(p_pet_id uuid)
RETURNS TABLE(
  post_count      bigint,
  follower_count  bigint,
  following_count bigint
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    (SELECT COUNT(*) FROM public.posts       WHERE pet_id           = p_pet_id)::bigint AS post_count,
    (SELECT COUNT(*) FROM public.pet_follows WHERE following_pet_id = p_pet_id)::bigint AS follower_count,
    (SELECT COUNT(*) FROM public.pet_follows WHERE follower_pet_id  = p_pet_id)::bigint AS following_count;
$$;

REVOKE ALL    ON FUNCTION public.get_pet_stats(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_pet_stats(uuid) TO authenticated;


-- ----------------------------------------------------------------
-- get_care_dashboard_snapshot
-- Replaces four concurrent DB fetches on the care dashboard.
--
-- Returns a single JSONB object:
--   tasks          – all care_task rows for the pet (snake_case keys)
--   logs_selected  – care_log rows for p_selected_date
--   logs_today     – care_log rows for CURRENT_DATE
--                    (empty array when CURRENT_DATE = p_selected_date)
--   logs_week      – care_log rows between p_week_start and p_week_end
--   badge_types    – array of badge_type strings for the pet
--
-- The Flutter client applies its existing merging / scheduling logic
-- against this raw data, preserving all client-side business rules
-- while cutting the round-trip count from 4 → 1.
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
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_tasks          jsonb;
  v_logs_selected  jsonb;
  v_logs_today     jsonb;
  v_logs_week      jsonb;
  v_badge_types    jsonb;
BEGIN
  -- All care task definitions for this pet
  SELECT jsonb_agg(to_jsonb(ct) ORDER BY ct.created_at)
  INTO   v_tasks
  FROM   public.care_tasks ct
  WHERE  ct.pet_id = p_pet_id;

  -- Care logs for the selected date
  SELECT jsonb_agg(to_jsonb(cl))
  INTO   v_logs_selected
  FROM   public.care_logs cl
  WHERE  cl.pet_id      = p_pet_id
    AND  cl.logged_date = p_selected_date;

  -- Care logs for today — only fetched when it differs from selected date
  IF CURRENT_DATE != p_selected_date THEN
    SELECT jsonb_agg(to_jsonb(cl))
    INTO   v_logs_today
    FROM   public.care_logs cl
    WHERE  cl.pet_id      = p_pet_id
      AND  cl.logged_date = CURRENT_DATE;
  ELSE
    v_logs_today := '[]'::jsonb;
  END IF;

  -- Care logs for the week window (for the goal-hit strip)
  SELECT jsonb_agg(to_jsonb(cl))
  INTO   v_logs_week
  FROM   public.care_logs cl
  WHERE  cl.pet_id      = p_pet_id
    AND  cl.logged_date >= p_week_start
    AND  cl.logged_date <= p_week_end;

  -- Badge types earned by this pet
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

REVOKE ALL    ON FUNCTION public.get_care_dashboard_snapshot(uuid, date, date, date) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_care_dashboard_snapshot(uuid, date, date, date) TO authenticated;
