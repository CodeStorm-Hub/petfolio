-- Remove duplicate care_tasks, keeping the earliest row per
-- (pet_id, task_type, frequency, lower(trimmed title)). Recurring duplicates
-- accumulated because the app's de-dup key compared the Dart enum name
-- (e.g. 'vetVisit') against the stored snake_case value ('vet_visit'), so
-- multi-word task types never matched and were re-inserted on each AI refresh.
WITH ranked AS (
  SELECT id,
         row_number() OVER (
           PARTITION BY pet_id, task_type, frequency, lower(btrim(title))
           ORDER BY created_at, id
         ) AS rn
    FROM public.care_tasks
)
DELETE FROM public.care_tasks
 WHERE id IN (SELECT id FROM ranked WHERE rn > 1);

-- Prevent future duplicates at the database level.
CREATE UNIQUE INDEX IF NOT EXISTS care_tasks_pet_dedup_uidx
  ON public.care_tasks (pet_id, task_type, frequency, lower(btrim(title)));
