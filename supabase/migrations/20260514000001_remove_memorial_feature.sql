-- Drop the post_candles table
DROP TABLE IF EXISTS post_candles;

-- Remove the is_memorial column from posts
ALTER TABLE posts DROP COLUMN IF EXISTS is_memorial;
