INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'pets',
  'pets',
  true,
  5242880,
  ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/heic', 'image/jpg']
)
ON CONFLICT (id) DO UPDATE SET
  public = EXCLUDED.public,
  file_size_limit = EXCLUDED.file_size_limit,
  allowed_mime_types = EXCLUDED.allowed_mime_types;

DROP POLICY IF EXISTS "pets: owner insert avatar" ON storage.objects;
DROP POLICY IF EXISTS "pets: owner update avatar" ON storage.objects;
DROP POLICY IF EXISTS "pets: owner delete avatar" ON storage.objects;

CREATE POLICY "pets: owner insert avatar"
  ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'pets'
    AND EXISTS (
      SELECT 1 FROM public.pets
      WHERE pets.id::text = (string_to_array(name, '/'))[1]
        AND pets.owner_id = (SELECT auth.uid())
    )
  );

CREATE POLICY "pets: owner update avatar"
  ON storage.objects FOR UPDATE TO authenticated
  USING (
    bucket_id = 'pets'
    AND EXISTS (
      SELECT 1 FROM public.pets
      WHERE pets.id::text = (string_to_array(name, '/'))[1]
        AND pets.owner_id = (SELECT auth.uid())
    )
  )
  WITH CHECK (
    bucket_id = 'pets'
    AND EXISTS (
      SELECT 1 FROM public.pets
      WHERE pets.id::text = (string_to_array(name, '/'))[1]
        AND pets.owner_id = (SELECT auth.uid())
    )
  );

CREATE POLICY "pets: owner delete avatar"
  ON storage.objects FOR DELETE TO authenticated
  USING (
    bucket_id = 'pets'
    AND EXISTS (
      SELECT 1 FROM public.pets
      WHERE pets.id::text = (string_to_array(name, '/'))[1]
        AND pets.owner_id = (SELECT auth.uid())
    )
  );
