-- ─────────────────────────────────────────────────────────────────────────────
-- Phase 4 — Commerce: Product Variants, Wishlist, Prescriptions, Shipments
-- ─────────────────────────────────────────────────────────────────────────────

-- ── 1. products.is_rx ─────────────────────────────────────────────────────────
ALTER TABLE public.products
  ADD COLUMN IF NOT EXISTS is_rx boolean NOT NULL DEFAULT false;

-- ── 2. product_variants ───────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.product_variants (
  id          uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id  uuid        NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
  sku         text,
  attributes  jsonb       NOT NULL DEFAULT '{}',
  price_cents int         NOT NULL CHECK (price_cents > 0),
  stock       int         NOT NULL DEFAULT 0 CHECK (stock >= 0),
  is_active   boolean     NOT NULL DEFAULT true,
  created_at  timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS product_variants_product_id_idx
  ON public.product_variants (product_id)
  WHERE is_active = true;

ALTER TABLE public.product_variants ENABLE ROW LEVEL SECURITY;

CREATE POLICY "variants: public read active"
  ON public.product_variants FOR SELECT
  USING (is_active = true);

CREATE POLICY "variants: vendor insert"
  ON public.product_variants FOR INSERT TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.products p
      JOIN  public.shops s ON s.id = p.shop_id
      WHERE p.id = product_id AND s.owner_id = (SELECT auth.uid())
    )
  );

CREATE POLICY "variants: vendor update"
  ON public.product_variants FOR UPDATE TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.products p
      JOIN  public.shops s ON s.id = p.shop_id
      WHERE p.id = product_id AND s.owner_id = (SELECT auth.uid())
    )
  );

-- ── 3. inventory_reservations — add variant_id ────────────────────────────────
ALTER TABLE public.inventory_reservations
  ADD COLUMN IF NOT EXISTS variant_id uuid
    REFERENCES public.product_variants(id) ON DELETE SET NULL;

-- Replace old single unique index with two partial unique indexes that handle
-- NULL vs non-NULL variant_id correctly (NULLs are not equal in UNIQUE).
DROP INDEX IF EXISTS public.inventory_reservations_order_product_active_idx;

CREATE UNIQUE INDEX IF NOT EXISTS inv_res_order_product_no_variant_idx
  ON public.inventory_reservations (order_id, product_id)
  WHERE status = 'active' AND variant_id IS NULL;

CREATE UNIQUE INDEX IF NOT EXISTS inv_res_order_product_variant_idx
  ON public.inventory_reservations (order_id, product_id, variant_id)
  WHERE status = 'active' AND variant_id IS NOT NULL;

