-- Fix care_tasks unique index to include scheduled_time, so distinct tasks
-- that share title/type/frequency but differ only by time (e.g. morning and
-- evening medication) are not incorrectly treated as duplicates.

DROP INDEX IF EXISTS public.care_tasks_pet_dedup_uidx;

CREATE UNIQUE INDEX care_tasks_pet_dedup_uidx
  ON public.care_tasks (pet_id, task_type, frequency, lower(btrim(title)), scheduled_time);
