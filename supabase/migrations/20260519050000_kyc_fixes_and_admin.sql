-- Index on shops.kyc_status for admin dashboard queries
create index if not exists idx_shops_kyc_status on public.shops (kyc_status);

-- NOTE: Admin privileges are NOT granted via migration.
-- Set is_admin = true in app_metadata via Supabase Dashboard → Authentication → Users
-- or via a local seed script that is NOT committed to the repository.
