-- ─────────────────────────────────────────────────────────────────────────────
-- 1. products.inventory_count — remove DEFAULT 0
--
-- Vendors must now explicitly supply inventory_count when listing a product.
-- The NOT NULL + CHECK (>= 0) constraints remain. Existing rows (including
-- the 8 seed products with inventory_count = 0) are unaffected.
-- ─────────────────────────────────────────────────────────────────────────────

ALTER TABLE public.products
  ALTER COLUMN inventory_count DROP DEFAULT;

-- ─────────────────────────────────────────────────────────────────────────────
-- 2. Hourly pg_cron job: cleanup_expired_stories
--
-- Requires the pg_cron extension to be enabled (pg_cron 1.6.4 confirmed).
-- Deletes story rows older than 24 hours every hour on the hour.
-- Idempotent: unschedule guards against duplicate registration on re-runs.
-- ─────────────────────────────────────────────────────────────────────────────

SELECT cron.unschedule('cleanup-expired-stories')
WHERE EXISTS (
  SELECT 1 FROM cron.job WHERE jobname = 'cleanup-expired-stories'
);

SELECT cron.schedule(
  'cleanup-expired-stories',
  '0 * * * *',
  'SELECT public.cleanup_expired_stories()'
);
