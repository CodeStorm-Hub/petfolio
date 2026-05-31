-- ─────────────────────────────────────────────────────────────────────────────
-- Migration: social_fixes
-- Addresses Issues #1, #2, #3 from the social feature audit.
-- ─────────────────────────────────────────────────────────────────────────────

-- ── Issue #2: Realtime — add posts and notifications to publication ────────────
DO $$
BEGIN
  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.posts;
  EXCEPTION WHEN duplicate_object THEN NULL;
  END;
  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.notifications;
  EXCEPTION WHEN duplicate_object THEN NULL;
  END;
END;
$$;

-- ── Issue #3: Fix comment_count trigger — only count top-level comments ────────
-- Replaces the version in 20260514000004_auto_count_triggers.sql.
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
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Backfill: recount only top-level comments so existing posts are consistent.
UPDATE public.posts p
SET comment_count = (
  SELECT COUNT(*) FROM public.comments c
  WHERE c.post_id = p.id AND c.parent_id IS NULL
);

-- ── Issue #1: Notification producers — DB triggers for like/comment/follow ────

-- 1a. Like notification
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
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_post_like_notification ON public.post_likes;
CREATE TRIGGER on_post_like_notification
  AFTER INSERT ON public.post_likes
  FOR EACH ROW EXECUTE FUNCTION public.handle_post_like_notification();

-- 1b. Comment notification (top-level comments only; replies aren't in scope)
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
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_post_comment_notification ON public.comments;
CREATE TRIGGER on_post_comment_notification
  AFTER INSERT ON public.comments
  FOR EACH ROW EXECUTE FUNCTION public.handle_post_comment_notification();

-- 1c. Follow notification
CREATE OR REPLACE FUNCTION public.handle_pet_follow_notification()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.notifications (recipient_pet_id, actor_pet_id, type)
  VALUES (NEW.following_pet_id, NEW.follower_pet_id, 'follow');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_pet_follow_notification ON public.pet_follows;
CREATE TRIGGER on_pet_follow_notification
  AFTER INSERT ON public.pet_follows
  FOR EACH ROW EXECUTE FUNCTION public.handle_pet_follow_notification();

-- Lock down trigger functions — they run via triggers only, not direct RPC.
REVOKE EXECUTE ON FUNCTION public.handle_post_like_notification()    FROM anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.handle_post_comment_notification() FROM anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.handle_pet_follow_notification()   FROM anon, authenticated;
