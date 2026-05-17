CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA extensions;

ALTER TABLE public.pets
  ADD COLUMN IF NOT EXISTS location extensions.geography(POINT, 4326);

CREATE INDEX IF NOT EXISTS pets_location_gix
  ON public.pets USING gist (location)
  WHERE location IS NOT NULL;

CREATE TABLE public.swipes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  actor_id uuid NOT NULL REFERENCES public.pets(id) ON DELETE CASCADE,
  target_id uuid NOT NULL REFERENCES public.pets(id) ON DELETE CASCADE,
  action text NOT NULL CHECK (action IN ('LIKE', 'PASS')),
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT swipes_no_self_swipe CHECK (NOT (actor_id = target_id)),
  CONSTRAINT swipes_actor_target_unique UNIQUE (actor_id, target_id)
);

CREATE INDEX swipes_actor_idx ON public.swipes (actor_id);
CREATE INDEX swipes_target_actor_like_idx
  ON public.swipes (target_id, actor_id)
  WHERE action = 'LIKE';

ALTER TABLE public.swipes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "swipes: select by actor pet owner"
  ON public.swipes FOR SELECT TO authenticated
  USING (
    (SELECT auth.uid()) IN (
      SELECT p.owner_id FROM public.pets p WHERE p.id = swipes.actor_id
    )
  );

CREATE POLICY "swipes: insert by actor pet owner"
  ON public.swipes FOR INSERT TO authenticated
  WITH CHECK (
    (SELECT auth.uid()) IN (
      SELECT p.owner_id FROM public.pets p WHERE p.id = swipes.actor_id
    )
  );

CREATE TABLE public.matches (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  pet_a_id uuid NOT NULL REFERENCES public.pets(id) ON DELETE CASCADE,
  pet_b_id uuid NOT NULL REFERENCES public.pets(id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT matches_ordered_pair CHECK (NOT (pet_a_id >= pet_b_id)),
  CONSTRAINT matches_unique_pair UNIQUE (pet_a_id, pet_b_id)
);

CREATE INDEX matches_pet_a_idx ON public.matches (pet_a_id);
CREATE INDEX matches_pet_b_idx ON public.matches (pet_b_id);

ALTER TABLE public.matches ENABLE ROW LEVEL SECURITY;

CREATE POLICY "matches: select if either pet owned"
  ON public.matches FOR SELECT TO authenticated
  USING (
    (SELECT auth.uid()) IN (
      SELECT p.owner_id FROM public.pets p
      WHERE p.id IN (matches.pet_a_id, matches.pet_b_id)
    )
  );

CREATE OR REPLACE FUNCTION private.swipes_after_insert_mutual_match()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_a uuid;
  v_b uuid;
BEGIN
  IF NOT (NEW.action = 'LIKE') THEN
    RETURN NEW;
  END IF;

  IF EXISTS (
    SELECT 1
    FROM public.swipes s
    WHERE s.actor_id = NEW.target_id
      AND s.target_id = NEW.actor_id
      AND s.action = 'LIKE'
  ) THEN
    v_a := LEAST(NEW.actor_id, NEW.target_id);
    v_b := GREATEST(NEW.actor_id, NEW.target_id);

    INSERT INTO public.matches (pet_a_id, pet_b_id)
    VALUES (v_a, v_b)
    ON CONFLICT (pet_a_id, pet_b_id) DO NOTHING;
  END IF;

  RETURN NEW;
END;
$$;

REVOKE ALL ON FUNCTION private.swipes_after_insert_mutual_match() FROM PUBLIC;

CREATE TRIGGER swipes_after_insert_mutual_match
  AFTER INSERT ON public.swipes
  FOR EACH ROW
  EXECUTE FUNCTION private.swipes_after_insert_mutual_match();

CREATE OR REPLACE FUNCTION public.matching_discovery_candidates(
  p_actor_pet_id uuid,
  p_radius_meters double precision,
  p_limit integer DEFAULT 20
)
RETURNS TABLE (
  id uuid,
  owner_id uuid,
  name text,
  species text,
  breed text,
  date_of_birth date,
  avatar_url text,
  bio text,
  distance_meters double precision,
  owner jsonb
)
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = public, extensions
AS $$
  WITH origin AS (
    SELECT p.location AS loc
    FROM public.pets p
    WHERE p.id = p_actor_pet_id
      AND (SELECT auth.uid()) = p.owner_id
  )
  SELECT
    c.id,
    c.owner_id,
    c.name,
    c.species,
    c.breed,
    c.date_of_birth,
    c.avatar_url,
    c.bio,
    ST_Distance(o.loc, c.location)::double precision AS distance_meters,
    (
      SELECT jsonb_build_object(
        'id', u.id,
        'username', u.username,
        'display_name', u.display_name
      )
      FROM public.users u
      WHERE u.id = c.owner_id
    ) AS owner
  FROM origin o
  CROSS JOIN public.pets c
  LEFT JOIN public.swipes s
    ON s.actor_id = p_actor_pet_id
   AND s.target_id = c.id
  WHERE NOT (c.id = p_actor_pet_id)
    AND c.is_public IS TRUE
    AND c.archived_at IS NULL
    AND c.location IS NOT NULL
    AND o.loc IS NOT NULL
    AND ST_DWithin(o.loc, c.location, p_radius_meters)
    AND s.id IS NULL
  ORDER BY c.created_at DESC
  LIMIT greatest(coalesce(nullif(p_limit, 0), 20), 1);
$$;

GRANT EXECUTE ON FUNCTION public.matching_discovery_candidates(uuid, double precision, integer)
  TO authenticated;

GRANT SELECT, INSERT ON public.swipes TO authenticated;
GRANT SELECT ON public.matches TO authenticated;
