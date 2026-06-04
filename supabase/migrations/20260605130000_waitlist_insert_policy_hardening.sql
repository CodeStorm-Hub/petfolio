DROP POLICY IF EXISTS allow_public_insert ON public.waitlist;

CREATE POLICY waitlist_public_insert ON public.waitlist
  FOR INSERT TO anon, authenticated
  WITH CHECK (
    email IS NOT NULL
    AND length(trim(email)) >= 5
    AND email ~* '^[^@\s]+@[^@\s]+\.[^@\s]+$'
  );
