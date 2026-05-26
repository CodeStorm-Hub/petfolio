# Petfolio — Live Database ERD & Schema Reference

> **Project:** `jqyjvhwlcqcsuwcqgcwf` · Region: ap-northeast-1 · PostgreSQL 17.6.1
> **Generated:** 2026-05-19 (live introspection via Supabase MCP)
> **Applied migrations:** 46 · **Local migration files:** 35 (all local names covered; 11 extra migrations applied via Studio with no local counterpart)

---

## Migration Sync Status

| Status | Count | Notes |
|--------|-------|-------|
| ✅ Applied (both local + DB) | 35 | All local files are reflected in the live DB |
| ⚠️ DB-only (no local file) | 11 | Applied via Supabase Studio: `20260520000000_social_chat_rpc`, `user_follows`, `matching_discovery_age_null_dob`, `enable_realtime_social`, `chat_realtime`, `optimized_last_message`, `add_public_keys`, `chat_views`, `fix_view_permissions`, `social_threads_pet_join`, `fix_social_rpc` |
| ❌ Local-only (unapplied) | 0 | None — nothing to push |

---

## Custom Enums

| Enum | Values |
|------|--------|
| `kyc_status_enum` | `pending`, `submitted`, `approved`, `rejected` |
| `payout_method_enum` | `stripe`, `manual` |
| `payment_method_enum` | `stripe`, `cod` |
| `payment_status_enum` | `pending`, `collected` |
| `ledger_status_enum` | `pending_clearance`, `available`, `paid` |

---

## Table Summary (25 tables, all RLS-enabled)

| Domain | Tables |
|--------|--------|
| **Identity** | `users`, `pets` |
| **Care & Health** | `care_logs`, `care_tasks`, `care_streaks`, `health_vitals`, `health_logs`, `medical_vault`, `pet_care_gamification`, `pet_badges` |
| **Social** | `posts`, `post_likes`, `comments`, `follows`, `pet_follows`, `notifications` |
| **Matching** | `swipes`, `matches`, `match_requests` |
| **Chat** | `chat_threads`, `chat_messages` |
| **Marketplace** | `shops`, `products`, `marketplace_orders`, `vendor_ledgers` |

---

## Entity Relationship Diagram

