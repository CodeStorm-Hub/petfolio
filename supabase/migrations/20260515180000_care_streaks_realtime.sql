DO $body$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_publication_tables
    WHERE
      pubname = 'supabase_realtime'
      AND schemaname = 'public'
      AND tablename = 'care_streaks'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.care_streaks;
  END IF;
END
$body$;
