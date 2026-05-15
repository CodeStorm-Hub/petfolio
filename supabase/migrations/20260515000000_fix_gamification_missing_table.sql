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

-- Policies
CREATE POLICY "pet_care_gamification: select by pet owner"
  ON public.pet_care_gamification FOR SELECT
  USING (
    pet_id IN (
      SELECT id FROM public.pets WHERE owner_id = (SELECT auth.uid())
    )
  );

-- Grant access
GRANT SELECT, INSERT, UPDATE, DELETE ON public.pet_care_gamification TO authenticated;
