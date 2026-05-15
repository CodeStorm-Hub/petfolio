# Supabase Database Schema Review and ERD

**Project:** petfolio (ID: jqyjvhwlcqcsuwcqgcwf)

## Table Summary
- **12 tables** in the `public` schema (+ 3 added by `20260513192825_pet_care_health`)
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
| activity_level | text | YES | - | check: sedentary/low/moderate/high/very_high |
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

---

## 10. care_tasks
**Primary Key:** id (uuid)
**Added by:** `20260513192825_pet_care_health`

| Column | Type | Nullable | Default | Constraints |
|--------|------|----------|---------|-------------|
| id | uuid | NO | gen_random_uuid() | PK |
| pet_id | uuid | NO | - | FK to pets.id ON DELETE CASCADE |
| task_type | text | NO | - | check: feeding/walk/grooming/medication/vet_visit/training/playtime/dental/nail_trim/bath/other |
| title | text | NO | - | - |
| frequency | text | NO | - | check: once/daily/twice_daily/weekly/biweekly/monthly/as_needed |
| scheduled_time | time | YES | - | - |
| is_completed | boolean | NO | false | - |
| completed_at | timestamptz | YES | - | - |
| gamification_points | integer | NO | 10 | check: >= 0 |
| notes | text | YES | - | - |
| created_at | timestamptz | NO | now() | - |
| updated_at | timestamptz | NO | now() | auto-updated via trigger |

**RLS Policies:** owner-only SELECT / INSERT / UPDATE / DELETE (pet ownership via `pets.owner_id`)

---

## 11. health_logs
**Primary Key:** id (uuid)
**Added by:** `20260513192825_pet_care_health`

Narrative health events (symptoms, weight history, vet visit notes). Distinct from `health_vitals`, which stores structured numeric measurements.

| Column | Type | Nullable | Default | Constraints |
|--------|------|----------|---------|-------------|
| id | uuid | NO | gen_random_uuid() | PK |
| pet_id | uuid | NO | - | FK to pets.id ON DELETE CASCADE |
| recorded_by | uuid | NO | - | FK to users.id |
| log_type | text | NO | - | check: symptom/weight/vet_visit/medication/allergy/injury/general |
| title | text | NO | - | - |
| description | text | YES | - | - |
| weight_kg | numeric | YES | - | check: > 0 |
| severity | text | YES | - | check: mild/moderate/severe/critical |
| vet_name | text | YES | - | - |
| vet_clinic | text | YES | - | - |
| diagnosis | text | YES | - | - |
| treatment | text | YES | - | - |
| follow_up_date | date | YES | - | - |
| occurred_at | timestamptz | NO | now() | - |
| created_at | timestamptz | NO | now() | - |
| updated_at | timestamptz | NO | now() | auto-updated via trigger |

**RLS Policies:** owner-only SELECT / UPDATE / DELETE; INSERT requires caller = recorded_by AND pet owner

---

## 12. medical_vault
**Primary Key:** id (uuid)
**Added by:** `20260513192825_pet_care_health`

Vaccine and medication records with expiry / renewal date tracking.

| Column | Type | Nullable | Default | Constraints |
|--------|------|----------|---------|-------------|
| id | uuid | NO | gen_random_uuid() | PK |
| pet_id | uuid | NO | - | FK to pets.id ON DELETE CASCADE |
| record_type | text | NO | - | check: vaccine/medication/allergy/surgery/parasite_prevention/other |
| name | text | NO | - | - |
| description | text | YES | - | - |
| administered_by | text | YES | - | - |
| administered_at | date | YES | - | - |
| expires_at | date | YES | - | partial index for expiry queries |
| next_due_at | date | YES | - | partial index for reminder queries |
| batch_number | text | YES | - | - |
| dosage | text | YES | - | - |
| frequency | text | YES | - | - |
| is_active | boolean | NO | true | - |
| reminder_enabled | boolean | NO | true | - |
| document_url | text | YES | - | - |
| notes | text | YES | - | - |
| created_at | timestamptz | NO | now() | - |
| updated_at | timestamptz | NO | now() | auto-updated via trigger |

**RLS Policies:** owner-only SELECT / INSERT / UPDATE / DELETE (pet ownership via `pets.owner_id`)

---

## Entity Relationship Summary
- **users** is the central entity, referenced by 10 other tables
- **pets** belongs to users and is referenced by 8 tables (including new care/health tables)
- **match_requests** connects two users and their pets, and links to chat_threads
- **chat_threads** connects two users and contains chat_messages
- **posts** can optionally reference a pet
- **care_logs** and **health_vitals** track low-level care events and numeric vitals
- **care_tasks** manages scheduled/recurring tasks with gamification
- **health_logs** stores narrative health events and vet notes
- **medical_vault** stores vaccine and medication records with expiry tracking

---

# ERD Diagram (Mermaid)

