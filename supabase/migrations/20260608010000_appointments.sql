create table if not exists public.appointments (
  id            uuid primary key default gen_random_uuid(),
  pet_id        uuid not null references public.pets(id) on delete cascade,
  owner_id      uuid not null references auth.users(id) on delete cascade,
  title         text not null,
  notes         text,
  location      text,
  vet_name      text,
  scheduled_at  timestamptz not null,
  status        text not null default 'upcoming'
                check (status in ('upcoming', 'completed', 'cancelled')),
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

alter table public.appointments enable row level security;

create policy "appointments_select" on public.appointments
  for select using (auth.uid() = owner_id);

create policy "appointments_insert" on public.appointments
  for insert with check (auth.uid() = owner_id);

create policy "appointments_update" on public.appointments
  for update using (auth.uid() = owner_id);

create policy "appointments_delete" on public.appointments
  for delete using (auth.uid() = owner_id);

create index if not exists idx_appointments_pet_id on public.appointments(pet_id);
create index if not exists idx_appointments_scheduled_at on public.appointments(scheduled_at);
