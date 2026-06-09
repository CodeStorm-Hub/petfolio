-- Chat read receipts: allow participants to mark inbound messages as read.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'chat_messages'
      AND policyname = 'chat_messages: mark read by participant'
  ) THEN
    EXECUTE $policy$
      CREATE POLICY "chat_messages: mark read by participant"
        ON public.chat_messages FOR UPDATE TO authenticated
        USING (
          thread_id IN (
            SELECT id FROM public.chat_threads
            WHERE participant_1_id = (SELECT auth.uid())
               OR participant_2_id = (SELECT auth.uid())
          )
          AND sender_id <> (SELECT auth.uid())
        )
        WITH CHECK (
          is_read = true
          AND sender_id <> (SELECT auth.uid())
        )
    $policy$;
  END IF;
END $$;

-- Story emoji reactions (E10).
CREATE TABLE IF NOT EXISTS public.story_reactions (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  story_id   uuid NOT NULL REFERENCES public.stories(id) ON DELETE CASCADE,
  user_id    uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  emoji      text NOT NULL CHECK (char_length(emoji) BETWEEN 1 AND 8),
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (story_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_story_reactions_story_id
  ON public.story_reactions(story_id);

ALTER TABLE public.story_reactions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "story_reactions_select"
  ON public.story_reactions FOR SELECT
  USING (true);

CREATE POLICY "story_reactions_upsert"
  ON public.story_reactions FOR INSERT
  TO authenticated
  WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "story_reactions_update"
  ON public.story_reactions FOR UPDATE
  TO authenticated
  USING ((SELECT auth.uid()) = user_id)
  WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "story_reactions_delete"
  ON public.story_reactions FOR DELETE
  TO authenticated
  USING ((SELECT auth.uid()) = user_id);

GRANT SELECT ON public.story_reactions TO anon, authenticated;
GRANT INSERT, UPDATE, DELETE ON public.story_reactions TO authenticated;
