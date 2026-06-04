CREATE EXTENSION IF NOT EXISTS pg_net WITH SCHEMA extensions;

CREATE TABLE IF NOT EXISTS private.fcm_internal_config (
  id int PRIMARY KEY DEFAULT 1 CHECK (id = 1),
  functions_base_url text NOT NULL DEFAULT 'https://jqyjvhwlcqcsuwcqgcwf.supabase.co/functions/v1',
  dispatch_secret text
);

INSERT INTO private.fcm_internal_config (id)
VALUES (1)
ON CONFLICT (id) DO NOTHING;

CREATE TABLE IF NOT EXISTS public.fcm_push_outbox (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  title text NOT NULL,
  body text NOT NULL,
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  processed_at timestamptz
);

CREATE INDEX IF NOT EXISTS fcm_push_outbox_pending_idx
  ON public.fcm_push_outbox (created_at)
  WHERE processed_at IS NULL;

ALTER TABLE public.fcm_push_outbox ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.care_web_reminders
  ADD COLUMN IF NOT EXISTS fcm_sent_at timestamptz;

CREATE OR REPLACE FUNCTION private.fcm_data_to_text_map(p_data jsonb)
RETURNS jsonb
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT COALESCE(
    (
      SELECT jsonb_object_agg(key, value)
      FROM jsonb_each_text(COALESCE(p_data, '{}'::jsonb))
    ),
    '{}'::jsonb
  );
$$;

CREATE OR REPLACE FUNCTION private.dispatch_fcm_push(
  p_user_id uuid,
  p_title text,
  p_body text,
  p_data jsonb DEFAULT '{}'::jsonb
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, private, extensions
AS $$
DECLARE
  v_base_url text;
  v_secret text;
  v_payload jsonb;
BEGIN
  IF p_user_id IS NULL OR btrim(COALESCE(p_title, '')) = '' THEN
    RETURN;
  END IF;

  SELECT functions_base_url, dispatch_secret
  INTO v_base_url, v_secret
  FROM private.fcm_internal_config
  WHERE id = 1;

  v_payload := jsonb_build_object(
    'userId', p_user_id::text,
    'title', p_title,
    'body', COALESCE(p_body, ''),
    'data', private.fcm_data_to_text_map(p_data)
  );

  IF v_secret IS NULL OR btrim(v_secret) = '' THEN
    INSERT INTO public.fcm_push_outbox (user_id, title, body, data)
    VALUES (p_user_id, p_title, COALESCE(p_body, ''), COALESCE(p_data, '{}'::jsonb));
    RETURN;
  END IF;

  BEGIN
    PERFORM net.http_post(
      url := rtrim(v_base_url, '/') || '/send-fcm-notification',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'x-fcm-dispatch-secret', v_secret
      ),
      body := v_payload
    );
  EXCEPTION WHEN OTHERS THEN
    INSERT INTO public.fcm_push_outbox (user_id, title, body, data)
    VALUES (p_user_id, p_title, COALESCE(p_body, ''), COALESCE(p_data, '{}'::jsonb));
  END;
END;
$$;

REVOKE ALL ON FUNCTION private.dispatch_fcm_push(uuid, text, text, jsonb) FROM PUBLIC;

CREATE OR REPLACE FUNCTION private.handle_notification_fcm_push()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, private
AS $$
DECLARE
  v_user_id uuid;
  v_actor_handle text;
  v_actor_name text;
  v_title text;
  v_body text;
  v_data jsonb;
