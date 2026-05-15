-- ─────────────────────────────────────────────────────────────────────────────
-- Migration: social_and_gamification_refinements
-- Documents missing tables and columns used by social and gamification features.
-- ─────────────────────────────────────────────────────────────────────────────

-- ── 0. pets — add handle ──────────────────────────────────────────────────────
-- The social models (FeedPost, Comment, AppNotification) all expect pets to 
-- have a unique @handle (e.g. 'biscuit_paws').

ALTER TABLE public.pets
  ADD COLUMN IF NOT EXISTS handle TEXT UNIQUE,
  ADD COLUMN IF NOT EXISTS accent_color TEXT DEFAULT '#FF6B9D';

-- Seed handles for existing pets (if any) based on their names to prevent nulls
UPDATE public.pets 
SET handle = lower(regexp_replace(name, '\s+', '_', 'g')) || '_' || substr(id::text, 1, 4)
WHERE handle IS NULL;

-- ── 1. post_likes ────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.post_likes (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id    UUID NOT NULL,
  pet_id     UUID NOT NULL,
  user_id    UUID NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  
  CONSTRAINT post_likes_post_id_fkey FOREIGN KEY (post_id) REFERENCES public.posts(id) ON DELETE CASCADE,
  CONSTRAINT post_likes_pet_id_fkey  FOREIGN KEY (pet_id)  REFERENCES public.pets(id)  ON DELETE CASCADE,
  CONSTRAINT post_likes_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE,
  CONSTRAINT post_likes_post_id_pet_id_key UNIQUE(post_id, pet_id)
);

ALTER TABLE public.post_likes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "post_likes: anyone can read"
  ON public.post_likes FOR SELECT
  USING (true);

CREATE POLICY "post_likes: insert own"
  ON public.post_likes FOR INSERT
  WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "post_likes: delete own"
  ON public.post_likes FOR DELETE
  USING ((SELECT auth.uid()) = user_id);

-- ── 2. notifications ─────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.notifications (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  recipient_pet_id UUID NOT NULL,
  actor_pet_id     UUID,
  type             TEXT NOT NULL CHECK (type IN ('like', 'comment', 'follow')),
  post_id          UUID,
  is_read          BOOLEAN NOT NULL DEFAULT false,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),

  CONSTRAINT notifications_recipient_pet_id_fkey FOREIGN KEY (recipient_pet_id) REFERENCES public.pets(id) ON DELETE CASCADE,
  CONSTRAINT notifications_actor_pet_id_fkey     FOREIGN KEY (actor_pet_id)     REFERENCES public.pets(id) ON DELETE SET NULL,
  CONSTRAINT notifications_post_id_fkey          FOREIGN KEY (post_id)          REFERENCES public.posts(id) ON DELETE CASCADE
);

ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

CREATE INDEX IF NOT EXISTS notifications_recipient_idx 
  ON public.notifications (recipient_pet_id, created_at DESC);

CREATE POLICY "notifications_insert_policy"
  ON public.notifications FOR INSERT
  WITH CHECK (true);

CREATE POLICY "notifications_select_policy"
  ON public.notifications FOR SELECT
  USING (
    recipient_pet_id IN (
      SELECT id FROM public.pets WHERE owner_id = (SELECT auth.uid())
    )
  );

CREATE POLICY "notifications_update_policy"
  ON public.notifications FOR UPDATE
  USING (
    recipient_pet_id IN (
      SELECT id FROM public.pets WHERE owner_id = (SELECT auth.uid())
    )
  );

-- ── 3. care_streaks ──────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.care_streaks (
  pet_id               UUID PRIMARY KEY,
  current_streak       INTEGER NOT NULL DEFAULT 0 CHECK (current_streak >= 0),
  last_completion_date DATE,
  best_streak          INTEGER NOT NULL DEFAULT 0 CHECK (best_streak >= 0),

  CONSTRAINT care_streaks_pet_id_fkey FOREIGN KEY (pet_id) REFERENCES public.pets(id) ON DELETE CASCADE
);

ALTER TABLE public.care_streaks ENABLE ROW LEVEL SECURITY;

CREATE POLICY "care_streaks: select by pet owner"
  ON public.care_streaks FOR SELECT
  USING (
    pet_id IN (
      SELECT id FROM public.pets WHERE owner_id = (SELECT auth.uid())
    )
  );

-- ── 4. pet_badges ────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.pet_badges (
  pet_id      UUID NOT NULL,
  badge_type  TEXT NOT NULL,
  unlocked_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  
  PRIMARY KEY (pet_id, badge_type),
  CONSTRAINT pet_badges_pet_id_fkey FOREIGN KEY (pet_id) REFERENCES public.pets(id) ON DELETE CASCADE
);

ALTER TABLE public.pet_badges ENABLE ROW LEVEL SECURITY;

CREATE INDEX IF NOT EXISTS pet_badges_pet_id_idx ON public.pet_badges (pet_id);

CREATE POLICY "pet_badges: select by pet owner"
  ON public.pet_badges FOR SELECT
  USING (
    pet_id IN (
      SELECT id FROM public.pets WHERE owner_id = (SELECT auth.uid())
    )
  );
