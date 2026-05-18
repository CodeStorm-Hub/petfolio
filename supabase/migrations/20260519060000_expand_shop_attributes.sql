ALTER TABLE public.shops
  ADD COLUMN IF NOT EXISTS business_email    text,
  ADD COLUMN IF NOT EXISTS business_phone    text,
  ADD COLUMN IF NOT EXISTS address_street    text,
  ADD COLUMN IF NOT EXISTS address_city      text,
  ADD COLUMN IF NOT EXISTS address_state     text,
  ADD COLUMN IF NOT EXISTS address_zip       text,
  ADD COLUMN IF NOT EXISTS return_policy     text,
  ADD COLUMN IF NOT EXISTS shipping_policy   text,
  ADD COLUMN IF NOT EXISTS social_links      jsonb DEFAULT '{}'::jsonb;
