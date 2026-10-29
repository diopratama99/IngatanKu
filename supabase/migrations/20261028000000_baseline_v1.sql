-- IngatanKu v1 — the whole database in one migration.
--
-- Replaces the migrations kept for the self-hosted server (now in
-- supabase/legacy-migrations/). Everything lives in the `ingatanku` schema:
-- after running this, add `ingatanku` to the API's exposed schemas
-- (Dashboard → Project Settings → Data API).
--
-- Access: only signed-in users (`authenticated`) get anything, and RLS keeps
-- each of them to their own rows; `anon` gets nothing. No function is
-- callable unless it's granted below. Edge functions write what users may
-- not write themselves (the quiz bank, the quizzes) with the service role.

create schema if not exists ingatanku;
create extension if not exists vector with schema extensions;

-- Functions made from here on aren't callable by everyone by default.
alter default privileges in schema ingatanku revoke execute on functions from public;

-- ── Profiles ─────────────────────────────────────────────────────

create table ingatanku.profiles (
  id          uuid primary key references auth.users (id) on delete cascade,
  username    text not null unique,
  avatar_url  text,
  created_at  timestamptz not null default now()
);

-- Every new account gets a profile. Its username comes from the sign-up
-- form, else from the email (digits added while it's taken).
create function ingatanku.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  uname text := coalesce(
    nullif(new.raw_user_meta_data ->> 'username', ''),
    nullif(split_part(coalesce(new.email, ''), '@', 1), ''),
    'user'
  );
begin
  while exists (select 1 from ingatanku.profiles where username = uname) loop
    uname := uname || floor(random() * 1000)::text;
  end loop;
  insert into ingatanku.profiles (id, username) values (new.id, uname);
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function ingatanku.handle_new_user();

-- updated_at follows every change made on the server.
create function ingatanku.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

-- ── Pustaka: saved links ─────────────────────────────────────────

create table ingatanku.content_vault (
  id             uuid primary key default gen_random_uuid(),
  user_id        uuid not null references auth.users (id) on delete cascade,
  url            text not null,
  -- The app's SourceMeta types.
  source_type    text not null default 'other' check (source_type in (
                   'youtube', 'tiktok', 'instagram', 'threads', 'facebook',
                   'x', 'article', 'other')),
  title          text,
  manual_notes   text not null,
  tags           text[] not null default '{}',
  thumbnail_url  text,
  -- Off for notes only worth keeping, not testing (no quiz questions).
  in_quiz        boolean not null default true,
  embedding      extensions.vector(1024),
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now()
);

create index content_vault_user_idx on ingatanku.content_vault (user_id, created_at desc);
create index content_vault_tags_idx on ingatanku.content_vault using gin (tags);
create index content_vault_embedding_idx on ingatanku.content_vault
  using hnsw (embedding extensions.vector_cosine_ops) with (m = 16, ef_construction = 64);

create trigger content_vault_updated_at
  before update on ingatanku.content_vault
  for each row execute function ingatanku.set_updated_at();

-- The user's notes closest to [query_embedding] (the assistant's search).
-- Runs as the caller, so RLS keeps it to their own notes.
create function ingatanku.match_notes(
  query_embedding  extensions.vector(1024),
  match_user_id    uuid,
  match_threshold  float default 0.7,
  match_count      int default 5
)
returns table (
  id            uuid,
  url           text,
  title         text,
  manual_notes  text,
  tags          text[],
  similarity    float
)
language sql
stable
set search_path = ''
as $$
  select v.id, v.url, v.title, v.manual_notes, v.tags,
         1 - (v.embedding operator(extensions.<=>) query_embedding) as similarity
  from ingatanku.content_vault v
  where v.user_id = match_user_id
    and v.embedding is not null
    and 1 - (v.embedding operator(extensions.<=>) query_embedding) > match_threshold
  order by v.embedding operator(extensions.<=>) query_embedding
  limit match_count;
$$;

-- ── Catatan: free-form notes ─────────────────────────────────────

