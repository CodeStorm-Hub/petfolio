CREATE OR REPLACE FUNCTION public.set_pet_location_point(
  p_pet_id uuid,
  p_longitude double precision,
  p_latitude double precision
)
RETURNS void
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public, extensions
AS $$
BEGIN
  UPDATE public.pets
  SET location = ST_SetSRID(ST_MakePoint(p_longitude, p_latitude), 4326)::geography
  WHERE id = p_pet_id
    AND owner_id = auth.uid();
END;
$$;

GRANT EXECUTE ON FUNCTION public.set_pet_location_point(
  uuid,
  double precision,
  double precision
) TO authenticated;