```mermaid
erDiagram

    %% ── IDENTITY ─────────────────────────────────────────────────────────────

    users {
        uuid id PK
        text username UK
        text display_name
        text avatar_url
        text bio
        text location
        text public_key
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
        text gender
        numeric weight_kg
        text avatar_url
        text bio
        text handle UK
        text accent_color
        text activity_level
        bool is_public
        bool is_discoverable
        geography location
        int display_order
        timestamptz archived_at
        timestamptz created_at
        timestamptz updated_at
    }

    %% ── CARE ─────────────────────────────────────────────────────────────────

    care_logs {
        uuid id PK
        uuid pet_id FK
        uuid logged_by FK
        text care_type
        text notes
        int duration_minutes
        date logged_date
        timestamptz occurred_at
        timestamptz created_at
    }

    care_tasks {
        uuid id PK
        uuid pet_id FK
        text task_type
        text title
        text frequency
        time scheduled_time
        bool is_completed
        timestamptz completed_at
        int gamification_points
        text notes
        timestamptz created_at
        timestamptz updated_at
    }

    care_streaks {
        uuid pet_id PK_FK
        int current_streak
        date last_completion_date
        int best_streak
    }

    pet_care_gamification {
        uuid pet_id PK_FK
        date daily_point_award_date
        int daily_point_award_accrued
        int total_points
        timestamptz created_at
        timestamptz updated_at
    }

    pet_badges {
        uuid pet_id PK_FK
        text badge_type PK
        timestamptz unlocked_at
    }

    %% ── HEALTH ───────────────────────────────────────────────────────────────

    health_vitals {
        uuid id PK
        uuid pet_id FK
        uuid recorded_by FK
        text vital_type
        numeric value
        text unit
        text notes
        timestamptz recorded_at
        timestamptz created_at
    }

    health_logs {
        uuid id PK
        uuid pet_id FK
        uuid recorded_by FK
        text log_type
        text title
        text description
        numeric weight_kg
        text severity
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
        text record_type
        text name
        text description
        text administered_by
        date administered_at
        date expires_at
        date next_due_at
        text batch_number
        text dosage
        text frequency
        bool is_active
        bool reminder_enabled
        text document_url
        text notes
        timestamptz created_at
        timestamptz updated_at
    }

    %% ── SOCIAL ───────────────────────────────────────────────────────────────

    posts {
        uuid id PK
        uuid author_id FK
        uuid pet_id FK
        text content
        text[] image_urls
        text visibility
        int like_count
        int comment_count
        timestamptz created_at
        timestamptz updated_at
    }

    post_likes {
        uuid id PK
        uuid post_id FK
        uuid pet_id FK
        uuid user_id FK
        timestamptz created_at
    }

    comments {
        uuid id PK
        uuid post_id FK
        uuid author_id FK
        uuid pet_id FK
        text content
        timestamptz created_at
    }

    follows {
        uuid id PK
        uuid follower_id FK
        uuid following_id FK
        timestamptz created_at
    }

    pet_follows {
        uuid id PK
        uuid follower_pet_id FK
        uuid following_pet_id FK
        timestamptz created_at
    }

    notifications {
        uuid id PK
        uuid recipient_pet_id FK
        uuid actor_pet_id FK
        text type
        uuid post_id FK
        bool is_read
        timestamptz created_at
    }

    %% ── MATCHING ─────────────────────────────────────────────────────────────

    swipes {
        uuid id PK
        uuid actor_id FK
        uuid target_id FK
        text action
        timestamptz created_at
    }

    matches {
        uuid id PK
        uuid pet_a_id FK
        uuid pet_b_id FK
        timestamptz created_at
    }

    match_requests {
        uuid id PK
        uuid requester_id FK
        uuid target_id FK
        uuid requester_pet_id FK
        uuid target_pet_id FK
        text match_type
        text status
        text message
        timestamptz created_at
        timestamptz updated_at
    }

    %% ── CHAT ─────────────────────────────────────────────────────────────────

    chat_threads {
        uuid id PK
        uuid participant_1_id FK
        uuid participant_2_id FK
        uuid match_request_id FK_UK
        uuid mutual_match_id FK
        text last_message_content
        timestamptz last_message_at
        timestamptz created_at
    }

    chat_messages {
        uuid id PK
        uuid thread_id FK
        uuid sender_id FK
        text content
        bool is_read
        timestamptz created_at
    }

    %% ── MARKETPLACE ──────────────────────────────────────────────────────────

    shops {
        uuid id PK
        uuid owner_id FK_UK
        text shop_name
        text slug UK
        text description
        text logo_url
        text banner_url
        bool is_active
        bool is_verified
        text stripe_connect_account_id UK
        bool stripe_onboarding_complete
        int platform_fee_percent
        payout_method_enum payout_method
        kyc_status_enum kyc_status
        text national_id_url
        text trade_license_url
        text rejection_reason
        jsonb bank_account_details
        timestamptz created_at
        timestamptz updated_at
    }

    products {
        uuid id PK
        uuid shop_id FK
        text name
        text brand
        text variant
        text category
        int price_cents
        text currency
        bool subscribable
        bool active
        text glyph
        text gradient_start
        text gradient_end
        text[] image_urls
        int inventory_count
        timestamptz created_at
    }

    marketplace_orders {
        uuid id PK
        uuid buyer_id FK
        uuid seller_id FK
        uuid shop_id FK
        text title
        text description
        bigint amount_cents
        text currency
        text status
        jsonb line_items
        jsonb shipping_address
        text stripe_payment_intent_id UK
        text shipping_tracking_number
        text shipping_tracking_url
        text shipping_carrier
        timestamptz shipped_at
        payment_method_enum payment_method
        payment_status_enum payment_status
        timestamptz created_at
        timestamptz updated_at
    }

    vendor_ledgers {
        uuid id PK
        uuid shop_id FK
        uuid order_id FK
        bigint order_total_cents
        bigint platform_fee_cents
        bigint vendor_earnings_cents
        ledger_status_enum status
        timestamptz created_at
        timestamptz updated_at
    }

    %% ── RELATIONSHIPS ────────────────────────────────────────────────────────

    %% Identity
    users ||--o{ pets : "owns"

    %% Care
    pets ||--o{ care_logs : "has"
    users ||--o{ care_logs : "logged_by"
    pets ||--|| care_streaks : "has"
    pets ||--o{ care_tasks : "has"
    pets ||--|| pet_care_gamification : "has"
    pets ||--o{ pet_badges : "earns"

    %% Health
    pets ||--o{ health_vitals : "has"
    users ||--o{ health_vitals : "records"
    pets ||--o{ health_logs : "has"
    users ||--o{ health_logs : "records"
    pets ||--o{ medical_vault : "has"

    %% Social
    users ||--o{ posts : "authors"
    pets |o--o{ posts : "featured_in"
    posts ||--o{ post_likes : "receives"
    pets ||--o{ post_likes : "gives"
    users ||--o{ post_likes : "gives"
    posts ||--o{ comments : "has"
    users ||--o{ comments : "writes"
    pets ||--o{ comments : "via"
    users ||--o{ follows : "follows (follower)"
    users ||--o{ follows : "followed_by (following)"
    pets ||--o{ pet_follows : "follows (follower)"
    pets ||--o{ pet_follows : "followed_by (following)"
    pets ||--o{ notifications : "receives"
    pets |o--o{ notifications : "triggers"
    posts |o--o{ notifications : "references"

    %% Matching
    pets ||--o{ swipes : "swipes (actor)"
    pets ||--o{ swipes : "swiped_on (target)"
    pets ||--o{ matches : "matched_as_a"
    pets ||--o{ matches : "matched_as_b"
    users ||--o{ match_requests : "sends"
    users ||--o{ match_requests : "receives"
    pets ||--o{ match_requests : "requester_pet"
    pets ||--o{ match_requests : "target_pet"

    %% Chat
    users ||--o{ chat_threads : "participant_1"
    users ||--o{ chat_threads : "participant_2"
    match_requests |o--o| chat_threads : "origin"
    matches |o--o| chat_threads : "mutual_match"
    chat_threads ||--o{ chat_messages : "contains"
    users ||--o{ chat_messages : "sends"

    %% Marketplace
    users ||--|| shops : "owns"
    shops ||--o{ products : "lists"
    users ||--o{ marketplace_orders : "buys"
    users |o--o{ marketplace_orders : "sells"
    shops ||--o{ marketplace_orders : "fulfils"
    shops ||--o{ vendor_ledgers : "has"
    marketplace_orders ||--|| vendor_ledgers : "generates"
```

