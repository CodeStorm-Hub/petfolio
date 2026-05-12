-- ─────────────────────────────────────────────────────────────────────────────
-- Migration: marketplace
-- Adds: products table (with 8 seeded products)
--       marketplace_orders refinements (seller_id nullable, stripe columns)
-- ─────────────────────────────────────────────────────────────────────────────

-- ── 1. Products table ────────────────────────────────────────────────────────

create table if not exists public.products (
  id            uuid         primary key default gen_random_uuid(),
  name          text         not null,
  brand         text         not null,
  variant       text         not null default '',
  category      text         not null check (category in ('food','gear','toys','treats','health','grooming')),
  price_cents   integer      not null check (price_cents > 0),
  currency      text         not null default 'usd',
  subscribable  boolean      not null default false,
  glyph         text         not null default 'bag',
  gradient_start text        not null default '#F4B57A',
  gradient_end  text         not null default '#C46A4F',
  active        boolean      not null default true,
  created_at    timestamptz  not null default now()
);

alter table public.products enable row level security;

-- Everyone can read active products; only service role can write.
create policy "Anyone can read active products"
  on public.products for select
  using (active = true);

-- ── 2. Seed products (prices in USD cents) ───────────────────────────────────

insert into public.products (id, name, brand, variant, category, price_cents, subscribable, glyph, gradient_start, gradient_end) values
  ('aaaaaaaa-0001-0001-0001-aaaaaaaaaaaa', 'Wild Salmon & Sweet Potato Kibble', 'Wholepack',  '12 kg bag',     'food',     4800, true,  'bag',   '#F4B57A', '#C46A4F'),
  ('aaaaaaaa-0002-0002-0002-aaaaaaaaaaaa', 'Tug-of-War Rope Twist',             'Pawhaus',    'Medium',        'toys',     1450, false, 'rope',  '#9BB59A', '#485F4F'),
  ('aaaaaaaa-0003-0003-0003-aaaaaaaaaaaa', 'Reflective Trail Harness',          'Highline',   'M · Slate',     'gear',     3800, false, 'leash', '#4B7DFA', '#173FA3'),
  ('aaaaaaaa-0004-0004-0004-aaaaaaaaaaaa', 'Single-Source Beef Liver Treats',   'Wholepack',  '200 g jar',     'treats',    920, true,  'bone',  '#E76F51', '#B14530'),
  ('aaaaaaaa-0005-0005-0005-aaaaaaaaaaaa', 'Joint Support Chews · Glucosamine', 'Vitavet',    '60 chews',      'health',   2400, true,  'pill',  '#9B5C8A', '#5E3354'),
  ('aaaaaaaa-0006-0006-0006-aaaaaaaaaaaa', 'Slicker Brush · Self-Cleaning',     'Pawhaus',    'Long-haired',   'grooming', 1950, false, 'brush', '#F5C49B', '#C49370'),
  ('aaaaaaaa-0007-0007-0007-aaaaaaaaaaaa', 'Pumpkin Digestive Wet Food',        'Wholepack',  '12 × 400g',     'food',     3200, true,  'bowl',  '#F4A261', '#B86E2C'),
  ('aaaaaaaa-0008-0008-0008-aaaaaaaaaaaa', 'Bouncing Squeaker Ball',            'Pawhaus',    'Two-pack',      'toys',      800, false, 'ball',  '#6BAF92', '#2F6A4D')
on conflict (id) do nothing;

-- ── 3. marketplace_orders — make seller_id nullable ──────────────────────────

-- Drop the self-order constraint first (references seller_id).
alter table public.marketplace_orders
  drop constraint if exists no_self_order;

-- Make seller_id nullable.
alter table public.marketplace_orders
  alter column seller_id drop not null;

-- Re-add constraint — only enforced when seller_id is populated.
alter table public.marketplace_orders
  add constraint no_self_order check (seller_id is null or buyer_id != seller_id);

-- ── 4. Add stripe / line-items columns to marketplace_orders ─────────────────

alter table public.marketplace_orders
  add column if not exists stripe_payment_intent_id text,
  add column if not exists line_items jsonb not null default '[]'::jsonb;

-- Unique index so we can idempotently look up by PI id.
create unique index if not exists marketplace_orders_stripe_pi_idx
  on public.marketplace_orders (stripe_payment_intent_id)
  where stripe_payment_intent_id is not null;
