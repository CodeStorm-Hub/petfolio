-- ─────────────────────────────────────────────────────────────────────────────
-- Migration: 20260610000000_vet_clinics_and_services.sql
-- Adds vet_clinics, vet_services, and extends appointments
-- with optional FK links back to a booked clinic/service.
-- ─────────────────────────────────────────────────────────────────────────────

-- ── 1. vet_clinics ────────────────────────────────────────────────────────────
create table if not exists public.vet_clinics (
  id             uuid primary key default gen_random_uuid(),
  name           text not null,
  tagline        text,
  address        text not null,
  city           text not null,
  phone          text,
  email          text,
  website        text,
  avatar_url     text,
  rating         numeric(3,2) not null default 0.0
                   check (rating >= 0.0 and rating <= 5.0),
  review_count   int not null default 0,
  is_active      boolean not null default true,
  created_at     timestamptz not null default now()
);

alter table public.vet_clinics enable row level security;

create policy "vet_clinics_public_read" on public.vet_clinics
  for select using (is_active = true);

-- ── 2. vet_services ──────────────────────────────────────────────────────────
create table if not exists public.vet_services (
  id                uuid primary key default gen_random_uuid(),
  clinic_id         uuid not null references public.vet_clinics(id) on delete cascade,
  name              text not null,
  description       text,
  duration_minutes  int not null default 30
                      check (duration_minutes > 0),
  price_cents       int not null default 0
                      check (price_cents >= 0),
  created_at        timestamptz not null default now()
);

alter table public.vet_services enable row level security;

create policy "vet_services_public_read" on public.vet_services
  for select using (true);

create index if not exists idx_vet_services_clinic_id
  on public.vet_services(clinic_id);

-- ── 3. Extend appointments with optional clinic / service FK ─────────────────
alter table public.appointments
  add column if not exists clinic_id  uuid references public.vet_clinics(id)  on delete set null,
  add column if not exists service_id uuid references public.vet_services(id) on delete set null;

create index if not exists idx_appointments_clinic_id
  on public.appointments(clinic_id) where clinic_id is not null;

-- ── 4. Seed — sample clinics & services ──────────────────────────────────────
insert into public.vet_clinics
  (id, name, tagline, address, city, phone, rating, review_count, avatar_url)
values
  ('11111111-0000-0000-0000-000000000001',
   'PawsCare Veterinary Clinic',
   'Compassionate care for every paw',
   '12 Gulshan Avenue',    'Dhaka', '+880-1700-000001', 4.8, 142, null),
  ('11111111-0000-0000-0000-000000000002',
   'City Pet Hospital',
   'Modern diagnostics, gentle hands',
   '58 Dhanmondi Road 27', 'Dhaka', '+880-1700-000002', 4.5,  98, null),
  ('11111111-0000-0000-0000-000000000003',
   'Happy Tails Animal Clinic',
   'Where pets come first',
   '3 Banani Block C',     'Dhaka', '+880-1700-000003', 4.7,  67, null),
  ('11111111-0000-0000-0000-000000000004',
   'VetPlus 24/7 Emergency',
   'Round-the-clock emergency care',
   '102 Mirpur Road',      'Dhaka', '+880-1700-000004', 4.6,  31, null)
on conflict (id) do nothing;

insert into public.vet_services
  (clinic_id, name, description, duration_minutes, price_cents)
values
  ('11111111-0000-0000-0000-000000000001', 'Annual Wellness Check',  'Full physical exam, vaccinations review',   30,  180000),
  ('11111111-0000-0000-0000-000000000001', 'Vaccination',            'Core & lifestyle vaccines',                 20,   80000),
  ('11111111-0000-0000-0000-000000000001', 'Dental Cleaning',        'Scaling & polishing under sedation',        60,  450000),
  ('11111111-0000-0000-0000-000000000001', 'Microchipping',          'ISO-standard chip implant',                 15,   60000),
  ('11111111-0000-0000-0000-000000000002', 'General Consultation',   'Illness or symptom evaluation',             30,  150000),
  ('11111111-0000-0000-0000-000000000002', 'Blood Panel',            'CBC + chemistry comprehensive panel',       20,  350000),
  ('11111111-0000-0000-0000-000000000002', 'X-Ray Imaging',          'Digital radiograph, 1–2 views',             30,  500000),
  ('11111111-0000-0000-0000-000000000003', 'Annual Wellness Check',  'Full physical exam & wellness plan',        30,  160000),
  ('11111111-0000-0000-0000-000000000003', 'Spay / Neuter',          'Routine sterilisation surgery',             90, 1200000),
  ('11111111-0000-0000-0000-000000000003', 'Flea & Tick Treatment',  'Topical + oral prevention options',         15,   55000),
  ('11111111-0000-0000-0000-000000000004', 'Emergency Consultation', 'Triage + immediate care plan',              20,  350000),
  ('11111111-0000-0000-0000-000000000004', 'IV Fluid Therapy',       'Intravenous rehydration, per session',      60,  600000);
