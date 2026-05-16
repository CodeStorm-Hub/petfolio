DROP FUNCTION IF EXISTS public.matching_discovery_candidates(uuid, double precision, integer);

CREATE OR REPLACE FUNCTION public.matching_discovery_candidates(
  p_actor_pet_id uuid,
  p_radius_meters double precision,
  p_limit integer DEFAULT 20,
  p_offset integer DEFAULT 0,
  p_species text[] DEFAULT NULL,
  p_min_age_years integer DEFAULT NULL,
  p_max_age_years integer DEFAULT NULL
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
    AND (
      p_species IS NULL
      OR cardinality(p_species) = 0
      OR EXISTS (
        SELECT 1
        FROM unnest(p_species) AS u(species_text)
        WHERE lower(trim(species_text)) = lower(trim(c.species))
      )
    )
    AND (
      (p_min_age_years IS NULL AND p_max_age_years IS NULL)
      OR (
        c.date_of_birth IS NOT NULL
        AND (
          p_min_age_years IS NULL
          OR date_part('year', age(current_date, c.date_of_birth))::int >= p_min_age_years
        )
        AND (
          p_max_age_years IS NULL
          OR date_part('year', age(current_date, c.date_of_birth))::int <= p_max_age_years
        )
      )
    )
  ORDER BY c.created_at DESC
  OFFSET greatest(coalesce(p_offset, 0), 0)
  LIMIT greatest(coalesce(nullif(p_limit, 0), 20), 1);
$$;

GRANT EXECUTE ON FUNCTION public.matching_discovery_candidates(
  uuid,
  double precision,
  integer,
  integer,
  text[],
  integer,
  integer
) TO authenticated;
