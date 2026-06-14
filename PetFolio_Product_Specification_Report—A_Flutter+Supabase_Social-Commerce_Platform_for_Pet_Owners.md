# PetFolio: Product Specification Report — A Flutter + Supabase Social-Commerce Platform for Pet Owners

## TL;DR

- A four-pillar pet super-app (Instagram-style social network, Tinder-style matching, gamified health tracker, e-commerce marketplace) built on Flutter + Supabase is technically feasible and strategically well-timed for Bangladesh, where the number of pet rearers rose ~170% (roughly doubled) in three years and cats represent ~90% of pets, then globally where pet care is a ~$182–346 billion market (2025 estimates vary by methodology).
- No single existing competitor combines all four pillars; rivals are point solutions (Pawmates/BarkHappy = social/matching; Dogo/11Pets = health/streaks; Chewy = commerce), so the integrated platform fills a genuine market gap, especially in a cat-first, Bengali-language, bKash/COD-driven market that Western apps ignore.
- The report specifies every module in full (features, 8–10+ user stories each, flows, screens, data entities), a unified Supabase schema with PostGIS geospatial matching and a swipe/match trigger pattern, Flutter architecture recommendations, and a 5-phase roadmap that sequences Social → Health → Commerce → Matching.

-----

## 1. Executive Summary

PetFolio is a single mobile application that unifies four product pillars pet owners currently juggle across separate apps: (1) an Instagram-style social network for owners and their pets; (2) a Tinder-style discovery and matching engine for breeding and playdates; (3) a health and daily-care tracker with Snapchat/Apple-Fitness-style streaks and achievements; and (4) an e-commerce marketplace for pet products. The target launch market is Bangladesh, with architecture and content designed from day one for global expansion.

The strategic thesis rests on three findings. First, the market is real and accelerating: per ACI Limited’s early-2024 study (researcher Mohammad Abdul Saleque), “the number of pets rearers has increased by 170 percent, or roughly twice, in the last three years,” with an estimated 564,848 pet cats and 289,000 pet dogs, and a pet-products market “valued at 236 crores and growing at 12% annually.” Globally, pet care is a ~$182–346 billion market in 2025 (Grand View Research puts it at USD 181.9B at 5.9% CAGR; Fortune Business Insights at USD 273.42B; Precedence Research at USD 346.01B at 7.10% CAGR), with Asia-Pacific the fastest-growing region. Second, the competitive field is fragmented — no incumbent offers all four pillars in one app, and none is localized for Bangladesh’s cat-dominant, Bengali-speaking, mobile-money economy. Third, the tech stack is proven: Supabase (Postgres + Auth + Realtime + Storage + Edge Functions) maps cleanly to all four pillars, and Flutter delivers a single codebase for iOS and Android.

The recommended build order deliberately leads with the Social + Health pillars (which drive daily engagement and retention through gamified streaks), then layers Commerce (monetizable, but requires logistics/payment integration), and finally Matching (highest trust/safety burden, benefits from an existing user base for liquidity). Monetization is intentionally out of scope for this document, which focuses entirely on features and functionality.

## 2. Market Analysis (Bangladesh + Global)

### 2.1 Bangladesh

**Pet ownership.** Pet adoption has risen sharply since COVID-19, driven by urbanization, rising incomes, and more nuclear families and working women. ACI Limited’s early-2024 study found the number of pet rearers increased ~170% (roughly doubled) in three years. Cats dominate — ~90% of pet owners keep cats — because they suit apartment living in one of the world’s most densely populated countries (population ~171–175 million). Pets, especially dogs, are often not permitted in multi-storey buildings. Independent academic surveys corroborate cat dominance: one 361-household national survey found cats the most-owned pet (56.2%), followed by birds (35.5%), dogs (11.1%), and rabbits (5.0%). Pet ownership skews young (largest share aged 18–25) and educated.

**Market size & structure.** The pet-products market is worth ~Tk 230–236 crore annually and growing ~10–15%/year. Pet food leads (~57% share), followed by medicines (~19%), litter (~16%), vaccines (~7%), and miscellaneous (~1%). Most products are imported (import demand ~$43 million/year), with import taxes on cat food reaching up to 50% in 2024 — making local production and a marketplace with local sellers attractive. There are 4,000+ pet shops and 225+ pet clinics; clinics are the primary source of medicines/vaccines. The first local pet-food brands (e.g., Chonk, which reportedly had 1,000+ mostly-recurring customers as of Feb 2025) are emerging.

**Digital & payment context.** Per DataReportal’s “Digital 2025: Bangladesh,” there were 77.7 million internet users (44.5% penetration) and 60.0 million social media user identities (34.3% of the population) in January 2025. Smartphone adoption is ~63–72% of mobile users and rising; mobile data dominates (avg ~8.2 GB/user/month). Crucially, connectivity is uneven (rural penetration lags, data costs are high due to >50% taxes), so **offline tolerance and data-light design are mandatory**. For payments: bKash dominates mobile financial services — it reports a customer base of over 83 million, of which more than 47 million are active users (transacted within 90 days), holding ~60%+ market share — alongside Nagad; SSLCommerz is the leading aggregator (one integration covers bKash, Nagad, Rocket, cards, net banking); **cash-on-delivery (COD) still dominates e-commerce** despite rising card transactions (~Tk 20.35 billion in Feb 2025, +23.6% YoY). Logistics partners (Pathao, Paperfly, Steadfast, RedX) handle last-mile.

**Cultural considerations.** Attitudes are transforming but uneven. Cats enjoy positive religious/cultural status in Islamic tradition; dogs face stigma (often viewed as impure), and are less commonly kept as indoor pets. This reinforces a **cat-first product strategy** for Bangladesh. Social media is the primary pet-information source for owners (one study: 48.1% cite social media as their primary source), validating the social pillar. Animal-welfare awareness and veterinary access remain limited, creating an opening for in-app health education and vet connectivity.

### 2.2 Global