create table ingatanku.personal_notes (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null references auth.users (id) on delete cascade,
  title        text,
  body         text not null default '',
  -- File names only: the images stay on the device that added them.
  image_files  text[] not null default '{}',
  -- [{ url, label }]
  links        jsonb not null default '[]'::jsonb,
  tags         text[] not null default '{}',
  pinned       boolean not null default false,
  -- default | red | orange | yellow | green | teal | blue | purple | pink | brown | gray
  color        text not null default 'default',
  embedding    extensions.vector(1024),
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

create index personal_notes_user_idx on ingatanku.personal_notes (user_id, pinned desc, updated_at desc);
create index personal_notes_tags_idx on ingatanku.personal_notes using gin (tags);

create trigger personal_notes_updated_at
  before update on ingatanku.personal_notes
  for each row execute function ingatanku.set_updated_at();

-- ── Assistant chat ───────────────────────────────────────────────

create table ingatanku.chat_messages (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references auth.users (id) on delete cascade,
  session_id  uuid not null,
  role        text not null check (role in ('user', 'assistant')),
  content     text not null,
  sources     jsonb,
  created_at  timestamptz not null default now()
);

create index chat_messages_session_idx on ingatanku.chat_messages (user_id, session_id, created_at);

-- ── Quizzes ──────────────────────────────────────────────────────

-- The weekly feast: one quiz per user per week (Monday).
-- questions: [{ question, options[4], correctIndex, explanation, sourceNoteId, questionHash }]
create table ingatanku.weekly_quizzes (
  id               uuid primary key default gen_random_uuid(),
  user_id          uuid not null references auth.users (id) on delete cascade,
  week_start       date not null,
  questions        jsonb not null,
  source_note_ids  uuid[] not null default '{}',
  target_count     int not null default 5,
  user_answers     jsonb,
  completed_at     timestamptz,
  score            int,
  created_at       timestamptz not null default now(),
  unique (user_id, week_start)
);

-- The daily meal: three questions a day (the user's local date).
create table ingatanku.daily_quizzes (
  id               uuid primary key default gen_random_uuid(),
  user_id          uuid not null references auth.users (id) on delete cascade,
  quiz_date        date not null,
  questions        jsonb not null,
  source_note_ids  uuid[] not null default '{}',
  user_answers     jsonb,
  completed_at     timestamptz,
  score            int,
  created_at       timestamptz not null default now(),
  unique (user_id, quiz_date)
);

-- The question bank: questions written once per note, for the daily quiz.
create table ingatanku.note_questions (
  id             uuid primary key default gen_random_uuid(),
  user_id        uuid not null references auth.users (id) on delete cascade,
  note_id        uuid not null references ingatanku.content_vault (id) on delete cascade,
  question       text not null,
  options        jsonb not null,
  correct_index  int not null check (correct_index between 0 and 3),
  explanation    text not null default '',
  -- Hash of the question and its correct option, shared with the history.
  question_hash  text not null,
  locale         text not null default 'id',
  created_at     timestamptz not null default now(),
  unique (user_id, question_hash)
);

create index note_questions_user_note_idx on ingatanku.note_questions (user_id, note_id);

-- Every question shown, how it went, and when it may come back.
create table ingatanku.quiz_question_history (
  id                    uuid primary key default gen_random_uuid(),
  user_id               uuid not null references auth.users (id) on delete cascade,
  question_hash         text not null,
  question_text         text not null,
  source_note_id        uuid references ingatanku.content_vault (id) on delete set null,
  difficulty            text not null default 'medium'
                          check (difficulty in ('easy', 'medium', 'hard', 'banned')),
  answered_correctly    boolean not null,
  time_to_answer_ms     int,
  self_rating           text check (self_rating in ('easy', 'medium', 'hard')),
  shown_at_week         date not null,
  -- The weekly quiz waits for this week; the daily quiz for this day.
  next_show_after_week  date not null,
  next_show_after       date,
  created_at            timestamptz not null default now()
);

create index quiz_history_user_week_idx on ingatanku.quiz_question_history (user_id, next_show_after_week);
create index quiz_history_user_day_idx on ingatanku.quiz_question_history (user_id, next_show_after);
create index quiz_history_user_hash_idx on ingatanku.quiz_question_history (user_id, question_hash);

-- ── Pet ──────────────────────────────────────────────────────────

-- The user's pet, kept in step by the app (PetSync). updated_at is the
-- time of the change on the device, so two devices can tell whose is newer.
create table ingatanku.pets (
  user_id          uuid primary key references auth.users (id) on delete cascade,
  name             text check (name is null or char_length(name) between 1 and 12),
  color            text,
  accessory        text,
  outfit           text,
  state            jsonb not null,
  events           jsonb not null default '[]'::jsonb,
  seen             text[] not null default '{}',
  meal_done_on     text,
  feast_done_week  text,
  updated_at       timestamptz not null default now(),
  created_at       timestamptz not null default now()
);

-- What a user owns for the pet. Written with the service role only.
create table ingatanku.pet_items (
  user_id     uuid not null references auth.users (id) on delete cascade,
  item        text not null check (item ~ '^(accessory|outfit)\.[A-Za-z]+$'),
  source      text not null default 'purchase' check (source in ('purchase', 'grant')),
  created_at  timestamptz not null default now(),
  primary key (user_id, item)
);

-- ── AI allowance ─────────────────────────────────────────────────

-- How much each user has asked of the AI today, per kind of request.
create table ingatanku.ai_usage (
  user_id  uuid not null references auth.users (id) on delete cascade,
  day      date not null default current_date,
  kind     text not null,
  count    int not null default 0,
  primary key (user_id, day, kind)
);

-- Takes [p_amount] from today's allowance of [p_kind] for the signed-in
-- user. False (and nothing taken) when it would go over [p_limit]. Edge
-- functions call it with the user's token before asking the AI.
create function ingatanku.consume_ai_quota(p_kind text, p_limit int, p_amount int default 1)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := auth.uid();
  used int;
begin
  if uid is null or p_amount < 1 or p_amount > p_limit then
    return false;
  end if;
  insert into ingatanku.ai_usage as u (user_id, day, kind, count)
  values (uid, current_date, p_kind, p_amount)
  on conflict (user_id, day, kind) do update
    set count = u.count + excluded.count
    where u.count + excluded.count <= p_limit
  returning u.count into used;
  return used is not null;
end;
$$;

-- ── Row level security ───────────────────────────────────────────

alter table ingatanku.profiles              enable row level security;
alter table ingatanku.content_vault         enable row level security;
alter table ingatanku.personal_notes        enable row level security;
alter table ingatanku.chat_messages         enable row level security;
alter table ingatanku.weekly_quizzes        enable row level security;
alter table ingatanku.daily_quizzes         enable row level security;
alter table ingatanku.note_questions        enable row level security;
alter table ingatanku.quiz_question_history enable row level security;
alter table ingatanku.pets                  enable row level security;
alter table ingatanku.pet_items             enable row level security;
alter table ingatanku.ai_usage              enable row level security;

create policy profiles_select_own on ingatanku.profiles
  for select to authenticated using ((select auth.uid()) = id);
create policy profiles_update_own on ingatanku.profiles
  for update to authenticated using ((select auth.uid()) = id) with check ((select auth.uid()) = id);

create policy content_vault_own on ingatanku.content_vault
  for all to authenticated
  using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);

create policy personal_notes_own on ingatanku.personal_notes
  for all to authenticated
  using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);

