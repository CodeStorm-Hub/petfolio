DROP FUNCTION IF EXISTS public.get_match_inbox(uuid);

CREATE OR REPLACE FUNCTION public.get_match_inbox(p_actor_pet_id uuid)
RETURNS TABLE (
  match_id uuid,
  other_pet_id uuid,
  other_pet_name text,
  other_pet_avatar_url text,
  other_pet_breed text,
  matched_at timestamptz,
  thread_id uuid,
  last_message_at timestamptz,
  last_message_preview text
)
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = public, extensions
AS $$
  SELECT
    m.id AS match_id,
    p.id AS other_pet_id,
    p.name AS other_pet_name,
    p.avatar_url AS other_pet_avatar_url,
    p.breed AS other_pet_breed,
    m.created_at AS matched_at,
    t.id AS thread_id,
    COALESCE(t.last_message_at, lm.created_at) AS last_message_at,
    lm.content AS last_message_preview
  FROM public.matches m
  INNER JOIN public.pets actor
    ON actor.id = p_actor_pet_id
    AND actor.owner_id = (SELECT auth.uid())
  JOIN public.pets p
    ON p.id = (
      CASE
        WHEN m.pet_a_id = p_actor_pet_id THEN m.pet_b_id
        ELSE m.pet_a_id
      END
    )
  LEFT JOIN public.chat_threads t
    ON t.mutual_match_id = m.id
  LEFT JOIN LATERAL (
    SELECT cm.content, cm.created_at
    FROM public.chat_messages cm
    WHERE cm.thread_id = t.id
    ORDER BY cm.created_at DESC
    LIMIT 1
  ) lm ON true
  WHERE m.pet_a_id = p_actor_pet_id OR m.pet_b_id = p_actor_pet_id;
$$;

REVOKE ALL ON FUNCTION public.ensure_chat_thread_for_match(uuid, uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.ensure_chat_thread_for_match(uuid, uuid) TO authenticated;