The global pet care market is large and growing: 2025 estimates range from USD 181.9 billion (Grand View Research, 5.9% CAGR) to USD 273.42 billion (Fortune Business Insights) to USD 346.01 billion (Precedence Research, 7.10% CAGR), with forecasts approaching $483–643 billion by 2034–2035. Drivers: “pet humanization” (97% of owners call pets “family”), premiumization, and a tech-enabled wellness shift (GPS trackers, activity wearables, tele-vet). Per Grand View Research (2025), the dogs segment led with a 40.4% revenue share while cats are anticipated to grow fastest (5.8% CAGR). E-commerce is increasingly central (pet-care e-commerce ~$102 billion in 2025; in China ~60% of pet retail is online). Digital health is a recognized growth pillar (e.g., Chewy’s “Connect with a Vet” logged its first million tele-consultations). North America is the largest region (Grand View: 42.9% share in 2025); **Asia-Pacific is the fastest-growing**, supporting the global-expansion thesis.

## 3. Competitor Analysis

### 3.1 Narrative

- **Pawshake / Rover / PetBacker / Wag** — Pet-sitting/dog-walking marketplaces. Strengths: booking, insurance (the Rover Guarantee covers up to $25,000 in vet care for eligible claims, per occurrence in the US subject to a $250 minimum contribution), GPS walk tracking, reviews. Not social networks, no health tracker, no product commerce. Rover takes ~15–20% service fees.
- **Pawmates (“Tinder for dogs”)** — Closest analog to the matching + light-social pillars: profile creation, news feed, swipe-based “meet playmates” with matching by age/distance/size, unlimited chat, and a business map (vets, stores). Playdate-focused; no breeding mode, no health tracker, no commerce.
- **BarkHappy** — Location-based social/discovery: dog + owner profiles, “wags” (pokes), messaging, dog-friendly places map (20,000+ places), events/meetups, lost-and-found alerts, breed search. Reached 60,000+ profiles. No health tracker, no commerce, no breeding.
- **Dogo** — Training + light health + strong gamification: 100+ guided trick videos, clicker/whistle, trainer video feedback, **daily training streaks**, walk tracking with points/competition, vaccination/medication reminders, weight tracking, festive avatar rewards, family sharing. 10M+ users. Subscription (~$9.99/mo). Dog-only; no commerce, no matching, no real social feed. Notably, some users complain the streak pressure is excessive and non-disableable — a UX lesson.
- **11Pets** — Health-management depth: weight/nutrition tracking, vaccine/vet schedules, medical history, symptom documentation, medication reminders, community. Free + premium (~$4.99/mo). No social/matching/commerce.
- **PetDesk** — Vet-clinic-linked: appointment scheduling, refill requests, health records, clinic communication. 4.7/5 rating. B2B2C; depends on clinic integrations.
- **Chewy** — E-commerce gold standard: 3,000+ brands, **Autoship** recurring delivery (per Chewy’s FY2025 results, Autoship customer sales were $10,497.1M, representing 83.3% of net sales, up from 79.2% a year earlier), pet pharmacy (4,000+ meds, Rx vet approval), Connect-with-a-Vet, symptom tracker, medicine reminders, shipment tracking, reviews, 365-day returns, pet-adoption network, Practice Hub vet marketplace. US-only. No social feed, no matching.
- **Find My K9 Match** — “Tinder for breeding programs”: stud/dam matching with pedigree, health testing, titles, photos. Validates the **breeding-specific matching mode**, niche to dog breeders.
- **Petfinder / Adopt-a-Pet / Barkbuddy / Zeppee** — Adoption discovery (swipe-based in some), 11,000+ shelters. Adjacent (adoption), not the core four pillars.

### 3.2 Feature Comparison Table

| Capability                    | Pawmates | BarkHappy | Dogo | 11Pets | PetDesk | Chewy | Find My K9 | **PetFolio (proposed)** |
|-------------------------------|----------|-----------|------|--------|---------|-------|------------|-------------------------|
| Social feed (posts/photos)    | ◐        | ◐         | ✗    | ✗      | ✗       | ✗     | ✗          | ✓                       |
| Stories / short video (reels) | ✗        | ✗         | ✗    | ✗      | ✗       | ✗     | ✗          | ✓                       |
| Pet profiles                  | ✓        | ✓         | ✓    | ✓      | ✓       | ◐     | ✓          | ✓                       |
| Playdate matching             | ✓        | ✓         | ✗    | ✗      | ✗       | ✗     | ✗          | ✓                       |
| Breeding matching             | ✗        | ✗         | ✗    | ✗      | ✗       | ✗     | ✓          | ✓                       |
| GPS nearby discovery          | ✓        | ✓         | ✗    | ✗      | ✗       | ✗     | ◐          | ✓                       |
| Health/care tracker           | ✗        | ✗         | ◐    | ✓      | ✓       | ◐     | ✗          | ✓                       |
| Streaks & achievements        | ✗        | ✗         | ✓    | ✗      | ✗       | ✗     | ✗          | ✓                       |
| Vet records / reminders       | ✗        | ✗         | ◐    | ✓      | ✓       | ◐     | ✗          | ✓                       |
| E-commerce marketplace        | ✗        | ◐         | ◐    | ✗      | ✗       | ✓     | ✗          | ✓                       |
| bKash/Nagad/COD payments      | ✗        | ✗         | ✗    | ✗      | ✗       | ✗     | ✗          | ✓                       |
| Bengali + English             | ✗        | ✗         | ✗    | ✗      | ✗       | ✗     | ✗          | ✓                       |
| Direct messaging              | ✓        | ✓         | ✗    | ✗      | ✗       | ✗     | ✓          | ✓                       |

✓ = full, ◐ = partial/limited, ✗ = absent. **The right-most column is the differentiation thesis: PetFolio is the only platform combining all four pillars with Bangladesh localization.**

### 3.3 Gaps PetFolio Fills

