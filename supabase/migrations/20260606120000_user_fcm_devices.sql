CREATE TABLE IF NOT EXISTS public.user_fcm_devices (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  fcm_token text NOT NULL,
  platform text NOT NULL CHECK (platform IN ('android', 'ios', 'web')),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (fcm_token)
);

CREATE INDEX IF NOT EXISTS user_fcm_devices_user_idx
  ON public.user_fcm_devices (user_id);

ALTER TABLE public.user_fcm_devices ENABLE ROW LEVEL SECURITY;

CREATE POLICY user_fcm_devices_select_own ON public.user_fcm_devices
  FOR SELECT TO authenticated
  USING (user_id = (SELECT auth.uid()));

CREATE POLICY user_fcm_devices_insert_own ON public.user_fcm_devices
  FOR INSERT TO authenticated
  WITH CHECK (user_id = (SELECT auth.uid()));

CREATE POLICY user_fcm_devices_update_own ON public.user_fcm_devices
  FOR UPDATE TO authenticated
  USING (user_id = (SELECT auth.uid()))
  WITH CHECK (user_id = (SELECT auth.uid()));

CREATE POLICY user_fcm_devices_delete_own ON public.user_fcm_devices
  FOR DELETE TO authenticated
  USING (user_id = (SELECT auth.uid()));
