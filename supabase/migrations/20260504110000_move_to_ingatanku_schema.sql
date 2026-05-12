-- ============================================================
-- INGATANKU :: Move all objects from `public` to `ingatanku`
-- ------------------------------------------------------------
-- Goal: isolate IngatanKu objects in their own Postgres schema
-- so a single Supabase project can host multiple apps cleanly.
--
-- After running this:
--   1. In Supabase Dashboard → Project Settings → API,
--      add `ingatanku` to "Exposed schemas".
--   2. In Flutter / Edge Functions, call:
--          supabase.schema('ingatanku').from('content_vault')…
--          supabase.schema('ingatanku').rpc('match_notes', …)
--      (defaults remain `public`).
--
-- Safe to re-run: every statement uses IF EXISTS / OR REPLACE.
-- ============================================================

-- 0. Schema -----------------------------------------------------
create schema if not exists ingatanku;

-- 1. Move tables ----------------------------------------------
-- Indexes, RLS policies, and table-level triggers travel with
-- the table automatically.
alter table if exists public.profiles        set schema ingatanku;
alter table if exists public.content_vault   set schema ingatanku;
alter table if exists public.badges          set schema ingatanku;
alter table if exists public.user_badges     set schema ingatanku;
alter table if exists public.chat_messages   set schema ingatanku;
alter table if exists public.weekly_quizzes  set schema ingatanku;

-- 2. Move functions -------------------------------------------
-- Postgres' ALTER FUNCTION does NOT support `IF EXISTS`, so wrap each
-- in a DO block that ignores the function-missing case for idempotency.
do $$
declare
  fns text[] := array[
    'public.handle_new_user()',
    'public.touch_updated_at()',
    'public.match_notes(vector, uuid, float, int)',
    'public.award_xp_on_note()',
    'public.evaluate_badges(uuid)',
    'public.evaluate_badges_after_note()',
    'public.evaluate_badges_after_chat()',
    'public.toggle_share(uuid, boolean)',
    'public.award_quiz_completion(uuid, int)'
  ];
  fn text;
begin
  foreach fn in array fns loop
    begin
      execute format('alter function %s set schema ingatanku', fn);
    exception
      when undefined_function then null;  -- function never existed; fine
      when invalid_schema_name then null; -- already moved; fine
    end;
  end loop;
end $$;

-- 3. Recreate function bodies to reference ingatanku.* --------
-- Original bodies hardcoded `public.<table>` and would break
-- after the schema move.

-- 3.1 handle_new_user
create or replace function ingatanku.handle_new_user()
returns trigger language plpgsql security definer as $$
declare
  uname text;
begin
  uname := coalesce(new.raw_user_meta_data->>'username',
                    split_part(new.email,'@',1));
  while exists (select 1 from ingatanku.profiles where username = uname) loop
    uname := uname || floor(random() * 1000)::text;
  end loop;
  insert into ingatanku.profiles (id, username) values (new.id, uname);
  return new;
end; $$;

-- The trigger lives on auth.users, so it must be re-pointed.
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function ingatanku.handle_new_user();

-- 3.2 touch_updated_at (defensive)
create or replace function ingatanku.touch_updated_at()
returns trigger language plpgsql as $$
begin
  if to_jsonb(new) ? 'updated_at' then
    new.updated_at = now();
  end if;
  return new;
end; $$;