1. **No all-in-one app** — owners stitch together Pawmates + 11Pets + Chewy. PetFolio unifies identity, pet profiles, and data across pillars.
2. **No localization for Bangladesh** — no major app supports Bengali, bKash/Nagad/COD, or cat-first defaults.
3. **Streaks without commerce/social** — Dogo gamifies but is dog-only and isolated; PetFolio ties care streaks to social sharing and product recommendations.
4. **Breeding + playdate in one matching engine** with health-certificate verification — neither Pawmates (playdate-only) nor Find My K9 (breeding-only) does both.
5. **Commerce integrated with health data** — recommend products by species/breed/age/medical profile (Chewy lacks the social/health-graph context PetFolio owns).

## 4. Platform Architecture Overview

**Client:** Flutter (single codebase, iOS + Android; web admin optional).

**Backend:** Supabase, using:

- **Postgres** — relational core for all entities, with **Row Level Security (RLS)** enforcing per-user/per-pet access on every table.
- **Auth** — phone OTP (primary for Bangladesh), plus Google/Apple social login for global; anonymous → linked accounts for low-friction onboarding.
- **Realtime** — Postgres changes / broadcast for DMs, match notifications, live feed updates, order status. Use **private channels with RLS** in production.
- **Storage** — buckets for post media, pet photos, medical-record PDFs/images, product images, verification documents. Use signed URLs for private medical docs.
- **Edge Functions** — server-side logic: push-notification fan-out, payment webhook handling (bKash/Nagad/SSLCommerz), content-moderation calls, feed ranking, scheduled reminder dispatch, match computation.
- **PostGIS extension** — geospatial “nearby pets” queries (see §11).
- **pg_cron** (or scheduled Edge Functions) — daily streak resets, reminder dispatch, flash-sale activation.

**Cross-cutting services:** push notifications (FCM + APNs), content moderation (automated first-pass + reactive user-flag + human review queue), search (Postgres full-text / `pg_trgm`; consider external index at scale), analytics, feature flags.

**Resilience for Bangladesh:** local cache (Drift/Isar/Hive) for offline reads, optimistic UI with sync queue, image compression and lazy-loading, CDN for media, low-bandwidth (“lite”) media mode.

-----

## 5. MODULE 1: Social Network (Instagram-style) — Full Specification

### 5.1 Feature List

- Dual identity: **owner profiles** and **pet profiles** (one owner → many pets; a pet profile is the primary “voice” of posts, like a pet persona account).
- Feed: photo/multi-photo carousel and video posts; **reels-style short vertical videos**.
- **Stories**: 24-hour disappearing photo/video with viewer list, reactions, replies.
- Engagement: likes, multi-emoji **reactions** (e.g., 🐾 “paw,” ❤️, 😂), threaded comments, shares (in-app + external), saves/bookmarks.
- **Follow/follower** graph (asymmetric, like Instagram); close-friends list for private stories.
- **Hashtags** and species/breed discovery; tag pets and products in posts.
- **Direct messaging** (1:1 and group), media sharing, post sharing into DM, message reactions, typing/read indicators.
- **Explore/Discover**: algorithmic grid (trending, nearby, breed-based, followed-hashtags).
- **Communities/Groups** (e.g., “Persian Cats Bangladesh,” “Dhaka Dog Park”): public/private, posts, threads, events, membership roles.
- **Notifications** center: likes, comments, follows, mentions, DM, community activity, match alerts, order/health reminders (unified).
- **Content moderation**: report/flag, block/mute, automated NSFW/abuse detection, human review queue, community guidelines, appeals.

### 5.2 User Stories (Social)

1. As a **pet owner**, I want to create a dedicated profile for each of my pets so that each pet has its own followers and identity.
1. As a **pet owner**, I want to post photos and short videos of my pet so that I can share moments with the community.
1. As a **user**, I want to post a 24-hour Story so that I can share casual updates without cluttering my permanent feed.
1. As a **user**, I want to follow other pets and owners so that my feed shows content I care about.
1. As a **user**, I want to like, react to, and comment on posts so that I can engage with content I enjoy.
1. As a **user**, I want to discover pets by breed and hashtag so that I can find content relevant to my pet’s species.
1. As a **user**, I want to send direct messages so that I can privately coordinate with other owners.
1. As a **community organizer**, I want to create a breed/location group so that local owners can gather and plan events.
1. As a **user**, I want a unified notifications center so that I never miss interactions, matches, reminders, or orders.
1. As a **user**, I want to report or block abusive content/users so that I feel safe.
1. As a **content creator**, I want to see view/like/reach metrics on my posts so that I understand what resonates.
1. As a **Bengali-speaking user**, I want the entire interface and content prompts in Bangla so that the app feels native.

### 5.3 Key User Flows

**Create a post:** Tap (+) → choose Post/Story/Reel → select/capture media → edit (crop, filter, trim, cover) → add caption, hashtags, tag pets/products/location → choose audience (public/followers/close friends) → publish → background upload to Storage with optimistic feed insert → moderation scan async.

**Story view:** Open feed → tap a story ring → auto-advance through segments → tap-hold to pause, swipe for next user → react/reply via DM → “seen-by” recorded for owner.

**Follow + discover:** Explore → tap breed chip / hashtag → grid of posts → tap pet profile → Follow → optional notification preference → appears in following feed.

**Report content:** Post overflow menu → Report → reason picker → submit → content hidden from reporter immediately → enters moderation queue → reporter notified of outcome.

### 5.4 Screen Breakdown (Social)

Home Feed; Reels Viewer (vertical pager); Story Viewer; Story Composer; Post Composer/Editor; Owner Profile; Pet Profile; Followers/Following List; Explore/Discover; Hashtag Page; Breed/Species Page; Search (people/pets/tags); Comments Thread; Likes/Reactions List; DM Inbox; DM Conversation; New Message/Group; Community List; Community Home; Community Post/Thread; Community Members/Settings; Notifications Center; Saved/Bookmarks; Report/Block dialogs; Content Guidelines; Post Insights.

### 5.5 Data Entities (Social)

