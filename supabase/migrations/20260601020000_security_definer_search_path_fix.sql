-- ─────────────────────────────────────────────────────────────────────────────
-- PR #15 review fix: pin search_path = '' on all SECURITY DEFINER functions.
-- All table references are already schema-qualified so an empty search_path
-- is safe and removes the search_path-based privilege escalation surface.
-- Consistent with the pattern enforced in 20260531100100_function_search_path.sql.
-- ─────────────────────────────────────────────────────────────────────────────

-- ── Trigger functions from 20260601000000_social_fixes.sql ───────────────────

CREATE OR REPLACE FUNCTION public.handle_post_comment_sync()
RETURNS TRIGGER AS $$
BEGIN
  IF (TG_OP = 'INSERT') THEN
    IF NEW.parent_id IS NULL THEN
      UPDATE public.posts SET comment_count = comment_count + 1 WHERE id = NEW.post_id;
    END IF;
  ELSIF (TG_OP = 'DELETE') THEN
    IF OLD.parent_id IS NULL THEN
      UPDATE public.posts SET comment_count = GREATEST(0, comment_count - 1) WHERE id = OLD.post_id;
    END IF;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = '';

CREATE OR REPLACE FUNCTION public.handle_post_like_notification()
RETURNS TRIGGER AS $$
DECLARE
  v_post_pet_id UUID;
BEGIN
  SELECT pet_id INTO v_post_pet_id FROM public.posts WHERE id = NEW.post_id;
  IF v_post_pet_id IS NOT NULL AND v_post_pet_id <> NEW.pet_id THEN
    INSERT INTO public.notifications (recipient_pet_id, actor_pet_id, type, post_id)
    VALUES (v_post_pet_id, NEW.pet_id, 'like', NEW.post_id);
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = '';

CREATE OR REPLACE FUNCTION public.handle_post_comment_notification()
RETURNS TRIGGER AS $$
DECLARE
  v_post_pet_id UUID;
BEGIN
  IF NEW.parent_id IS NULL THEN
    SELECT pet_id INTO v_post_pet_id FROM public.posts WHERE id = NEW.post_id;
    IF v_post_pet_id IS NOT NULL AND v_post_pet_id <> NEW.pet_id THEN
      INSERT INTO public.notifications (recipient_pet_id, actor_pet_id, type, post_id)
      VALUES (v_post_pet_id, NEW.pet_id, 'comment', NEW.post_id);
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = '';

CREATE OR REPLACE FUNCTION public.handle_pet_follow_notification()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.notifications (recipient_pet_id, actor_pet_id, type)
  VALUES (NEW.following_pet_id, NEW.follower_pet_id, 'follow');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = '';

REVOKE ALL ON FUNCTION public.handle_post_comment_sync() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.handle_post_like_notification() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.handle_post_comment_notification() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.handle_pet_follow_notification() FROM PUBLIC;

-- ── RPCs from 20260601010000_social_dm_chat.sql ──────────────────────────────

CREATE OR REPLACE FUNCTION public.ensure_direct_chat_thread(
  p_actor_pet_id UUID,
  p_other_pet_id UUID
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
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
  SELECT owner_id INTO v_actor_user_id
  FROM public.pets
  WHERE id = p_actor_pet_id AND owner_id = (SELECT auth.uid());

  IF NOT FOUND THEN
    RAISE EXCEPTION 'forbidden: actor pet not owned by caller';
  END IF;

  SELECT owner_id INTO v_other_user_id
  FROM public.pets
  WHERE id = p_other_pet_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'not_found: other pet does not exist';
  END IF;

  IF v_actor_user_id = v_other_user_id THEN
    RAISE EXCEPTION 'invalid: cannot start a DM with your own pet';
  END IF;

  IF p_actor_pet_id < p_other_pet_id THEN
    v_pet_a_id  := p_actor_pet_id;  v_pet_b_id  := p_other_pet_id;
    v_user_a_id := v_actor_user_id; v_user_b_id := v_other_user_id;
  ELSE
    v_pet_a_id  := p_other_pet_id;  v_pet_b_id  := p_actor_pet_id;
    v_user_a_id := v_other_user_id; v_user_b_id := v_actor_user_id;
  END IF;

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
SET search_path = ''
AS $$
  SELECT *
  FROM (
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
  ) inbox
  ORDER BY COALESCE(inbox.last_message_at, inbox.matched_at) DESC NULLS LAST
$$;

REVOKE ALL ON FUNCTION public.get_chat_inbox(uuid) FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION public.get_chat_inbox(uuid) TO authenticated;
