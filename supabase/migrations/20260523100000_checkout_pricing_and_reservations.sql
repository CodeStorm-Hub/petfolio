-- sub_price_cents on products (vendor-set subscription price; NULL = compute 12% off) ──
ALTER TABLE public.products
  ADD COLUMN IF NOT EXISTS sub_price_cents integer NULL
    CONSTRAINT products_sub_price_cents_positive CHECK (sub_price_cents IS NULL OR sub_price_cents > 0);

-- inventory_reservations ──────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.inventory_reservations (
  id          uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id    uuid        NOT NULL REFERENCES public.marketplace_orders(id) ON DELETE CASCADE,
  product_id  uuid        NOT NULL REFERENCES public.products(id)           ON DELETE CASCADE,
  quantity    int         NOT NULL CHECK (quantity > 0),
  status      text        NOT NULL DEFAULT 'active'
              CHECK (status IN ('active', 'confirmed', 'released')),
  expires_at  timestamptz NOT NULL DEFAULT now() + interval '15 minutes',
  created_at  timestamptz NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX IF NOT EXISTS inventory_reservations_order_product_active_idx
  ON public.inventory_reservations (order_id, product_id)
  WHERE status = 'active';

CREATE INDEX IF NOT EXISTS inventory_reservations_product_active_idx
  ON public.inventory_reservations (product_id)
  WHERE status = 'active';

ALTER TABLE public.inventory_reservations ENABLE ROW LEVEL SECURITY;

-- No client-facing policies — all writes go through SECURITY DEFINER RPCs.
-- The service-role key used by Edge Functions bypasses RLS automatically.

-- process_checkout (server-authoritative pricing + reservation model) ─────────

CREATE OR REPLACE FUNCTION public.process_checkout(
  p_buyer_id   uuid,
  p_shop_id    uuid,
  p_cart_items jsonb   -- [{product_id, quantity, is_subscribed, frequency_weeks}]
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
  v_quantity      int;
  v_is_subscribed boolean;
  v_unit_cents    bigint;
  v_line_total    bigint;
  v_inv_count     int;
  v_reserved      int;
  v_product_name  text;
  v_price_cents   bigint;
  v_sub_price     bigint;
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

  IF NOT FOUND      THEN RAISE EXCEPTION 'Shop not found';     END IF;
  IF NOT v_shop_active    THEN RAISE EXCEPTION 'SHOP_INACTIVE';      END IF;
  IF NOT v_shop_verified  THEN RAISE EXCEPTION 'SHOP_NOT_VERIFIED';  END IF;

  FOR v_item IN SELECT value FROM jsonb_array_elements(p_cart_items)
  LOOP
    v_product_id    := (v_item->>'product_id')::uuid;
    v_quantity      := (v_item->>'quantity')::int;
    v_is_subscribed := COALESCE((v_item->>'is_subscribed')::boolean, false);

    SELECT name,
           price_cents,
           COALESCE(sub_price_cents, ROUND(price_cents::numeric * 0.88)::bigint),
           inventory_count
    INTO   v_product_name, v_price_cents, v_sub_price, v_inv_count
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
      AND  status     = 'active'
      AND  expires_at > now();

    IF (v_inv_count - v_reserved) < v_quantity THEN
      RAISE EXCEPTION 'INSUFFICIENT_STOCK:%:%:%',
        v_product_name,
        GREATEST(v_inv_count - v_reserved, 0),
        v_quantity;
    END IF;

    v_unit_cents := CASE
      WHEN v_is_subscribed THEN v_sub_price
      ELSE v_price_cents
    END;
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
      'frequency_weeks',  COALESCE((v_item->>'frequency_weeks')::int, 0)
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

    INSERT INTO public.inventory_reservations (order_id, product_id, quantity)
    VALUES (v_order_id, v_product_id, v_quantity)
    ON CONFLICT (order_id, product_id) WHERE status = 'active'
    DO UPDATE SET quantity = inventory_reservations.quantity + EXCLUDED.quantity;
  END LOOP;

  RETURN v_order_id;
END;
$$;

REVOKE ALL ON FUNCTION public.process_checkout(uuid, uuid, jsonb) FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION public.process_checkout(uuid, uuid, jsonb) TO authenticated;

-- confirm_order_inventory ─────────────────────────────────────────────────────
-- Called by stripe-webhook (service role) after payment_intent.succeeded.

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
    SELECT product_id, quantity
    FROM   public.inventory_reservations
    WHERE  order_id   = p_order_id
      AND  status     = 'active'
      AND  expires_at > now()
  LOOP
    UPDATE public.products
    SET    inventory_count = inventory_count - v_item.quantity
    WHERE  id = v_item.product_id;
  END LOOP;

  UPDATE public.inventory_reservations
  SET    status = 'confirmed'
  WHERE  order_id   = p_order_id
    AND  status     = 'active'
    AND  expires_at > now();
END;
$$;

REVOKE ALL ON FUNCTION public.confirm_order_inventory(uuid) FROM PUBLIC;

-- release_order_inventory ─────────────────────────────────────────────────────
-- Called by Flutter (cancel / dismissed sheet) and webhook (payment_failed).
-- Ownership guard: authenticated callers must own the order.
-- Service-role callers (webhook) have auth.uid() = NULL and bypass the check.

CREATE OR REPLACE FUNCTION public.release_order_inventory(p_order_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_buyer_id uuid;
BEGIN
  SELECT buyer_id INTO v_buyer_id
  FROM   public.marketplace_orders
  WHERE  id = p_order_id;

  IF (SELECT auth.uid()) IS NOT NULL
     AND v_buyer_id IS DISTINCT FROM (SELECT auth.uid()) THEN
    RAISE EXCEPTION 'Forbidden';
  END IF;

  UPDATE public.inventory_reservations
  SET    status = 'released'
  WHERE  order_id = p_order_id AND status = 'active';
END;
$$;

REVOKE ALL ON FUNCTION public.release_order_inventory(uuid) FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION public.release_order_inventory(uuid) TO authenticated;