- `profiles` (owner): id (→ auth.users), username, display_name, bio, avatar_url, location, language_pref, created_at.
- `pets`: id, owner_id, name, species, breed, gender, birthdate, avatar_url, bio, is_public, temperament, created_at.
- `posts`: id, author_pet_id, author_owner_id, type (photo/video/reel), caption, audience, location, created_at, like_count, comment_count, view_count.
- `post_media`: id, post_id, storage_path, media_type, width, height, order_index.
- `stories`: id, author_pet_id, media_path, created_at, expires_at (24h).
- `story_views`: story_id, viewer_id, viewed_at.
- `comments`: id, post_id, author_id, parent_comment_id, body, created_at.
- `reactions`: id, target_type (post/comment/story), target_id, user_id, reaction_type.
- `follows`: follower_id, followee_pet_id (or followee_owner_id), created_at.
- `hashtags` / `post_hashtags`: tag, post_id.
- `conversations`, `conversation_members`, `messages` (id, conversation_id, sender_id, body, media_path, created_at, read_by).
- `communities`, `community_members` (role: admin/mod/member), `community_posts`.
- `notifications`: id, user_id, type, actor_id, target_ref, body, is_read, created_at.
- `reports`: id, reporter_id, target_type, target_id, reason, status, created_at; `blocks` (blocker_id, blocked_id).

### 5.6 Edge Cases & Considerations

Deleted/expired stories cleanup (pg_cron); orphaned media on post delete; muted vs blocked distinction; reporting a post you can no longer see; pets with multiple co-owners (family sharing); username uniqueness with Bengali/Unicode; very large followings (fan-out cost — use pull model for feed at scale); offline post drafts; abusive content in DMs; minors (age gate); copyright/stolen pet photos.

-----

## 6. MODULE 2: Pet Matching (Tinder-style) — Full Specification

### 6.1 Feature List

- **Two explicit modes:** **Breeding match** and **Playdate match** (toggle; different filters, fields, and safety rules).
- Swipe deck (like/pass/superlike “paw”) with rich pet cards (photos, species, breed, age, temperament, distance, vaccination/health badges).
- **Filters:** species, breed, age range, distance/radius, gender, intent (breeding vs playdate), vaccination status, size.
- **GPS-based nearby discovery** (PostGIS radius query); manual location override for privacy.
- **Mutual match** → unlock chat; match notifications.
- **Breeding-specific:** stud/dam designation, pedigree info, health certificates (vaccination, genetic-test uploads), heat-cycle/availability, breed registry IDs, verification badge.
- **Playdate-specific:** play style, energy level, preferred playmate size/temperament, **playdate scheduling** + dog-friendly **location suggestions** (parks, cafés).
- **Safety:** user verification (phone OTP + optional ID/photo verification), report/block, vaccination-proof gating, in-app meeting-safety tips, no exact-location sharing pre-match.

### 6.2 User Stories (Matching)

1. As a **dog owner**, I want to switch between breeding and playdate modes so that I see only relevant matches.
1. As an **owner**, I want to swipe through nearby pets so that I can quickly find compatible companions.
1. As an **owner**, I want to filter by breed, age, and distance so that matches fit my criteria.
1. As an **owner**, I want to match only when both parties like each other so that chats are mutually wanted.
1. As a **breeder**, I want to view a potential mate’s pedigree and health certificates so that I can make responsible breeding decisions.
1. As an **owner**, I want to verify vaccination status before meeting so that playdates are safe.
1. As an **owner**, I want to schedule a playdate and get suggested dog-friendly locations so that meeting up is easy.
1. As a **user**, I want to report or block a suspicious user so that the community stays safe.
1. As a **privacy-conscious owner**, I want my exact location hidden until I choose to share so that I stay safe.
1. As an **owner**, I want match notifications and chat so that I can coordinate in real time.
1. As a **cat owner**, I want breeding matches restricted to my pet’s species/breed so that results are appropriate.
1. As a **verified breeder**, I want a verification badge so that others trust my listings.

### 6.3 Key User Flows

**Set up matching:** Select pet → choose mode (Breeding/Playdate) → confirm/complete required fields (breeding requires health certs/pedigree) → set filters & radius → enter deck.

**Swipe & match:** View card → swipe right (like) / left (pass) / up (superlike) → on mutual right-swipe, “It’s a Match!” modal → open chat or keep swiping. Already-swiped and matched pets excluded from future decks.

**Breeding due diligence:** Open candidate card → expand pedigree & health docs → request verification → if satisfied, like → match → chat → arrange stud service offline.

**Playdate scheduling:** In match chat → “Plan playdate” → pick date/time → app suggests nearby dog-friendly places → send invite → both confirm → calendar reminder + notification.

### 6.4 Screen Breakdown (Matching)

Matching Home (mode toggle); Swipe Deck; Pet Match Card (expanded); Filters; Match-made Modal; Matches List; Match Chat; Breeding Profile Editor (pedigree/certs); Playdate Scheduler; Location Suggestions Map; Verification Center; Safety Tips; Report/Block; Boost/Superlike (feature, monetization deferred).

### 6.5 Data Entities (Matching)

- `match_profiles`: id, pet_id, mode (breeding/playdate), is_active, play_style, energy_level, preferred_size, availability, updated_at.
- `pet_health_certs`: id, pet_id, cert_type (vaccination/genetic/vet), file_path, verified (bool), verified_by, expires_at.
- `pet_pedigree`: id, pet_id, sire_ref, dam_ref, registry_name, registry_id, titles.
- `pet_location`: pet_id, geog (PostGIS geography point), city, is_visible, updated_at.
- `swipes`: id, swiper_pet_id, swipee_pet_id, direction (left/right/super), mode, created_at; unique(swiper,swipee,mode).
- `matches`: id, pet_a, pet_b (canonical ordering), mode, created_at; unique(pet_a,pet_b,mode).
- `playdates`: id, match_id, scheduled_at, location_name, geog, status (proposed/confirmed/done/cancelled).
- `verifications`: id, user_id, type (phone/id/photo), status, reviewed_at.

### 6.6 Edge Cases & Considerations

Species/breed mismatch prevention in breeding mode; expired vaccination certs (block matching, prompt re-upload); fake profiles (verification + reporting); breeding age enforcement (min breeding age by species); ghost matches (inactive users); location spoofing; sparse liquidity in early markets (seed with playdate mode, widen radius); same-owner pets shouldn’t match each other; re-swipe after pass (cooldown); RLS so a user only sees their own swipes/matches.

