CREATE OR REPLACE FUNCTION public.process_checkout(
  p_buyer_id uuid,
  p_shop_id uuid,
  p_cart_items jsonb,
  p_promo_code text DEFAULT NULL::text
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $function$
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
  v_promo_id       uuid;
  v_discount_type  text;
  v_discount_value int;
  v_min_order_cents int;
  v_max_discount   int;
  v_max_usage      int;
  v_usage_count    int;
  v_valid_until    timestamptz;
  v_discount_cents bigint := 0;
  v_applied_code   text;
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

  IF p_promo_code IS NOT NULL THEN
    SELECT id, discount_type, discount_value, min_order_cents,
           max_discount_cents, max_usage, usage_count, valid_until
    INTO   v_promo_id, v_discount_type, v_discount_value, v_min_order_cents,
           v_max_discount, v_max_usage, v_usage_count, v_valid_until
    FROM   public.promos
    WHERE  code      = upper(trim(p_promo_code))
      AND  is_active = true
    FOR UPDATE;

    IF FOUND
       AND (v_valid_until IS NULL OR v_valid_until > now())
       AND (v_max_usage IS NULL OR v_usage_count < v_max_usage)
       AND v_amount_cents >= v_min_order_cents
    THEN
      v_discount_cents := CASE v_discount_type
        WHEN 'percent' THEN
          LEAST(
            (v_amount_cents * v_discount_value / 100)::bigint,
            COALESCE(v_max_discount, 999999999)::bigint
          )
        ELSE
          LEAST(v_discount_value::bigint, v_amount_cents)
      END;
      v_amount_cents := v_amount_cents - v_discount_cents;
      v_applied_code := upper(trim(p_promo_code));
      UPDATE public.promos SET usage_count = usage_count + 1 WHERE id = v_promo_id;
    END IF;
  END IF;

  INSERT INTO public.marketplace_orders (
    buyer_id, shop_id, title, status, amount_cents, currency,
    line_items, promo_code, discount_cents
  ) VALUES (
    p_buyer_id, p_shop_id, 'PetFolio Order', 'pending',
    v_amount_cents, 'usd',
    v_line_items, v_applied_code, v_discount_cents
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
$function$;

REVOKE ALL ON FUNCTION public.process_checkout(uuid, uuid, jsonb, text) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.process_checkout(uuid, uuid, jsonb, text) FROM anon;
GRANT EXECUTE ON FUNCTION public.process_checkout(uuid, uuid, jsonb, text) TO authenticated;
