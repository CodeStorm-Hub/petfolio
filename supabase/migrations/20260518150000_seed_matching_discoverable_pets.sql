DO $$
DECLARE
  base_lng double precision := -122.084;
  base_lat double precision := 37.422;
BEGIN
  UPDATE public.pets SET
    is_public = true,
    is_discoverable = true,
    bio = COALESCE(bio, 'Friendly and ready to meet new friends nearby.'),
    date_of_birth = COALESCE(date_of_birth, (CURRENT_DATE - INTERVAL '3 years')::date),
    activity_level = COALESCE(activity_level, 'moderate'),
    location = ST_SetSRID(ST_MakePoint(base_lng + 0.012, base_lat + 0.008), 4326)::geography
  WHERE id = 'd287308b-8f99-45e5-ae59-d38486697d31';

  UPDATE public.pets SET
    is_public = true,
    is_discoverable = true,
    bio = COALESCE(bio, 'Playful Persian who loves calm introductions.'),
    activity_level = COALESCE(activity_level, 'low'),
    location = ST_SetSRID(ST_MakePoint(base_lng - 0.006, base_lat + 0.004), 4326)::geography
  WHERE id = '4c0c7bb1-4319-4b11-8a29-918b8e4c3ccc';

  UPDATE public.pets SET
    is_public = true,
    is_discoverable = true,
    bio = COALESCE(bio, 'Young cat looking for playdates and cuddles.'),
    activity_level = COALESCE(activity_level, 'moderate'),
    location = ST_SetSRID(ST_MakePoint(base_lng + 0.002, base_lat - 0.003), 4326)::geography
  WHERE id = 'e462295a-ca39-4744-95e3-c9ea945b0ca5';

  UPDATE public.pets SET
    is_public = true,
    is_discoverable = true,
    bio = COALESCE(bio, 'Curious indoor cat — treat-motivated.'),
    date_of_birth = COALESCE(date_of_birth, (CURRENT_DATE - INTERVAL '2 years')::date),
    activity_level = COALESCE(activity_level, 'moderate'),
    location = ST_SetSRID(ST_MakePoint(base_lng, base_lat), 4326)::geography
  WHERE id = '14378b2e-5961-4d07-ab9f-48246e839e10';

  UPDATE public.pets SET
    is_public = true,
    is_discoverable = true,
    bio = COALESCE(bio, 'Golden retriever energy — great on walks and at the park.'),
    activity_level = COALESCE(activity_level, 'high'),
    location = ST_SetSRID(ST_MakePoint(base_lng + 0.018, base_lat - 0.010), 4326)::geography
  WHERE id = 'e23b4fa6-34ed-4c89-a9ff-7efb661d6141';

  UPDATE public.pets SET
    is_public = true,
    is_discoverable = true,
    bio = COALESCE(bio, 'Happy mixed-breed pup — loves fetch and new pals.'),
    date_of_birth = COALESCE(date_of_birth, (CURRENT_DATE - INTERVAL '2 years')::date),
    activity_level = COALESCE(activity_level, 'high'),
    location = ST_SetSRID(ST_MakePoint(base_lng - 0.015, base_lat - 0.012), 4326)::geography
  WHERE id = 'ca2ffad9-b18f-498d-b609-10d5e7a60b1e';
END $$;