-----

## 7. MODULE 3: Health & Care Tracker — Full Specification

### 7.1 Feature List

- **Pet health profile:** weight, height, body-condition, vaccinations, medications, allergies, conditions, microchip ID, insurance.
- **Daily care checklist:** feeding, water, grooming, exercise/walk, litter/potty, medication doses — customizable per pet/species.
- **Streak system** (Snapchat/Duolingo-style): consecutive days of completed care; **streak freeze** insurance; streak milestones; friend/family shared streaks for co-owned pets.
- **Achievement/badge system** (Apple-Fitness-style rings/milestones): daily “care ring” completion, weekly goals, lifetime badges (e.g., “100-day streak,” “Vaccination Hero”).
- **Reminders:** medication, feeding, vaccination due, vet appointment, deworming/flea — push + in-app.
- **Vet appointments:** schedule, reminders, clinic info, visit notes; optional clinic directory.
- **Medical records storage:** upload PDF/image (prescriptions, lab reports, vaccine cards); tag by type/date.
- **Growth tracking with charts:** weight-over-time line chart, breed-reference ranges, trend alerts.
- **Symptom checker / health alerts:** guided symptom triage → severity guidance → “see a vet” prompts (clearly non-diagnostic).
- **Multi-pet management:** switch between pets; household dashboard.
- **Shareable health summaries:** generate a PDF/link summary for vets, sitters, or breeding partners.

### 7.2 User Stories (Health)

1. As an **owner**, I want a daily care checklist so that I never forget feeding, meds, or walks.
1. As an **owner**, I want to maintain a care streak so that I stay motivated to care consistently.
1. As an **owner**, I want a streak freeze so that one busy day doesn’t erase months of progress.
1. As an **owner**, I want achievement badges and care rings so that consistent care feels rewarding.
1. As an **owner**, I want medication and vaccination reminders so that I keep my pet healthy and on schedule.
1. As an **owner**, I want to upload and store medical records so that I have my pet’s history in one place.
1. As an **owner**, I want to track my pet’s weight over time on a chart so that I can spot health trends.
1. As an **owner with multiple pets**, I want to manage each pet separately so that care is accurate per animal.
1. As an **owner**, I want to schedule vet appointments with reminders so that I don’t miss checkups.
1. As an **owner**, I want a symptom checker so that I can decide whether to see a vet.
1. As an **owner**, I want to generate a shareable health summary so that my vet or sitter has full context.
1. As a **co-owner**, I want shared care tasks and streaks so that my family coordinates my pet’s care.

### 7.3 Key User Flows

**Daily care loop:** Open Health tab → see today’s care ring per pet → check off tasks (feeding, meds, walk) → ring fills → on full completion, streak increments + celebratory animation + possible badge → optional “share to feed.”

**Add medication reminder:** Pet → Medications → Add → name, dose, frequency, time(s), start/end → save → scheduled local + push reminders → mark “given” feeds the checklist & adherence stats.

**Upload medical record:** Pet → Records → Upload → camera/file → tag type/date/vet → store in private Storage bucket (signed URL) → appears in timeline.

**Weight tracking:** Pet → Growth → Add weight → chart updates → if outside breed reference or sharp change, surface a gentle health alert.

**Generate health summary:** Pet → Share Health → select sections (vaccines, meds, weight, conditions) → generate PDF/secure link → share to vet/sitter/match partner.

### 7.4 Screen Breakdown (Health)

Health Dashboard (multi-pet); Pet Health Profile; Daily Care Checklist; Streak/Rings detail; Achievements/Badges gallery; Reminders list; Add/Edit Reminder; Medications list; Vaccination schedule; Vet Appointments; Add Appointment; Medical Records timeline; Record Upload; Record Viewer; Growth/Weight Charts; Add Measurement; Symptom Checker (multi-step); Health Alert detail; Health Summary generator/preview; Pet Switcher.

### 7.5 Data Entities (Health)

- `pet_health`: pet_id, microchip_id, allergies, conditions, insurance_info, updated_at.
- `care_tasks`: id, pet_id, type, label, schedule (cron/time), is_active.
- `care_logs`: id, care_task_id, pet_id, completed_at, completed_by.
- `streaks`: id, pet_id (or household_id), current_count, longest_count, last_completed_date, freezes_available.
- `achievements` / `pet_achievements`: badge_key, pet_id, earned_at.
- `medications`: id, pet_id, name, dose, frequency, times, start_date, end_date.
- `medication_logs`: id, medication_id, given_at, given_by.
- `vaccinations`: id, pet_id, vaccine, date_given, next_due, vet, cert_path.
- `vet_appointments`: id, pet_id, clinic, datetime, reason, notes, reminder_at, status.
- `medical_records`: id, pet_id, type, file_path, record_date, notes.
- `measurements`: id, pet_id, metric (weight/height), value, unit, measured_at.
- `reminders`: id, pet_id, ref_type, ref_id, fire_at, channel, sent.

### 7.6 Edge Cases & Considerations

Timezone-correct streak day boundaries; streak fairness when offline (sync, grace window); multi-pet household streaks (whose streak?); medication overdose-prevention (don’t double-log); the symptom checker must include clear “not a diagnosis / consult a vet” disclaimers and never block emergency action; private medical docs must use RLS + signed URLs; vaccination reminders localized to Bangladesh schedules; species-specific reference ranges (cat vs dog vs bird); avoid Dogo’s mistake of non-disableable, guilt-heavy streak nags — make pressure humane and configurable.

-----

## 8. MODULE 4: E-commerce Marketplace — Full Specification

### 8.1 Feature List

