-- Create an UPDATE policy for comments to allow authors to update their own comments,
-- and restrict UPDATE privileges strictly to the 'content' column to prevent malicious mutations.

-- 1. Revoke all UPDATE privileges on the comments table by default
REVOKE UPDATE ON public.comments FROM authenticated, anon, PUBLIC;

-- 2. Grant UPDATE privilege ONLY on the 'content' column of the comments table to authenticated users
GRANT UPDATE (content) ON public.comments TO authenticated;

-- 3. Create RLS update policy enforcing that the author owns the comment
DROP POLICY IF EXISTS "comments_update_policy" ON public.comments;
CREATE POLICY "comments_update_policy"
  ON public.comments
  FOR UPDATE
  TO authenticated
  USING (author_id = (SELECT auth.uid()))
  WITH CHECK (author_id = (SELECT auth.uid()));
