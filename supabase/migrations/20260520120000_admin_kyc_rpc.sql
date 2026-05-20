-- ─────────────────────────────────────────────────────────────────────────────
-- 1. Audit logs table
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.audit_logs (
  id          uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  admin_id    uuid        NOT NULL REFERENCES auth.users(id),
  action      text        NOT NULL,
  target_type text        NOT NULL,
  target_id   uuid        NOT NULL,
  metadata    jsonb       NOT NULL DEFAULT '{}',
  created_at  timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;

-- Admins can read audit logs; writes only via SECURITY DEFINER RPC
CREATE POLICY "audit_logs_admin_select"
  ON public.audit_logs FOR SELECT
  TO authenticated
  USING (public.is_admin());

-- ─────────────────────────────────────────────────────────────────────────────
-- 2. Extend notifications to support user-level (vendor) notifications
-- ─────────────────────────────────────────────────────────────────────────────

-- Make recipient_pet_id nullable so vendor notifications (which target a user,
-- not a pet) can be inserted without a pet_id.
ALTER TABLE public.notifications
  ALTER COLUMN recipient_pet_id DROP NOT NULL;

ALTER TABLE public.notifications
  ADD COLUMN IF NOT EXISTS recipient_user_id uuid REFERENCES public.users(id) ON DELETE CASCADE,
  ADD COLUMN IF NOT EXISTS metadata           jsonb NOT NULL DEFAULT '{}';

-- Enforce at least one recipient column is always set
ALTER TABLE public.notifications
  ADD CONSTRAINT notifications_recipient_check
  CHECK (recipient_pet_id IS NOT NULL OR recipient_user_id IS NOT NULL);

-- Update SELECT policy to cover both pet-based and user-based notifications
DROP POLICY IF EXISTS notifications_select_policy ON public.notifications;
CREATE POLICY "notifications_select_policy"
  ON public.notifications FOR SELECT
  TO authenticated
  USING (
    recipient_pet_id IN (
      SELECT id FROM public.pets WHERE owner_id = auth.uid()
    )
    OR recipient_user_id = auth.uid()
  );

-- Update UPDATE policy (mark-as-read) to match
DROP POLICY IF EXISTS notifications_update_policy ON public.notifications;
CREATE POLICY "notifications_update_policy"
  ON public.notifications FOR UPDATE
  TO authenticated
  USING (
    recipient_pet_id IN (
      SELECT id FROM public.pets WHERE owner_id = auth.uid()
    )
    OR recipient_user_id = auth.uid()
  );

-- ─────────────────────────────────────────────────────────────────────────────
-- 3. approve_vendor_kyc RPC
-- ─────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.approve_vendor_kyc(
  p_shop_id  uuid,
  p_admin_id uuid
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_owner_id uuid;
BEGIN
  -- Guard: caller must hold the is_admin JWT claim
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Admin access required';
  END IF;

  -- Guard: p_admin_id must match the authenticated user (prevent spoofing)
  IF p_admin_id IS DISTINCT FROM auth.uid() THEN
    RAISE EXCEPTION 'admin_id mismatch';
  END IF;

  -- Resolve the shop owner for the notification
  SELECT owner_id INTO v_owner_id
  FROM public.shops
  WHERE id = p_shop_id;

  IF v_owner_id IS NULL THEN
    RAISE EXCEPTION 'Shop not found: %', p_shop_id;
  END IF;

  -- 1. Approve the shop
  UPDATE public.shops
  SET
    kyc_status       = 'approved'::kyc_status_enum,
    is_verified      = true,
    rejection_reason = NULL,
    updated_at       = now()
  WHERE id = p_shop_id;

  -- 2. Immutable audit trail
  INSERT INTO public.audit_logs (admin_id, action, target_type, target_id, metadata)
  VALUES (
    p_admin_id,
    'kyc_approved',
    'shop',
    p_shop_id,
    jsonb_build_object('approved_at', now())
  );

  -- 3. Notify the vendor
  INSERT INTO public.notifications (recipient_user_id, type, metadata)
  VALUES (
    v_owner_id,
    'kyc_approved',
    jsonb_build_object('shop_id', p_shop_id)
  );
END;
$$;

-- Only authenticated users may call this function; the is_admin() guard is
-- enforced inside the body.
REVOKE ALL ON FUNCTION public.approve_vendor_kyc(uuid, uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.approve_vendor_kyc(uuid, uuid) TO authenticated;