-- 3.3 match_notes (RAG)
create or replace function ingatanku.match_notes(
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
  from ingatanku.content_vault
  where user_id = match_user_id
    and embedding is not null
    and 1 - (embedding <=> query_embedding) > match_threshold
  order by embedding <=> query_embedding
  limit match_count;
$$;

-- 3.4 award_xp_on_note
create or replace function ingatanku.award_xp_on_note()
returns trigger language plpgsql as $$
declare
  cur_streak int;
  cur_last   date;
begin
  select streak_days, last_active into cur_streak, cur_last
  from ingatanku.profiles where id = new.user_id;

  update ingatanku.profiles
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

-- 3.5 evaluate_badges
create or replace function ingatanku.evaluate_badges(target_user uuid)
returns int language plpgsql security definer as $$
declare
  granted int := 0;
  v_count int;
  v_streak int;
  v_tag_distinct int;
  v_chat_user_count int;
  v_midnight_days int;
  v_framework text;
  v_framework_count int;
begin
  -- BUG_HUNTER
  select count(*) into v_count from ingatanku.content_vault
   where user_id = target_user and 'debugging' = any(tags);
  if v_count >= 5 then
    insert into ingatanku.user_badges (user_id, badge_id)
    select target_user, id from ingatanku.badges where code = 'BUG_HUNTER'
    on conflict do nothing;
    if found then granted := granted + 1; end if;
  end if;

  -- FRAMEWORK_MASTER
  select tag, count(*) c into v_framework, v_framework_count
  from (
    select unnest(tags) as tag from ingatanku.content_vault where user_id = target_user
  ) t
  where tag in ('flutter','react','vue','svelte','nextjs','angular','django','rails','laravel','spring','express','fastapi')
  group by tag
  order by count(*) desc
  limit 1;
  if coalesce(v_framework_count,0) >= 10 then
    insert into ingatanku.user_badges (user_id, badge_id)
    select target_user, id from ingatanku.badges where code = 'FRAMEWORK_MASTER'
    on conflict do nothing;
    if found then granted := granted + 1; end if;
  end if;

  -- CONSISTENCY_KING
  select streak_days into v_streak from ingatanku.profiles where id = target_user;
  if coalesce(v_streak,0) >= 7 then
    insert into ingatanku.user_badges (user_id, badge_id)
    select target_user, id from ingatanku.badges where code = 'CONSISTENCY_KING'
    on conflict do nothing;
    if found then granted := granted + 1; end if;
  end if;

  -- MIDNIGHT_CODER
  select count(distinct (created_at::date)) into v_midnight_days
  from ingatanku.content_vault
  where user_id = target_user
    and extract(hour from created_at) between 0 and 3;
  if coalesce(v_midnight_days,0) >= 7 then
    insert into ingatanku.user_badges (user_id, badge_id)
    select target_user, id from ingatanku.badges where code = 'MIDNIGHT_CODER'
    on conflict do nothing;
    if found then granted := granted + 1; end if;
  end if;

  -- THE_ORACLE
  select count(*) into v_chat_user_count
  from ingatanku.chat_messages where user_id = target_user and role = 'user';
  if coalesce(v_chat_user_count,0) >= 50 then
    insert into ingatanku.user_badges (user_id, badge_id)
    select target_user, id from ingatanku.badges where code = 'THE_ORACLE'
    on conflict do nothing;
    if found then granted := granted + 1; end if;
  end if;

  -- POLYGLOT
  select count(distinct tag) into v_tag_distinct from (
    select unnest(tags) as tag from ingatanku.content_vault where user_id = target_user
  ) t
  where tag in ('python','dart','typescript','javascript','rust','go','golang','java','kotlin','swift','cpp','csharp','ruby','php');
  if coalesce(v_tag_distinct,0) >= 5 then
    insert into ingatanku.user_badges (user_id, badge_id)
    select target_user, id from ingatanku.badges where code = 'POLYGLOT'
    on conflict do nothing;
    if found then granted := granted + 1; end if;
  end if;

  -- KNOWLEDGE_CARTOGRAPHER
  select count(distinct tag) into v_tag_distinct from (
    select unnest(tags) as tag from ingatanku.content_vault where user_id = target_user
  ) t;
  if coalesce(v_tag_distinct,0) >= 25 then
    insert into ingatanku.user_badges (user_id, badge_id)
    select target_user, id from ingatanku.badges where code = 'KNOWLEDGE_CARTOGRAPHER'
    on conflict do nothing;
    if found then granted := granted + 1; end if;
  end if;

  return granted;
end; $$;

-- 3.6 evaluate_badges_after_note
create or replace function ingatanku.evaluate_badges_after_note()
returns trigger language plpgsql as $$
begin
  perform ingatanku.evaluate_badges(new.user_id);
  return new;
end; $$;

-- 3.7 evaluate_badges_after_chat
create or replace function ingatanku.evaluate_badges_after_chat()
returns trigger language plpgsql as $$
begin
  if new.role = 'user' then perform ingatanku.evaluate_badges(new.user_id); end if;
  return new;
end; $$;

-- 3.8 toggle_share
create or replace function ingatanku.toggle_share(
  note_id uuid,
  enable  boolean default true
) returns text
language plpgsql security definer as $$
declare
  new_token text;
begin
  if not enable then
    update ingatanku.content_vault
       set share_token = null, shared_at = null
     where id = note_id and user_id = auth.uid();
    return null;
  end if;

  new_token := encode(gen_random_bytes(16), 'hex');
  update ingatanku.content_vault
     set share_token = new_token, shared_at = now()
   where id = note_id and user_id = auth.uid();
  return new_token;
end; $$;

revoke all on function ingatanku.toggle_share(uuid, boolean) from public;
grant execute on function ingatanku.toggle_share(uuid, boolean) to authenticated;

-- 3.9 award_quiz_completion
create or replace function ingatanku.award_quiz_completion(
  quiz_id    uuid,
  earned_xp  int
) returns void
language plpgsql security definer as $$
begin
  if earned_xp < 0 or earned_xp > 50 then
    earned_xp := least(greatest(earned_xp, 0), 50);
  end if;

  update ingatanku.profiles
     set xp    = xp + earned_xp,
         level = greatest(1, 1 + floor((xp + earned_xp) / 100))
   where id = auth.uid();

  insert into ingatanku.user_badges (user_id, badge_id)
  select auth.uid(), id from ingatanku.badges where code = 'WEEKLY_REVIEWER'
  on conflict do nothing;
end; $$;

revoke all on function ingatanku.award_quiz_completion(uuid, int) from public;
grant execute on function ingatanku.award_quiz_completion(uuid, int) to authenticated;

-- 4. Recreate table-level triggers that reference moved functions
-- (Triggers themselves moved with the table, but we re-`create or replace`
-- to guarantee they point at the ingatanku.* function definitions.)
drop trigger if exists touch_content_vault on ingatanku.content_vault;
create trigger touch_content_vault before update on ingatanku.content_vault
  for each row execute function ingatanku.touch_updated_at();

drop trigger if exists on_note_inserted on ingatanku.content_vault;
create trigger on_note_inserted after insert on ingatanku.content_vault
  for each row execute function ingatanku.award_xp_on_note();

drop trigger if exists on_note_eval_badges on ingatanku.content_vault;
create trigger on_note_eval_badges after insert on ingatanku.content_vault
  for each row execute function ingatanku.evaluate_badges_after_note();

drop trigger if exists on_chat_eval_badges on ingatanku.chat_messages;
create trigger on_chat_eval_badges after insert on ingatanku.chat_messages
  for each row execute function ingatanku.evaluate_badges_after_chat();

-- 5. Permissions for PostgREST -------------------------------
-- Allow API roles to see the new schema. Without this, even after
-- exposing the schema in the dashboard, requests will fail.
grant usage on schema ingatanku to anon, authenticated, service_role;
grant all on all tables    in schema ingatanku to anon, authenticated, service_role;
grant all on all sequences in schema ingatanku to anon, authenticated, service_role;
grant all on all functions in schema ingatanku to anon, authenticated, service_role;

alter default privileges in schema ingatanku
  grant all on tables to anon, authenticated, service_role;
alter default privileges in schema ingatanku
  grant all on sequences to anon, authenticated, service_role;
alter default privileges in schema ingatanku
  grant all on functions to anon, authenticated, service_role;
