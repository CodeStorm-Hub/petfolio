-- Add rating column and expand product category constraint

ALTER TABLE products
  ADD COLUMN IF NOT EXISTS rating DECIMAL(3,2)
    CHECK (rating IS NULL OR (rating >= 0 AND rating <= 5));

ALTER TABLE products
  DROP CONSTRAINT IF EXISTS products_category_check;

ALTER TABLE products
  ADD CONSTRAINT products_category_check
    CHECK (category IN ('food','gear','toys','treats','health','grooming','beds','apparel'));
