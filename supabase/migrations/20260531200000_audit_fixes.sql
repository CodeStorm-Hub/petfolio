-- ================================================================
-- 20260531_audit_fixes.sql
--
-- Non-marketplace audit fixes:
--   4.8 medical-documents bucket admin read policy (optimized)
-- ================================================================

DROP POLICY IF EXISTS "medical-documents: admin read" ON storage.objects;

CREATE POLICY "medical-documents: admin read"
  ON storage.objects FOR SELECT TO authenticated
  USING (
    bucket_id = 'medical-documents'
    AND (select public.is_admin())
  );
