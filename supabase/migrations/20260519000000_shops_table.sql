-- ─────────────────────────────────────────────────────────────────────────────
-- Migration: shops_table
-- Creates the shops table for the multi-vendor marketplace.
-- Seeds the PetFolio Official service account (auth.users + public.users)
-- and its corresponding shop row so existing products can be migrated in the
-- next migration.
-- ─────────────────────────────────────────────────────────────────────────────

-- ── 1. PetFolio Official service account ─────────────────────────────────────
-- A static system user that owns the PetFolio Official shop.
-- UUID: 00000000-0000-0000-0000-000000000001
-- ON CONFLICT DO NOTHING makes this idempotent on re-runs.

INSERT INTO auth.users (
  id,
  instance_id,
  email,
  encrypted_password,
  email_confirmed_at,
  created_at,
  updated_at,
  raw_user_meta_data,
  raw_app_meta_data,
  is_super_admin,
  role,
  aud
)
VALUES (
  '00000000-0000-0000-0000-000000000001',
  '00000000-0000-0000-0000-000000000000',
  'system@petfolio.internal',
  '',
  now(), now(), now(),
  '{"username":"petfolio_official","display_name":"PetFolio Official"}'::jsonb,
  '{"provider":"email","providers":["email"]}'::jsonb,
  false,
  'authenticated',
  'authenticated'
)
ON CONFLICT (id) DO NOTHING;

-- Mirror into public.users explicitly in case the trigger doesn't fire
-- inside the migration transaction context.
INSERT INTO public.users (id, username, display_name)
VALUES (
  '00000000-0000-0000-0000-000000000001',
  'petfolio_official',
  'PetFolio Official'
)
ON CONFLICT (id) DO NOTHING;

-- ── 2. shops table ────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.shops (
  id                         uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id                   uuid        NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
  shop_name                  text        NOT NULL,
  slug                       text        NOT NULL UNIQUE,
  description                text,
  logo_url                   text,
  banner_url                 text,
  is_active                  boolean     NOT NULL DEFAULT true,
  is_verified                boolean     NOT NULL DEFAULT false,
  stripe_connect_account_id  text        UNIQUE,
  stripe_onboarding_complete boolean     NOT NULL DEFAULT false,
  platform_fee_percent       integer     NOT NULL DEFAULT 10
                               CHECK (platform_fee_percent BETWEEN 0 AND 100),
  created_at                 timestamptz NOT NULL DEFAULT now(),
  updated_at                 timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.shops ENABLE ROW LEVEL SECURITY;

-- ── 3. RLS policies ───────────────────────────────────────────────────────────

-- Any authenticated user can browse active + verified shops (for storefront).
CREATE POLICY "shops: select active verified"
  ON public.shops FOR SELECT TO authenticated
  USING (is_active = true AND is_verified = true);

-- Owner can always read their own shop (even if unverified / inactive).
CREATE POLICY "shops: owner can select own"
  ON public.shops FOR SELECT TO authenticated
  USING ((select auth.uid()) = owner_id);

-- Owner can create their shop. The UNIQUE constraint on owner_id is the
-- DB-level guard that prevents a second shop per user.
CREATE POLICY "shops: owner can insert"
  ON public.shops FOR INSERT TO authenticated
  WITH CHECK ((select auth.uid()) = owner_id);

-- Owner can update their own shop (name, description, logo, banner).
-- is_verified and stripe_connect_account_id are set only via service role
-- in Edge Functions — the authenticated UPDATE policy cannot bypass RLS
-- to set those fields because the WITH CHECK condition is the same as USING.
CREATE POLICY "shops: owner can update"
  ON public.shops FOR UPDATE TO authenticated
  USING  ((select auth.uid()) = owner_id)
  WITH CHECK ((select auth.uid()) = owner_id);

-- No DELETE policy: shops are deactivated (is_active = false) to preserve
-- the order history that references them.

-- ── 4. updated_at trigger ─────────────────────────────────────────────────────

CREATE OR REPLACE TRIGGER set_updated_at_shops
  BEFORE UPDATE ON public.shops
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- ── 5. Indexes ────────────────────────────────────────────────────────────────
-- owner_id is already covered by its UNIQUE constraint index.
-- slug is already covered by its UNIQUE constraint index.

CREATE INDEX IF NOT EXISTS idx_shops_stripe_account
  ON public.shops(stripe_connect_account_id)
  WHERE stripe_connect_account_id IS NOT NULL;

-- ── 6. Grants ─────────────────────────────────────────────────────────────────

GRANT SELECT           ON public.shops TO anon, authenticated;
GRANT INSERT, UPDATE   ON public.shops TO authenticated;

-- ── 7. Seed: PetFolio Official shop ──────────────────────────────────────────
-- Fixed UUID: cccccccc-0000-0000-0000-cccccccccccc
-- is_verified = true, stripe_onboarding_complete = true:
--   platform products do not route through Stripe Connect.
-- platform_fee_percent = 0: the platform takes no fee from itself.

INSERT INTO public.shops (
  id,
  owner_id,
  shop_name,
  slug,
  description,
  is_active,
  is_verified,
  stripe_onboarding_complete,
  platform_fee_percent
)
VALUES (
  'cccccccc-0000-0000-0000-cccccccccccc',
  '00000000-0000-0000-0000-000000000001',
  'PetFolio Official',
  'petfolio-official',
  'Curated products from the PetFolio team.',
  true,
  true,
  true,
  0
)
ON CONFLICT (id) DO NOTHING;