- **Product catalog:** food, accessories, medicine/health, grooming, litter, toys; species/breed/age attributes.
- **Vendor/seller profiles:** brands and individual sellers; seller onboarding, storefront, ratings.
- **Search, filter, discovery:** category, species, brand, price, rating; sort; full-text search.
- **Cart & wishlist;** save-for-later; **recently viewed**.
- **Checkout** with **bKash, Nagad, card (via SSLCommerz), and Cash-on-Delivery**.
- **Order management & tracking:** status timeline, courier integration (Pathao/Paperfly/Steadfast/RedX), delivery updates.
- **Reviews & ratings** (verified-purchase), photo reviews, seller responses.
- **Flash sales & promotions:** time-boxed deals, coupons, campaign banners (e.g., 11.11-style).
- **Pet-specific recommendations:** by species/breed/age and (optionally) the pet’s health profile — e.g., kitten food for a young cat, joint supplements for a senior dog.
- **Prescription handling** (Chewy-style): Rx items require vet authorization upload before fulfillment.
- **(Deferred) subscription/Autoship** for recurring food/litter/meds — note as roadmap, monetization out of scope. (Chewy’s Autoship reached 83.3% of net sales in FY2025, underscoring its retention power.)

### 8.2 User Stories (Commerce)

1. As a **shopper**, I want to browse products by category and species so that I find relevant items quickly.
1. As a **shopper**, I want to search and filter by brand, price, and rating so that I find the best option.
1. As a **shopper**, I want product recommendations based on my pet’s species/breed/age so that I buy suitable products.
1. As a **shopper**, I want to add items to a cart and wishlist so that I can purchase now or later.
1. As a **Bangladeshi shopper**, I want to pay with bKash, Nagad, card, or cash-on-delivery so that I can use my preferred method.
1. As a **shopper**, I want to track my order and delivery so that I know when it arrives.
1. As a **shopper**, I want to read and write verified reviews so that I can trust product quality.
1. As a **seller**, I want to list products and manage inventory so that I can sell to pet owners.
1. As a **seller**, I want to see and fulfill orders so that I can run my store.
1. As a **shopper**, I want flash sales and coupons so that I save money.
1. As a **shopper buying medicine**, I want to upload a vet prescription so that I can legally order Rx items.
1. As a **shopper**, I want to reorder past purchases easily so that restocking is fast.

### 8.3 Key User Flows

**Browse → buy:** Shop tab → category/species filter or search → product list → product detail (images, specs, reviews, recommendations) → add to cart → cart → checkout → address → payment method (bKash/Nagad/card/COD) → confirm → order created → (online) payment webhook confirms → order tracking.

**bKash/Nagad payment:** Checkout → select bKash → Edge Function creates payment/agreement → in-app webview/SDK → user authorizes → webhook confirms → order marked paid. COD path skips payment, flags “collect on delivery.”

**Seller fulfillment:** Seller dashboard → new order → confirm stock → mark “ready” → assign courier → status updates pushed to buyer.

**Prescription order:** Add Rx item → prompted to upload prescription / vet info → order held → admin/vet verifies → fulfillment proceeds → buyer notified.

### 8.4 Screen Breakdown (Commerce)

Shop Home; Category/Species Listing; Product Search & Filters; Product Detail; Reviews; Cart; Wishlist; Checkout (address, payment, review); Payment Webview; Order Confirmation; Orders List; Order Detail/Tracking; Reorder; Coupons/Promotions; Flash Sale page; Seller Storefront; Seller Dashboard (Products, Orders, Inventory, Payouts); Add/Edit Product; Prescription Upload; Recommendations (“For your pet”).

### 8.5 Data Entities (Commerce)

- `sellers`: id, owner_id, name, type (brand/individual), logo, rating, is_verified, payout_info.
- `products`: id, seller_id, title, description, category, species, age_group, brand, price, currency, stock, is_rx, rating, created_at.
- `product_media`: product_id, path, order_index.
- `product_variants`: id, product_id, attributes (size/flavor), price, stock, sku.
- `carts` / `cart_items`: cart_id, product_variant_id, qty.
- `wishlists` / `wishlist_items`.
- `orders`: id, buyer_id, status, subtotal, shipping, discount, total, payment_method, payment_status, address_id, created_at.
- `order_items`: order_id, product_variant_id, qty, unit_price, seller_id.
- `payments`: id, order_id, gateway (bkash/nagad/sslcommerz/cod), trx_id, status, raw_payload.
- `shipments`: id, order_id, courier, tracking_id, status, updated_at.
- `reviews`: id, product_id, buyer_id, order_id, rating, body, media, seller_response, created_at.
- `coupons` / `promotions`: code, type, value, starts_at, ends_at, conditions.
- `prescriptions`: id, order_item_id, file_path, vet_info, status.
- `addresses`: id, user_id, name, phone, division, district, thana, area, street, is_default.

### 8.6 Edge Cases & Considerations

COD risk (failed deliveries, fake orders — phone-verify, COD limits/deposits); partial fulfillment across multiple sellers (split shipments); payment webhook reliability (idempotent handling, reconciliation); inventory race conditions (atomic stock decrement); Rx items must not ship without verification; refunds/returns flow and COD refunds via bKash; address granularity for Bangladesh (division → district → thana/upazila → area); flash-sale traffic spikes (cache, rate-limit); price/currency display in BDT with English/Bengali numerals; counterfeit-product reporting; seller payout scheduling (deferred with monetization).

-----

## 9. Cross-Cutting Features

- **Onboarding:** language pick (Bengali/English) → phone OTP (or social) → owner profile → **add first pet** (species default cat for BD, breed, age, photo) → optional interests/breeds for feed seeding → enable notifications/location with clear rationale → land on personalized feed. Defer sign-up friction where possible (let users browse first), mirroring proven retention tactics.
- **Authentication:** Supabase Auth — phone OTP primary (Bangladesh), Google/Apple social login (global), session refresh, multi-device, account linking, secure logout, optional biometric app-lock.
- **Push notifications architecture:** FCM (Android) + APNs (iOS) via Edge Functions; per-category preferences (social, matches, health reminders, orders, promos); quiet hours; deep links into the relevant screen; scheduled reminders via pg_cron/Edge Functions; respect humane-pressure principle.
- **Unified search:** one search bar spanning people/pets, hashtags, communities, products, and (mode-aware) matches; Postgres full-text + `pg_trgm` fuzzy; recent & trending; Bengali tokenization considerations.
- **Settings & privacy:** profile visibility, location precision, who-can-DM, blocked list, data export/delete (privacy compliance), notification controls, connected accounts, content-language filter.
- **Multi-language (Bengali + English):** full i18n with `flutter_localizations`/ARB; RTL not required but Bengali script rendering and numeral localization needed; user-generated content language tagging.
- **Dark mode:** full theming via Flutter `ThemeMode` (system/light/dark); persisted preference.
- **Offline support:** local cache for feed/health/pet data; offline care-task logging with sync queue and conflict resolution; queued posts/messages; graceful degradation and clear offline indicators — essential given Bangladesh connectivity variability.

