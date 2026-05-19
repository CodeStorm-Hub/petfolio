-- ─────────────────────────────────────────────────────────────────────────────
-- Migration: marketplace_images_bucket
-- Creates the marketplace-images storage bucket for vendor product photos.
-- Sets public read, authenticated upload (path-scoped to {userId}/*),
-- and owner-only update/delete policies.
-- ─────────────────────────────────────────────────────────────────────────────

-- ── 1. Create bucket ──────────────────────────────────────────────────────────

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'marketplace-images',
  'marketplace-images',
  true,
  5242880,
  ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif']
)
ON CONFLICT (id) DO NOTHING;

-- ── 2. Public read ────────────────────────────────────────────────────────────
-- All product images are public — no auth needed to view them.

CREATE POLICY "marketplace-images: public read"
  ON storage.objects FOR SELECT TO anon, authenticated
  USING (bucket_id = 'marketplace-images');

-- ── 3. Authenticated upload ───────────────────────────────────────────────────
-- Vendors upload product images under their own user-ID path prefix so that
-- RLS ownership checks are trivially derived from the file path.
-- Expected path format: {userId}/{filename}  e.g. "abc-123/product-photo.jpg"

CREATE POLICY "marketplace-images: authenticated upload"
  ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'marketplace-images'
    AND (select auth.uid())::text = (string_to_array(name, '/'))[1]
  );

-- ── 4. Owner update (replace) ────────────────────────────────────────────────

CREATE POLICY "marketplace-images: owner update"
  ON storage.objects FOR UPDATE TO authenticated
  USING (
    bucket_id = 'marketplace-images'
    AND (select auth.uid())::text = (string_to_array(name, '/'))[1]
  )
  WITH CHECK (
    bucket_id = 'marketplace-images'
    AND (select auth.uid())::text = (string_to_array(name, '/'))[1]
  );

-- ── 5. Owner delete ───────────────────────────────────────────────────────────

CREATE POLICY "marketplace-images: owner delete"
  ON storage.objects FOR DELETE TO authenticated
  USING (
    bucket_id = 'marketplace-images'
    AND (select auth.uid())::text = (string_to_array(name, '/'))[1]
  );
