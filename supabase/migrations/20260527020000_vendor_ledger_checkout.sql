-- ─────────────────────────────────────────────────────────────────────────────
-- 1. Enforce uniqueness on vendor_ledgers.order_id
--    One order → at most one ledger entry. Required for the ON CONFLICT guard
--    in both process_checkout and the stripe-webhook handler.
-- ─────────────────────────────────────────────────────────────────────────────

ALTER TABLE public.vendor_ledgers
  ADD CONSTRAINT vendor_ledgers_order_id_key UNIQUE (order_id);

-- ─────────────────────────────────────────────────────────────────────────────
-- 2. RLS: allow the service role (used by SECURITY DEFINER functions) to
--    INSERT into vendor_ledgers.
--    process_checkout and stripe-webhook both run as the postgres/service role,
--    which bypasses RLS — this policy is a defensive belt-and-suspenders grant
--    for any future SECURITY INVOKER refactor.
-- ─────────────────────────────────────────────────────────────────────────────

DROP POLICY IF EXISTS "service_role_insert_ledger" ON public.vendor_ledgers;
CREATE POLICY "service_role_insert_ledger" ON public.vendor_ledgers
  FOR INSERT TO service_role
  WITH CHECK (true);

-- ─────────────────────────────────────────────────────────────────────────────
-- 3. Updated process_checkout: adds ledger INSERT at the end of the transaction
--    so a vendor_ledgers row always exists for every order, even if the
--    stripe-webhook is delayed or misconfigured.
--
--    The stripe-webhook uses ON CONFLICT DO NOTHING on the same order_id,
--    so there is no double-counting risk.
-- ─────────────────────────────────────────────────────────────────────────────

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
  v_order_id            uuid;
  v_amount_cents        bigint := 0;
  v_item                jsonb;
  v_product_id          uuid;
  v_quantity            int;
  v_line_total          bigint;
  v_inv_count           int;
  v_product_name        text;
  v_shop_active         boolean;
  v_shop_verified       boolean;
  v_platform_fee_pct    integer;
  v_platform_fee_cents  bigint;
  v_vendor_earnings     bigint;
BEGIN
  IF p_buyer_id IS DISTINCT FROM auth.uid() THEN
    RAISE EXCEPTION 'buyer_id mismatch';
  END IF;

  -- ── 1. Validate shop ───────────────────────────────────────────────────────
  SELECT is_active, is_verified, platform_fee_percent
  INTO   v_shop_active, v_shop_verified, v_platform_fee_pct
  FROM   public.shops
  WHERE  id = p_shop_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Shop not found';
  END IF;

  IF NOT v_shop_active THEN
    RAISE EXCEPTION 'SHOP_INACTIVE';
  END IF;

  IF NOT v_shop_verified THEN
    RAISE EXCEPTION 'SHOP_NOT_VERIFIED';
  END IF;

  -- ── 2. Validate items & accumulate total ──────────────────────────────────
  FOR v_item IN SELECT value FROM jsonb_array_elements(p_cart_items)
  LOOP
    v_product_id := (v_item->>'product_id')::uuid;
    v_quantity   := (v_item->>'quantity')::int;
    v_line_total := (v_item->>'line_total_cents')::bigint;

    SELECT inventory_count, name
    INTO   v_inv_count, v_product_name
    FROM   public.products
    WHERE  id       = v_product_id
      AND  shop_id  = p_shop_id
      AND  active   = true;

    IF NOT FOUND THEN
      RAISE EXCEPTION 'PRODUCT_UNAVAILABLE:%', v_product_id;
    END IF;

    IF v_inv_count < v_quantity THEN
      RAISE EXCEPTION 'INSUFFICIENT_STOCK:%:%:%', v_product_name, v_inv_count, v_quantity;
    END IF;

    v_amount_cents := v_amount_cents + v_line_total;
  END LOOP;

  -- ── 3. Create the order ────────────────────────────────────────────────────
  INSERT INTO public.marketplace_orders (
    buyer_id, shop_id, title, status,
    amount_cents, currency, line_items
  )
  VALUES (
    p_buyer_id, p_shop_id, 'PetFolio Order', 'pending',
    v_amount_cents, 'usd', p_cart_items
  )
  RETURNING id INTO v_order_id;

  -- ── 4. Decrement inventory ─────────────────────────────────────────────────
  FOR v_item IN SELECT value FROM jsonb_array_elements(p_cart_items)
  LOOP
    v_product_id := (v_item->>'product_id')::uuid;
    v_quantity   := (v_item->>'quantity')::int;

    UPDATE public.products
    SET    inventory_count = inventory_count - v_quantity
    WHERE  id = v_product_id
      AND  shop_id = p_shop_id;
  END LOOP;

  -- ── 5. Create initial vendor ledger entry ─────────────────────────────────
  -- Status starts as 'pending_clearance'; stripe-webhook updates it to
  -- 'available' on payment_intent.succeeded.
  -- ON CONFLICT DO NOTHING makes this idempotent if the webhook fires first.
  v_platform_fee_cents := FLOOR(v_amount_cents * v_platform_fee_pct / 100.0)::bigint;
  v_vendor_earnings    := v_amount_cents - v_platform_fee_cents;

  INSERT INTO public.vendor_ledgers (
    shop_id, order_id,
    order_total_cents, platform_fee_cents, vendor_earnings_cents,
    status
  )
  VALUES (
    p_shop_id, v_order_id,
    v_amount_cents, v_platform_fee_cents, v_vendor_earnings,
    'pending_clearance'
  )
  ON CONFLICT (order_id) DO NOTHING;

  RETURN v_order_id;
END;
$$;

REVOKE ALL ON FUNCTION public.process_checkout(uuid, uuid, jsonb) FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION public.process_checkout(uuid, uuid, jsonb) TO authenticated;
