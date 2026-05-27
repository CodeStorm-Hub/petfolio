-- Add NOT NULL constraints to follows FK columns.
-- Both tables have 0 NULL rows (confirmed via live-DB check 2026-05-27),
-- so the ALTER TABLE is safe and will not fail on existing data.

ALTER TABLE public.pet_follows
  ALTER COLUMN follower_pet_id  SET NOT NULL,
  ALTER COLUMN following_pet_id SET NOT NULL;

ALTER TABLE public.follows
  ALTER COLUMN follower_id  SET NOT NULL,
  ALTER COLUMN following_id SET NOT NULL;
