CREATE OR REPLACE FUNCTION public.reject_vendor_kyc(
  p_shop_id  uuid,
  p_admin_id uuid,
  p_reason   text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_owner_id uuid;
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Admin access required';
  END IF;

  IF p_admin_id IS DISTINCT FROM auth.uid() THEN
    RAISE EXCEPTION 'admin_id mismatch';
  END IF;

  IF p_reason IS NULL OR trim(p_reason) = '' THEN
    RAISE EXCEPTION 'Rejection reason must not be empty';
  END IF;

  SELECT owner_id INTO v_owner_id
  FROM public.shops
  WHERE id = p_shop_id;

  IF v_owner_id IS NULL THEN
    RAISE EXCEPTION 'Shop not found: %', p_shop_id;
  END IF;

  UPDATE public.shops
  SET
    kyc_status       = 'rejected'::kyc_status_enum,
    is_verified      = false,
    rejection_reason = trim(p_reason),
    updated_at       = now()
  WHERE id = p_shop_id;

  INSERT INTO public.audit_logs (admin_id, action, target_type, target_id, metadata)
  VALUES (
    p_admin_id,
    'kyc_rejected',
    'shop',
    p_shop_id,
    jsonb_build_object('rejected_at', now(), 'reason', trim(p_reason))
  );

  INSERT INTO public.notifications (recipient_user_id, type, metadata)
  VALUES (
    v_owner_id,
    'kyc_rejected',
    jsonb_build_object('shop_id', p_shop_id, 'reason', trim(p_reason))
  );
END;
$$;

REVOKE ALL ON FUNCTION public.reject_vendor_kyc(uuid, uuid, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.reject_vendor_kyc(uuid, uuid, text) TO authenticated;
