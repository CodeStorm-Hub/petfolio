-- ─────────────────────────────────────────────────────────────────────────────
-- Migration: orders_vendor_columns
-- Adds shop_id and shipping/tracking columns to marketplace_orders.
-- Updates the order status CHECK to the new 5-value lifecycle.
-- Replaces combined buyer+seller RLS policies with separate buyer and vendor
-- policies now that vendor access is scoped through the shops table.
-- ─────────────────────────────────────────────────────────────────────────────

-- ── 1. Add shop_id and shipping/tracking columns ──────────────────────────────

ALTER TABLE public.marketplace_orders
  ADD COLUMN IF NOT EXISTS shop_id                  uuid
    REFERENCES public.shops(id) ON DELETE RESTRICT,
  ADD COLUMN IF NOT EXISTS shipping_tracking_number text,
  ADD COLUMN IF NOT EXISTS shipping_tracking_url    text,
  ADD COLUMN IF NOT EXISTS shipping_carrier         text,
  ADD COLUMN IF NOT EXISTS shipped_at               timestamptz;

-- ── 2. Migrate existing order(s) to PetFolio Official shop ───────────────────

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM public.shops WHERE id = 'cccccccc-0000-0000-0000-cccccccccccc') THEN
    RAISE EXCEPTION 'PetFolio Official shop seed (cccccccc-0000-0000-0000-cccccccccccc) not found — run 20260519000000_shops_table.sql first';
  END IF;
END $$;

UPDATE public.marketplace_orders
  SET shop_id = 'cccccccc-0000-0000-0000-cccccccccccc'
  WHERE shop_id IS NULL;

-- ── 3. Enforce NOT NULL now that all rows have a shop ────────────────────────

ALTER TABLE public.marketplace_orders
  ALTER COLUMN shop_id SET NOT NULL;

-- ── 4. Update status CHECK to the new 5-value lifecycle ──────────────────────
-- Old values: pending | confirmed | shipped | delivered | cancelled | refunded
-- New values: pending | processing | shipped | delivered | cancelled
-- Migrate any rows using removed statuses before altering the constraint.

UPDATE public.marketplace_orders SET status = 'processing' WHERE status = 'confirmed';
UPDATE public.marketplace_orders SET status = 'cancelled'  WHERE status = 'refunded';

ALTER TABLE public.marketplace_orders
  DROP CONSTRAINT IF EXISTS marketplace_orders_status_check;

ALTER TABLE public.marketplace_orders
  ADD CONSTRAINT marketplace_orders_status_check
  CHECK (status IN ('pending', 'processing', 'shipped', 'delivered', 'cancelled'));

-- ── 5. Index ──────────────────────────────────────────────────────────────────

CREATE INDEX IF NOT EXISTS idx_orders_shop_id ON public.marketplace_orders(shop_id);

-- ── 6. Replace the old combined RLS policies ─────────────────────────────────
-- These were defined in schema.sql and reference the now-removed seller_id
-- semantics. Drop and replace with buyer + vendor variants.

DROP POLICY IF EXISTS "orders: select by buyer or seller" ON public.marketplace_orders;
DROP POLICY IF EXISTS "orders: update by buyer or seller" ON public.marketplace_orders;

-- Buyer sees their own orders.
CREATE POLICY "orders: buyer can select own"
  ON public.marketplace_orders FOR SELECT TO authenticated
  USING ((select auth.uid()) = buyer_id);

-- Vendor (shop owner) sees all orders placed with their shop.
CREATE POLICY "orders: vendor can select shop orders"
  ON public.marketplace_orders FOR SELECT TO authenticated
  USING (
    (select auth.uid()) = (
      SELECT owner_id FROM public.shops WHERE id = shop_id
    )
  );

-- Buyer order cancellation is routed through a SECURITY DEFINER RPC that only
-- touches the status column, preventing column-injection via the UPDATE policy.
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

-- Vendor order updates are routed through a SECURITY DEFINER RPC that only
-- allows mutating status and tracking fields, preventing financial field injection.
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
