-- ─────────────────────────────────────────────────────────────────────────────
-- Fix + enhance check_daily_completion
--
-- BUG FIX (critical):
--   ON CONFLICT DO UPDATE referenced the existing row as
--   `public.care_streaks.best_streak`.  PostgreSQL forbids schema-qualified
--   table names in that clause; only the alias declared in the INSERT
--   statement (`INSERT INTO … AS cs`) is valid.  Changed to `cs.best_streak`.
--
-- ENHANCEMENTS (Apple Fitness / Duolingo-inspired):
--   • Per-day completion points (sum of task gamification_points + streak bonus)
--     awarded once per day, idempotent on replay.
--   • Extended badge ladder:
--       first_log       – first ever care log
--       3_day_streak    – 3-day consecutive completion
--       7_day_hero      – 7-day consecutive completion (existing)
--       routine_master  – 14-day consecutive completion
--       30_day_legend   – 30-day consecutive completion
--       care_champion   – 100 total care logs
-- ─────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.check_daily_completion(
  target_pet_id   uuid,
  completion_date date DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid             uuid     := auth.uid();
  v_today           date     := COALESCE(completion_date,
                                         (CURRENT_TIMESTAMP AT TIME ZONE 'UTC')::date);
  v_types           text[];
  v_total           int;
  v_completed       int;
  v_all_done        boolean;
  v_row             care_streaks%ROWTYPE;
  v_new_streak      int;
  v_last            date;
  v_badge_unlocked  boolean  := false;
  v_badge_rows      int;
  v_unlocked_badges text[]   := ARRAY[]::text[];
  v_total_logs      bigint;
  v_task_pts        int;
  v_bonus_pts       int;
BEGIN
  -- ── Auth & ownership ────────────────────────────────────────────────────
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'not authenticated';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pets p
    WHERE p.id = target_pet_id AND p.owner_id = v_uid
  ) THEN
    RAISE EXCEPTION 'pet not found or access denied';
  END IF;

  -- ── Resolve expected daily task types ───────────────────────────────────
  SELECT COALESCE(
    ARRAY_AGG(DISTINCT ct.task_type)
      FILTER (WHERE ct.frequency = ANY(ARRAY['daily','twice_daily'])),
    ARRAY[]::text[]
  )
  INTO v_types
  FROM care_tasks ct
  WHERE ct.pet_id = target_pet_id;

  IF v_types IS NULL OR COALESCE(array_length(v_types, 1), 0) = 0 THEN
    v_types := ARRAY['feeding','walk','medication'];
  END IF;
  v_total := array_length(v_types, 1);

  -- ── Count completed tasks today ─────────────────────────────────────────
  SELECT COUNT(DISTINCT cl.care_type)::int INTO v_completed
  FROM care_logs cl
  WHERE cl.pet_id      = target_pet_id
    AND cl.logged_date = v_today
    AND cl.care_type   = ANY(v_types);

  v_all_done := (v_completed = v_total);

  -- ── first_log badge (award on any completion, not only full day) ────────
  SELECT COUNT(*) INTO v_total_logs FROM care_logs WHERE pet_id = target_pet_id;

  IF v_total_logs >= 1 THEN
    INSERT INTO pet_badges (pet_id, badge_type)
    VALUES (target_pet_id, 'first_log')
    ON CONFLICT (pet_id, badge_type) DO NOTHING;

    GET DIAGNOSTICS v_badge_rows = ROW_COUNT;
    IF v_badge_rows > 0 THEN
      v_unlocked_badges := array_append(v_unlocked_badges, 'first_log');
      v_badge_unlocked  := true;
    END IF;
  END IF;

  -- ── Early return when day is not fully complete ─────────────────────────
  IF NOT v_all_done THEN
    RETURN jsonb_build_object(
      'total',                v_total,
      'completed',            v_completed,
      'all_done',             false,
      'current_streak',       COALESCE(
                                (SELECT cs.current_streak FROM care_streaks cs WHERE cs.pet_id = target_pet_id),
                                0),
      'best_streak',          COALESCE(
                                (SELECT cs.best_streak FROM care_streaks cs WHERE cs.pet_id = target_pet_id),
                                0),
      'last_completion_date', (SELECT to_jsonb(cs.last_completion_date) FROM care_streaks cs WHERE cs.pet_id = target_pet_id),
      'badge_unlocked',       v_badge_unlocked,
      'unlocked_badges',      v_unlocked_badges
    );
  END IF;

  -- ── Compute new streak ──────────────────────────────────────────────────
  SELECT * INTO v_row FROM care_streaks cs WHERE cs.pet_id = target_pet_id;
  v_last := v_row.last_completion_date;

  IF    v_last IS NULL        THEN v_new_streak := 1;
  ELSIF v_last = v_today      THEN v_new_streak := v_row.current_streak;    -- idempotent replay
  ELSIF v_last = v_today - 1  THEN v_new_streak := v_row.current_streak + 1;
  ELSE                             v_new_streak := 1;                        -- streak broken
  END IF;

  -- ── Upsert streak row ────────────────────────────────────────────────────
  -- FIX: reference the existing row by its declared alias `cs`,
  --      NOT by the schema-qualified name `public.care_streaks`.
  INSERT INTO care_streaks AS cs (pet_id, current_streak, last_completion_date, best_streak)
  VALUES (target_pet_id, v_new_streak, v_today, v_new_streak)
  ON CONFLICT (pet_id) DO UPDATE
    SET current_streak       = EXCLUDED.current_streak,
        last_completion_date = EXCLUDED.last_completion_date,
        best_streak          = GREATEST(cs.best_streak, EXCLUDED.current_streak);

  -- ── Award daily points (idempotent — once per calendar day) ────────────
  IF NOT EXISTS (
    SELECT 1 FROM pet_care_gamification pcg
    WHERE pcg.pet_id = target_pet_id
      AND pcg.daily_point_award_date = v_today
  ) THEN
    -- Sum gamification_points for all daily tasks
    SELECT COALESCE(SUM(ct.gamification_points), 30) INTO v_task_pts
    FROM care_tasks ct
    WHERE ct.pet_id   = target_pet_id
      AND ct.frequency = ANY(ARRAY['daily','twice_daily']);

    -- Streak bonus: +5 per streak day, capped at 50
    v_bonus_pts := LEAST(v_new_streak * 5, 50);

    INSERT INTO pet_care_gamification AS pcg
      (pet_id, total_points, daily_point_award_date, daily_point_award_accrued)
    VALUES
      (target_pet_id, v_task_pts + v_bonus_pts, v_today, v_task_pts + v_bonus_pts)
    ON CONFLICT (pet_id) DO UPDATE
      SET total_points              = pcg.total_points + v_task_pts + v_bonus_pts,
          daily_point_award_date    = v_today,
          daily_point_award_accrued = v_task_pts + v_bonus_pts,
          updated_at                = now();
  END IF;

  -- ── Badge ladder ─────────────────────────────────────────────────────────

  IF v_new_streak >= 3 THEN
    INSERT INTO pet_badges (pet_id, badge_type)
    VALUES (target_pet_id, '3_day_streak')
    ON CONFLICT (pet_id, badge_type) DO NOTHING;
    GET DIAGNOSTICS v_badge_rows = ROW_COUNT;
    IF v_badge_rows > 0 THEN
      v_unlocked_badges := array_append(v_unlocked_badges, '3_day_streak');
      v_badge_unlocked  := true;
    END IF;
  END IF;

  IF v_new_streak >= 7 THEN
    INSERT INTO pet_badges (pet_id, badge_type)
    VALUES (target_pet_id, '7_day_hero')
    ON CONFLICT (pet_id, badge_type) DO NOTHING;
    GET DIAGNOSTICS v_badge_rows = ROW_COUNT;
    IF v_badge_rows > 0 THEN
      v_unlocked_badges := array_append(v_unlocked_badges, '7_day_hero');
      v_badge_unlocked  := true;
    END IF;
  END IF;

  IF v_new_streak >= 14 THEN
    INSERT INTO pet_badges (pet_id, badge_type)
    VALUES (target_pet_id, 'routine_master')
    ON CONFLICT (pet_id, badge_type) DO NOTHING;
    GET DIAGNOSTICS v_badge_rows = ROW_COUNT;
    IF v_badge_rows > 0 THEN
      v_unlocked_badges := array_append(v_unlocked_badges, 'routine_master');
      v_badge_unlocked  := true;
    END IF;
  END IF;

  IF v_new_streak >= 30 THEN
    INSERT INTO pet_badges (pet_id, badge_type)
    VALUES (target_pet_id, '30_day_legend')
    ON CONFLICT (pet_id, badge_type) DO NOTHING;
    GET DIAGNOSTICS v_badge_rows = ROW_COUNT;
    IF v_badge_rows > 0 THEN
      v_unlocked_badges := array_append(v_unlocked_badges, '30_day_legend');
      v_badge_unlocked  := true;
    END IF;
  END IF;

  IF v_total_logs >= 100 THEN
    INSERT INTO pet_badges (pet_id, badge_type)
    VALUES (target_pet_id, 'care_champion')
    ON CONFLICT (pet_id, badge_type) DO NOTHING;
    GET DIAGNOSTICS v_badge_rows = ROW_COUNT;
    IF v_badge_rows > 0 THEN
      v_unlocked_badges := array_append(v_unlocked_badges, 'care_champion');
      v_badge_unlocked  := true;
    END IF;
  END IF;

  RETURN jsonb_build_object(
    'total',                v_total,
    'completed',            v_completed,
    'all_done',             true,
    'current_streak',       v_new_streak,
    'best_streak',          (SELECT cs.best_streak FROM care_streaks cs WHERE cs.pet_id = target_pet_id),
    'last_completion_date', to_jsonb(v_today),
    'badge_unlocked',       v_badge_unlocked,
    'unlocked_badges',      v_unlocked_badges
  );
END;
$$;

REVOKE ALL ON FUNCTION public.check_daily_completion(uuid, date) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.check_daily_completion(uuid, date) TO authenticated;

-- Ensure gamification row exists for every pet that already has streaks
INSERT INTO public.pet_care_gamification (pet_id)
SELECT pet_id FROM public.care_streaks
ON CONFLICT (pet_id) DO NOTHING;
