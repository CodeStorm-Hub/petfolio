DROP FUNCTION IF EXISTS public.matching_discovery_candidates(
  uuid,
  double precision,
  integer,
  integer,
  text[],
  integer,
  integer
);

DROP FUNCTION IF EXISTS public.matching_discovery_candidates(
  uuid,
  double precision,
  integer,
  timestamptz,
  uuid,
  text[],
  integer,
  integer
);

CREATE OR REPLACE FUNCTION public.matching_discovery_candidates(
  p_actor_pet_id      uuid,
  p_radius_meters     double precision  DEFAULT 80467,
  p_limit             integer           DEFAULT 20,
  p_cursor_created_at timestamptz       DEFAULT NULL,
  p_cursor_pet_id     uuid              DEFAULT NULL,
  p_species           text[]            DEFAULT NULL,
  p_min_age_years     integer           DEFAULT NULL,
  p_max_age_years     integer           DEFAULT NULL
)
RETURNS TABLE (
  id                uuid,
  owner_id          uuid,
  name              text,
  species           text,
  breed             text,
  date_of_birth     date,
  avatar_url        text,
  bio               text,
  distance_meters   double precision,
  is_discoverable   boolean,
  created_at        timestamptz,
  owner             jsonb
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, extensions
AS $$
  WITH origin AS (
    SELECT p.location AS loc, p.owner_id
    FROM   public.pets p
    WHERE  p.id              = p_actor_pet_id
      AND  (select auth.uid()) = p.owner_id
      AND  p.is_discoverable IS TRUE
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
    c.created_at,
    owner_sub.owner_json AS owner
  FROM   origin o
  CROSS  JOIN public.pets c
  LEFT   JOIN public.swipes s
    ON   s.actor_id  = p_actor_pet_id
   AND   s.target_id = c.id
  LEFT   JOIN LATERAL (
    SELECT jsonb_build_object(
      'id',           u.id,
      'username',     u.username,
      'display_name', u.display_name
    ) AS owner_json
    FROM public.users u
    WHERE u.id = c.owner_id
    LIMIT 1
  ) owner_sub ON true
  WHERE  NOT (c.id = p_actor_pet_id)
    AND  c.owner_id        != o.owner_id
    AND  c.is_public       IS TRUE
    AND  c.is_discoverable IS TRUE
    AND  c.archived_at     IS NULL
    AND  c.location        IS NOT NULL
    AND  o.loc             IS NOT NULL
    AND  ST_DWithin(o.loc, c.location, p_radius_meters)
    AND  s.id IS NULL
    AND (
      p_cursor_created_at IS NULL
      OR c.created_at < p_cursor_created_at
      OR (c.created_at = p_cursor_created_at AND c.id < p_cursor_pet_id)
    )
    AND (
      p_species IS NULL
      OR cardinality(p_species) = 0
      OR lower(trim(c.species)) = ANY(
           SELECT lower(trim(s2)) FROM unnest(p_species) s2
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
  ORDER  BY c.created_at DESC, c.id DESC
  LIMIT  greatest(coalesce(nullif(p_limit, 0), 20), 1);
$$;

REVOKE ALL ON FUNCTION public.matching_discovery_candidates(
  uuid, double precision, integer, timestamptz, uuid, text[], integer, integer
) FROM PUBLIC;

REVOKE EXECUTE ON FUNCTION public.matching_discovery_candidates(
  uuid, double precision, integer, timestamptz, uuid, text[], integer, integer
) FROM anon;

GRANT EXECUTE ON FUNCTION public.matching_discovery_candidates(
  uuid, double precision, integer, timestamptz, uuid, text[], integer, integer
) TO authenticated;

GRANT EXECUTE ON FUNCTION public.matching_discovery_candidates(
  uuid, double precision, integer, timestamptz, uuid, text[], integer, integer
) TO service_role;
