ALTER TABLE public.marketplace_orders
  ADD COLUMN IF NOT EXISTS stripe_checkout_session_id text;

CREATE UNIQUE INDEX IF NOT EXISTS marketplace_orders_stripe_cs_idx
  ON public.marketplace_orders (stripe_checkout_session_id)
  WHERE stripe_checkout_session_id IS NOT NULL;

CREATE TABLE IF NOT EXISTS public.care_web_reminders (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  task_id text NOT NULL,
  title text NOT NULL,
  remind_at timestamptz NOT NULL,
  repeating boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (user_id, task_id)
);

CREATE INDEX IF NOT EXISTS care_web_reminders_fire_idx
  ON public.care_web_reminders (remind_at);

ALTER TABLE public.care_web_reminders ENABLE ROW LEVEL SECURITY;

CREATE POLICY care_web_reminders_select_own ON public.care_web_reminders
  FOR SELECT TO authenticated
  USING (user_id = (SELECT auth.uid()));

CREATE POLICY care_web_reminders_insert_own ON public.care_web_reminders
  FOR INSERT TO authenticated
  WITH CHECK (user_id = (SELECT auth.uid()));

CREATE POLICY care_web_reminders_update_own ON public.care_web_reminders
  FOR UPDATE TO authenticated
  USING (user_id = (SELECT auth.uid()))
  WITH CHECK (user_id = (SELECT auth.uid()));

CREATE POLICY care_web_reminders_delete_own ON public.care_web_reminders
  FOR DELETE TO authenticated
  USING (user_id = (SELECT auth.uid()));

CREATE TABLE IF NOT EXISTS public.user_web_push_subscriptions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  endpoint text NOT NULL,
  p256dh text NOT NULL,
  auth text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (endpoint)
);

CREATE INDEX IF NOT EXISTS user_web_push_subscriptions_user_idx
  ON public.user_web_push_subscriptions (user_id);

ALTER TABLE public.user_web_push_subscriptions ENABLE ROW LEVEL SECURITY;

CREATE POLICY user_web_push_subscriptions_select_own ON public.user_web_push_subscriptions
  FOR SELECT TO authenticated
  USING (user_id = (SELECT auth.uid()));

CREATE POLICY user_web_push_subscriptions_insert_own ON public.user_web_push_subscriptions
  FOR INSERT TO authenticated
  WITH CHECK (user_id = (SELECT auth.uid()));

CREATE POLICY user_web_push_subscriptions_update_own ON public.user_web_push_subscriptions
  FOR UPDATE TO authenticated
  USING (user_id = (SELECT auth.uid()))
  WITH CHECK (user_id = (SELECT auth.uid()));

CREATE POLICY user_web_push_subscriptions_delete_own ON public.user_web_push_subscriptions
  FOR DELETE TO authenticated
  USING (user_id = (SELECT auth.uid()));
