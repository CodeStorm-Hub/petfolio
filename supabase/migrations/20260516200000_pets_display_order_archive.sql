-- Pets: ordering + soft-archive support for the Manage Pets screen.
--
-- display_order — drives the order pets appear in the switcher / manage list.
--                 Lower values come first; ties break on created_at.
-- archived_at   — soft delete. Archived pets are filtered out everywhere by
--                 default; data is preserved for care_logs history.

ALTER TABLE public.pets
  ADD COLUMN IF NOT EXISTS display_order INTEGER NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS archived_at TIMESTAMPTZ NULL;

CREATE INDEX IF NOT EXISTS pets_owner_active_order_idx
  ON public.pets (owner_id, archived_at, display_order, created_at)
  WHERE archived_at IS NULL;

-- Backfill: existing pets get a stable order based on creation timestamp.
WITH ranked AS (
  SELECT
    id,
    ROW_NUMBER() OVER (PARTITION BY owner_id ORDER BY created_at ASC) - 1 AS rn
  FROM public.pets
  WHERE display_order = 0
)
UPDATE public.pets p
SET display_order = ranked.rn
FROM ranked
WHERE p.id = ranked.id;
