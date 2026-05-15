-- Create the comments table for social post discussions.
--
-- Columns:
--   id          – PK, auto-generated UUID.
--   post_id     – FK to posts(id); deleting a post cascades to its comments.
--   author_id   – FK to auth.users; the Supabase user who wrote the comment.
--   pet_id      – FK to pets(id); the pet persona used when commenting.
--   content     – The comment body text (non-empty enforced at app level).
--   created_at  – Server-set timestamp.

CREATE TABLE IF NOT EXISTS comments (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id    UUID NOT NULL REFERENCES posts(id)  ON DELETE CASCADE,
  author_id  UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  pet_id     UUID NOT NULL REFERENCES pets(id)   ON DELETE CASCADE,
  content    TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Index for fast per-post comment retrieval (ordered by created_at).
CREATE INDEX IF NOT EXISTS comments_post_id_created_at_idx
  ON comments (post_id, created_at ASC);

-- ── Row-Level Security ────────────────────────────────────────────────────────

ALTER TABLE comments ENABLE ROW LEVEL SECURITY;

-- Anyone (including anonymous users) can read comments.
CREATE POLICY "comments_select_policy"
  ON comments FOR SELECT
  USING (true);

-- Only the comment's author can insert; they must be logged in and the
-- author_id must match their Supabase UID to prevent spoofing.
CREATE POLICY "comments_insert_policy"
  ON comments FOR INSERT
  WITH CHECK (author_id = auth.uid());

-- Only the comment's author can delete their own comments.
CREATE POLICY "comments_delete_policy"
  ON comments FOR DELETE
  USING (author_id = auth.uid());
