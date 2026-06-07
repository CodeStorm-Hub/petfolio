ALTER TABLE public.products
  ADD COLUMN IF NOT EXISTS review_count integer NOT NULL DEFAULT 0
    CHECK (review_count >= 0);

CREATE TABLE IF NOT EXISTS public.product_reviews (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id  uuid NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
  user_id     uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  rating      smallint NOT NULL CHECK (rating >= 1 AND rating <= 5),
  body        text CHECK (body IS NULL OR char_length(body) <= 500),
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now(),
  UNIQUE (product_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_product_reviews_product_id
  ON public.product_reviews(product_id);

CREATE OR REPLACE FUNCTION public.refresh_product_rating_stats()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  target_product_id uuid;
BEGIN
  IF TG_OP = 'DELETE' THEN
    target_product_id := OLD.product_id;
  ELSE
    target_product_id := NEW.product_id;
  END IF;

  UPDATE public.products
  SET
    rating = (
      SELECT ROUND(AVG(r.rating)::numeric, 2)
      FROM public.product_reviews r
      WHERE r.product_id = target_product_id
    ),
    review_count = (
      SELECT COUNT(*)::integer
      FROM public.product_reviews r
      WHERE r.product_id = target_product_id
    )
  WHERE id = target_product_id;

  RETURN COALESCE(NEW, OLD);
END;
$$;

DROP TRIGGER IF EXISTS trg_product_reviews_stats ON public.product_reviews;
CREATE TRIGGER trg_product_reviews_stats
  AFTER INSERT OR UPDATE OR DELETE ON public.product_reviews
  FOR EACH ROW
  EXECUTE FUNCTION public.refresh_product_rating_stats();

ALTER TABLE public.product_reviews ENABLE ROW LEVEL SECURITY;

CREATE POLICY "product_reviews_select"
  ON public.product_reviews FOR SELECT
  USING (true);

CREATE POLICY "product_reviews_insert"
  ON public.product_reviews FOR INSERT
  TO authenticated
  WITH CHECK ((select auth.uid()) = user_id);

CREATE POLICY "product_reviews_update"
  ON public.product_reviews FOR UPDATE
  TO authenticated
  USING ((select auth.uid()) = user_id)
  WITH CHECK ((select auth.uid()) = user_id);

CREATE POLICY "product_reviews_delete"
  ON public.product_reviews FOR DELETE
  TO authenticated
  USING ((select auth.uid()) = user_id);

GRANT SELECT ON public.product_reviews TO anon, authenticated;
GRANT INSERT, UPDATE, DELETE ON public.product_reviews TO authenticated;
