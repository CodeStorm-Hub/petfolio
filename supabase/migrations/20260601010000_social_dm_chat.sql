-- ─────────────────────────────────────────────────────────────────────────────
-- 20260601010000_social_dm_chat: extend chat_threads to support pet-to-pet direct messages
-- ─────────────────────────────────────────────────────────────────────────────

-- 1. Add pet ID columns for DM threads (NULL on match-based threads).
--    Stored in canonical order (LEAST/GREATEST by UUID) so two pets always
--    map to the same row regardless of who initiates the conversation.
ALTER TABLE public.chat_threads
  ADD COLUMN IF NOT EXISTS dm_pet_a_id UUID REFERENCES public.pets(id),
  ADD COLUMN IF NOT EXISTS dm_pet_b_id UUID REFERENCES public.pets(id);

-- 2. Deduplication: one DM thread per ordered pet pair, on non-match threads.
CREATE UNIQUE INDEX IF NOT EXISTS chat_threads_dm_pets_uidx
  ON public.chat_threads (dm_pet_a_id, dm_pet_b_id)
  WHERE mutual_match_id IS NULL;

-- ─────────────────────────────────────────────────────────────────────────────
-- 3. ensure_direct_chat_thread
--    Creates (or returns existing) DM thread between two pets.
--    Security: verifies the caller owns p_actor_pet_id via auth.uid().
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.ensure_direct_chat_thread(
  p_actor_pet_id UUID,
  p_other_pet_id UUID
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_actor_user_id UUID;
  v_other_user_id UUID;
  v_pet_a_id      UUID;
  v_pet_b_id      UUID;
  v_user_a_id     UUID;
  v_user_b_id     UUID;
  v_thread_id     UUID;
BEGIN
  -- Verify caller owns the actor pet
  SELECT owner_id INTO v_actor_user_id
  FROM public.pets
  WHERE id = p_actor_pet_id AND owner_id = (SELECT auth.uid());

  IF NOT FOUND THEN
    RAISE EXCEPTION 'forbidden: actor pet not owned by caller';
  END IF;

  -- Fetch the other pet's owner
  SELECT owner_id INTO v_other_user_id
  FROM public.pets
  WHERE id = p_other_pet_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'not_found: other pet does not exist';
  END IF;

  -- Prevent self-DM
  IF v_actor_user_id = v_other_user_id THEN
    RAISE EXCEPTION 'invalid: cannot start a DM with your own pet';
  END IF;

  -- Canonical UUID ordering guarantees the same thread for both directions
  IF p_actor_pet_id < p_other_pet_id THEN
    v_pet_a_id  := p_actor_pet_id;  v_pet_b_id  := p_other_pet_id;
    v_user_a_id := v_actor_user_id; v_user_b_id := v_other_user_id;
  ELSE
    v_pet_a_id  := p_other_pet_id;  v_pet_b_id  := p_actor_pet_id;
    v_user_a_id := v_other_user_id; v_user_b_id := v_actor_user_id;
  END IF;

  -- Idempotent insert: silently skip if the thread already exists
  INSERT INTO public.chat_threads (
    participant_1_id, participant_2_id,
    dm_pet_a_id, dm_pet_b_id
  )
  VALUES (v_user_a_id, v_user_b_id, v_pet_a_id, v_pet_b_id)
  ON CONFLICT (dm_pet_a_id, dm_pet_b_id) WHERE mutual_match_id IS NULL
  DO NOTHING;

  SELECT id INTO v_thread_id
  FROM public.chat_threads
  WHERE dm_pet_a_id = v_pet_a_id
    AND dm_pet_b_id = v_pet_b_id
    AND mutual_match_id IS NULL;

  RETURN v_thread_id;
END;
$$;

REVOKE ALL ON FUNCTION public.ensure_direct_chat_thread(uuid, uuid) FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION public.ensure_direct_chat_thread(uuid, uuid) TO authenticated;

-- ─────────────────────────────────────────────────────────────────────────────
-- 4. get_chat_inbox
--    Unified inbox: match-based threads UNION DM threads, sorted by activity.
--    Replaces get_match_inbox for callers that need both thread types.
--    get_match_inbox is left intact so the Match tab is unaffected.
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.get_chat_inbox(p_actor_pet_id uuid)
RETURNS TABLE (
  thread_type          text,
  match_id             uuid,
  other_pet_id         uuid,
  other_pet_name       text,
  other_pet_avatar_url text,
  other_pet_breed      text,
  matched_at           timestamptz,
  thread_id            uuid,
  last_message_at      timestamptz,
  last_message_preview text
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  -- ── Part 1: match-based chat threads ──────────────────────────────────────
  SELECT
    'match'::text                               AS thread_type,
    m.id                                        AS match_id,
    p.id                                        AS other_pet_id,
    p.name                                      AS other_pet_name,
    p.avatar_url                                AS other_pet_avatar_url,
    p.breed                                     AS other_pet_breed,
    m.created_at                                AS matched_at,
    t.id                                        AS thread_id,
    COALESCE(t.last_message_at, lm.created_at) AS last_message_at,
    lm.content                                  AS last_message_preview
  FROM public.matches m
  INNER JOIN public.pets actor
    ON actor.id = p_actor_pet_id
   AND actor.owner_id = (SELECT auth.uid())
  JOIN public.pets p
    ON p.id = CASE WHEN m.pet_a_id = p_actor_pet_id THEN m.pet_b_id ELSE m.pet_a_id END
  LEFT JOIN public.chat_threads t ON t.mutual_match_id = m.id
  LEFT JOIN LATERAL (
    SELECT cm.content, cm.created_at
    FROM   public.chat_messages cm
    WHERE  cm.thread_id = t.id
    ORDER  BY cm.created_at DESC
    LIMIT  1
  ) lm ON true
  WHERE m.pet_a_id = p_actor_pet_id OR m.pet_b_id = p_actor_pet_id

  UNION ALL

  -- ── Part 2: direct message threads ────────────────────────────────────────
  SELECT
    'dm'::text                                  AS thread_type,
    NULL::uuid                                  AS match_id,
    p.id                                        AS other_pet_id,
    p.name                                      AS other_pet_name,
    p.avatar_url                                AS other_pet_avatar_url,
    p.breed                                     AS other_pet_breed,
    t.created_at                                AS matched_at,
    t.id                                        AS thread_id,
    COALESCE(t.last_message_at, lm.created_at) AS last_message_at,
    lm.content                                  AS last_message_preview
  FROM public.chat_threads t
  INNER JOIN public.pets actor
    ON actor.id = p_actor_pet_id
   AND actor.owner_id = (SELECT auth.uid())
  JOIN public.pets p
    ON p.id = CASE
                WHEN t.dm_pet_a_id = p_actor_pet_id THEN t.dm_pet_b_id
                ELSE t.dm_pet_a_id
              END
  LEFT JOIN LATERAL (
    SELECT cm.content, cm.created_at
    FROM   public.chat_messages cm
    WHERE  cm.thread_id = t.id
    ORDER  BY cm.created_at DESC
    LIMIT  1
  ) lm ON true
  WHERE (t.dm_pet_a_id = p_actor_pet_id OR t.dm_pet_b_id = p_actor_pet_id)
    AND t.mutual_match_id IS NULL
$$;

REVOKE ALL ON FUNCTION public.get_chat_inbox(uuid) FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION public.get_chat_inbox(uuid) TO authenticated;
