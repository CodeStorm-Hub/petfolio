-- Create an UPDATE policy for comments to allow authors to update their own comments
CREATE POLICY "comments_update_policy"
  ON public.comments
  FOR UPDATE
  TO authenticated
  USING (author_id = (SELECT auth.uid()))
  WITH CHECK (author_id = (SELECT auth.uid()));
