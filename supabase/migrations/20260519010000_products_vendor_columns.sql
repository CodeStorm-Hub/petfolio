-- ─────────────────────────────────────────────────────────────────────────────
-- Migration: products_vendor_columns
-- Adds shop_id, image_urls, and inventory_count to the products table.
-- Migrates the 8 existing platform products to the PetFolio Official shop.
-- Replaces the old read-only product policy with vendor write policies.
-- ─────────────────────────────────────────────────────────────────────────────

-- ── 1. Add vendor columns ─────────────────────────────────────────────────────

ALTER TABLE public.products
  ADD COLUMN IF NOT EXISTS shop_id         uuid
    REFERENCES public.shops(id) ON DELETE CASCADE,
  ADD COLUMN IF NOT EXISTS image_urls      text[]  NOT NULL DEFAULT '{}',
  ADD COLUMN IF NOT EXISTS inventory_count integer NOT NULL DEFAULT 0
    CHECK (inventory_count >= 0);

-- ── 2. Migrate existing 8 platform products to PetFolio Official shop ─────────

UPDATE public.products
  SET shop_id = 'cccccccc-0000-0000-0000-cccccccccccc'
  WHERE shop_id IS NULL;

-- ── 3. Enforce NOT NULL now that every row has a shop ─────────────────────────

ALTER TABLE public.products
  ALTER COLUMN shop_id SET NOT NULL;

-- ── 4. Index ──────────────────────────────────────────────────────────────────

CREATE INDEX IF NOT EXISTS idx_products_shop_id ON public.products(shop_id);

-- ── 5. Replace the old single read policy with granular vendor policies ────────
-- The policy below was created in 20260512000000_marketplace.sql.

DROP POLICY IF EXISTS "Anyone can read active products" ON public.products;

-- Authenticated users see all active products.
CREATE POLICY "products: select active"
  ON public.products FOR SELECT TO authenticated
  USING (active = true);

-- Anon users can also browse (for future public/unauthenticated storefronts).
CREATE POLICY "products: anon select active"
  ON public.products FOR SELECT TO anon
  USING (active = true);

-- Vendors can insert products into their own shop.
CREATE POLICY "products: vendor can insert"
  ON public.products FOR INSERT TO authenticated
  WITH CHECK (
    (select auth.uid()) = (
      SELECT owner_id FROM public.shops WHERE id = shop_id
    )
  );

-- Vendors can update their own shop's products.
CREATE POLICY "products: vendor can update"
  ON public.products FOR UPDATE TO authenticated
  USING (
    (select auth.uid()) = (
      SELECT owner_id FROM public.shops WHERE id = shop_id
    )
  )
  WITH CHECK (
    (select auth.uid()) = (
      SELECT owner_id FROM public.shops WHERE id = shop_id
    )
  );

-- Vendors can delete their own shop's products.
CREATE POLICY "products: vendor can delete"
  ON public.products FOR DELETE TO authenticated
  USING (
    (select auth.uid()) = (
      SELECT owner_id FROM public.shops WHERE id = shop_id
    )
  );

-- ── 6. Grant write access (SELECT was already granted in schema.sql) ───────────

GRANT INSERT, UPDATE, DELETE ON public.products TO authenticated;
