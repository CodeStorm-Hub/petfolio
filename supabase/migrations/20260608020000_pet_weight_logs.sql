create table if not exists public.pet_weight_logs (
  id           uuid primary key default gen_random_uuid(),
  pet_id       uuid not null references public.pets(id) on delete cascade,
  weight_kg    numeric(6,3) not null check (weight_kg > 0 and weight_kg < 500),
  notes        text,
  recorded_at  timestamptz not null default now(),
  created_at   timestamptz not null default now()
);

alter table public.pet_weight_logs enable row level security;

create policy "weight_logs_select" on public.pet_weight_logs
  for select using (
    exists (select 1 from public.pets where id = pet_id and owner_id = auth.uid())
  );

create policy "weight_logs_insert" on public.pet_weight_logs
  for insert with check (
    exists (select 1 from public.pets where id = pet_id and owner_id = auth.uid())
  );

create policy "weight_logs_delete" on public.pet_weight_logs
  for delete using (
    exists (select 1 from public.pets where id = pet_id and owner_id = auth.uid())
  );

create index if not exists idx_pet_weight_logs_pet_recorded
  on public.pet_weight_logs(pet_id, recorded_at desc);
