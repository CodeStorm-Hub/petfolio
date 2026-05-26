# Supabase Database Schema Review

**Project:** petfolio (ID: jqyjvhwlcqcsuwcqgcwf)

## Table Summary
- **9 tables** in the `public` schema
- **All tables have Row Level Security (RLS) enabled**

---

## 1. users
**Primary Key:** id (uuid)

| Column | Type | Nullable | Default | Constraints |
|--------|------|----------|---------|-------------|
| id | uuid | NO | - | PK, FK to auth.users.id |
| username | text | NO | - | unique |
| display_name | text | NO | ''::text | - |
| avatar_url | text | YES | - | - |
| bio | text | YES | - | - |
| location | text | YES | - | - |
| created_at | timestamptz | NO | now() | - |
| updated_at | timestamptz | NO | now() | - |

**Foreign Key Relationships:**
- Referenced by: pets.owner_id, care_logs.logged_by, match_requests.requester_id/target_id, health_vitals.recorded_by, posts.author_id, chat_threads.participant_1_id/participant_2_id, chat_messages.sender_id, marketplace_orders.buyer_id/seller_id

---

## 2. pets
**Primary Key:** id (uuid)

| Column | Type | Nullable | Default | Constraints |
|--------|------|----------|---------|-------------|
| id | uuid | NO | gen_random_uuid() | PK |
| owner_id | uuid | NO | - | FK to users.id |
| name | text | NO | - | - |
| species | text | NO | - | - |
| breed | text | YES | - | - |
| date_of_birth | date | YES | - | - |
| gender | text | NO | 'unknown' | check: male/female/unknown |
| weight_kg | numeric | YES | - | - |
| avatar_url | text | YES | - | - |
| bio | text | YES | - | - |
| is_public | boolean | NO | true | - |
| created_at | timestamptz | NO | now() | - |
| updated_at | timestamptz | NO | now() | - |

**Foreign Key Relationships:**
- Referenced by: care_logs.pet_id, health_vitals.pet_id, match_requests.requester_pet_id/target_pet_id, posts.pet_id

---

## 3. care_logs
**Primary Key:** id (uuid)

| Column | Type | Nullable | Default | Constraints |
|--------|------|----------|---------|-------------|
| id | uuid | NO | gen_random_uuid() | PK |
| pet_id | uuid | NO | - | FK to pets.id |
| logged_by | uuid | NO | - | FK to users.id |
| care_type | text | NO | - | check: feeding/walk/grooming/medication/vet_visit/training/playtime/other |
| notes | text | YES | - | - |
| duration_minutes | integer | YES | - | check: > 0 |
| occurred_at | timestamptz | NO | now() | - |
| created_at | timestamptz | NO | now() | - |

---

## 4. health_vitals
**Primary Key:** id (uuid)

| Column | Type | Nullable | Default | Constraints |
|--------|------|----------|---------|-------------|
| id | uuid | NO | gen_random_uuid() | PK |
| pet_id | uuid | NO | - | FK to pets.id |
| recorded_by | uuid | NO | - | FK to users.id |
| vital_type | text | NO | - | check: weight/temperature/heart_rate/blood_pressure/glucose/other |
| value | numeric | NO | - | - |
| unit | text | NO | - | - |
| notes | text | YES | - | - |
| recorded_at | timestamptz | NO | now() | - |
| created_at | timestamptz | NO | now() | - |

---

## 5. posts
**Primary Key:** id (uuid)

| Column | Type | Nullable | Default | Constraints |
|--------|------|----------|---------|-------------|
| id | uuid | NO | gen_random_uuid() | PK |
| author_id | uuid | NO | - | FK to users.id |
| pet_id | uuid | YES | - | FK to pets.id |
| content | text | NO | - | - |
| image_urls | text[] | NO | '{}' | - |
| visibility | text | NO | 'public' | check: public/followers/private |
| like_count | integer | NO | 0 | check: >= 0 |
| comment_count | integer | NO | 0 | check: >= 0 |
| created_at | timestamptz | NO | now() | - |
| updated_at | timestamptz | NO | now() | - |

---

## 6. match_requests
**Primary Key:** id (uuid)

| Column | Type | Nullable | Default | Constraints |
|--------|------|----------|---------|-------------|
| id | uuid | NO | gen_random_uuid() | PK |
| requester_id | uuid | NO | - | FK to users.id |
| target_id | uuid | NO | - | FK to users.id |
| requester_pet_id | uuid | NO | - | FK to pets.id |
| target_pet_id | uuid | NO | - | FK to pets.id |
| match_type | text | NO | - | check: playdate/breeding/adoption |
| status | text | NO | 'pending' | check: pending/accepted/rejected/cancelled |
| message | text | YES | - | - |
| created_at | timestamptz | NO | now() | - |
| updated_at | timestamptz | NO | now() | - |

**Foreign Key Relationships:**
- Referenced by: chat_threads.match_request_id

---

## 7. chat_threads
**Primary Key:** id (uuid)

| Column | Type | Nullable | Default | Constraints |
|--------|------|----------|---------|-------------|
| id | uuid | NO | gen_random_uuid() | PK |
| match_request_id | uuid | YES | - | FK to match_requests.id, unique |
| participant_1_id | uuid | NO | - | FK to users.id |
| participant_2_id | uuid | NO | - | FK to users.id |
| last_message_at | timestamptz | YES | - | - |
| created_at | timestamptz | NO | now() | - |

**Foreign Key Relationships:**
- Referenced by: chat_messages.thread_id

---

## 8. chat_messages
**Primary Key:** id (uuid)

| Column | Type | Nullable | Default | Constraints |
|--------|------|----------|---------|-------------|
| id | uuid | NO | gen_random_uuid() | PK |
| thread_id | uuid | NO | - | FK to chat_threads.id |
| sender_id | uuid | NO | - | FK to users.id |
| content | text | NO | - | - |
| is_read | boolean | NO | false | - |
| created_at | timestamptz | NO | now() | - |

---

## 9. marketplace_orders
**Primary Key:** id (uuid)

| Column | Type | Nullable | Default | Constraints |
|--------|------|----------|---------|-------------|
| id | uuid | NO | gen_random_uuid() | PK |
| buyer_id | uuid | NO | - | FK to users.id |
| seller_id | uuid | NO | - | FK to users.id |
| title | text | NO | - | - |
| description | text | YES | - | - |
| amount_cents | bigint | NO | - | check: > 0 |
| currency | text | NO | 'usd' | - |
| status | text | NO | 'pending' | check: pending/confirmed/shipped/delivered/cancelled/refunded |
| shipping_address | jsonb | YES | - | - |
| created_at | timestamptz | NO | now() | - |
| updated_at | timestamptz | NO | now() | - |

---

## Entity Relationship Summary
- **users** is the central entity, referenced by 10 other tables
- **pets** belongs to users and is referenced by 5 tables
- **match_requests** connects two users and their pets, and links to chat_threads
- **chat_threads** connects two users and contains chat_messages
- **posts** can optionally reference a pet
- **care_logs** and **health_vitals** track pet care activities