INSERT INTO public.pets (
  id,
  owner_id,
  name,
  species,
  breed,
  date_of_birth,
  gender,
  weight_kg,
  bio,
  is_public,
  is_discoverable,
  activity_level,
  display_order,
  location
) VALUES
  (
    'a1000001-0001-4000-8000-000000000001',
    '0ebef945-12d5-49d8-b2e2-f554634365ff',
    'Cooper',
    'dog',
    'Labrador Retriever',
    (CURRENT_DATE - INTERVAL '4 years')::date,
    'male',
    28.5,
    'Outgoing lab who loves park meetups and gentle play.',
    true,
    true,
    'high',
    1,
    ST_SetSRID(ST_MakePoint(-122.071, 37.435), 4326)::geography
  ),
  (
    'a1000001-0001-4000-8000-000000000002',
    '53623a91-1133-4431-951f-b478cba4fe81',
    'Clover',
    'rabbit',
    'Holland Lop',
    (CURRENT_DATE - INTERVAL '18 months')::date,
    'female',
    1.8,
    'Gentle bunny — best with calm pets and supervised hops.',
    true,
    true,
    'low',
    1,
    ST_SetSRID(ST_MakePoint(-122.095, 37.428), 4326)::geography
  ),
  (
    'a1000001-0001-4000-8000-000000000003',
    'a49b3aa0-0a8f-42e5-a95f-9c512a39c513',
    'Sunny',
    'bird',
    'Cockatiel',
    (CURRENT_DATE - INTERVAL '10 months')::date,
    'unknown',
    0.09,
    'Chatty cockatiel — curious about other small pets from a distance.',
    true,
    true,
    'moderate',
    1,
    ST_SetSRID(ST_MakePoint(-122.078, 37.415), 4326)::geography
  ),
  (
    'a1000001-0001-4000-8000-000000000004',
    '7d41d5c6-a21b-4e25-966e-2d5e813b43d0',
    'Nori',
    'fish',
    'Betta',
    (CURRENT_DATE - INTERVAL '8 months')::date,
    'male',
    NULL,
    'Colorful betta — low-key tank mate interest for experienced owners.',
    true,
    true,
    'sedentary',
    2,
    ST_SetSRID(ST_MakePoint(-122.088, 37.418), 4326)::geography
  ),
  (
    'a1000001-0001-4000-8000-000000000005',
    '7d41d5c6-a21b-4e25-966e-2d5e813b43d0',
    'Rex',
    'reptile',
    'Bearded Dragon',
    (CURRENT_DATE - INTERVAL '3 years')::date,
    'male',
    0.45,
    'Chill beardie — enjoys basking and slow introductions.',
    true,
    true,
    'low',
    3,
    ST_SetSRID(ST_MakePoint(-122.076, 37.426), 4326)::geography
  ),
  (
    'a1000001-0001-4000-8000-000000000006',
    '81ed5508-e634-4957-805a-efd800cf7dd8',
    'Willow',
    'rabbit',
    'Mini Rex',
    (CURRENT_DATE - INTERVAL '2 years')::date,
    'female',
    2.2,
    'Soft mini rex — binkies on demand, kid-friendly energy.',
    true,
    true,
    'moderate',
    1,
    ST_SetSRID(ST_MakePoint(-122.102, 37.410), 4326)::geography
  ),
  (
    'a1000001-0001-4000-8000-000000000007',
    '81ed5508-e634-4957-805a-efd800cf7dd8',
    'Echo',
    'bird',
    'Budgerigar',
    (CURRENT_DATE - INTERVAL '14 months')::date,
    'female',
    0.04,
    'Cheerful budgie flock curious about other birds.',
    true,
    true,
    'moderate',
    2,
    ST_SetSRID(ST_MakePoint(-122.067, 37.419), 4326)::geography
  ),
  (
    'a1000001-0001-4000-8000-000000000008',
    '0ebef945-12d5-49d8-b2e2-f554634365ff',
    'Mochi',
    'cat',
    'Domestic Shorthair',
    (CURRENT_DATE - INTERVAL '6 years')::date,
    'female',
    4.1,
    'Senior sweetheart — calm energy, perfect for quiet homes.',
    true,
    true,
    'low',
    2,
    ST_SetSRID(ST_MakePoint(-122.090, 37.432), 4326)::geography
  ),
  (
    'a1000001-0001-4000-8000-000000000009',
    '53623a91-1133-4431-951f-b478cba4fe81',
    'Duke',
    'dog',
    'Border Collie',
    (CURRENT_DATE - INTERVAL '5 years')::date,
    'male',
    22.0,
    'Smart and athletic — needs an active playmate.',
    true,
    true,
    'very_high',
    2,
    ST_SetSRID(ST_MakePoint(-122.058, 37.424), 4326)::geography
  ),
  (
    'a1000001-0001-4000-8000-000000000010',
    'a49b3aa0-0a8f-42e5-a95f-9c512a39c513',
    'Ziggy',
    'reptile',
    'Leopard Gecko',
    (CURRENT_DATE - INTERVAL '4 years')::date,
    'unknown',
    0.05,
    'Easy-going gecko — great for reptile-experienced families.',
    true,
    true,
    'sedentary',
    2,
    ST_SetSRID(ST_MakePoint(-122.081, 37.408), 4326)::geography
  )
ON CONFLICT (id) DO UPDATE SET
  is_discoverable = EXCLUDED.is_discoverable,
  is_public = EXCLUDED.is_public,
  location = EXCLUDED.location,
  bio = EXCLUDED.bio,
  activity_level = EXCLUDED.activity_level,
  date_of_birth = EXCLUDED.date_of_birth;
