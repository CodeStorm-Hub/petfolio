ALTER TABLE public.swipes DROP CONSTRAINT IF EXISTS swipes_action_check;
ALTER TABLE public.swipes ADD CONSTRAINT swipes_action_check CHECK (action IN ('LIKE', 'PASS', 'GREET', 'SUPER_PAW'));

DROP INDEX IF EXISTS public.swipes_target_actor_like_idx;
CREATE INDEX swipes_target_actor_like_idx
  ON public.swipes (target_id, actor_id)
  WHERE action IN ('LIKE', 'GREET', 'SUPER_PAW');

CREATE OR REPLACE FUNCTION private.swipes_after_insert_mutual_match()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_a uuid;
  v_b uuid;
BEGIN
  IF NOT (NEW.action IN ('LIKE', 'GREET', 'SUPER_PAW')) THEN
    RETURN NEW;
  END IF;

  IF EXISTS (
    SELECT 1
    FROM public.swipes s
    WHERE s.actor_id = NEW.target_id
      AND s.target_id = NEW.actor_id
      AND s.action IN ('LIKE', 'GREET', 'SUPER_PAW')
  ) THEN
    v_a := LEAST(NEW.actor_id, NEW.target_id);
    v_b := GREATEST(NEW.actor_id, NEW.target_id);

    INSERT INTO public.matches (pet_a_id, pet_b_id)
    VALUES (v_a, v_b)
    ON CONFLICT (pet_a_id, pet_b_id) DO NOTHING;
  END IF;

  RETURN NEW;
END;
$$;
