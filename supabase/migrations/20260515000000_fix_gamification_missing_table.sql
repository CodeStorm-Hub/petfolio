-- Fix for missing pet_care_gamification table
-- This table was referenced in a failing ALTER TABLE statement in Supabase CI.

CREATE TABLE IF NOT EXISTS public.pet_care_gamification (
  pet_id UUID PRIMARY KEY REFERENCES public.pets(id) ON DELETE CASCADE,
  daily_point_award_date DATE,
  daily_point_award_accrued INT NOT NULL DEFAULT 0,
  total_points INT NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Enable RLS
ALTER TABLE public.pet_care_gamification ENABLE ROW LEVEL SECURITY;

CREATE POLICY "pet_care_gamification: select by pet owner"
  ON public.pet_care_gamification FOR SELECT TO authenticated
  USING (
    pet_id IN (
      SELECT id FROM public.pets WHERE owner_id = (SELECT auth.uid())
    )
  );

CREATE POLICY "pet_care_gamification: insert by pet owner"
  ON public.pet_care_gamification FOR INSERT TO authenticated
  WITH CHECK (
    pet_id IN (
      SELECT id FROM public.pets WHERE owner_id = (SELECT auth.uid())
    )
  );

CREATE POLICY "pet_care_gamification: update by pet owner"
  ON public.pet_care_gamification FOR UPDATE TO authenticated
  USING (
    pet_id IN (
      SELECT id FROM public.pets WHERE owner_id = (SELECT auth.uid())
    )
  )
  WITH CHECK (
    pet_id IN (
      SELECT id FROM public.pets WHERE owner_id = (SELECT auth.uid())
    )
  );

CREATE POLICY "pet_care_gamification: delete by pet owner"
  ON public.pet_care_gamification FOR DELETE TO authenticated
  USING (
    pet_id IN (
      SELECT id FROM public.pets WHERE owner_id = (SELECT auth.uid())
    )
  );

GRANT SELECT, INSERT, UPDATE, DELETE ON public.pet_care_gamification TO authenticated;

DROP TRIGGER IF EXISTS pet_care_gamification_updated_at ON public.pet_care_gamification;
CREATE TRIGGER pet_care_gamification_updated_at
  BEFORE UPDATE ON public.pet_care_gamification
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
