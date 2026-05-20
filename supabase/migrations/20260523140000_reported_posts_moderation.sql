ALTER TABLE public.reported_posts
  ADD COLUMN IF NOT EXISTS status      text NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'reviewed', 'dismissed')),
  ADD COLUMN IF NOT EXISTS reviewed_by uuid REFERENCES auth.users(id),
  ADD COLUMN IF NOT EXISTS reviewed_at timestamptz;

CREATE INDEX IF NOT EXISTS reported_posts_status_idx
  ON public.reported_posts (status);

CREATE POLICY "admins can view all reported posts"
  ON public.reported_posts FOR SELECT TO authenticated
  USING (public.is_admin());

ALTER TABLE public.posts
  ADD COLUMN IF NOT EXISTS is_hidden boolean NOT NULL DEFAULT false;

CREATE POLICY "admins can select all posts"
  ON public.posts FOR SELECT TO authenticated
  USING (public.is_admin());

CREATE OR REPLACE FUNCTION public.resolve_reported_post(
  p_report_id uuid,
  p_action    text,
  p_hide_post boolean DEFAULT false
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_admin_id uuid := auth.uid();
  v_post_id  uuid;
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'ADMIN_REQUIRED';
  END IF;

  IF p_action NOT IN ('reviewed', 'dismissed') THEN
    RAISE EXCEPTION 'INVALID_ACTION';
  END IF;

  SELECT post_id INTO v_post_id
  FROM reported_posts
  WHERE id = p_report_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'REPORT_NOT_FOUND';
  END IF;

  UPDATE reported_posts
  SET
    status      = p_action,
    reviewed_by = v_admin_id,
    reviewed_at = now()
  WHERE id = p_report_id;

  IF p_hide_post THEN
    UPDATE posts SET is_hidden = true WHERE id = v_post_id;
  END IF;

  INSERT INTO audit_logs (admin_id, action, target_type, target_id, metadata)
  VALUES (
    v_admin_id,
    'post_report_' || p_action,
    'reported_post',
    p_report_id,
    jsonb_build_object('post_id', v_post_id, 'hide_post', p_hide_post)
  );
END;
$$;

REVOKE ALL ON FUNCTION public.resolve_reported_post(uuid, text, boolean) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.resolve_reported_post(uuid, text, boolean) TO authenticated;
