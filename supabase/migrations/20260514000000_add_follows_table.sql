-- Create the follows table
CREATE TABLE pet_follows (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  follower_pet_id UUID REFERENCES pets(id) ON DELETE CASCADE,
  following_pet_id UUID REFERENCES pets(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(follower_pet_id, following_pet_id)
);

-- Enable RLS
ALTER TABLE pet_follows ENABLE ROW LEVEL SECURITY;

-- Allow everyone to see follow counts
CREATE POLICY "Public Read Access" ON pet_follows FOR SELECT USING (true);

-- Allow authenticated pets to follow others (policy based on owner_id of the follower pet)
CREATE POLICY "Pets can follow" ON pet_follows FOR INSERT WITH CHECK (
  EXISTS (
    SELECT 1 FROM pets WHERE id = follower_pet_id AND owner_id = auth.uid()
  )
);

-- Allow pets to unfollow
CREATE POLICY "Pets can unfollow" ON pet_follows FOR DELETE USING (
  EXISTS (
    SELECT 1 FROM pets WHERE id = follower_pet_id AND owner_id = auth.uid()
  )
);
