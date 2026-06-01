-- Add covering indexes for foreign keys flagged by advisor 0001
-- (unindexed_foreign_keys). These columns are used for joins / cascade lookups
-- and would otherwise sequential-scan as the tables grow.

create index if not exists idx_audit_logs_admin_id
  on public.audit_logs (admin_id);

create index if not exists idx_comment_likes_pet_id
  on public.comment_likes (pet_id);

create index if not exists idx_comment_likes_user_id
  on public.comment_likes (user_id);

create index if not exists idx_comments_pet_id
  on public.comments (pet_id);

create index if not exists idx_notifications_actor_pet_id
  on public.notifications (actor_pet_id);

create index if not exists idx_notifications_post_id
  on public.notifications (post_id);

create index if not exists idx_notifications_recipient_user_id
  on public.notifications (recipient_user_id);

create index if not exists idx_post_likes_pet_id
  on public.post_likes (pet_id);

create index if not exists idx_reported_posts_reporter_id
  on public.reported_posts (reporter_id);

create index if not exists idx_reported_posts_reviewed_by
  on public.reported_posts (reviewed_by);

create index if not exists idx_shop_deletion_requests_owner_id
  on public.shop_deletion_requests (owner_id);
