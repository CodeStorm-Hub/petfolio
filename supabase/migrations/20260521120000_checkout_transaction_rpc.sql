-- ─────────────────────────────────────────────────────────────────────────────
-- process_checkout RPC
--
-- Atomically:
--   1. Validates the shop is active and verified
--   2. Validates each product belongs to the shop, is active, and has stock
--   3. Creates the marketplace_orders row
--   4. Decrements inventory_count for each product
--
-- Returns the new order UUID.
-- All steps run inside a single implicit PL/pgSQL transaction; any failure
-- rolls back the entire operation.
-- ─────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.process_checkout(
  p_buyer_id   uuid,
  p_shop_id    uuid,
  p_cart_items jsonb   -- array of CartItem.toJson() objects
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_order_id      uuid;
  v_amount_cents  bigint := 0;
  v_item          jsonb;
  v_product_id    uuid;
  v_quantity      int;
  v_line_total    bigint;
  v_inv_count     int;
  v_product_name  text;
  v_shop_active   boolean;
  v_shop_verified boolean;
BEGIN
  -- Guard: caller must match the declared buyer (prevent impersonation)
  IF p_buyer_id IS DISTINCT FROM auth.uid() THEN
    RAISE EXCEPTION 'buyer_id mismatch';
  END IF;

  -- ── 1. Validate shop ───────────────────────────────────────────────────────
  SELECT is_active, is_verified
  INTO   v_shop_active, v_shop_verified
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

  -- ── 2. Validate each item & accumulate total ───────────────────────────────
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
      -- Colon-delimited so the Dart client can split and build InsufficientStockException
      RAISE EXCEPTION 'INSUFFICIENT_STOCK:%:%:%', v_product_name, v_inv_count, v_quantity;
    END IF;

    v_amount_cents := v_amount_cents + v_line_total;
  END LOOP;

  -- ── 3. Create the order ────────────────────────────────────────────────────
  INSERT INTO public.marketplace_orders (
    buyer_id,
    shop_id,
    title,
    status,
    amount_cents,
    currency,
    line_items
  )
  VALUES (
    p_buyer_id,
    p_shop_id,
    'PetFolio Order',
    'pending',
    v_amount_cents,
    'usd',
    p_cart_items
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

  RETURN v_order_id;
END;
$$;

-- Only authenticated buyers may call this; the buyer_id guard is enforced inside.
REVOKE ALL ON FUNCTION public.process_checkout(uuid, uuid, jsonb) FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION public.process_checkout(uuid, uuid, jsonb) TO authenticated;