```mermaid
---
id: 600acb93-5eca-4271-ac6c-3cd396779d22
---
erDiagram
    users ||--o{ pets : "owns"
    users ||--o{ care_logs : "logs"
    users ||--o{ health_vitals : "records"
    users ||--o{ health_logs : "records"
    users ||--o{ posts : "authors"
    users ||--o{ match_requests : "requests"
    users ||--o{ chat_threads : "participates"
    users ||--o{ chat_messages : "sends"
    users ||--o{ marketplace_orders : "orders"
    pets ||--o{ care_logs : "has"
    pets ||--o{ care_tasks : "has"
    pets ||--o{ health_vitals : "has"
    pets ||--o{ health_logs : "has"
    pets ||--o{ medical_vault : "has"
    pets ||--o{ match_requests : "matches"
    pets ||--o{ posts : "featured in"
    match_requests ||--o{ chat_threads : "initiates"
    chat_threads ||--o{ chat_messages : "contains"


    users {
        uuid id PK
        text username UNIQUE
        text display_name
        text avatar_url
        text bio
        text location
        timestamptz created_at
        timestamptz updated_at
    }

    pets {
        uuid id PK
        uuid owner_id FK

        text name
        text species
        text breed
        date date_of_birth
        text gender CHECK(male/female/unknown)
        numeric weight_kg
        text avatar_url
        text bio
        boolean is_public
        timestamptz created_at

        timestamptz updated_at
    }

    care_logs {
        uuid id PK
        uuid pet_id FK
        uuid logged_by FK
        text care_type CHECK(feeding/walk/grooming/medication/vet_visit/training/playtime/other)
        text notes
        integer duration_minutes CHECK(> 0)
        timestamptz occurred_at

        timestamptz created_at
    }

    health_vitals {
        uuid id PK
        uuid pet_id FK
        uuid recorded_by FK
        text vital_type CHECK(weight/temperature/heart_rate/blood_pressure/glucose/other)
        numeric value
        text unit
        text notes
        timestamptz recorded_at

        timestamptz created_at
    }

    posts {
        uuid id PK
        uuid author_id FK
        uuid pet_id FK NULLABLE
        text content
        text[] image_urls
        text visibility CHECK(public/followers/private)
        integer like_count CHECK(>= 0)
        integer comment_count CHECK(>= 0)

        timestamptz created_at
        timestamptz updated_at
    }

    match_requests {
        uuid id PK
        uuid requester_id FK
        uuid target_id FK

        uuid requester_pet_id FK
        uuid target_pet_id FK
        text match_type CHECK(playdate/breeding/adoption)
        text status CHECK(pending/accepted/rejected/cancelled)
        text message
        timestamptz created_at
        timestamptz updated_at
    }


    chat_threads {
        uuid id PK
        uuid match_request_id FK NULLABLE UNIQUE
        uuid participant_1_id FK
        uuid participant_2_id FK
        timestamptz last_message_at
        timestamptz created_at
    }

    chat_messages {
        uuid id PK
        uuid thread_id FK
        uuid sender_id FK
        text content
        boolean is_read
        timestamptz created_at
    }

    marketplace_orders {
        uuid id PK
        uuid buyer_id FK
        uuid seller_id FK
        text title
        text description
        bigint amount_cents CHECK(> 0)
        text currency DEFAULT('usd')
        text status CHECK(pending/confirmed/shipped/delivered/cancelled/refunded)
        jsonb shipping_address
        timestamptz created_at
        timestamptz updated_at
    }

    care_tasks {
        uuid id PK
        uuid pet_id FK
        text task_type CHECK(feeding/walk/grooming/medication/vet_visit/training/playtime/dental/nail_trim/bath/other)
        text title
        text frequency CHECK(once/daily/twice_daily/weekly/biweekly/monthly/as_needed)
        time scheduled_time
        boolean is_completed
        timestamptz completed_at
        integer gamification_points CHECK(>= 0)
        text notes
        timestamptz created_at
        timestamptz updated_at
    }

    health_logs {
        uuid id PK
        uuid pet_id FK
        uuid recorded_by FK
        text log_type CHECK(symptom/weight/vet_visit/medication/allergy/injury/general)
        text title
        text description
        numeric weight_kg CHECK(> 0)
        text severity CHECK(mild/moderate/severe/critical)
        text vet_name
        text vet_clinic
        text diagnosis
        text treatment
        date follow_up_date
        timestamptz occurred_at
        timestamptz created_at
        timestamptz updated_at
    }

    medical_vault {
        uuid id PK
        uuid pet_id FK
        text record_type CHECK(vaccine/medication/allergy/surgery/parasite_prevention/other)
        text name
        text administered_by
        date administered_at
        date expires_at
        date next_due_at
        text batch_number
        text dosage
        text frequency
        boolean is_active
        boolean reminder_enabled
        text document_url
        text notes
        timestamptz created_at
        timestamptz updated_at
    }
```

---

## How to View the Diagram
- If you open this markdown file in VS Code, GitHub, GitLab, or any markdown viewer that supports Mermaid, the diagram will render automatically.
- You can also copy the `erDiagram` block into an online Mermaid live editor (e.g., https://mermaid.live) to see the visual layout.

---

## Notes
- All tables use **UUID** primary keys with `gen_random_uuid()` default.
- All tables have **RLS (Row Level Security)** enabled.
- Timestamps use **timestamptz** (timestamp with time zone).
- The `users` table references `auth.users.id` for Supabase authentication integration.
- Check constraints enforce enum‑like behavior for gender, care_type, vital_type, visibility, match_type, and status fields.