-- Remove broad public SELECT policies on storage.objects for the `pets` and
-- `shops` buckets (advisor 0025 public_bucket_allows_listing).
--
-- Both buckets are public, so object content is served via the public URL
-- endpoint (getPublicUrl) without any storage.objects SELECT policy. The broad
-- `USING (bucket_id = ...)` SELECT policies only enabled clients to *list* every
-- file in the bucket via the API — unnecessary and an over-exposure. The app
-- never calls .list()/.download() on these buckets, only getPublicUrl.

drop policy if exists "Public Access" on storage.objects;
drop policy if exists "Shop assets are publicly readable" on storage.objects;
