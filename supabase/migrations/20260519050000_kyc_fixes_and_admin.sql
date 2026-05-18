-- Index on shops.kyc_status for admin dashboard queries
create index if not exists idx_shops_kyc_status on public.shops (kyc_status);

-- Grant admin privileges to syed.reza181@gmail.com via app metadata
update auth.users
set raw_app_meta_data = coalesce(raw_app_meta_data, '{}'::jsonb) || '{"is_admin": true}'::jsonb
where email = 'syed.reza181@gmail.com';
