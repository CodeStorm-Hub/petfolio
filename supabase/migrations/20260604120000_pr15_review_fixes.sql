-- PR #15 review fixes: social notification triggers, trigger EXECUTE lockdown,
-- deterministic get_chat_inbox ordering.

DO $$
BEGIN
  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.notifications;
  EXCEPTION WHEN duplicate_object THEN NULL;
  END;
END;
$$;

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

DROP TRIGGER IF EXISTS on_post_like_notification ON public.post_likes;
CREATE TRIGGER on_post_like_notification
  AFTER INSERT ON public.post_likes
  FOR EACH ROW EXECUTE FUNCTION public.handle_post_like_notification();

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

DROP TRIGGER IF EXISTS on_post_comment_notification ON public.comments;
CREATE TRIGGER on_post_comment_notification
  AFTER INSERT ON public.comments
  FOR EACH ROW EXECUTE FUNCTION public.handle_post_comment_notification();

CREATE OR REPLACE FUNCTION public.handle_pet_follow_notification()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.notifications (recipient_pet_id, actor_pet_id, type)
  VALUES (NEW.following_pet_id, NEW.follower_pet_id, 'follow');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = '';

DROP TRIGGER IF EXISTS on_pet_follow_notification ON public.pet_follows;
CREATE TRIGGER on_pet_follow_notification
  AFTER INSERT ON public.pet_follows
  FOR EACH ROW EXECUTE FUNCTION public.handle_pet_follow_notification();

REVOKE ALL ON FUNCTION public.handle_post_comment_sync() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.handle_post_like_notification() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.handle_post_comment_notification() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.handle_pet_follow_notification() FROM PUBLIC;

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
