-- ============================================================
-- PETFOLIO  –  Complete Database Schema
-- PostgreSQL 17  |  Supabase  |  Project: petfolio
--
-- Sections:
--   0. Private schema
--   1. Tables (dependency order)
--   2. Indexes
--   3. Row Level Security
--   4. RLS Policies
--   5. Trigger functions
--   6. Triggers
--   7. Grants
-- ============================================================

-- ── 0. PRIVATE SCHEMA ─────────────────────────────────────────
-- SECURITY DEFINER functions live here so they are never
-- reachable through the Supabase Data (REST/GraphQL) API.
CREATE SCHEMA IF NOT EXISTS private;

-- ── 1. TABLES ─────────────────────────────────────────────────

-- 1a. USERS  (mirrors auth.users with public profile data)
CREATE TABLE IF NOT EXISTS public.users (
  id           uuid        PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username     text        UNIQUE NOT NULL,
  display_name text        NOT NULL DEFAULT '',
  avatar_url   text,
  bio          text,
  location     text,
  created_at   timestamptz NOT NULL DEFAULT now(),
  updated_at   timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.users IS 'Public profile for every authenticated user.';

-- 1b. PETS
CREATE TABLE IF NOT EXISTS public.pets (
  id            uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id      uuid        NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  name          text        NOT NULL,
  species       text        NOT NULL,
  breed         text,
  date_of_birth date,
  gender        text        CHECK (gender IN ('male', 'female', 'unknown')) DEFAULT 'unknown',
  weight_kg     numeric(5,2),
  avatar_url    text,
  bio           text,
  is_public     boolean     NOT NULL DEFAULT true,
  created_at    timestamptz NOT NULL DEFAULT now(),
  updated_at    timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.pets IS 'Pet profiles owned by users.';

-- 1c. CARE_LOGS
CREATE TABLE IF NOT EXISTS public.care_logs (
  id               uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  pet_id           uuid        NOT NULL REFERENCES public.pets(id) ON DELETE CASCADE,
  logged_by        uuid        NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  care_type        text        NOT NULL CHECK (care_type IN (
                                 'feeding', 'walk', 'grooming', 'medication',
                                 'vet_visit', 'training', 'playtime', 'other')),
  notes            text,
  duration_minutes int         CHECK (duration_minutes > 0),
  occurred_at      timestamptz NOT NULL DEFAULT now(),
  created_at       timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.care_logs IS 'Activity log entries for each pet.';

-- 1d. HEALTH_VITALS
CREATE TABLE IF NOT EXISTS public.health_vitals (
  id          uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  pet_id      uuid        NOT NULL REFERENCES public.pets(id) ON DELETE CASCADE,
  recorded_by uuid        NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  vital_type  text        NOT NULL CHECK (vital_type IN (
                            'weight', 'temperature', 'heart_rate',
                            'blood_pressure', 'glucose', 'other')),
  value       numeric     NOT NULL,
  unit        text        NOT NULL,
  notes       text,
  recorded_at timestamptz NOT NULL DEFAULT now(),
  created_at  timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.health_vitals IS 'Time-series health measurements for each pet.';

-- 1e. POSTS  (social feed)
CREATE TABLE IF NOT EXISTS public.posts (
  id            uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  author_id     uuid        NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  pet_id        uuid        REFERENCES public.pets(id) ON DELETE SET NULL,
  content       text        NOT NULL,
  image_urls    text[]      NOT NULL DEFAULT '{}',
  visibility    text        NOT NULL
                  CHECK (visibility IN ('public', 'followers', 'private'))
                  DEFAULT 'public',
  like_count    int         NOT NULL DEFAULT 0 CHECK (like_count >= 0),
  comment_count int         NOT NULL DEFAULT 0 CHECK (comment_count >= 0),
  created_at    timestamptz NOT NULL DEFAULT now(),
  updated_at    timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.posts IS 'Social feed posts, optionally linked to a pet.';

-- 1f. MATCH_REQUESTS  (playdate / breeding / adoption)
CREATE TABLE IF NOT EXISTS public.match_requests (
  id               uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  requester_id     uuid        NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  target_id        uuid        NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  requester_pet_id uuid        NOT NULL REFERENCES public.pets(id) ON DELETE CASCADE,
  target_pet_id    uuid        NOT NULL REFERENCES public.pets(id) ON DELETE CASCADE,
  match_type       text        NOT NULL CHECK (match_type IN ('playdate', 'breeding', 'adoption')),
  status           text        NOT NULL
                     CHECK (status IN ('pending', 'accepted', 'rejected', 'cancelled'))
                     DEFAULT 'pending',
  message          text,
  created_at       timestamptz NOT NULL DEFAULT now(),
  updated_at       timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT no_self_match CHECK (requester_id != target_id)
);
COMMENT ON TABLE public.match_requests IS
  'Match requests between pet owners. Accepting triggers chat_thread creation.';

-- 1g. CHAT_THREADS
-- Rows are inserted only by private.handle_match_accepted() trigger.
-- No INSERT policy is granted to end users.
CREATE TABLE IF NOT EXISTS public.chat_threads (
  id               uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  match_request_id uuid        UNIQUE REFERENCES public.match_requests(id) ON DELETE SET NULL,
  participant_1_id uuid        NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  participant_2_id uuid        NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  last_message_at  timestamptz,
  created_at       timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT no_self_thread CHECK (participant_1_id != participant_2_id)
);
COMMENT ON TABLE public.chat_threads IS
  'Chat conversation channels, auto-created when a match_request is accepted.';

-- 1h. CHAT_MESSAGES
CREATE TABLE IF NOT EXISTS public.chat_messages (
  id         uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  thread_id  uuid        NOT NULL REFERENCES public.chat_threads(id) ON DELETE CASCADE,
  sender_id  uuid        NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  content    text        NOT NULL,
  is_read    boolean     NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.chat_messages IS 'Individual messages within a chat thread.';

-- 1i. MARKETPLACE_ORDERS
CREATE TABLE IF NOT EXISTS public.marketplace_orders (
  id               uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  buyer_id         uuid        NOT NULL REFERENCES public.users(id) ON DELETE RESTRICT,
  seller_id        uuid        NOT NULL REFERENCES public.users(id) ON DELETE RESTRICT,
  title            text        NOT NULL,
  description      text,
  amount_cents     bigint      NOT NULL CHECK (amount_cents > 0),
  currency         text        NOT NULL DEFAULT 'usd',
  status           text        NOT NULL
                     CHECK (status IN (
                       'pending', 'confirmed', 'shipped',
                       'delivered', 'cancelled', 'refunded'))
                     DEFAULT 'pending',
  shipping_address jsonb,
  created_at       timestamptz NOT NULL DEFAULT now(),
  updated_at       timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT no_self_order CHECK (buyer_id != seller_id)
);
COMMENT ON TABLE public.marketplace_orders IS 'Pet product and service marketplace orders.';


-- ── 2. INDEXES ────────────────────────────────────────────────
-- All FK columns used in RLS USING/WITH CHECK clauses must be indexed.

CREATE INDEX IF NOT EXISTS idx_pets_owner_id             ON public.pets(owner_id);

CREATE INDEX IF NOT EXISTS idx_care_logs_pet_id          ON public.care_logs(pet_id);
CREATE INDEX IF NOT EXISTS idx_care_logs_logged_by       ON public.care_logs(logged_by);

CREATE INDEX IF NOT EXISTS idx_health_vitals_pet_id      ON public.health_vitals(pet_id);
CREATE INDEX IF NOT EXISTS idx_health_vitals_recorded_by ON public.health_vitals(recorded_by);

CREATE INDEX IF NOT EXISTS idx_posts_author_id           ON public.posts(author_id);
CREATE INDEX IF NOT EXISTS idx_posts_pet_id              ON public.posts(pet_id);
CREATE INDEX IF NOT EXISTS idx_posts_visibility          ON public.posts(visibility);

CREATE INDEX IF NOT EXISTS idx_match_requests_requester  ON public.match_requests(requester_id);
CREATE INDEX IF NOT EXISTS idx_match_requests_target     ON public.match_requests(target_id);
CREATE INDEX IF NOT EXISTS idx_match_requests_status     ON public.match_requests(status);

CREATE INDEX IF NOT EXISTS idx_chat_threads_p1           ON public.chat_threads(participant_1_id);
CREATE INDEX IF NOT EXISTS idx_chat_threads_p2           ON public.chat_threads(participant_2_id);

CREATE INDEX IF NOT EXISTS idx_chat_messages_thread      ON public.chat_messages(thread_id);
CREATE INDEX IF NOT EXISTS idx_chat_messages_sender      ON public.chat_messages(sender_id);

CREATE INDEX IF NOT EXISTS idx_orders_buyer              ON public.marketplace_orders(buyer_id);
CREATE INDEX IF NOT EXISTS idx_orders_seller             ON public.marketplace_orders(seller_id);
CREATE INDEX IF NOT EXISTS idx_orders_status             ON public.marketplace_orders(status);


-- ── 3. ROW LEVEL SECURITY ─────────────────────────────────────
ALTER TABLE public.users              ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pets               ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.care_logs          ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.health_vitals      ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.posts              ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.match_requests     ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_threads       ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_messages      ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.marketplace_orders ENABLE ROW LEVEL SECURITY;


-- ── 4. RLS POLICIES ───────────────────────────────────────────
-- Convention:
--   • Always target `TO authenticated` (stops policy eval for anon early)
--   • Use (select auth.uid()) — caches per statement, not per row
--   • UPDATE always has both USING and WITH CHECK
--   • Every UPDATE-able table also has a SELECT policy (required by Postgres)

-- ·· users ···················································
CREATE POLICY "users: authenticated can view all profiles"
  ON public.users FOR SELECT TO authenticated
  USING (true);

CREATE POLICY "users: insert own profile only"
  ON public.users FOR INSERT TO authenticated
  WITH CHECK ((select auth.uid()) = id);

CREATE POLICY "users: update own profile only"
  ON public.users FOR UPDATE TO authenticated
  USING  ((select auth.uid()) = id)
  WITH CHECK ((select auth.uid()) = id);

CREATE POLICY "users: delete own profile only"
  ON public.users FOR DELETE TO authenticated
  USING ((select auth.uid()) = id);

-- ·· pets ····················································
CREATE POLICY "pets: select public or own"
  ON public.pets FOR SELECT TO authenticated
  USING (is_public = true OR (select auth.uid()) = owner_id);

CREATE POLICY "pets: insert own pets only"
  ON public.pets FOR INSERT TO authenticated
  WITH CHECK ((select auth.uid()) = owner_id);

CREATE POLICY "pets: update own pets only"
  ON public.pets FOR UPDATE TO authenticated
  USING  ((select auth.uid()) = owner_id)
  WITH CHECK ((select auth.uid()) = owner_id);

CREATE POLICY "pets: delete own pets only"
  ON public.pets FOR DELETE TO authenticated
  USING ((select auth.uid()) = owner_id);

-- ·· care_logs ···············································
CREATE POLICY "care_logs: select by owner or logger"
  ON public.care_logs FOR SELECT TO authenticated
  USING (
    (select auth.uid()) = logged_by
    OR (select auth.uid()) IN (
      SELECT owner_id FROM public.pets WHERE id = care_logs.pet_id
    )
  );

CREATE POLICY "care_logs: insert by pet owner only"
  ON public.care_logs FOR INSERT TO authenticated
  WITH CHECK (
    (select auth.uid()) = logged_by
    AND (select auth.uid()) IN (
      SELECT owner_id FROM public.pets WHERE id = care_logs.pet_id
    )
  );

CREATE POLICY "care_logs: update own logs only"
  ON public.care_logs FOR UPDATE TO authenticated
  USING  ((select auth.uid()) = logged_by)
  WITH CHECK ((select auth.uid()) = logged_by);

CREATE POLICY "care_logs: delete own logs only"
  ON public.care_logs FOR DELETE TO authenticated
  USING ((select auth.uid()) = logged_by);

-- ·· health_vitals ············································
CREATE POLICY "health_vitals: select by owner or recorder"
  ON public.health_vitals FOR SELECT TO authenticated
  USING (
    (select auth.uid()) = recorded_by
    OR (select auth.uid()) IN (
      SELECT owner_id FROM public.pets WHERE id = health_vitals.pet_id
    )
  );

CREATE POLICY "health_vitals: insert by pet owner only"
  ON public.health_vitals FOR INSERT TO authenticated
  WITH CHECK (
    (select auth.uid()) = recorded_by
    AND (select auth.uid()) IN (
      SELECT owner_id FROM public.pets WHERE id = health_vitals.pet_id
    )
  );

CREATE POLICY "health_vitals: update own records only"
  ON public.health_vitals FOR UPDATE TO authenticated
  USING  ((select auth.uid()) = recorded_by)
  WITH CHECK ((select auth.uid()) = recorded_by);

CREATE POLICY "health_vitals: delete own records only"
  ON public.health_vitals FOR DELETE TO authenticated
  USING ((select auth.uid()) = recorded_by);

-- ·· posts ···················································
-- 'followers' is treated as owner-only until a follow/friend system is added
CREATE POLICY "posts: select public or own"
  ON public.posts FOR SELECT TO authenticated
  USING (visibility = 'public' OR (select auth.uid()) = author_id);

CREATE POLICY "posts: insert own posts only"
  ON public.posts FOR INSERT TO authenticated
  WITH CHECK ((select auth.uid()) = author_id);

CREATE POLICY "posts: update own posts only"
  ON public.posts FOR UPDATE TO authenticated
  USING  ((select auth.uid()) = author_id)
  WITH CHECK ((select auth.uid()) = author_id);

CREATE POLICY "posts: delete own posts only"
  ON public.posts FOR DELETE TO authenticated
  USING ((select auth.uid()) = author_id);

-- ·· match_requests ···········································
CREATE POLICY "match_requests: select by requester or target"
  ON public.match_requests FOR SELECT TO authenticated
  USING (
    (select auth.uid()) = requester_id
    OR (select auth.uid()) = target_id
  );

CREATE POLICY "match_requests: insert as requester only"
  ON public.match_requests FOR INSERT TO authenticated
  WITH CHECK ((select auth.uid()) = requester_id);

-- Both parties can accept / reject / cancel
CREATE POLICY "match_requests: update by requester or target"
  ON public.match_requests FOR UPDATE TO authenticated
  USING (
    (select auth.uid()) = requester_id
    OR (select auth.uid()) = target_id
  )
  WITH CHECK (
    (select auth.uid()) = requester_id
    OR (select auth.uid()) = target_id
  );

-- Only the requester can retract an unsent request
CREATE POLICY "match_requests: delete by requester only"
  ON public.match_requests FOR DELETE TO authenticated
  USING ((select auth.uid()) = requester_id);

-- ·· chat_threads ·············································
-- INSERT is intentionally omitted — rows are created by trigger only
CREATE POLICY "chat_threads: select by participants only"
  ON public.chat_threads FOR SELECT TO authenticated
  USING (
    (select auth.uid()) = participant_1_id
    OR (select auth.uid()) = participant_2_id
  );

-- ·· chat_messages ············································
CREATE POLICY "chat_messages: select by thread participants"
  ON public.chat_messages FOR SELECT TO authenticated
  USING (
    (select auth.uid()) IN (
      SELECT participant_1_id FROM public.chat_threads WHERE id = chat_messages.thread_id
      UNION ALL
      SELECT participant_2_id FROM public.chat_threads WHERE id = chat_messages.thread_id
    )
  );

-- Sender must be a participant of the target thread
CREATE POLICY "chat_messages: insert by thread participants"
  ON public.chat_messages FOR INSERT TO authenticated
  WITH CHECK (
    (select auth.uid()) = sender_id
    AND (select auth.uid()) IN (
      SELECT participant_1_id FROM public.chat_threads WHERE id = chat_messages.thread_id
      UNION ALL
      SELECT participant_2_id FROM public.chat_threads WHERE id = chat_messages.thread_id
    )
  );

-- ·· marketplace_orders ·······································
CREATE POLICY "orders: select by buyer or seller"
  ON public.marketplace_orders FOR SELECT TO authenticated
  USING (
    (select auth.uid()) = buyer_id
    OR (select auth.uid()) = seller_id
  );

CREATE POLICY "orders: insert as buyer only"
  ON public.marketplace_orders FOR INSERT TO authenticated
  WITH CHECK ((select auth.uid()) = buyer_id);

CREATE POLICY "orders: update by buyer or seller"
  ON public.marketplace_orders FOR UPDATE TO authenticated
  USING (
    (select auth.uid()) = buyer_id
    OR (select auth.uid()) = seller_id
  )
  WITH CHECK (
    (select auth.uid()) = buyer_id
    OR (select auth.uid()) = seller_id
  );

-- Buyer can only delete their own pending orders
CREATE POLICY "orders: delete by buyer when pending"
  ON public.marketplace_orders FOR DELETE TO authenticated
  USING ((select auth.uid()) = buyer_id AND status = 'pending');


-- ── 5. TRIGGER FUNCTIONS ──────────────────────────────────────

-- 5a. updated_at helper (no SECURITY DEFINER, search_path pinned)
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql
SET search_path = '' AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

-- 5b. last_message_at denormalization (no SECURITY DEFINER, search_path pinned)
CREATE OR REPLACE FUNCTION public.handle_new_chat_message()
RETURNS TRIGGER LANGUAGE plpgsql
SET search_path = '' AS $$
BEGIN
  UPDATE public.chat_threads
  SET last_message_at = NEW.created_at
  WHERE id = NEW.thread_id;
  RETURN NEW;
END;
$$;

-- 5c. Auto-provision public.users row when auth.users is created
-- SECURITY DEFINER + private schema: runs as postgres, bypasses RLS safely
CREATE OR REPLACE FUNCTION private.handle_new_user()
RETURNS TRIGGER LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public AS $$
BEGIN
  INSERT INTO public.users (id, username, display_name)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'username',  split_part(NEW.email, '@', 1)),
    COALESCE(NEW.raw_user_meta_data->>'display_name', split_part(NEW.email, '@', 1))
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$;

-- 5d. Auto-create chat_thread when a match_request is accepted
-- SECURITY DEFINER + private schema: users have no INSERT grant on chat_threads.
-- ON CONFLICT (match_request_id) makes this idempotent.
CREATE OR REPLACE FUNCTION private.handle_match_accepted()
RETURNS TRIGGER LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF NEW.status = 'accepted' AND (OLD.status IS DISTINCT FROM 'accepted') THEN
    INSERT INTO public.chat_threads (
      match_request_id,
      participant_1_id,
      participant_2_id
    )
    VALUES (
      NEW.id,
      NEW.requester_id,
      NEW.target_id
    )
    ON CONFLICT (match_request_id) DO NOTHING;
  END IF;
  RETURN NEW;
END;
$$;


-- ── 6. TRIGGERS ───────────────────────────────────────────────

-- updated_at
CREATE OR REPLACE TRIGGER set_updated_at_users
  BEFORE UPDATE ON public.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE OR REPLACE TRIGGER set_updated_at_pets
  BEFORE UPDATE ON public.pets
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE OR REPLACE TRIGGER set_updated_at_posts
  BEFORE UPDATE ON public.posts
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE OR REPLACE TRIGGER set_updated_at_match_requests
  BEFORE UPDATE ON public.match_requests
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE OR REPLACE TRIGGER set_updated_at_marketplace_orders
  BEFORE UPDATE ON public.marketplace_orders
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- last_message_at denorm
DROP TRIGGER IF EXISTS on_chat_message_sent ON public.chat_messages;
CREATE TRIGGER on_chat_message_sent
  AFTER INSERT ON public.chat_messages
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_chat_message();

-- auth.users → public.users sync
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION private.handle_new_user();

-- match_requests accepted → chat_thread created
DROP TRIGGER IF EXISTS on_match_accepted ON public.match_requests;
CREATE TRIGGER on_match_accepted
  AFTER UPDATE ON public.match_requests
  FOR EACH ROW EXECUTE FUNCTION private.handle_match_accepted();


-- ── 7. GRANTS ─────────────────────────────────────────────────
-- RLS controls which ROWS are visible; GRANTs control which TABLES are reachable.
-- Tables not listed below are inaccessible via the API by default.

GRANT USAGE ON SCHEMA public TO anon, authenticated;

-- users: anon can see public profiles; authenticated can mutate own row (RLS enforces)
GRANT SELECT                         ON public.users              TO anon, authenticated;
GRANT INSERT, UPDATE, DELETE         ON public.users              TO authenticated;

-- pets: anon can read (RLS limits to is_public = true); authenticated can mutate own
GRANT SELECT                         ON public.pets               TO anon, authenticated;
GRANT INSERT, UPDATE, DELETE         ON public.pets               TO authenticated;

-- care & health: authenticated only (private data)
GRANT SELECT, INSERT, UPDATE, DELETE ON public.care_logs          TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.health_vitals      TO authenticated;

-- posts: anon can read public posts; authenticated can mutate own
GRANT SELECT                         ON public.posts              TO anon, authenticated;
GRANT INSERT, UPDATE, DELETE         ON public.posts              TO authenticated;

-- matching: authenticated only
GRANT SELECT, INSERT, UPDATE, DELETE ON public.match_requests     TO authenticated;

-- chat: SELECT only on threads (no INSERT — trigger-only creation); messages: SELECT + INSERT
GRANT SELECT                         ON public.chat_threads       TO authenticated;
GRANT SELECT, INSERT                 ON public.chat_messages      TO authenticated;

-- marketplace: authenticated only
GRANT SELECT, INSERT, UPDATE, DELETE ON public.marketplace_orders TO authenticated;
