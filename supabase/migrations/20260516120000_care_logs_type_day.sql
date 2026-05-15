ALTER TABLE public.care_logs
  ADD COLUMN IF NOT EXISTS logged_date date;

UPDATE public.care_logs
SET
  logged_date = (occurred_at AT TIME ZONE 'UTC')::date
WHERE
  logged_date IS NULL;

DO $body$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM information_schema.table_constraints
    WHERE
      constraint_schema = 'public'
      AND table_name = 'care_logs'
      AND constraint_name = 'care_logs_care_type_check'
  ) THEN
    ALTER TABLE public.care_logs DROP CONSTRAINT care_logs_care_type_check;
  END IF;
END
$body$;

ALTER TABLE public.care_logs
  ADD CONSTRAINT care_logs_care_type_check CHECK (
    care_type IN (
      'feeding',
      'walk',
      'grooming',
      'medication',
      'vet_visit',
      'training',
      'playtime',
      'dental',
      'nail_trim',
      'bath',
      'other'
    )
  );

DELETE FROM public.care_logs cl
WHERE
  cl.id IN (
    SELECT id
    FROM (
      SELECT
        id,
        ROW_NUMBER() OVER (
          PARTITION BY pet_id, care_type, logged_date
          ORDER BY
            occurred_at ASC NULLS LAST,
            id ASC
        ) AS rn
      FROM public.care_logs
      WHERE
        logged_date IS NOT NULL
    ) deduped
    WHERE
      deduped.rn > 1
  );

CREATE UNIQUE INDEX IF NOT EXISTS care_logs_pet_care_type_logged_date_uq
  ON public.care_logs (pet_id, care_type, logged_date);
