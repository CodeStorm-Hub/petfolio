# Communities Audit Report

**Audit Summary**: The communities feature is built using feature-first architecture and Riverpod. However, its database schema has critical performance issues: it violates the project rule by using bare `auth.uid()` in RLS policies instead of `(select auth.uid())` subselects, and it lacks foreign key indexes on membership and post tables, which will trigger full table scans.

## Architecture & UI/UX

- **Feature-First Architecture**: Implemented under `lib/features/communities/` with clean presentation and data layers:
  - `data/`: Contains models (`community.dart`, `community_post.dart`) and `community_repository.dart`.
  - `presentation/`: Contains `communities_controller.dart`, `communities_screen.dart`, and related widgets.
- **Riverpod State Management**: Uses modern Riverpod notifiers to handle lists and state mutations (joins, likes, and creations).
- **UI & Layout**: Displays lists of communities and detail pages containing posts. It implements animated UI widgets but lacks direct deep linking route definitions in its directory (routing is currently handled externally).

## Supabase & Data Integration

- **Uncached RLS Policies (Critical Rule Violation)**: In `20260608000000_communities.sql`, RLS policies use bare `auth.uid()` checks (e.g., `auth.uid() = created_by`, `owner_id = auth.uid()`). This violates the project rule in `AGENTS.md` requiring `(select auth.uid())` to enable Postgres plan-cache reuse, causing database performance degradation.
- **Missing Foreign Key Indexes**: The migrations do not create indexes for the following foreign key fields:
  - `community_members(pet_id)`
  - `community_posts(community_id)`
  - `community_posts(author_pet_id)`
  - `community_post_likes(pet_id)`
  This makes joins and lookups on these fields highly inefficient and will result in full table scans as rows increase.
- **Client Retrieval Optimization**: The repository is designed to prevent N+1 query loops by:
  - Joining author details inside the select statement: `pets!community_posts_author_pet_id_fkey(name, avatar_url)`.
  - Performing batch lookups for likes using a single query targeting the active `petId` instead of per-post like fetches.
- **Security Definer Hardening**: The trigger functions to increment/decrement member and post counts are securely locked down by revoking execution permissions from public roles (`anon` and `authenticated`) in `20260615000002_phase6_security_hardening.sql`.
