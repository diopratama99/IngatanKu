-- ============================================================
-- INGATANKU :: Initial Schema
-- ============================================================

-- 1. EXTENSIONS ----------------------------------------------
create extension if not exists "uuid-ossp";
create extension if not exists "vector";          -- pgvector
create extension if not exists "pg_trgm";

-- 2. PROFILES ------------------------------------------------
create table if not exists public.profiles (
  id           uuid primary key references auth.users(id) on delete cascade,
  username     text unique not null,
  avatar_url   text,
  level        int  not null default 1,
  xp           int  not null default 0,
  streak_days  int  not null default 0,
  last_active  date not null default current_date,
  created_at   timestamptz not null default now()
);

-- Auto-create profile on signup (defensive: unique-safe)
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer as $$
declare
  uname text;
begin
  uname := coalesce(new.raw_user_meta_data->>'username',
                    split_part(new.email,'@',1));
  -- Ensure uniqueness by suffixing if needed
  while exists (select 1 from public.profiles where username = uname) loop
    uname := uname || floor(random() * 1000)::text;
  end loop;
  insert into public.profiles (id, username) values (new.id, uname);
  return new;
end; $$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- 3. CONTENT VAULT ------------------------------------------
create table if not exists public.content_vault (
  id            uuid primary key default uuid_generate_v4(),
  user_id       uuid not null references public.profiles(id) on delete cascade,
  url           text not null,
  source_type   text check (source_type in ('youtube','tiktok','instagram','x','article','other')) default 'other',
  title         text,
  manual_notes  text not null,
  tags          text[] not null default '{}',
  embedding     vector(1536),
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

create index if not exists content_vault_embedding_idx
  on public.content_vault
  using hnsw (embedding vector_cosine_ops)
  with (m = 16, ef_construction = 64);

create index if not exists content_vault_user_idx
  on public.content_vault(user_id, created_at desc);

create index if not exists content_vault_tags_idx
  on public.content_vault using gin(tags);

-- updated_at auto-update
create or replace function public.touch_updated_at()
returns trigger language plpgsql as $$
begin new.updated_at = now(); return new; end; $$;

drop trigger if exists touch_content_vault on public.content_vault;
create trigger touch_content_vault before update on public.content_vault
  for each row execute function public.touch_updated_at();

-- 4. BADGES + USER_BADGES -----------------------------------
create table if not exists public.badges (
  id          uuid primary key default uuid_generate_v4(),
  code        text unique not null,
  name        text not null,
  description text not null,
  icon_url    text,
  rarity      text check (rarity in ('common','rare','epic','legendary')) default 'common',
  xp_reward   int  not null default 50,
  criteria    jsonb not null
);

create table if not exists public.user_badges (
  user_id     uuid references public.profiles(id) on delete cascade,
  badge_id    uuid references public.badges(id)   on delete cascade,
  unlocked_at timestamptz not null default now(),
  primary key (user_id, badge_id)
);

-- 5. CHAT MESSAGES ------------------------------------------
create table if not exists public.chat_messages (
  id          uuid primary key default uuid_generate_v4(),
  user_id     uuid not null references public.profiles(id) on delete cascade,
  session_id  uuid not null,
  role        text check (role in ('user','assistant')) not null,
  content     text not null,
  sources     jsonb,
  created_at  timestamptz not null default now()
);
create index if not exists chat_session_idx
  on public.chat_messages(user_id, session_id, created_at);

-- 6. RAG MATCH FUNCTION -------------------------------------
create or replace function public.match_notes(
  query_embedding vector(1536),
  match_user_id   uuid,
  match_threshold float default 0.7,
  match_count     int   default 5
) returns table (
  id            uuid,
  url           text,
  title         text,
  manual_notes  text,
  tags          text[],
  similarity    float
) language sql stable as $$
  select id, url, title, manual_notes, tags,
         1 - (embedding <=> query_embedding) as similarity
  from public.content_vault
  where user_id = match_user_id
    and embedding is not null
    and 1 - (embedding <=> query_embedding) > match_threshold
  order by embedding <=> query_embedding
  limit match_count;
$$;

-- 7. XP / LEVEL / STREAK TRIGGER ----------------------------
create or replace function public.award_xp_on_note()
returns trigger language plpgsql as $$
declare
  cur_streak int;
  cur_last   date;
begin
  select streak_days, last_active into cur_streak, cur_last
  from public.profiles where id = new.user_id;

  update public.profiles
  set xp          = xp + 10,
      level       = greatest(1, 1 + floor((xp + 10) / 100)),
      streak_days = case
                      when cur_last = current_date - 1 then coalesce(cur_streak,0) + 1
                      when cur_last = current_date     then coalesce(cur_streak,1)
                      else 1 end,
      last_active = current_date
  where id = new.user_id;
  return new;
end; $$;

drop trigger if exists on_note_inserted on public.content_vault;
create trigger on_note_inserted
  after insert on public.content_vault
  for each row execute function public.award_xp_on_note();

-- 8. BADGE EVALUATION ---------------------------------------
-- Re-evaluates all badges for a given user. Safe to call from
-- triggers and from a daily cron via Edge Functions.
create or replace function public.evaluate_badges(target_user uuid)
returns int language plpgsql security definer as $$
declare
  granted int := 0;
  v_id uuid;
  v_count int;
  v_streak int;
  v_tag_distinct int;
  v_chat_user_count int;
  v_midnight_days int;
  v_framework text;
  v_framework_count int;
begin
  -- BUG_HUNTER: 5 notes tagged 'debugging'
  select count(*) into v_count from public.content_vault
   where user_id = target_user and 'debugging' = any(tags);
  if v_count >= 5 then
    insert into public.user_badges (user_id, badge_id)
    select target_user, id from public.badges where code = 'BUG_HUNTER'
    on conflict do nothing;
    if found then granted := granted + 1; end if;
  end if;

  -- FRAMEWORK_MASTER: 10 notes about ANY single framework
  select tag, count(*) c into v_framework, v_framework_count
  from (
    select unnest(tags) as tag from public.content_vault where user_id = target_user
  ) t
  where tag in ('flutter','react','vue','svelte','nextjs','angular','django','rails','laravel','spring','express','fastapi')
  group by tag
  order by count(*) desc
  limit 1;
  if coalesce(v_framework_count,0) >= 10 then
    insert into public.user_badges (user_id, badge_id)
    select target_user, id from public.badges where code = 'FRAMEWORK_MASTER'
    on conflict do nothing;
    if found then granted := granted + 1; end if;
  end if;

  -- CONSISTENCY_KING: streak >= 7
  select streak_days into v_streak from public.profiles where id = target_user;
  if coalesce(v_streak,0) >= 7 then
    insert into public.user_badges (user_id, badge_id)
    select target_user, id from public.badges where code = 'CONSISTENCY_KING'
    on conflict do nothing;
    if found then granted := granted + 1; end if;
  end if;

  -- MIDNIGHT_CODER: 7 distinct days saving between 00:00–04:00 (UTC)
  select count(distinct (created_at::date)) into v_midnight_days
  from public.content_vault
  where user_id = target_user
    and extract(hour from created_at) between 0 and 3;
  if coalesce(v_midnight_days,0) >= 7 then
    insert into public.user_badges (user_id, badge_id)
    select target_user, id from public.badges where code = 'MIDNIGHT_CODER'
    on conflict do nothing;
    if found then granted := granted + 1; end if;
  end if;

  -- THE_ORACLE: 50+ user questions in chat
  select count(*) into v_chat_user_count
  from public.chat_messages where user_id = target_user and role = 'user';
  if coalesce(v_chat_user_count,0) >= 50 then
    insert into public.user_badges (user_id, badge_id)
    select target_user, id from public.badges where code = 'THE_ORACLE'
    on conflict do nothing;
    if found then granted := granted + 1; end if;
  end if;

  -- POLYGLOT: 5 different programming-language tags
  select count(distinct tag) into v_tag_distinct from (
    select unnest(tags) as tag from public.content_vault where user_id = target_user
  ) t
  where tag in ('python','dart','typescript','javascript','rust','go','golang','java','kotlin','swift','cpp','csharp','ruby','php');
  if coalesce(v_tag_distinct,0) >= 5 then
    insert into public.user_badges (user_id, badge_id)
    select target_user, id from public.badges where code = 'POLYGLOT'
    on conflict do nothing;
    if found then granted := granted + 1; end if;
  end if;

  -- KNOWLEDGE_CARTOGRAPHER: 25 distinct tags
  select count(distinct tag) into v_tag_distinct from (
    select unnest(tags) as tag from public.content_vault where user_id = target_user
  ) t;
  if coalesce(v_tag_distinct,0) >= 25 then
    insert into public.user_badges (user_id, badge_id)
    select target_user, id from public.badges where code = 'KNOWLEDGE_CARTOGRAPHER'
    on conflict do nothing;
    if found then granted := granted + 1; end if;
  end if;

  return granted;
end; $$;

-- Trigger badge evaluation after note insert
create or replace function public.evaluate_badges_after_note()
returns trigger language plpgsql as $$
begin
  perform public.evaluate_badges(new.user_id);
  return new;
end; $$;

drop trigger if exists on_note_eval_badges on public.content_vault;
create trigger on_note_eval_badges
  after insert on public.content_vault
  for each row execute function public.evaluate_badges_after_note();

-- And after each user chat message
create or replace function public.evaluate_badges_after_chat()
returns trigger language plpgsql as $$
begin
  if new.role = 'user' then perform public.evaluate_badges(new.user_id); end if;
  return new;
end; $$;

drop trigger if exists on_chat_eval_badges on public.chat_messages;
create trigger on_chat_eval_badges
  after insert on public.chat_messages
  for each row execute function public.evaluate_badges_after_chat();

-- 9. ROW LEVEL SECURITY -------------------------------------
alter table public.profiles      enable row level security;
alter table public.content_vault enable row level security;
alter table public.user_badges   enable row level security;
alter table public.chat_messages enable row level security;
alter table public.badges        enable row level security;

drop policy if exists "own profile read"  on public.profiles;
drop policy if exists "own profile write" on public.profiles;
create policy "own profile read"  on public.profiles for select using (auth.uid() = id);
create policy "own profile write" on public.profiles for update using (auth.uid() = id);

drop policy if exists "own notes all" on public.content_vault;
create policy "own notes all" on public.content_vault for all
  using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "own badges read" on public.user_badges;
create policy "own badges read" on public.user_badges for select using (auth.uid() = user_id);

drop policy if exists "own chat all" on public.chat_messages;
create policy "own chat all" on public.chat_messages for all
  using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "badges public read" on public.badges;
create policy "badges public read" on public.badges for select using (true);
