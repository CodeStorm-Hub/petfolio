-- Covering indexes for marketplace FK columns flagged by advisor unindexed_foreign_keys.
-- user_addresses and shop_deletion_requests INSERT policies were already correct.

create index if not exists idx_disputes_order_id
  on public.disputes (order_id);

create index if not exists idx_disputes_raised_by
  on public.disputes (raised_by);

create index if not exists idx_inventory_reservations_variant_id
  on public.inventory_reservations (variant_id);

create index if not exists idx_payout_requests_resolved_by
  on public.payout_requests (resolved_by);

create index if not exists idx_payout_requests_shop_id
  on public.payout_requests (shop_id);

create index if not exists idx_prescriptions_reviewer_id
  on public.prescriptions (reviewer_id);

create index if not exists idx_product_reviews_user_id
  on public.product_reviews (user_id);

create index if not exists idx_promos_shop_id
  on public.promos (shop_id);

create index if not exists idx_vendor_ledgers_payout_request_id
  on public.vendor_ledgers (payout_request_id);

create index if not exists idx_wishlist_items_product_id
  on public.wishlist_items (product_id);

create index if not exists idx_wishlist_items_variant_id
  on public.wishlist_items (variant_id);