---

## Indexes

### `care_logs`
| Index | Type | Columns |
|-------|------|---------|
| `care_logs_pkey` | UNIQUE | `id` |
| `care_logs_pet_care_type_logged_date_uq` | UNIQUE | `pet_id, care_type, logged_date` |
| `idx_care_logs_pet_id` | BTREE | `pet_id` |
| `idx_care_logs_logged_by` | BTREE | `logged_by` |

### `care_tasks`
| Index | Type | Columns |
|-------|------|---------|
| `care_tasks_pkey` | UNIQUE | `id` |
| `care_tasks_pet_id_idx` | BTREE | `pet_id` |
| `care_tasks_scheduled_idx` | BTREE | `pet_id, scheduled_time` |

### `chat_messages`
| Index | Type | Columns |
|-------|------|---------|
| `chat_messages_pkey` | UNIQUE | `id` |
| `idx_chat_messages_thread` | BTREE | `thread_id` |
| `idx_chat_messages_sender` | BTREE | `sender_id` |
| `idx_chat_messages_thread_created_at` | BTREE | `thread_id, created_at DESC` |

### `chat_threads`
| Index | Type | Columns |
|-------|------|---------|
| `chat_threads_pkey` | UNIQUE | `id` |
| `chat_threads_match_request_id_key` | UNIQUE | `match_request_id` |
| `chat_threads_mutual_match_id_uidx` | UNIQUE (partial) | `mutual_match_id WHERE NOT NULL` |
| `idx_chat_threads_p1` | BTREE | `participant_1_id` |
| `idx_chat_threads_p2` | BTREE | `participant_2_id` |

