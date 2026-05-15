DROP FUNCTION IF EXISTS public.check_daily_completion (uuid);

CREATE OR REPLACE FUNCTION public.check_daily_completion (
  target_pet_id uuid,
  completion_date date DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_uid            uuid := auth.uid ();
  v_today          date := COALESCE (
    completion_date,
    (CURRENT_TIMESTAMP AT TIME ZONE 'UTC')::date
  );
  v_types          text[];
  v_total          int;
  v_completed      int;
  v_all_done       boolean;
  v_row            public.care_streaks%ROWTYPE;
  v_new_streak     int;
  v_last           date;
  v_badge_unlocked boolean := false;
  v_badge_rows     int;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'not authenticated';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM public.pets p
    WHERE p.id = target_pet_id
      AND p.owner_id = v_uid
  ) THEN
    RAISE EXCEPTION 'pet not found or access denied';
  END IF;

  SELECT COALESCE(
    ARRAY_AGG(DISTINCT ct.task_type) FILTER (
      WHERE
        ct.frequency = ANY (ARRAY['daily'::text, 'twice_daily'::text])
    ),
    ARRAY[]::text[]
  )
  INTO v_types
  FROM public.care_tasks AS ct
  WHERE
    ct.pet_id = target_pet_id;

  IF v_types IS NULL OR COALESCE(array_length(v_types, 1), 0) = 0 THEN
    v_types := ARRAY['feeding', 'walk', 'medication']::text[];
  END IF;

  v_total := array_length(v_types, 1);

  SELECT COUNT(DISTINCT cl.care_type)::int INTO v_completed
  FROM
    public.care_logs AS cl
  WHERE
    cl.pet_id = target_pet_id
    AND cl.logged_date = v_today
    AND cl.care_type = ANY (v_types);

  v_all_done := v_completed = v_total;

  IF NOT v_all_done THEN
    RETURN jsonb_build_object(
      'total', v_total,
      'completed', v_completed,
      'all_done', false,
      'current_streak', COALESCE((
        SELECT cs.current_streak
        FROM public.care_streaks AS cs
        WHERE
          cs.pet_id = target_pet_id
      ), 0),
      'best_streak', COALESCE((
        SELECT cs.best_streak
        FROM public.care_streaks AS cs
        WHERE
          cs.pet_id = target_pet_id
      ), 0),
      'last_completion_date', (
        SELECT to_jsonb(cs.last_completion_date)
        FROM public.care_streaks AS cs
        WHERE
          cs.pet_id = target_pet_id
      ),
      'badge_unlocked', false
    );
  END IF;

  SELECT *
  INTO v_row
  FROM public.care_streaks AS cs
  WHERE
    cs.pet_id = target_pet_id;

  v_last := v_row.last_completion_date;

  IF v_last IS NULL THEN
    v_new_streak := 1;
  ELSIF v_last = v_today THEN
    v_new_streak := v_row.current_streak;
  ELSIF v_last = v_today - 1 THEN
    v_new_streak := v_row.current_streak + 1;
  ELSE
    v_new_streak := 1;
  END IF;

  INSERT INTO public.care_streaks AS cs (pet_id, current_streak, last_completion_date, best_streak)
  VALUES (target_pet_id, v_new_streak, v_today, v_new_streak)
  ON CONFLICT (pet_id) DO UPDATE
    SET
      current_streak = EXCLUDED.current_streak,
      last_completion_date = EXCLUDED.last_completion_date,
      best_streak = GREATEST(public.care_streaks.best_streak, EXCLUDED.current_streak);

  IF v_new_streak >= 7 THEN
    INSERT INTO public.pet_badges AS pb (pet_id, badge_type, unlocked_at)
    VALUES (target_pet_id, '7_day_hero', now())
    ON CONFLICT (pet_id, badge_type) DO NOTHING;

    GET DIAGNOSTICS v_badge_rows = ROW_COUNT;
    v_badge_unlocked := v_badge_rows > 0;
  END IF;

  RETURN jsonb_build_object(
    'total', v_total,
    'completed', v_completed,
    'all_done', true,
    'current_streak', v_new_streak,
    'best_streak', (
      SELECT cs.best_streak
      FROM public.care_streaks AS cs
      WHERE
        cs.pet_id = target_pet_id
    ),
    'last_completion_date', to_jsonb(v_today),
    'badge_unlocked', v_badge_unlocked
  );
END;
$$;

REVOKE ALL ON FUNCTION public.check_daily_completion (uuid, date) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.check_daily_completion (uuid, date) TO authenticated;
