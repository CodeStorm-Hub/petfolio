create table if not exists public.reported_posts (
  id           uuid        primary key default gen_random_uuid(),
  post_id      uuid        not null references public.posts(id) on delete cascade,
  reporter_id  uuid        not null references auth.users(id) on delete cascade,
  reason       text        not null check (char_length(reason) between 1 and 500),
  created_at   timestamptz not null default now(),
  unique (post_id, reporter_id)
);

alter table public.reported_posts enable row level security;

create policy "authenticated users can report posts"
  on public.reported_posts for insert to authenticated
  with check (reporter_id = auth.uid());

create policy "reporters can view own reports"
  on public.reported_posts for select to authenticated
  using (reporter_id = auth.uid());
