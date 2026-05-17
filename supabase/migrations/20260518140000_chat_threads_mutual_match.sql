ALTER TABLE public.chat_threads
  ADD COLUMN IF NOT EXISTS mutual_match_id uuid REFERENCES public.matches(id) ON DELETE SET NULL;

CREATE UNIQUE INDEX IF NOT EXISTS chat_threads_mutual_match_id_uidx
  ON public.chat_threads (mutual_match_id)
  WHERE mutual_match_id IS NOT NULL;

CREATE OR REPLACE FUNCTION public.ensure_chat_thread_for_match(
  p_match_id uuid,
  p_actor_pet_id uuid
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_match public.matches%ROWTYPE;
  v_actor_owner uuid;
  v_other_pet_id uuid;
  v_other_owner uuid;
  v_p1 uuid;
  v_p2 uuid;
  v_thread_id uuid;
BEGIN
  SELECT * INTO v_match FROM public.matches WHERE id = p_match_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'match_not_found';
  END IF;

  SELECT owner_id INTO v_actor_owner
  FROM public.pets
  WHERE id = p_actor_pet_id AND owner_id = auth.uid();
  IF NOT FOUND THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  IF v_match.pet_a_id = p_actor_pet_id THEN
    v_other_pet_id := v_match.pet_b_id;
  ELSIF v_match.pet_b_id = p_actor_pet_id THEN
    v_other_pet_id := v_match.pet_a_id;
  ELSE
    RAISE EXCEPTION 'forbidden';
  END IF;

  SELECT owner_id INTO v_other_owner FROM public.pets WHERE id = v_other_pet_id;
  IF v_other_owner IS NULL THEN
    RAISE EXCEPTION 'other_pet_not_found';
  END IF;

  SELECT id INTO v_thread_id
  FROM public.chat_threads
  WHERE mutual_match_id = p_match_id
  LIMIT 1;

  IF v_thread_id IS NOT NULL THEN
    RETURN v_thread_id;
  END IF;

  v_p1 := LEAST(v_actor_owner, v_other_owner);
  v_p2 := GREATEST(v_actor_owner, v_other_owner);

  INSERT INTO public.chat_threads (
    mutual_match_id,
    participant_1_id,
    participant_2_id
  )
  VALUES (p_match_id, v_p1, v_p2)
  RETURNING id INTO v_thread_id;

  RETURN v_thread_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.ensure_chat_thread_for_match(uuid, uuid) TO authenticated;
