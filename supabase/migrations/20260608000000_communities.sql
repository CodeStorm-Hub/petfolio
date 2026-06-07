create table if not exists public.communities (
  id            uuid primary key default gen_random_uuid(),
  name          text not null,
  description   text,
  species_filter text,
  avatar_url    text,
  created_by    uuid references auth.users(id) on delete set null,
  member_count  integer not null default 0,
  post_count    integer not null default 0,
  created_at    timestamptz not null default now()
);

create table if not exists public.community_members (
  community_id  uuid not null references public.communities(id) on delete cascade,
  pet_id        uuid not null references public.pets(id) on delete cascade,
  joined_at     timestamptz not null default now(),
  primary key (community_id, pet_id)
);

create table if not exists public.community_posts (
  id            uuid primary key default gen_random_uuid(),
  community_id  uuid not null references public.communities(id) on delete cascade,
  author_pet_id uuid not null references public.pets(id) on delete cascade,
  content       text not null check (char_length(content) <= 1000),
  image_url     text,
  like_count    integer not null default 0,
  created_at    timestamptz not null default now()
);

create table if not exists public.community_post_likes (
  post_id  uuid not null references public.community_posts(id) on delete cascade,
  pet_id   uuid not null references public.pets(id) on delete cascade,
  primary key (post_id, pet_id)
);

-- triggers: keep member_count and post_count accurate
create or replace function public.inc_community_member_count()
returns trigger language plpgsql as $$
begin
  update public.communities set member_count = member_count + 1 where id = NEW.community_id;
  return NEW;
end;
$$;

create or replace function public.dec_community_member_count()
returns trigger language plpgsql as $$
begin
  update public.communities set member_count = greatest(0, member_count - 1) where id = OLD.community_id;
  return OLD;
end;
$$;

create or replace function public.inc_community_post_count()
returns trigger language plpgsql as $$
begin
  update public.communities set post_count = post_count + 1 where id = NEW.community_id;
  return NEW;
end;
$$;

create or replace function public.dec_community_post_count()
returns trigger language plpgsql as $$
begin
  update public.communities set post_count = greatest(0, post_count - 1) where id = OLD.community_id;
  return OLD;
end;
$$;

create or replace trigger trg_community_member_join
  after insert on public.community_members
  for each row execute function public.inc_community_member_count();

create or replace trigger trg_community_member_leave
  after delete on public.community_members
  for each row execute function public.dec_community_member_count();

create or replace trigger trg_community_post_added
  after insert on public.community_posts
  for each row execute function public.inc_community_post_count();

create or replace trigger trg_community_post_removed
  after delete on public.community_posts
  for each row execute function public.dec_community_post_count();

-- RLS
alter table public.communities enable row level security;
alter table public.community_members enable row level security;
alter table public.community_posts enable row level security;
alter table public.community_post_likes enable row level security;

create policy "communities_read" on public.communities for select using (true);
create policy "communities_insert" on public.communities for insert with check (auth.uid() = created_by);

create policy "members_read" on public.community_members for select using (true);
create policy "members_insert" on public.community_members for insert
  with check (exists (select 1 from public.pets where id = pet_id and owner_id = auth.uid()));
create policy "members_delete" on public.community_members for delete
  using (exists (select 1 from public.pets where id = pet_id and owner_id = auth.uid()));

create policy "posts_read" on public.community_posts for select using (true);
create policy "posts_insert" on public.community_posts for insert
  with check (exists (select 1 from public.pets where id = author_pet_id and owner_id = auth.uid()));
create policy "posts_delete" on public.community_posts for delete
  using (exists (select 1 from public.pets where id = author_pet_id and owner_id = auth.uid()));

create policy "likes_read" on public.community_post_likes for select using (true);
create policy "likes_insert" on public.community_post_likes for insert
  with check (exists (select 1 from public.pets where id = pet_id and owner_id = auth.uid()));
create policy "likes_delete" on public.community_post_likes for delete
  using (exists (select 1 from public.pets where id = pet_id and owner_id = auth.uid()));

-- realtime
alter publication supabase_realtime add table public.community_posts;
