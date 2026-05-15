-- Triggers to keep like_count and comment_count in sync on the posts table.
-- This allows us to fetch the feed efficiently without downloading every reaction/comment.

-- 1. Like Count Synchronization
CREATE OR REPLACE FUNCTION public.handle_post_like_sync()
RETURNS TRIGGER AS $$
BEGIN
  IF (TG_OP = 'INSERT') THEN
    UPDATE public.posts 
    SET like_count = like_count + 1 
    WHERE id = NEW.post_id;
  ELSIF (TG_OP = 'DELETE') THEN
    UPDATE public.posts 
    SET like_count = GREATEST(0, like_count - 1) 
    WHERE id = OLD.post_id;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_post_like_change
AFTER INSERT OR DELETE ON public.post_likes
FOR EACH ROW EXECUTE FUNCTION public.handle_post_like_sync();

-- 2. Comment Count Synchronization
CREATE OR REPLACE FUNCTION public.handle_post_comment_sync()
RETURNS TRIGGER AS $$
BEGIN
  IF (TG_OP = 'INSERT') THEN
    UPDATE public.posts 
    SET comment_count = comment_count + 1 
    WHERE id = NEW.post_id;
  ELSIF (TG_OP = 'DELETE') THEN
    UPDATE public.posts 
    SET comment_count = GREATEST(0, comment_count - 1) 
    WHERE id = OLD.post_id;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_post_comment_change
AFTER INSERT OR DELETE ON public.comments
FOR EACH ROW EXECUTE FUNCTION public.handle_post_comment_sync();

-- 3. Initial Sync (Backfill existing counts)
UPDATE public.posts p
SET 
  like_count = (SELECT count(*) FROM public.post_likes WHERE post_id = p.id),
  comment_count = (SELECT count(*) FROM public.comments WHERE post_id = p.id);