BEGIN
  IF NEW.recipient_user_id IS NOT NULL THEN
    v_user_id := NEW.recipient_user_id;
  ELSIF NEW.recipient_pet_id IS NOT NULL THEN
    SELECT owner_id INTO v_user_id FROM public.pets WHERE id = NEW.recipient_pet_id;
  END IF;

  IF v_user_id IS NULL THEN
    RETURN NEW;
  END IF;

  IF NEW.actor_pet_id IS NOT NULL THEN
    SELECT handle, name
    INTO v_actor_handle, v_actor_name
    FROM public.pets
    WHERE id = NEW.actor_pet_id;
  END IF;

  v_actor_handle := COALESCE(v_actor_handle, 'someone');
  v_actor_name := COALESCE(v_actor_name, 'A pet');

  v_data := jsonb_build_object('type', NEW.type);
  IF NEW.post_id IS NOT NULL THEN
    v_data := v_data || jsonb_build_object('post_id', NEW.post_id::text);
  END IF;

  CASE NEW.type
    WHEN 'like' THEN
      v_title := 'New like';
      v_body := '@' || v_actor_handle || ' liked your post.';
      v_data := v_data || jsonb_build_object('route', '/social/notifications');
    WHEN 'comment' THEN
      v_title := 'New comment';
      v_body := '@' || v_actor_handle || ' commented on your post.';
      IF NEW.post_id IS NOT NULL THEN
        v_data := v_data || jsonb_build_object('route', '/social/post/' || NEW.post_id::text);
      END IF;
    WHEN 'follow' THEN
      v_title := 'New follower';
      v_body := '@' || v_actor_handle || ' started following you.';
      v_data := v_data || jsonb_build_object('route', '/social/notifications');
    WHEN 'kyc_approved' THEN
      v_title := 'Shop verified';
      v_body := 'Your seller verification was approved.';
      v_data := v_data || jsonb_build_object('route', '/seller');
    WHEN 'kyc_rejected' THEN
      v_title := 'Verification update';
      v_body := 'Your seller verification needs attention.';
      v_data := v_data || jsonb_build_object('route', '/seller/kyc');
    ELSE
      v_title := 'PetFolio';
      v_body := v_actor_name || ' interacted with you.';
      v_data := v_data || jsonb_build_object('route', '/social/notifications');
  END CASE;

  PERFORM private.dispatch_fcm_push(v_user_id, v_title, v_body, v_data);
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_notification_fcm_push ON public.notifications;
CREATE TRIGGER trg_notification_fcm_push
  AFTER INSERT ON public.notifications
  FOR EACH ROW
  EXECUTE FUNCTION private.handle_notification_fcm_push();

CREATE OR REPLACE FUNCTION private.handle_chat_message_fcm_push()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, private
AS $$
DECLARE
  v_recipient uuid;
  v_sender_handle text;
  v_preview text;
BEGIN
  SELECT
    CASE
      WHEN t.participant_1_id = NEW.sender_id THEN t.participant_2_id
      ELSE t.participant_1_id
    END
  INTO v_recipient
  FROM public.chat_threads t
  WHERE t.id = NEW.thread_id;

  IF v_recipient IS NULL OR v_recipient = NEW.sender_id THEN
    RETURN NEW;
  END IF;

  SELECT COALESCE('@' || p.handle, 'Someone')
  INTO v_sender_handle
  FROM public.pets p
  WHERE p.owner_id = NEW.sender_id
  ORDER BY p.id
  LIMIT 1;

  v_preview := left(regexp_replace(NEW.content, '\s+', ' ', 'g'), 120);

  PERFORM private.dispatch_fcm_push(
    v_recipient,
    'New message',
    COALESCE(v_sender_handle, 'Someone') || ': ' || v_preview,
    jsonb_build_object(
      'type', 'chat_message',
      'thread_id', NEW.thread_id::text,
      'route', '/matching/chat/' || NEW.thread_id::text
    )
  );

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_chat_message_fcm_push ON public.chat_messages;
CREATE TRIGGER trg_chat_message_fcm_push
  AFTER INSERT ON public.chat_messages
  FOR EACH ROW
  EXECUTE FUNCTION private.handle_chat_message_fcm_push();

CREATE OR REPLACE FUNCTION private.handle_match_fcm_push()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, private
AS $$
DECLARE
  v_owner_a uuid;
  v_owner_b uuid;
  v_name_a text;
  v_name_b text;
BEGIN
  SELECT owner_id, name INTO v_owner_a, v_name_a FROM public.pets WHERE id = NEW.pet_a_id;
  SELECT owner_id, name INTO v_owner_b, v_name_b FROM public.pets WHERE id = NEW.pet_b_id;

  IF v_owner_a IS NOT NULL AND v_owner_a IS DISTINCT FROM v_owner_b THEN
    PERFORM private.dispatch_fcm_push(
      v_owner_a,
      'New match!',
      'You matched with ' || COALESCE(v_name_b, 'a pet') || '.',
      jsonb_build_object('type', 'match', 'route', '/matching/inbox')
    );
  END IF;

  IF v_owner_b IS NOT NULL AND v_owner_b IS DISTINCT FROM v_owner_a THEN
    PERFORM private.dispatch_fcm_push(
      v_owner_b,
      'New match!',
      'You matched with ' || COALESCE(v_name_a, 'a pet') || '.',
      jsonb_build_object('type', 'match', 'route', '/matching/inbox')
    );
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_match_fcm_push ON public.matches;
CREATE TRIGGER trg_match_fcm_push
  AFTER INSERT ON public.matches
  FOR EACH ROW
  EXECUTE FUNCTION private.handle_match_fcm_push();