-- ── 4. process_checkout — variant-aware replacement ───────────────────────────
CREATE OR REPLACE FUNCTION public.process_checkout(
  p_buyer_id   uuid,
  p_shop_id    uuid,
  p_cart_items jsonb
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_order_id      uuid;
  v_amount_cents  bigint  := 0;
  v_item          jsonb;
  v_product_id    uuid;
  v_variant_id    uuid;
  v_quantity      int;
  v_is_subscribed boolean;
  v_unit_cents    bigint;
  v_line_total    bigint;
  v_inv_count     int;
  v_reserved      int;
  v_product_name  text;
  v_price_cents   bigint;
  v_sub_price     bigint;
  v_is_rx         boolean;
  v_shop_active   boolean;
  v_shop_verified boolean;
  v_line_items    jsonb := '[]'::jsonb;
BEGIN
  IF p_buyer_id IS DISTINCT FROM (SELECT auth.uid()) THEN
    RAISE EXCEPTION 'buyer_id mismatch';
  END IF;

  SELECT is_active, is_verified
  INTO   v_shop_active, v_shop_verified
  FROM   public.shops
  WHERE  id = p_shop_id;

  IF NOT FOUND          THEN RAISE EXCEPTION 'Shop not found';    END IF;
  IF NOT v_shop_active   THEN RAISE EXCEPTION 'SHOP_INACTIVE';     END IF;
  IF NOT v_shop_verified THEN RAISE EXCEPTION 'SHOP_NOT_VERIFIED'; END IF;

  FOR v_item IN SELECT value FROM jsonb_array_elements(p_cart_items)
  LOOP
    v_product_id    := (v_item->>'product_id')::uuid;
    v_quantity      := (v_item->>'quantity')::int;
    v_is_subscribed := COALESCE((v_item->>'is_subscribed')::boolean, false);
    v_variant_id    := NULLIF(v_item->>'variant_id', '')::uuid;

    IF v_variant_id IS NOT NULL THEN
      SELECT pv.price_cents, pv.stock, p.name, p.is_rx
      INTO   v_price_cents, v_inv_count, v_product_name, v_is_rx
      FROM   public.product_variants pv
      JOIN   public.products p ON p.id = pv.product_id
      WHERE  pv.id         = v_variant_id
        AND  pv.product_id = v_product_id
        AND  p.shop_id     = p_shop_id
        AND  p.active      = true
        AND  pv.is_active  = true
      FOR UPDATE OF pv;

      IF NOT FOUND THEN
        RAISE EXCEPTION 'PRODUCT_UNAVAILABLE:%', v_product_id;
      END IF;

      v_sub_price := ROUND(v_price_cents::numeric * 0.88)::bigint;

      SELECT COALESCE(SUM(quantity), 0) INTO v_reserved
      FROM   public.inventory_reservations
      WHERE  variant_id = v_variant_id
        AND  status     = 'active'
        AND  expires_at > now();
    ELSE
      SELECT name,
             price_cents,
             COALESCE(sub_price_cents, ROUND(price_cents::numeric * 0.88)::bigint),
             inventory_count,
             is_rx
      INTO   v_product_name, v_price_cents, v_sub_price, v_inv_count, v_is_rx
      FROM   public.products
      WHERE  id      = v_product_id
        AND  shop_id = p_shop_id
        AND  active  = true
      FOR UPDATE;

      IF NOT FOUND THEN
        RAISE EXCEPTION 'PRODUCT_UNAVAILABLE:%', v_product_id;
      END IF;

      SELECT COALESCE(SUM(quantity), 0) INTO v_reserved
      FROM   public.inventory_reservations
      WHERE  product_id = v_product_id
        AND  variant_id IS NULL
        AND  status     = 'active'
        AND  expires_at > now();
    END IF;

    IF (v_inv_count - v_reserved) < v_quantity THEN
      RAISE EXCEPTION 'INSUFFICIENT_STOCK:%:%:%',
        v_product_name,
        GREATEST(v_inv_count - v_reserved, 0),
        v_quantity;
    END IF;

    v_unit_cents := CASE WHEN v_is_subscribed THEN v_sub_price ELSE v_price_cents END;
    v_line_total   := v_unit_cents * v_quantity;
    v_amount_cents := v_amount_cents + v_line_total;

    v_line_items := v_line_items || jsonb_build_object(
      'product_id',       v_product_id,
      'product_name',     v_product_name,
      'shop_id',          p_shop_id,
      'quantity',         v_quantity,
      'unit_cents',       v_unit_cents,
      'line_total_cents', v_line_total,
      'is_subscribed',    v_is_subscribed,
      'frequency_weeks',  COALESCE((v_item->>'frequency_weeks')::int, 0),
      'variant_id',       v_variant_id,
      'is_rx',            COALESCE(v_is_rx, false)
    );
  END LOOP;

  INSERT INTO public.marketplace_orders (
    buyer_id, shop_id, title, status, amount_cents, currency, line_items
  ) VALUES (
    p_buyer_id, p_shop_id, 'PetFolio Order', 'pending',
    v_amount_cents, 'usd', v_line_items
  )
  RETURNING id INTO v_order_id;

  FOR v_item IN SELECT value FROM jsonb_array_elements(p_cart_items)
  LOOP
    v_product_id := (v_item->>'product_id')::uuid;
    v_quantity   := (v_item->>'quantity')::int;
    v_variant_id := NULLIF(v_item->>'variant_id', '')::uuid;

    IF v_variant_id IS NULL THEN
      INSERT INTO public.inventory_reservations (order_id, product_id, quantity)
      VALUES (v_order_id, v_product_id, v_quantity)
      ON CONFLICT (order_id, product_id) WHERE status = 'active' AND variant_id IS NULL
      DO UPDATE SET quantity = inventory_reservations.quantity + EXCLUDED.quantity;
    ELSE
      INSERT INTO public.inventory_reservations (order_id, product_id, variant_id, quantity)
      VALUES (v_order_id, v_product_id, v_variant_id, v_quantity)
      ON CONFLICT (order_id, product_id, variant_id) WHERE status = 'active' AND variant_id IS NOT NULL
      DO UPDATE SET quantity = inventory_reservations.quantity + EXCLUDED.quantity;
    END IF;
  END LOOP;

  RETURN v_order_id;
END;
$$;

REVOKE ALL ON FUNCTION public.process_checkout(uuid, uuid, jsonb) FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION public.process_checkout(uuid, uuid, jsonb) TO authenticated;

-- ── 5. confirm_order_inventory — variant-aware ────────────────────────────────
CREATE OR REPLACE FUNCTION public.confirm_order_inventory(p_order_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_item RECORD;
BEGIN
  FOR v_item IN
    SELECT product_id, variant_id, quantity
    FROM   public.inventory_reservations
    WHERE  order_id   = p_order_id
      AND  status     = 'active'
      AND  expires_at > now()
  LOOP
    IF v_item.variant_id IS NOT NULL THEN
      UPDATE public.product_variants
      SET    stock = stock - v_item.quantity
      WHERE  id = v_item.variant_id;
    ELSE
      UPDATE public.products
      SET    inventory_count = inventory_count - v_item.quantity
      WHERE  id = v_item.product_id;
    END IF;
  END LOOP;

  UPDATE public.inventory_reservations
  SET    status = 'confirmed'
  WHERE  order_id   = p_order_id
    AND  status     = 'active'
    AND  expires_at > now();
END;
$$;

REVOKE ALL ON FUNCTION public.confirm_order_inventory(uuid) FROM PUBLIC;

-- ── 6. wishlists + wishlist_items ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.wishlists (
  id         uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    uuid        NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.wishlists ENABLE ROW LEVEL SECURITY;

CREATE POLICY "wishlists: owner select"
  ON public.wishlists FOR SELECT TO authenticated
  USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "wishlists: owner insert"
  ON public.wishlists FOR INSERT TO authenticated
  WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE TABLE IF NOT EXISTS public.wishlist_items (
  id          uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  wishlist_id uuid        NOT NULL REFERENCES public.wishlists(id) ON DELETE CASCADE,
  product_id  uuid        NOT NULL REFERENCES public.products(id)  ON DELETE CASCADE,
  variant_id  uuid        REFERENCES public.product_variants(id)   ON DELETE SET NULL,
  added_at    timestamptz NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX IF NOT EXISTS wishlist_items_no_variant_unique_idx
  ON public.wishlist_items (wishlist_id, product_id)
  WHERE variant_id IS NULL;

CREATE UNIQUE INDEX IF NOT EXISTS wishlist_items_with_variant_unique_idx
  ON public.wishlist_items (wishlist_id, product_id, variant_id)
  WHERE variant_id IS NOT NULL;

ALTER TABLE public.wishlist_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "wishlist_items: owner select"
  ON public.wishlist_items FOR SELECT TO authenticated
  USING (
    EXISTS (SELECT 1 FROM public.wishlists WHERE id = wishlist_id AND user_id = (SELECT auth.uid()))
  );

CREATE POLICY "wishlist_items: owner insert"
  ON public.wishlist_items FOR INSERT TO authenticated
  WITH CHECK (
    EXISTS (SELECT 1 FROM public.wishlists WHERE id = wishlist_id AND user_id = (SELECT auth.uid()))
  );

CREATE POLICY "wishlist_items: owner delete"
  ON public.wishlist_items FOR DELETE TO authenticated
  USING (
    EXISTS (SELECT 1 FROM public.wishlists WHERE id = wishlist_id AND user_id = (SELECT auth.uid()))
  );

CREATE OR REPLACE FUNCTION public.get_or_create_wishlist()
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_id  uuid;
  v_uid uuid := (SELECT auth.uid());
BEGIN
  SELECT id INTO v_id FROM public.wishlists WHERE user_id = v_uid;
  IF NOT FOUND THEN
    INSERT INTO public.wishlists (user_id) VALUES (v_uid) RETURNING id INTO v_id;
  END IF;
  RETURN v_id;
END;
$$;

REVOKE ALL ON FUNCTION public.get_or_create_wishlist() FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION public.get_or_create_wishlist() TO authenticated;

-- ── 7. prescriptions ──────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.prescriptions (
  id          uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id    uuid        NOT NULL REFERENCES public.marketplace_orders(id) ON DELETE CASCADE,
  file_path   text        NOT NULL,
  vet_name    text,
  status      text        NOT NULL DEFAULT 'pending'
              CHECK (status IN ('pending', 'approved', 'rejected')),
  reviewed_at timestamptz,
  created_at  timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS prescriptions_order_id_idx ON public.prescriptions(order_id);

ALTER TABLE public.prescriptions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "prescriptions: buyer select"
  ON public.prescriptions FOR SELECT TO authenticated
  USING (
    (SELECT buyer_id FROM public.marketplace_orders WHERE id = order_id) = (SELECT auth.uid())
  );

CREATE POLICY "prescriptions: buyer insert"
  ON public.prescriptions FOR INSERT TO authenticated
  WITH CHECK (
    (SELECT buyer_id FROM public.marketplace_orders WHERE id = order_id) = (SELECT auth.uid())
  );

CREATE POLICY "prescriptions: vendor select"
  ON public.prescriptions FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.marketplace_orders o
      JOIN  public.shops s ON s.id = o.shop_id
      WHERE o.id = order_id AND s.owner_id = (SELECT auth.uid())
    )
  );

-- ── 8. shipments ──────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.shipments (
  id                    uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id              uuid        NOT NULL UNIQUE REFERENCES public.marketplace_orders(id) ON DELETE CASCADE,
  courier               text,
  tracking_id           text,
  tracking_url          text,
  status                text        NOT NULL DEFAULT 'pending'
                        CHECK (status IN ('pending','picked_up','in_transit','out_for_delivery','delivered','failed')),
  shipped_at            timestamptz,
  estimated_delivery_at timestamptz,
  created_at            timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.shipments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "shipments: buyer select"
  ON public.shipments FOR SELECT TO authenticated
  USING (
    (SELECT buyer_id FROM public.marketplace_orders WHERE id = order_id) = (SELECT auth.uid())
  );

CREATE POLICY "shipments: vendor select"
  ON public.shipments FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.marketplace_orders o
      JOIN  public.shops s ON s.id = o.shop_id
      WHERE o.id = order_id AND s.owner_id = (SELECT auth.uid())
    )
  );

CREATE OR REPLACE FUNCTION public.vendor_upsert_shipment(
  p_order_id              uuid,
  p_courier               text        DEFAULT NULL,
  p_tracking_id           text        DEFAULT NULL,
  p_tracking_url          text        DEFAULT NULL,
  p_status                text        DEFAULT 'in_transit',
  p_estimated_delivery_at timestamptz DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM public.marketplace_orders o
    JOIN  public.shops s ON s.id = o.shop_id
    WHERE o.id = p_order_id AND s.owner_id = (SELECT auth.uid())
  ) THEN
    RAISE EXCEPTION 'Not authorized';
  END IF;

  INSERT INTO public.shipments
    (order_id, courier, tracking_id, tracking_url, status, shipped_at, estimated_delivery_at)
  VALUES (
    p_order_id, p_courier, p_tracking_id, p_tracking_url, p_status,
    CASE WHEN p_status IN ('picked_up','in_transit') THEN now() ELSE NULL END,
    p_estimated_delivery_at
  )
  ON CONFLICT (order_id) DO UPDATE SET
    courier               = COALESCE(EXCLUDED.courier,               shipments.courier),
    tracking_id           = COALESCE(EXCLUDED.tracking_id,           shipments.tracking_id),
    tracking_url          = COALESCE(EXCLUDED.tracking_url,          shipments.tracking_url),
    status                = EXCLUDED.status,
    shipped_at            = COALESCE(shipments.shipped_at,           EXCLUDED.shipped_at),
    estimated_delivery_at = COALESCE(EXCLUDED.estimated_delivery_at, shipments.estimated_delivery_at);
END;
$$;

REVOKE ALL ON FUNCTION public.vendor_upsert_shipment(uuid,text,text,text,text,timestamptz) FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION public.vendor_upsert_shipment(uuid,text,text,text,text,timestamptz) TO authenticated;

-- vendor_update_order — also upserts shipment row when tracking info provided
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
    SELECT 1 FROM public.marketplace_orders o
    JOIN  public.shops s ON s.id = o.shop_id
    WHERE o.id = p_order_id AND s.owner_id = (SELECT auth.uid())
  ) THEN
    RAISE EXCEPTION 'Not authorized to update this order';
  END IF;

  UPDATE public.marketplace_orders SET
    status                   = p_status,
    shipping_tracking_number = COALESCE(p_tracking_number, shipping_tracking_number),
    shipping_tracking_url    = COALESCE(p_tracking_url,    shipping_tracking_url),
    shipping_carrier         = COALESCE(p_carrier,         shipping_carrier),
    shipped_at               = CASE WHEN p_status = 'shipped' THEN now() ELSE shipped_at END
  WHERE id = p_order_id;

  IF p_tracking_number IS NOT NULL OR p_carrier IS NOT NULL THEN
    PERFORM public.vendor_upsert_shipment(
      p_order_id    := p_order_id,
      p_courier     := p_carrier,
      p_tracking_id := p_tracking_number,
      p_tracking_url:= p_tracking_url,
      p_status      := CASE WHEN p_status = 'shipped' THEN 'in_transit'::text ELSE 'pending'::text END
    );
  END IF;
END;
$$;

-- ── 9. Storage bucket: prescriptions (private) ────────────────────────────────
INSERT INTO storage.buckets (id, name, public)
VALUES ('prescriptions', 'prescriptions', false)
ON CONFLICT (id) DO NOTHING;

CREATE POLICY "prescriptions storage: owner upload"
  ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'prescriptions'
    AND (storage.foldername(name))[1] = (SELECT auth.uid())::text
  );

CREATE POLICY "prescriptions storage: owner read"
  ON storage.objects FOR SELECT TO authenticated
  USING (
    bucket_id = 'prescriptions'
    AND (storage.foldername(name))[1] = (SELECT auth.uid())::text
  );