## 10. Screen Inventory (Full App)

**Auth/Onboarding:** Splash; Language Select; Login (phone/social); OTP Verify; Profile Setup; Add Pet; Interests; Permissions.
**Global/Nav:** Bottom Nav (Home, Explore/Shop, Create, Health, Profile); Unified Search; Notifications Center; Settings; Privacy; Account; Blocked Users; Language; Theme.
**Social:** Home Feed; Reels Viewer; Story Viewer; Story Composer; Post Composer/Editor; Owner Profile; Pet Profile; Followers/Following; Explore; Hashtag; Breed Page; Comments; Reactions List; DM Inbox; DM Conversation; New Message/Group; Communities List; Community Home; Community Thread; Community Settings; Saved; Post Insights; Report/Block.
**Matching:** Matching Home (mode toggle); Swipe Deck; Match Card; Filters; Match Modal; Matches List; Match Chat; Breeding Profile Editor; Playdate Scheduler; Location Suggestions Map; Verification Center; Safety Tips.
**Health:** Health Dashboard; Pet Health Profile; Daily Care Checklist; Streak/Rings; Achievements; Reminders; Add Reminder; Medications; Vaccinations; Vet Appointments; Add Appointment; Medical Records; Record Upload/Viewer; Growth Charts; Add Measurement; Symptom Checker; Health Alert; Health Summary; Pet Switcher.
**Commerce:** Shop Home; Category Listing; Product Search/Filters; Product Detail; Reviews; Cart; Wishlist; Checkout; Payment Webview; Order Confirmation; Orders List; Order Tracking; Reorder; Coupons; Flash Sale; Seller Storefront; Seller Dashboard; Add/Edit Product; Prescription Upload; Recommendations.

## 11. Supabase Data Schema Overview

**Design principles:** UUID primary keys (except high-volume serial tables); `auth.users` as identity root; **RLS on every table**; foreign keys with `on delete cascade` where appropriate; `created_at timestamptz default now()`; enums for fixed vocabularies; spatial data via PostGIS; Storage buckets (`post-media` public-read, `pet-media`, `medical-records` private, `product-media`, `verification-docs` private).

**Core table groups:** Identity (`profiles`, `pets`), Social (`posts`, `post_media`, `stories`, `story_views`, `comments`, `reactions`, `follows`, `hashtags`, `post_hashtags`, `conversations`, `conversation_members`, `messages`, `communities`, `community_members`, `community_posts`, `notifications`, `reports`, `blocks`), Matching (`match_profiles`, `pet_location`, `pet_health_certs`, `pet_pedigree`, `swipes`, `matches`, `playdates`, `verifications`), Health (`pet_health`, `care_tasks`, `care_logs`, `streaks`, `achievements`, `pet_achievements`, `medications`, `medication_logs`, `vaccinations`, `vet_appointments`, `medical_records`, `measurements`, `reminders`), Commerce (`sellers`, `products`, `product_media`, `product_variants`, `carts`, `cart_items`, `wishlists`, `wishlist_items`, `orders`, `order_items`, `payments`, `shipments`, `reviews`, `coupons`, `promotions`, `prescriptions`, `addresses`).

**Key relationships:** `auth.users 1—1 profiles`; `profiles 1—* pets`; `pets 1—* posts/health/match_profiles`; `posts 1—* post_media/comments/reactions`; `pets *—* follows`; `swipes → matches` (mutual right-swipe); `sellers 1—* products`; `orders 1—* order_items`, `orders 1—1 payments/shipments`.

### 11.1 Geospatial matching (PostGIS) — implementation detail

Per Supabase’s official PostGIS guide (“PostGIS: Geo queries,” supabase.com/docs/guides/database/extensions/postgis), store location in a `geography(POINT)` column rather than raw decimals because, as the docs note, raw lat/long “does not scale very well when you try to query through a large data set,” whereas PostGIS types are “efficient, and indexable for high scalability.”  Enable with `create extension postgis with schema "extensions";`, store the point, and add a **GIST** spatial index:

```sql
create index pets_geo_index on public.pet_location using GIST (geog);
```

Insert from the Dart client as a space-separated `POINT(long lat)` string (longitude first, no comma). For nearest-neighbor sorting the docs use the `<->` KNN operator inside `order by` and `ST_Distance` for `dist_meters`. For a Tinder-style **radius filter**, combine the docs’ RPC pattern with the standard, index-accelerated `ST_DWithin`:

```sql
create or replace function nearby_pets(lat float, long float, radius_meters float)
returns table (id bigint, name text, lat float, long float, dist_meters float)
language sql stable as $$
  select p.id, p.name,
         st_y(p.location::geometry) as lat,
         st_x(p.location::geometry) as long,
         st_distance(p.location, st_point(long, lat)::geography) as dist_meters
  from public.pets p
  where st_dwithin(p.location, st_point(long, lat)::geography, radius_meters)
  order by p.location <-> st_point(long, lat)::geography;
$$;
```

Call from Flutter: `await supabase.rpc('nearby_pets', params: {'lat': .., 'long': .., 'radius_meters': ..});`. A lighter alternative is the `earthdistance`/`cube` extension, but it assumes a perfect sphere (less accurate) — PostGIS `geography` is recommended.

### 11.2 Swipe & mutual-match pattern

