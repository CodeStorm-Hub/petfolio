-- ─────────────────────────────────────────────────────────────────────────────
-- Migration: 20260611000000_enhance_appointments.sql
-- Alters appointments status choices, adds intake columns, and
-- sets up appointment-media storage bucket.
-- ─────────────────────────────────────────────────────────────────────────────

-- 1. Drop the check constraint on status column if it exists (usually auto-named)
ALTER TABLE public.appointments DROP CONSTRAINT IF EXISTS appointments_status_check;

-- 2. Migrate existing 'upcoming' status values to 'pending' to ensure data integrity
UPDATE public.appointments SET status = 'pending' WHERE status = 'upcoming';

-- 3. Add the check constraint back with the new choices
ALTER TABLE public.appointments ADD CONSTRAINT appointments_status_check 
  CHECK (status IN ('pending', 'confirmed', 'cancelled', 'completed'));

-- 4. Set the default value of the status column to 'pending'
ALTER TABLE public.appointments ALTER COLUMN status SET DEFAULT 'pending';

-- 5. Add reason, urgency, and media_url columns to appointments
ALTER TABLE public.appointments
  ADD COLUMN IF NOT EXISTS reason text,
  ADD COLUMN IF NOT EXISTS urgency text,
  ADD COLUMN IF NOT EXISTS media_url text;

-- 6. Create storage bucket for appointment-media
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'appointment-media',
  'appointment-media',
  true,
  52428800, -- 50MB
  ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/heic', 'image/jpg', 'video/mp4', 'video/quicktime', 'video/3gpp', 'video/webm']
)
ON CONFLICT (id) DO UPDATE SET
  public = EXCLUDED.public,
  file_size_limit = EXCLUDED.file_size_limit,
  allowed_mime_types = EXCLUDED.allowed_mime_types;

-- 7. Define RLS policies for the appointment-media storage bucket
DROP POLICY IF EXISTS "appointment-media: owner insert" ON storage.objects;
DROP POLICY IF EXISTS "appointment-media: public read" ON storage.objects;
DROP POLICY IF EXISTS "appointment-media: owner update" ON storage.objects;
DROP POLICY IF EXISTS "appointment-media: owner delete" ON storage.objects;

-- Ensure auth.uid() checks are wrapped in a subselect for performance caching
CREATE POLICY "appointment-media: owner insert"
  ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'appointment-media'
    AND (SELECT auth.uid())::text = (string_to_array(name, '/'))[1]
  );

CREATE POLICY "appointment-media: public read"
  ON storage.objects FOR SELECT USING (
    bucket_id = 'appointment-media'
  );

CREATE POLICY "appointment-media: owner update"
  ON storage.objects FOR UPDATE TO authenticated
  USING (
    bucket_id = 'appointment-media'
    AND (SELECT auth.uid())::text = (string_to_array(name, '/'))[1]
  )
  WITH CHECK (
    bucket_id = 'appointment-media'
    AND (SELECT auth.uid())::text = (string_to_array(name, '/'))[1]
  );

CREATE POLICY "appointment-media: owner delete"
  ON storage.objects FOR DELETE TO authenticated
  USING (
    bucket_id = 'appointment-media'
    AND (SELECT auth.uid())::text = (string_to_array(name, '/'))[1]
  );

-- 8. Schedule the hourly pg_cron reminder job
DO $$
DECLARE
  r record;
BEGIN
  FOR r IN SELECT jobid FROM cron.job WHERE jobname = 'appointment_reminders'
  LOOP
    PERFORM cron.unschedule(r.jobid);
  END LOOP;
END;
$$;

SELECT cron.schedule(
  'appointment_reminders',
  '0 * * * *', -- runs every hour
  $$
  SELECT net.http_post(
    url := (SELECT rtrim(functions_base_url, '/') || '/appointment-reminders' FROM private.fcm_internal_config WHERE id = 1),
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'x-fcm-dispatch-secret', (SELECT dispatch_secret FROM private.fcm_internal_config WHERE id = 1)
    ),
    body := '{}'::jsonb
  );
  $$
);
