-- Drop unused views
DROP VIEW IF EXISTS vw_match_threads;
DROP VIEW IF EXISTS vw_social_threads;

-- Drop unused tables
DROP TABLE IF EXISTS match_requests CASCADE;
DROP TABLE IF EXISTS follows CASCADE;

-- Add BTREE indexes for heavily used foreign keys to prevent sequential scans
CREATE INDEX IF NOT EXISTS idx_care_logs_pet_id ON care_logs USING BTREE(pet_id);
CREATE INDEX IF NOT EXISTS idx_posts_author_id ON posts USING BTREE(author_id);
CREATE INDEX IF NOT EXISTS idx_posts_pet_id ON posts USING BTREE(pet_id);
