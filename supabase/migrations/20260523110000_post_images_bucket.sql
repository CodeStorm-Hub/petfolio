-- Creates the post-images storage bucket for social post photos.
-- Upload path: {auth.uid()}/{filename} — matches social_repository.dart uploadPostImage.
-- Public read; authenticated upload/update/delete scoped to first path segment = caller uid.

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'post-images',
  'post-images',
  true,
  10485760,
  ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif', 'image/heic']
)
ON CONFLICT (id) DO NOTHING;

CREATE POLICY "post-images: public read"
  ON storage.objects FOR SELECT TO anon, authenticated
  USING (bucket_id = 'post-images');

CREATE POLICY "post-images: authenticated upload"
  ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'post-images'
    AND (select auth.uid())::text = (string_to_array(name, '/'))[1]
  );

CREATE POLICY "post-images: owner update"
  ON storage.objects FOR UPDATE TO authenticated
  USING (
    bucket_id = 'post-images'
    AND (select auth.uid())::text = (string_to_array(name, '/'))[1]
  )
  WITH CHECK (
    bucket_id = 'post-images'
    AND (select auth.uid())::text = (string_to_array(name, '/'))[1]
  );

CREATE POLICY "post-images: owner delete"
  ON storage.objects FOR DELETE TO authenticated
  USING (
    bucket_id = 'post-images'
    AND (select auth.uid())::text = (string_to_array(name, '/'))[1]
  );
