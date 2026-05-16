CREATE POLICY "swipes: update by actor pet owner"
  ON public.swipes FOR UPDATE TO authenticated
  USING (
    (SELECT auth.uid()) IN (
      SELECT p.owner_id FROM public.pets p WHERE p.id = swipes.actor_id
    )
  )
  WITH CHECK (
    (SELECT auth.uid()) IN (
      SELECT p.owner_id FROM public.pets p WHERE p.id = swipes.actor_id
    )
  );

GRANT UPDATE ON public.swipes TO authenticated;