CREATE OR REPLACE FUNCTION private.handle_order_status_fcm_push()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, private
AS $$
DECLARE
  v_shop_name text;
  v_seller_id uuid;
BEGIN
  IF NEW.status IS NOT DISTINCT FROM OLD.status THEN
    RETURN NEW;
  END IF;

  IF NEW.shop_id IS NOT NULL THEN
    SELECT s.name, s.owner_id INTO v_shop_name, v_seller_id
    FROM public.shops s
    WHERE s.id = NEW.shop_id;
  END IF;
  v_seller_id := COALESCE(v_seller_id, NEW.seller_id);
  v_shop_name := COALESCE(v_shop_name, 'your shop');

  IF NEW.status = 'processing'
     AND OLD.status IS DISTINCT FROM 'processing'
     AND NEW.buyer_id IS NOT NULL THEN
    PERFORM private.dispatch_fcm_push(
      NEW.buyer_id,
      'Order confirmed',
      'Your order is being prepared.',
      jsonb_build_object(
        'type', 'order',
        'order_id', NEW.id::text,
        'route', '/profile/orders/' || NEW.id::text
      )
    );
    IF v_seller_id IS NOT NULL THEN
      PERFORM private.dispatch_fcm_push(
        v_seller_id,
        'New order',
        'You have a new order at ' || v_shop_name || '.',
        jsonb_build_object(
          'type', 'seller_order',
          'order_id', NEW.id::text,
          'route', '/seller/orders/' || NEW.id::text
        )
      );
    END IF;
  ELSIF NEW.status = 'shipped'
        AND OLD.status IS DISTINCT FROM 'shipped'
        AND NEW.buyer_id IS NOT NULL THEN
    PERFORM private.dispatch_fcm_push(
      NEW.buyer_id,
      'Order shipped',
      'Your order is on the way.',
      jsonb_build_object(
        'type', 'order',
        'order_id', NEW.id::text,
        'route', '/profile/orders/' || NEW.id::text
      )
    );
  ELSIF NEW.status = 'delivered'
        AND OLD.status IS DISTINCT FROM 'delivered'
        AND NEW.buyer_id IS NOT NULL THEN
    PERFORM private.dispatch_fcm_push(
      NEW.buyer_id,
      'Order delivered',
      'Your order was delivered.',
      jsonb_build_object(
        'type', 'order',
        'order_id', NEW.id::text,
        'route', '/profile/orders/' || NEW.id::text
      )
    );
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_order_status_fcm_push ON public.marketplace_orders;
CREATE TRIGGER trg_order_status_fcm_push
  AFTER UPDATE OF status ON public.marketplace_orders
  FOR EACH ROW
  EXECUTE FUNCTION private.handle_order_status_fcm_push();

DO $$
DECLARE
  r record;
BEGIN
  FOR r IN SELECT jobid FROM cron.job WHERE jobname IN ('process_fcm_outbox', 'process_care_fcm_reminders')
  LOOP
    PERFORM cron.unschedule(r.jobid);
  END LOOP;
END;
$$;

SELECT cron.schedule(
  'process_fcm_outbox',
  '* * * * *',
  $$
  SELECT net.http_post(
    url := (SELECT rtrim(functions_base_url, '/') || '/process-fcm-outbox' FROM private.fcm_internal_config WHERE id = 1),
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'x-fcm-dispatch-secret', (SELECT dispatch_secret FROM private.fcm_internal_config WHERE id = 1)
    ),
    body := '{}'::jsonb
  );
  $$
);

SELECT cron.schedule(
  'process_care_fcm_reminders',
  '*/5 * * * *',
  $$
  SELECT net.http_post(
    url := (SELECT rtrim(functions_base_url, '/') || '/process-care-fcm-reminders' FROM private.fcm_internal_config WHERE id = 1),
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'x-fcm-dispatch-secret', (SELECT dispatch_secret FROM private.fcm_internal_config WHERE id = 1)
    ),
    body := '{}'::jsonb
  );
  $$
);