### `health_logs`
| Index | Type | Columns |
|-------|------|---------|
| `health_logs_pkey` | UNIQUE | `id` |
| `health_logs_pet_id_idx` | BTREE | `pet_id` |
| `health_logs_recorder_idx` | BTREE | `recorded_by` |
| `health_logs_timeline_idx` | BTREE | `pet_id, occurred_at DESC` |

### `health_vitals`
| Index | Type | Columns |
|-------|------|---------|
| `health_vitals_pkey` | UNIQUE | `id` |
| `idx_health_vitals_pet_id` | BTREE | `pet_id` |
| `idx_health_vitals_recorded_by` | BTREE | `recorded_by` |

### `marketplace_orders`
| Index | Type | Columns |
|-------|------|---------|
| `marketplace_orders_pkey` | UNIQUE | `id` |
| `marketplace_orders_stripe_pi_idx` | UNIQUE (partial) | `stripe_payment_intent_id WHERE NOT NULL` |
| `idx_orders_buyer` | BTREE | `buyer_id` |
| `idx_orders_seller` | BTREE | `seller_id` |
| `idx_orders_shop_id` | BTREE | `shop_id` |
| `idx_orders_status` | BTREE | `status` |

### `match_requests`
| Index | Type | Columns |
|-------|------|---------|
| `match_requests_pkey` | UNIQUE | `id` |
| `idx_match_requests_requester` | BTREE | `requester_id` |
| `idx_match_requests_target` | BTREE | `target_id` |
| `idx_match_requests_status` | BTREE | `status` |

### `matches`
| Index | Type | Columns |
|-------|------|---------|
| `matches_pkey` | UNIQUE | `id` |
| `matches_unique_pair` | UNIQUE | `pet_a_id, pet_b_id` |
| `matches_pet_a_idx` | BTREE | `pet_a_id` |
| `matches_pet_b_idx` | BTREE | `pet_b_id` |

### `medical_vault`
| Index | Type | Columns |
|-------|------|---------|
| `medical_vault_pkey` | UNIQUE | `id` |
| `medical_vault_pet_id_idx` | BTREE | `pet_id` |
| `medical_vault_due_idx` | BTREE (partial) | `pet_id, next_due_at WHERE NOT NULL` |
| `medical_vault_expiry_idx` | BTREE (partial) | `pet_id, expires_at WHERE NOT NULL` |

### `pets`
| Index | Type | Columns |
|-------|------|---------|
| `pets_pkey` | UNIQUE | `id` |
| `pets_handle_key` | UNIQUE | `handle` |
| `idx_pets_owner_id` | BTREE | `owner_id` |
| `pets_location_gix` | GIST (partial) | `location WHERE NOT NULL` |
| `pets_owner_active_order_idx` | BTREE (partial) | `owner_id, archived_at, display_order, created_at WHERE archived_at IS NULL` |

### `posts`
| Index | Type | Columns |
|-------|------|---------|
| `posts_pkey` | UNIQUE | `id` |
| `idx_posts_author_id` | BTREE | `author_id` |
| `idx_posts_pet_id` | BTREE | `pet_id` |
| `idx_posts_visibility` | BTREE | `visibility` |

### `shops`
| Index | Type | Columns |
|-------|------|---------|
| `shops_pkey` | UNIQUE | `id` |
| `shops_owner_id_key` | UNIQUE | `owner_id` |
| `shops_slug_key` | UNIQUE | `slug` |
| `shops_stripe_connect_account_id_key` | UNIQUE | `stripe_connect_account_id` |
| `idx_shops_kyc_status` | BTREE | `kyc_status` |
| `idx_shops_stripe_account` | BTREE (partial) | `stripe_connect_account_id WHERE NOT NULL` |