Use the **Directed Swipes** model (one row per swipe). A `swipes` table holds `(swiper_pet_id, swipee_pet_id, direction, mode)` with `unique(swiper, swipee, mode)` and a `check` preventing self-swipes. A `matches` table stores pairs **canonically** (smaller id first, enforced by `check (pet_a < pet_b)` + `unique`) so a mutual match yields exactly one row. Detect matches with an `AFTER INSERT` trigger on `swipes` that, on a right swipe, checks for the reverse right swipe and inserts the match with `on conflict do nothing` (idempotent). The discovery feed query excludes already-swiped and matched pets, then applies the `nearby_pets` radius filter.

## 12. Flutter Architecture Recommendations

- **State management:** Riverpod (or BLoC) for testable, scalable state; Riverpod recommended for its simplicity with async providers wrapping Supabase streams/futures.
- **Layered/Clean architecture:** Presentation (widgets/controllers) → Domain (entities/use-cases) → Data (repositories wrapping `supabase_flutter`). Consider a feature-first folder structure (one folder per pillar) and a monorepo with shared packages (core, ui-kit, models) for scale.
- **Routing:** `go_router` with deep-link support (notifications/payment returns/share links).
- **Realtime:** wrap Supabase Realtime streams in `StreamProvider`s feeding `StreamBuilder`/Riverpod for DMs, matches, feed, order status.
- **Local persistence/offline:** Drift or Isar for structured cache; an outbox/sync queue for offline care logs, posts, and messages; optimistic UI.
- **Media:** `image_picker`/`camera`, client-side compression, `cached_network_image`, video via `video_player`/`better_player`; upload to Supabase Storage with progress.
- **Payments:** `flutter_bkash` (community package) and/or SSLCommerz/Nagad via webview + Edge Function backend; never embed secret keys in the client — broker through Edge Functions.
- **i18n/theming:** `flutter_localizations` + ARB (Bengali/English); central `ThemeData` with light/dark; design-token-based UI kit.
- **Notifications:** `firebase_messaging` + `flutter_local_notifications`; token registration stored server-side; deep-link routing.
- **Maps/location:** `geolocator` for GPS, Google Maps/Mapbox Flutter SDK for location suggestions; send coordinates to the `nearby_pets` RPC.
- **Quality:** repository interfaces for testability, golden tests for UI, CI/CD (Codemagic/GitHub Actions), Sentry for crash reporting, feature flags for staged rollout.

## 13. Phased Development Roadmap

**Phase 0 — Foundations (Weeks 1–4).** Supabase project, schema + RLS for identity, Auth (phone OTP + social), onboarding, i18n (Bengali/English), theming/dark mode, navigation shell, CI/CD, offline cache scaffolding.

**Phase 1 — Social Core (Weeks 5–12).** Owner + pet profiles, feed (photo/video), posts, likes/reactions/comments, follow graph, stories, basic Explore, DMs (Realtime), notifications, reporting/blocking + automated moderation first-pass. *Goal: daily-active engagement and content liquidity.*

**Phase 2 — Health & Gamification (Weeks 10–18, overlapping).** Pet health profiles, daily care checklist, streaks + freezes, achievements/rings, reminders (pg_cron/Edge Functions + push), medical records storage, growth charts, multi-pet, shareable summaries, symptom checker (with disclaimers). *Goal: retention via humane streaks; ties to social via shareable milestones.*

**Phase 3 — Commerce (Weeks 16–26).** Catalog, seller onboarding/storefronts, search/filter, cart/wishlist, checkout, **bKash/Nagad/SSLCommerz + COD**, courier tracking, reviews, flash sales, prescription handling, pet-specific recommendations. *Goal: utility + (later) revenue; leverage health/pet graph for recommendations.*

**Phase 4 — Matching (Weeks 24–34).** PostGIS nearby discovery, swipe deck, breeding & playdate modes, filters, mutual-match + chat, health-cert/pedigree verification, playdate scheduler + location suggestions, safety/verification. *Goal: high-engagement feature launched once user base provides match liquidity and trust/safety tooling is mature.*

**Phase 5 — Scale & Global (Weeks 32+).** Feed ranking improvements, external search index, dog-first defaults toggle for non-BD markets, additional languages, Autoship/subscriptions, tele-vet, performance/cost optimization, regional logistics/payment expansion.

*Rationale for ordering:* Social + Health build the daily habit and data graph cheaply; Commerce monetizes and benefits from that graph; Matching is deferred because it carries the highest trust/safety burden and needs density to work — exactly the sequencing that de-risks a four-pillar super-app.

## 14. Caveats

- **Market figures vary by source.** Global pet-care market estimates range widely ($181.9B Grand View / $273.42B Fortune Business Insights / $346.01B Precedence for 2025) depending on methodology/scope; Bangladesh pet-population figures are estimates from a single ACI study and academic surveys with small samples — treat as directional, not precise.
- **Cat-first vs dog-first.** Several competitor features (Pawmates, BarkHappy, Dogo, Find My K9) are dog-centric; Bangladesh is cat-dominant. Product defaults must flip by market.
- **Breeding ethics & regulation.** A breeding-match feature carries welfare and legal sensitivities (responsible breeding, health screening); strong verification and clear policies are required, and local regulations should be checked before launch.
- **Health module is not veterinary advice.** The symptom checker and health summaries are informational; explicit disclaimers and “consult a vet” prompts are mandatory.
- **Payment/logistics dependencies.** bKash/Nagad require merchant approval (days–weeks); COD introduces fraud/return risk; courier integrations vary in API maturity.
- **Supabase official docs use `<->`/`&&` in their RPC example, not `ST_DWithin`** — the radius pattern above is standard, index-accelerated PostGIS but should be tested; the swipe/match trigger schema is synthesized from relational best practice, not an official Supabase template.
- **Moderation at scale** needs investment (automated + reactive + human review); Bengali-language abuse detection is less mature than English.
- **Monetization deliberately excluded** per scope; subscription/Autoship (Chewy’s reached 83.3% of net sales, a strong precedent), seller commissions, boosts, and ads are noted only as future hooks.
