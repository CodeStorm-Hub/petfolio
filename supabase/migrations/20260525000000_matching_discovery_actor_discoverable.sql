-- Fix matching_discovery_candidates to ensure actor is also discoverable
CREATE OR REPLACE FUNCTION public.matching_discovery_candidates(
  p_actor_pet_id UUID,
  p_radius_meters DOUBLE PRECISION DEFAULT 80467,
  p_limit INTEGER DEFAULT 20,
  p_offset INTEGER DEFAULT 0,
  p_species TEXT[] DEFAULT NULL,
  p_min_age_years INTEGER DEFAULT NULL,
  p_max_age_years INTEGER DEFAULT NULL
) RETURNS TABLE(
  id UUID,
  owner_id UUID,
  name TEXT,
  species TEXT,
  breed TEXT,
  date_of_birth DATE,
  avatar_url TEXT,
  bio TEXT,
  distance_meters DOUBLE PRECISION,
  is_discoverable BOOLEAN,
  owner JSONB
) AS $$
  WITH origin AS (
    SELECT p.location AS loc, p.owner_id
    FROM public.pets p
    WHERE p.id = p_actor_pet_id
      AND (SELECT auth.uid()) = p.owner_id
      AND p.is_discoverable IS TRUE
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
    c.is_discoverable,
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
    AND c.owner_id != o.owner_id
    AND c.is_public IS TRUE
    AND c.is_discoverable IS TRUE
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
      c.date_of_birth IS NULL
      OR (
        (p_min_age_years IS NULL
          OR date_part('year', age(current_date, c.date_of_birth))::int >= p_min_age_years)
        AND (p_max_age_years IS NULL
          OR date_part('year', age(current_date, c.date_of_birth))::int <= p_max_age_years)
      )
    )
  ORDER BY c.created_at DESC
  OFFSET greatest(coalesce(p_offset, 0), 0)
  LIMIT greatest(coalesce(nullif(p_limit, 0), 20), 1);
$$ LANGUAGE sql STABLE SECURITY DEFINER;