create policy chat_messages_own on ingatanku.chat_messages
  for all to authenticated
  using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);

-- Quizzes are made by edge functions; the owner reads them and writes
-- their answers.
create policy weekly_quizzes_select_own on ingatanku.weekly_quizzes
  for select to authenticated using ((select auth.uid()) = user_id);
create policy weekly_quizzes_update_own on ingatanku.weekly_quizzes
  for update to authenticated using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);

create policy daily_quizzes_select_own on ingatanku.daily_quizzes
  for select to authenticated using ((select auth.uid()) = user_id);
create policy daily_quizzes_update_own on ingatanku.daily_quizzes
  for update to authenticated using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);

create policy note_questions_select_own on ingatanku.note_questions
  for select to authenticated using ((select auth.uid()) = user_id);

-- Written by record-quiz-answer with the user's token.
create policy quiz_history_own on ingatanku.quiz_question_history
  for all to authenticated
  using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);

-- No delete: the pet goes with the account.
create policy pets_select_own on ingatanku.pets
  for select to authenticated using ((select auth.uid()) = user_id);
create policy pets_insert_own on ingatanku.pets
  for insert to authenticated with check ((select auth.uid()) = user_id);
create policy pets_update_own on ingatanku.pets
  for update to authenticated using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);

create policy pet_items_select_own on ingatanku.pet_items
  for select to authenticated using ((select auth.uid()) = user_id);

create policy ai_usage_select_own on ingatanku.ai_usage
  for select to authenticated using ((select auth.uid()) = user_id);

-- ── Grants ───────────────────────────────────────────────────────

grant usage on schema ingatanku to authenticated, service_role;

grant select, insert, update, delete on ingatanku.content_vault, ingatanku.personal_notes to authenticated;
grant select on ingatanku.profiles to authenticated;
grant update (username, avatar_url) on ingatanku.profiles to authenticated;
grant select, insert on ingatanku.chat_messages to authenticated;
grant select, update on ingatanku.weekly_quizzes, ingatanku.daily_quizzes to authenticated;
grant select, insert, update on ingatanku.quiz_question_history to authenticated;
grant select on ingatanku.note_questions, ingatanku.pet_items, ingatanku.ai_usage to authenticated;
grant select, insert, update on ingatanku.pets to authenticated;

grant all on all tables in schema ingatanku to service_role;

grant execute on function ingatanku.match_notes(extensions.vector, uuid, float, int) to authenticated, service_role;
grant execute on function ingatanku.consume_ai_quota(text, int, int) to authenticated;
