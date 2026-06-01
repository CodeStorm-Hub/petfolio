-- Tighten notifications INSERT RLS.
--
-- Previously `notifications_insert_policy` used WITH CHECK (true), letting any
-- authenticated user insert a notification addressed to any recipient (spoof /
-- spam vector). Client inserts always set actor_pet_id to a pet the caller
-- owns (see SocialRepository → NotificationRepository.insertNotification).
-- Admin/system notifications (kyc_*, shop_deletion_*) are written by
-- SECURITY DEFINER RPCs which bypass RLS, so they are unaffected.

drop policy if exists notifications_insert_policy on public.notifications;

create policy notifications_insert_policy
  on public.notifications
  for insert
  to authenticated
  with check (
    actor_pet_id in (
      select id from public.pets where owner_id = (select auth.uid())
    )
  );
