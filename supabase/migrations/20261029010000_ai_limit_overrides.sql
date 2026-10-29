-- A different daily AI allowance for particular accounts (a developer's
-- test account, say), per kind of request. Set by hand from the
-- dashboard; the app's users never see it.
create table ingatanku.ai_limit_overrides (
  user_id      uuid not null references auth.users (id) on delete cascade,
  kind         text not null check (kind in ('ask', 'summarize', 'quiz', 'embed')),
  daily_limit  int  not null check (daily_limit > 0),
  primary key (user_id, kind)
);

alter table ingatanku.ai_limit_overrides enable row level security;
-- No policies: only consume_ai_quota (security definer) reads it.
revoke all on ingatanku.ai_limit_overrides from anon, authenticated;
grant all on ingatanku.ai_limit_overrides to service_role;

-- As before, except an account's own limit in ai_limit_overrides wins
-- over [p_limit] (the edge function's AI_LIMIT_*).
create or replace function ingatanku.consume_ai_quota(p_kind text, p_limit int, p_amount int default 1)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := auth.uid();
  lim int;
  used int;
begin
  if uid is null then
    return false;
  end if;
  select o.daily_limit into lim
    from ingatanku.ai_limit_overrides o
    where o.user_id = uid and o.kind = p_kind;
  lim := coalesce(lim, p_limit);
  if p_amount < 1 or p_amount > lim then
    return false;
  end if;
  insert into ingatanku.ai_usage as u (user_id, day, kind, count)
  values (uid, current_date, p_kind, p_amount)
  on conflict (user_id, day, kind) do update
    set count = u.count + excluded.count
    where u.count + excluded.count <= lim
  returning u.count into used;
  return used is not null;
end;
$$;
