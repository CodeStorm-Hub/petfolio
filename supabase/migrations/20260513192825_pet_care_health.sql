-- ─────────────────────────────────────────────────────────────────────────────
-- Migration: pet_care_health
-- Adds:
--   • public.set_updated_at() trigger function (shared)
--   • pets.activity_level column
--   • care_tasks  — scheduled/recurring tasks with gamification points
--   • health_logs — narrative health events (symptoms, weight, vet notes)
--   • medical_vault — vaccines & medications with expiry/renewal dates
-- RLS: all new tables enforce pet-owner-only access
-- ─────────────────────────────────────────────────────────────────────────────

-- ── 0. Shared trigger function ───────────────────────────────────────────────

-- SET search_path = '' prevents search_path injection (Supabase security lint 0011)
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql
SET search_path = ''
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

-- ── 1. pets — add activity_level ────────────────────────────────────────────

ALTER TABLE public.pets
  ADD COLUMN IF NOT EXISTS activity_level text
    CHECK (activity_level IN ('sedentary','low','moderate','high','very_high'));

-- ── 2. care_tasks ─────────────────────────────────────────────────────────────
-- Scheduled / recurring care tasks per pet with optional gamification points.
-- Distinct from care_logs, which records completed events after the fact.

CREATE TABLE IF NOT EXISTS public.care_tasks (
  id                  uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  pet_id              uuid        NOT NULL REFERENCES public.pets(id) ON DELETE CASCADE,
  task_type           text        NOT NULL
    CHECK (task_type IN ('feeding','walk','grooming','medication','vet_visit',
                         'training','playtime','dental','nail_trim','bath','other')),
  title               text        NOT NULL,
  frequency           text        NOT NULL
    CHECK (frequency IN ('once','daily','twice_daily','weekly','biweekly','monthly','as_needed')),
  scheduled_time      time,
  is_completed        boolean     NOT NULL DEFAULT false,
  completed_at        timestamptz,
  gamification_points integer     NOT NULL DEFAULT 10 CHECK (gamification_points >= 0),
  notes               text,
  created_at          timestamptz NOT NULL DEFAULT now(),
  updated_at          timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.care_tasks ENABLE ROW LEVEL SECURITY;

CREATE INDEX IF NOT EXISTS care_tasks_pet_id_idx    ON public.care_tasks (pet_id);
CREATE INDEX IF NOT EXISTS care_tasks_scheduled_idx ON public.care_tasks (pet_id, scheduled_time);

CREATE TRIGGER care_tasks_updated_at
  BEFORE UPDATE ON public.care_tasks
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- SELECT: pet owner can read their tasks
CREATE POLICY "care_tasks: select by pet owner"
  ON public.care_tasks FOR SELECT TO authenticated
  USING (
    (SELECT auth.uid()) IN (
      SELECT owner_id FROM public.pets WHERE id = care_tasks.pet_id
    )
  );

-- INSERT: only the pet's owner may create tasks
CREATE POLICY "care_tasks: insert by pet owner"
  ON public.care_tasks FOR INSERT TO authenticated
  WITH CHECK (
    (SELECT auth.uid()) IN (
      SELECT owner_id FROM public.pets WHERE id = care_tasks.pet_id
    )
  );

-- UPDATE: both USING and WITH CHECK required — prevents row re-assignment to another pet
CREATE POLICY "care_tasks: update by pet owner"
  ON public.care_tasks FOR UPDATE TO authenticated
  USING (
    (SELECT auth.uid()) IN (
      SELECT owner_id FROM public.pets WHERE id = care_tasks.pet_id
    )
  )
  WITH CHECK (
    (SELECT auth.uid()) IN (
      SELECT owner_id FROM public.pets WHERE id = care_tasks.pet_id
    )
  );

-- DELETE: owner only
CREATE POLICY "care_tasks: delete by pet owner"
  ON public.care_tasks FOR DELETE TO authenticated
  USING (
    (SELECT auth.uid()) IN (
      SELECT owner_id FROM public.pets WHERE id = care_tasks.pet_id
    )
  );

-- ── 3. health_logs ────────────────────────────────────────────────────────────
-- Narrative health events: symptoms, weight history, vet visit notes.
-- Distinct from health_vitals, which stores structured numeric measurements.

CREATE TABLE IF NOT EXISTS public.health_logs (
  id             uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  pet_id         uuid        NOT NULL REFERENCES public.pets(id)  ON DELETE CASCADE,
  recorded_by    uuid        NOT NULL REFERENCES public.users(id),
  log_type       text        NOT NULL
    CHECK (log_type IN ('symptom','weight','vet_visit','medication','allergy','injury','general')),
  title          text        NOT NULL,
  description    text,
  weight_kg      numeric     CHECK (weight_kg > 0),
  severity       text        CHECK (severity IN ('mild','moderate','severe','critical')),
  vet_name       text,
  vet_clinic     text,
  diagnosis      text,
  treatment      text,
  follow_up_date date,
  occurred_at    timestamptz NOT NULL DEFAULT now(),
  created_at     timestamptz NOT NULL DEFAULT now(),
  updated_at     timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.health_logs ENABLE ROW LEVEL SECURITY;

CREATE INDEX IF NOT EXISTS health_logs_pet_id_idx   ON public.health_logs (pet_id);
-- Composite descending index supports timeline queries (most-recent-first)
CREATE INDEX IF NOT EXISTS health_logs_timeline_idx ON public.health_logs (pet_id, occurred_at DESC);
CREATE INDEX IF NOT EXISTS health_logs_recorder_idx ON public.health_logs (recorded_by);

CREATE TRIGGER health_logs_updated_at
  BEFORE UPDATE ON public.health_logs
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE POLICY "health_logs: select by pet owner"
  ON public.health_logs FOR SELECT TO authenticated
  USING (
    (SELECT auth.uid()) IN (
      SELECT owner_id FROM public.pets WHERE id = health_logs.pet_id
    )
  );

-- INSERT: caller must be the recorder AND the pet's owner
CREATE POLICY "health_logs: insert by pet owner"
  ON public.health_logs FOR INSERT TO authenticated
  WITH CHECK (
    (SELECT auth.uid()) = recorded_by
    AND (SELECT auth.uid()) IN (
      SELECT owner_id FROM public.pets WHERE id = health_logs.pet_id
    )
  );

CREATE POLICY "health_logs: update by pet owner"
  ON public.health_logs FOR UPDATE TO authenticated
  USING (
    (SELECT auth.uid()) IN (
      SELECT owner_id FROM public.pets WHERE id = health_logs.pet_id
    )
  )
  WITH CHECK (
    (SELECT auth.uid()) IN (
      SELECT owner_id FROM public.pets WHERE id = health_logs.pet_id
    )
  );

CREATE POLICY "health_logs: delete by pet owner"
  ON public.health_logs FOR DELETE TO authenticated
  USING (
    (SELECT auth.uid()) IN (
      SELECT owner_id FROM public.pets WHERE id = health_logs.pet_id
    )
  );

-- ── 4. medical_vault ──────────────────────────────────────────────────────────
-- Vaccine and medication records with expiry / renewal date tracking.

CREATE TABLE IF NOT EXISTS public.medical_vault (
  id               uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  pet_id           uuid        NOT NULL REFERENCES public.pets(id) ON DELETE CASCADE,
  record_type      text        NOT NULL
    CHECK (record_type IN ('vaccine','medication','allergy','surgery','parasite_prevention','other')),
  name             text        NOT NULL,
  description      text,
  administered_by  text,
  administered_at  date,
  expires_at       date,
  next_due_at      date,
  batch_number     text,
  dosage           text,
  frequency        text,
  is_active        boolean     NOT NULL DEFAULT true,
  reminder_enabled boolean     NOT NULL DEFAULT true,
  document_url     text,
  notes            text,
  created_at       timestamptz NOT NULL DEFAULT now(),
  updated_at       timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.medical_vault ENABLE ROW LEVEL SECURITY;

CREATE INDEX IF NOT EXISTS medical_vault_pet_id_idx ON public.medical_vault (pet_id);
-- Partial indexes on nullable date columns — small and fast for reminder queries
CREATE INDEX IF NOT EXISTS medical_vault_due_idx    ON public.medical_vault (pet_id, next_due_at)
  WHERE next_due_at IS NOT NULL;
CREATE INDEX IF NOT EXISTS medical_vault_expiry_idx ON public.medical_vault (pet_id, expires_at)
  WHERE expires_at IS NOT NULL;

CREATE TRIGGER medical_vault_updated_at
  BEFORE UPDATE ON public.medical_vault
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE POLICY "medical_vault: select by pet owner"
  ON public.medical_vault FOR SELECT TO authenticated
  USING (
    (SELECT auth.uid()) IN (
      SELECT owner_id FROM public.pets WHERE id = medical_vault.pet_id
    )
  );

CREATE POLICY "medical_vault: insert by pet owner"
  ON public.medical_vault FOR INSERT TO authenticated
  WITH CHECK (
    (SELECT auth.uid()) IN (
      SELECT owner_id FROM public.pets WHERE id = medical_vault.pet_id
    )
  );

CREATE POLICY "medical_vault: update by pet owner"
  ON public.medical_vault FOR UPDATE TO authenticated
  USING (
    (SELECT auth.uid()) IN (
      SELECT owner_id FROM public.pets WHERE id = medical_vault.pet_id
    )
  )
  WITH CHECK (
    (SELECT auth.uid()) IN (
      SELECT owner_id FROM public.pets WHERE id = medical_vault.pet_id
    )
  );

CREATE POLICY "medical_vault: delete by pet owner"
  ON public.medical_vault FOR DELETE TO authenticated
  USING (
    (SELECT auth.uid()) IN (
      SELECT owner_id FROM public.pets WHERE id = medical_vault.pet_id
    )
  );
