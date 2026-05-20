INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'medical-documents',
  'medical-documents',
  false,
  10485760,
  ARRAY['image/jpeg', 'image/png', 'image/webp', 'application/pdf']
)
ON CONFLICT (id) DO NOTHING;

CREATE POLICY "medical-documents: owner read"
  ON storage.objects FOR SELECT TO authenticated
  USING (
    bucket_id = 'medical-documents'
    AND (select auth.uid())::text = (string_to_array(name, '/'))[1]
  );

CREATE POLICY "medical-documents: owner insert"
  ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'medical-documents'
    AND (select auth.uid())::text = (string_to_array(name, '/'))[1]
  );

CREATE POLICY "medical-documents: owner update"
  ON storage.objects FOR UPDATE TO authenticated
  USING (
    bucket_id = 'medical-documents'
    AND (select auth.uid())::text = (string_to_array(name, '/'))[1]
  )
  WITH CHECK (
    bucket_id = 'medical-documents'
    AND (select auth.uid())::text = (string_to_array(name, '/'))[1]
  );

CREATE POLICY "medical-documents: owner delete"
  ON storage.objects FOR DELETE TO authenticated
  USING (
    bucket_id = 'medical-documents'
    AND (select auth.uid())::text = (string_to_array(name, '/'))[1]
  );
