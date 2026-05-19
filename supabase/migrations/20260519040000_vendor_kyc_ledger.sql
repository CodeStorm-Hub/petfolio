-- Migration: vendor KYC, payout method, CoD payment support, vendor ledger, KYC bucket

-- ─── Enums ───────────────────────────────────────────────────────────────────

DO $$ BEGIN
  CREATE TYPE public.payout_method_enum   AS ENUM ('stripe', 'manual');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE public.kyc_status_enum      AS ENUM ('pending', 'submitted', 'approved', 'rejected');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE public.payment_method_enum  AS ENUM ('stripe', 'cod');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE public.payment_status_enum  AS ENUM ('pending', 'paid', 'collected');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE public.ledger_status_enum   AS ENUM ('pending_clearance', 'available', 'paid');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- ─── shops: new KYC + payout columns ─────────────────────────────────────────

ALTER TABLE public.shops
  ADD COLUMN IF NOT EXISTS payout_method       public.payout_method_enum NOT NULL DEFAULT 'stripe',
  ADD COLUMN IF NOT EXISTS kyc_status          public.kyc_status_enum    NOT NULL DEFAULT 'pending',
  ADD COLUMN IF NOT EXISTS trade_license_url   text,
  ADD COLUMN IF NOT EXISTS national_id_url     text,
  ADD COLUMN IF NOT EXISTS rejection_reason    text,
  ADD COLUMN IF NOT EXISTS bank_account_details jsonb;

-- ─── marketplace_orders: payment method + status ─────────────────────────────

ALTER TABLE public.marketplace_orders
  ADD COLUMN IF NOT EXISTS payment_method  public.payment_method_enum  NOT NULL DEFAULT 'stripe',
  ADD COLUMN IF NOT EXISTS payment_status  public.payment_status_enum  NOT NULL DEFAULT 'pending';

-- ─── vendor_ledgers ───────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.vendor_ledgers (
  id                    uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  shop_id               uuid        NOT NULL REFERENCES public.shops(id)               ON DELETE CASCADE,
  order_id              uuid        NOT NULL REFERENCES public.marketplace_orders(id)  ON DELETE CASCADE,
  order_total_cents     bigint      NOT NULL CHECK (order_total_cents  > 0),
  platform_fee_cents    bigint      NOT NULL CHECK (platform_fee_cents >= 0),
  vendor_earnings_cents bigint      NOT NULL CHECK (vendor_earnings_cents >= 0),
  status                public.ledger_status_enum NOT NULL DEFAULT 'pending_clearance',
  created_at            timestamptz NOT NULL DEFAULT now(),
  updated_at            timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.vendor_ledgers ENABLE ROW LEVEL SECURITY;

CREATE INDEX IF NOT EXISTS vendor_ledgers_shop_id_idx  ON public.vendor_ledgers (shop_id);
CREATE INDEX IF NOT EXISTS vendor_ledgers_order_id_idx ON public.vendor_ledgers (order_id);
CREATE INDEX IF NOT EXISTS vendor_ledgers_status_idx   ON public.vendor_ledgers (status);

-- ─── Admin helper (reads is_admin from JWT app_metadata) ─────────────────────

CREATE OR REPLACE FUNCTION public.is_admin()
  RETURNS boolean
  LANGUAGE sql
  STABLE
  SECURITY INVOKER
AS $$
  SELECT coalesce(
    (auth.jwt() -> 'app_metadata' ->> 'is_admin')::boolean,
    false
  );
$$;

-- ─── RLS: shops — admin full access ──────────────────────────────────────────

DROP POLICY IF EXISTS "admins_select_shops"  ON public.shops;
DROP POLICY IF EXISTS "admins_update_shops"  ON public.shops;
DROP POLICY IF EXISTS "admins_delete_shops"  ON public.shops;

CREATE POLICY "admins_select_shops" ON public.shops
  FOR SELECT TO authenticated
  USING (public.is_admin());

CREATE POLICY "admins_update_shops" ON public.shops
  FOR UPDATE TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

CREATE POLICY "admins_delete_shops" ON public.shops
  FOR DELETE TO authenticated
  USING (public.is_admin());

-- ─── RLS: marketplace_orders — admin full access ──────────────────────────────

DROP POLICY IF EXISTS "admins_select_orders" ON public.marketplace_orders;
DROP POLICY IF EXISTS "admins_update_orders" ON public.marketplace_orders;
DROP POLICY IF EXISTS "admins_delete_orders" ON public.marketplace_orders;

CREATE POLICY "admins_select_orders" ON public.marketplace_orders
  FOR SELECT TO authenticated
  USING (public.is_admin());

CREATE POLICY "admins_update_orders" ON public.marketplace_orders
  FOR UPDATE TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

CREATE POLICY "admins_delete_orders" ON public.marketplace_orders
  FOR DELETE TO authenticated
  USING (public.is_admin());

-- ─── RLS: vendor_ledgers ──────────────────────────────────────────────────────

-- Shop owner reads their own ledger entries
CREATE POLICY "shop_owner_select_ledger" ON public.vendor_ledgers
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.shops
      WHERE shops.id = vendor_ledgers.shop_id
        AND shops.owner_id = auth.uid()
    )
  );

-- Admin full access
CREATE POLICY "admins_select_ledger" ON public.vendor_ledgers
  FOR SELECT TO authenticated
  USING (public.is_admin());

CREATE POLICY "admins_insert_ledger" ON public.vendor_ledgers
  FOR INSERT TO authenticated
  WITH CHECK (public.is_admin());

CREATE POLICY "admins_update_ledger" ON public.vendor_ledgers
  FOR UPDATE TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

CREATE POLICY "admins_delete_ledger" ON public.vendor_ledgers
  FOR DELETE TO authenticated
  USING (public.is_admin());

-- ─── Storage: kyc-documents bucket ───────────────────────────────────────────

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'kyc-documents',
  'kyc-documents',
  false,
  10485760,
  ARRAY['image/jpeg', 'image/png', 'image/webp', 'application/pdf']
)
ON CONFLICT (id) DO NOTHING;

-- Owners upload to their own folder: kyc-documents/{user_id}/...
DROP POLICY IF EXISTS "kyc_owner_upload"  ON storage.objects;
DROP POLICY IF EXISTS "kyc_owner_read"    ON storage.objects;
DROP POLICY IF EXISTS "kyc_owner_update"  ON storage.objects;
DROP POLICY IF EXISTS "kyc_admin_read"    ON storage.objects;
DROP POLICY IF EXISTS "kyc_admin_delete"  ON storage.objects;

CREATE POLICY "kyc_owner_upload" ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'kyc-documents'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

CREATE POLICY "kyc_owner_read" ON storage.objects
  FOR SELECT TO authenticated
  USING (
    bucket_id = 'kyc-documents'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

CREATE POLICY "kyc_owner_update" ON storage.objects
  FOR UPDATE TO authenticated
  USING (
    bucket_id = 'kyc-documents'
    AND (storage.foldername(name))[1] = auth.uid()::text
  )
  WITH CHECK (
    bucket_id = 'kyc-documents'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

CREATE POLICY "kyc_admin_read" ON storage.objects
  FOR SELECT TO authenticated
  USING (
    bucket_id = 'kyc-documents'
    AND public.is_admin()
  );

CREATE POLICY "kyc_admin_delete" ON storage.objects
  FOR DELETE TO authenticated
  USING (
    bucket_id = 'kyc-documents'
    AND public.is_admin()
  );
