-- Migration: comment_likes_and_replies
-- Adds replies (parent_id) and likes to the comments table.

-- 1. Alter comments table to support parent_id and like_count
ALTER TABLE public.comments
  ADD COLUMN IF NOT EXISTS parent_id UUID REFERENCES public.comments(id) ON DELETE CASCADE,
  ADD COLUMN IF NOT EXISTS like_count INT NOT NULL DEFAULT 0 CHECK (like_count >= 0);

-- Index for fast nested comment retrieval
CREATE INDEX IF NOT EXISTS comments_parent_id_idx ON public.comments(parent_id);

-- 2. Create comment_likes table
CREATE TABLE IF NOT EXISTS public.comment_likes (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  comment_id UUID NOT NULL,
  pet_id     UUID NOT NULL,
  user_id    UUID NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  
  CONSTRAINT comment_likes_comment_id_fkey FOREIGN KEY (comment_id) REFERENCES public.comments(id) ON DELETE CASCADE,
  CONSTRAINT comment_likes_pet_id_fkey  FOREIGN KEY (pet_id)  REFERENCES public.pets(id)  ON DELETE CASCADE,
  CONSTRAINT comment_likes_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE,
  CONSTRAINT comment_likes_comment_id_pet_id_key UNIQUE(comment_id, pet_id)
);

-- Row-Level Security
ALTER TABLE public.comment_likes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "comment_likes: anyone can read"
  ON public.comment_likes FOR SELECT
  USING (true);

-- Always wrap auth.uid check in a subselect for performance
CREATE POLICY "comment_likes: insert own"
  ON public.comment_likes FOR INSERT
  WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "comment_likes: delete own"
  ON public.comment_likes FOR DELETE
  USING ((SELECT auth.uid()) = user_id);

-- 3. Trigger to keep like_count in sync on public.comments
CREATE OR REPLACE FUNCTION public.handle_comment_like_sync()
RETURNS TRIGGER AS $$
BEGIN
  IF (TG_OP = 'INSERT') THEN
    UPDATE public.comments 
    SET like_count = like_count + 1 
    WHERE id = NEW.comment_id;
  ELSIF (TG_OP = 'DELETE') THEN
    UPDATE public.comments 
    SET like_count = GREATEST(0, like_count - 1) 
    WHERE id = OLD.comment_id;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_comment_like_change
  AFTER INSERT OR DELETE ON public.comment_likes
  FOR EACH ROW EXECUTE FUNCTION public.handle_comment_like_sync();

-- Revoke execution permissions from anon/authenticated on trigger functions
REVOKE EXECUTE ON FUNCTION public.handle_comment_like_sync() FROM anon, authenticated;
