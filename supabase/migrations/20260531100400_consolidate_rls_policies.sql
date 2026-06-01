-- Consolidate duplicate / overlapping permissive RLS policies
-- (advisor 0006 multiple_permissive_policies). Each table+command below had
-- 2-3 permissive policies that Postgres OR-evaluates on every query. Merging
-- them into a single policy with the same OR-ed predicate is access-preserving
-- and removes the per-query overhead. Predicates are reproduced verbatim from
-- the existing policies.

-- ── users: two identical `USING (true)` SELECT policies ─────────────────────
drop policy if exists "Authenticated users can read basic profile info" on public.users;
-- keeps "users: authenticated can view all profiles"

-- ── chat_threads: two identical participant SELECT policies ─────────────────
drop policy if exists "Users can read their own chat threads" on public.chat_threads;
-- keeps "chat_threads: select by participants only"

-- ── pet_follows: drop legacy public-role duplicates, keep authenticated set ──
drop policy if exists "Pets can unfollow" on public.pet_follows;
drop policy if exists "Pets can follow" on public.pet_follows;
drop policy if exists "Public Read Access" on public.pet_follows;

-- ── posts: admin OR public-or-own → single SELECT ───────────────────────────
drop policy if exists "admins can select all posts" on public.posts;
drop policy if exists "posts: select public or own" on public.posts;
create policy "posts: select visible or admin"
  on public.posts for select to authenticated
  using (
    (select public.is_admin())
    or visibility = 'public'
    or (select auth.uid()) = author_id
  );

-- ── shops: admin OR owner OR active-verified → single SELECT ─────────────────
drop policy if exists "admins_select_shops" on public.shops;
drop policy if exists "shops: owner can select own" on public.shops;
drop policy if exists "shops: select active verified" on public.shops;
create policy "shops: select visible or admin"
  on public.shops for select to authenticated
  using (
    (select public.is_admin())
    or (select auth.uid()) = owner_id
    or (is_active = true and is_verified = true)
  );

-- ── shops: admin OR owner → single UPDATE ───────────────────────────────────
drop policy if exists "admins_update_shops" on public.shops;
drop policy if exists "shops: owner can update" on public.shops;
create policy "shops: update owner or admin"
  on public.shops for update to authenticated
  using ((select public.is_admin()) or (select auth.uid()) = owner_id)
  with check ((select public.is_admin()) or (select auth.uid()) = owner_id);

-- ── marketplace_orders: admin OR buyer OR vendor → single SELECT ────────────
drop policy if exists "admins_select_orders" on public.marketplace_orders;
drop policy if exists "orders: buyer can select own" on public.marketplace_orders;
drop policy if exists "orders: vendor can select shop orders" on public.marketplace_orders;
create policy "orders: select buyer vendor or admin"
  on public.marketplace_orders for select to authenticated
  using (
    (select public.is_admin())
    or (select auth.uid()) = buyer_id
    or (select auth.uid()) = (
      select shops.owner_id from public.shops where shops.id = marketplace_orders.shop_id
    )
  );

-- ── marketplace_orders: admin OR buyer-when-pending → single DELETE ─────────
drop policy if exists "admins_delete_orders" on public.marketplace_orders;
drop policy if exists "orders: delete by buyer when pending" on public.marketplace_orders;
create policy "orders: delete buyer-pending or admin"
  on public.marketplace_orders for delete to authenticated
  using (
    (select public.is_admin())
    or ((select auth.uid()) = buyer_id and status = 'pending')
  );

-- ── reported_posts: admin OR reporter → single SELECT ───────────────────────
drop policy if exists "admins can view all reported posts" on public.reported_posts;
drop policy if exists "reporters can view own reports" on public.reported_posts;
create policy "reported_posts: select reporter or admin"
  on public.reported_posts for select to authenticated
  using (
    (select public.is_admin())
    or reporter_id = (select auth.uid())
  );

-- ── vendor_ledgers: admin OR shop-owner → single SELECT ─────────────────────
drop policy if exists "admins_select_ledger" on public.vendor_ledgers;
drop policy if exists "shop_owner_select_ledger" on public.vendor_ledgers;
create policy "vendor_ledgers: select owner or admin"
  on public.vendor_ledgers for select to authenticated
  using (
    (select public.is_admin())
    or exists (
      select 1 from public.shops
      where shops.id = vendor_ledgers.shop_id
        and shops.owner_id = (select auth.uid())
    )
  );

-- ── shop_deletion_requests: admin OR owner → single SELECT ──────────────────
drop policy if exists "admin_select" on public.shop_deletion_requests;
drop policy if exists "owner_select" on public.shop_deletion_requests;
create policy "deletion_requests: select owner or admin"
  on public.shop_deletion_requests for select to authenticated
  using (
    (select public.is_admin())
    or (select auth.uid()) = owner_id
  );
