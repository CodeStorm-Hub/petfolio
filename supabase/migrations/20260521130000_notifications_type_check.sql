-- Extend the notifications.type allowed values to include vendor KYC types.
-- The approve_vendor_kyc RPC inserts 'kyc_approved'; reject will use 'kyc_rejected'.

ALTER TABLE public.notifications
  DROP CONSTRAINT IF EXISTS notifications_type_check;

ALTER TABLE public.notifications
  ADD CONSTRAINT notifications_type_check
  CHECK (type = ANY (ARRAY[
    'like',
    'comment',
    'follow',
    'kyc_approved',
    'kyc_rejected'
  ]));
