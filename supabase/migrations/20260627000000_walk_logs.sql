create table if not exists public.walk_logs (
  id               uuid primary key default gen_random_uuid(),
  pet_id           uuid not null references public.pets(id) on delete cascade,
  user_id          uuid not null references auth.users(id) on delete cascade,
  started_at       timestamptz not null,
  ended_at         timestamptz not null,
  duration_seconds integer not null check (duration_seconds > 0),
  distance_meters  numeric(10, 2) not null check (distance_meters >= 0),
  created_at       timestamptz not null default now()
);

alter table public.walk_logs enable row level security;

create policy "Users can insert their own walk logs"
  on public.walk_logs for insert
  with check (auth.uid() = user_id);

create policy "Users can view their own walk logs"
  on public.walk_logs for select
  using (auth.uid() = user_id);

create policy "Users can delete their own walk logs"
  on public.walk_logs for delete
  using (auth.uid() = user_id);

create index if not exists walk_logs_pet_id_idx
  on public.walk_logs (pet_id, started_at desc);
