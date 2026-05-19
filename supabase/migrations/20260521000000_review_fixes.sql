-- Corrective migration: PR #8 review feedback
-- Applies security fixes that were already landed in prior migrations.

-- ── 1. Fix is_admin(): SECURITY DEFINER is unnecessary — drop to INVOKER ──────

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

-- ── 2. Add missing kyc_owner_update policy ────────────────────────────────────
-- Vendors need UPDATE on their own kyc-documents folder so they can re-upload
-- rejected KYC documents (Supabase storage upsert requires UPDATE on existing objects).

DROP POLICY IF EXISTS "kyc_owner_update" ON storage.objects;

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

-- ── 3. Scope marketplace-images public read to explicit roles ─────────────────

DROP POLICY IF EXISTS "marketplace-images: public read" ON storage.objects;

CREATE POLICY "marketplace-images: public read"
  ON storage.objects FOR SELECT TO anon, authenticated
  USING (bucket_id = 'marketplace-images');

-- ── 4. Replace buyer cancel UPDATE policy with SECURITY DEFINER RPC ──────────
-- Direct UPDATE RLS cannot restrict which columns are mutated; a buyer could
-- overwrite financial/shipping columns while setting status = 'cancelled'.

DROP POLICY IF EXISTS "orders: buyer can cancel pending" ON public.marketplace_orders;

CREATE OR REPLACE FUNCTION public.cancel_order(p_order_id uuid)
  RETURNS void
  LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path = public
AS $$
BEGIN
  UPDATE public.marketplace_orders
    SET status = 'cancelled'
  WHERE id = p_order_id
    AND buyer_id = auth.uid()
    AND status = 'pending';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Order not found or cannot be cancelled';
  END IF;
END;
$$;

-- ── 5. Replace vendor update policy with SECURITY DEFINER RPC ────────────────
-- Same column-injection risk: vendor could overwrite buyer_id, total_cents, etc.
-- RPC restricts mutations to status and tracking fields only.

DROP POLICY IF EXISTS "orders: vendor can update shop orders" ON public.marketplace_orders;

CREATE OR REPLACE FUNCTION public.vendor_update_order(
  p_order_id        uuid,
  p_status          text,
  p_tracking_number text DEFAULT NULL,
  p_tracking_url    text DEFAULT NULL,
  p_carrier         text DEFAULT NULL
)
  RETURNS void
  LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path = public
AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM public.marketplace_orders o
    JOIN public.shops s ON s.id = o.shop_id
    WHERE o.id = p_order_id
      AND s.owner_id = auth.uid()
  ) THEN
    RAISE EXCEPTION 'Not authorized to update this order';
  END IF;

  UPDATE public.marketplace_orders
    SET
      status                   = p_status,
      shipping_tracking_number = COALESCE(p_tracking_number, shipping_tracking_number),
      shipping_tracking_url    = COALESCE(p_tracking_url,    shipping_tracking_url),
      shipping_carrier         = COALESCE(p_carrier,         shipping_carrier),
      shipped_at               = CASE WHEN p_status = 'shipped' THEN now() ELSE shipped_at END
  WHERE id = p_order_id;
END;
$$;