### `swipes`
| Index | Type | Columns |
|-------|------|---------|
| `swipes_pkey` | UNIQUE | `id` |
| `swipes_actor_target_unique` | UNIQUE | `actor_id, target_id` |
| `swipes_actor_idx` | BTREE | `actor_id` |
| `swipes_target_actor_like_idx` | BTREE (partial) | `target_id, actor_id WHERE action IN ('LIKE','GREET','SUPER_PAW')` |

### `vendor_ledgers`
| Index | Type | Columns |
|-------|------|---------|
| `vendor_ledgers_pkey` | UNIQUE | `id` |
| `vendor_ledgers_shop_id_idx` | BTREE | `shop_id` |
| `vendor_ledgers_order_id_idx` | BTREE | `order_id` |
| `vendor_ledgers_status_idx` | BTREE | `status` |

---

## RPC Functions & Triggers

| Name | Type | Returns | Description |
|------|------|---------|-------------|
| `check_daily_completion(target_pet_id, completion_date)` | Function | `jsonb` | Checks if all care tasks are done for a pet on a given date; updates streak + awards badge if ≥7 days |
| `ensure_chat_thread_for_match(p_match_id, p_actor_pet_id)` | Function | `uuid` | Gets or creates a `chat_threads` row tied to a `matches` row; uses canonical p1/p2 ordering |
| `get_match_inbox(p_actor_pet_id)` | Function | `record` | Returns inbox rows (match, other pet, thread, last message) for a pet |
| `get_or_create_social_thread(other_user_id)` | Function | `uuid` | Gets or creates a direct-message thread between two users (not match-linked) |
| `matching_discovery_candidates(...)` | Function | `record` | PostGIS-powered pet discovery: filters by radius, species, age, already-swiped; paginated |
| `set_pet_location_point(p_pet_id, p_latitude, p_longitude)` | Function | `void` | Converts lat/lng to PostGIS geography point and writes to `pets.location` |
| `is_admin()` | Function | `boolean` | Reads `app_metadata.is_admin` from the JWT; used in RLS policies |
| `handle_new_chat_message()` | Trigger fn | `trigger` | On `chat_messages` INSERT: updates `chat_threads.last_message_at` and `last_message_content` |
| `handle_post_like_sync()` | Trigger fn | `trigger` | On `post_likes` INSERT/DELETE: increments/decrements `posts.like_count` |
| `handle_post_comment_sync()` | Trigger fn | `trigger` | On `comments` INSERT/DELETE: increments/decrements `posts.comment_count` |
| `handle_updated_at()` / `set_updated_at()` | Trigger fn | `trigger` | Sets `updated_at = now()` on any UPDATE |
| `rls_auto_enable()` | Event trigger | `event_trigger` | Auto-enables RLS on every new `public` schema table at DDL time |

---

## Key Constraints & Notes

| Observation | Detail |
|-------------|--------|
| `users.id` mirrors `auth.users.id` | FK `users_id_fkey` references itself; actual linkage is via `auth.uid()` in RLS |
| `shops.owner_id` is UNIQUE | One shop per user enforced at DB level |
| `chat_threads.match_request_id` is UNIQUE | One thread per match request |
| `chat_threads.mutual_match_id` unique partial | `WHERE mutual_match_id IS NOT NULL` — one thread per mutual match |
| `swipes` UNIQUE on `(actor_id, target_id)` | A pet can only swipe another pet once |
| `matches` UNIQUE on `(pet_a_id, pet_b_id)` | Canonical pair with `pet_a_id < pet_b_id` convention |
| `post_likes` UNIQUE on `(post_id, pet_id)` | A pet can only like a post once |
| `care_logs` UNIQUE on `(pet_id, care_type, logged_date)` | One log per care type per day per pet |
| `pets.location` is `geography` (PostGIS) | Enables `ST_DWithin` radius search in discovery |
| `marketplace_orders.stripe_payment_intent_id` partial unique | Deduplication across Stripe webhook retries |
| All 25 tables have RLS enabled | Enforced via `rls_auto_enable` event trigger |
