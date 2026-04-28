-- Weekly quizzes — multiple-choice review of the user's notes from the
-- last 7 days. Generated on demand by the `generate-weekly-quiz` edge
-- function (no pg_cron required) and answered through the Flutter app.
--
-- A "week" is anchored on Monday so a single user owns at most one quiz
-- per week. The `week_start` is stored as a `date` (no time component) so
-- the unique constraint behaves predictably regardless of TZ drift.
--
-- `questions` shape (jsonb):
--   [
--     {
--       "question": "…",
--       "options": ["A","B","C","D"],
--       "correctIndex": 2,
--       "explanation": "Why this answer is correct.",
--       "sourceNoteId": "uuid-or-null"
--     },
--     …  (5 entries)
--   ]
--
-- `user_answers` shape (jsonb): array of {selectedIndex, correct} matching
-- `questions` order. Set when the user submits.

create table if not exists public.weekly_quizzes (
  id              uuid        primary key default gen_random_uuid(),
  user_id         uuid        not null references auth.users on delete cascade,
  week_start      date        not null,
  questions       jsonb       not null,
  source_note_ids uuid[]      not null default '{}',
  created_at      timestamptz not null default now(),
  user_answers    jsonb,
  completed_at    timestamptz,
  score           int,
  unique(user_id, week_start)
);

create index if not exists weekly_quizzes_user_week_idx
  on public.weekly_quizzes(user_id, week_start desc);

alter table public.weekly_quizzes enable row level security;

-- Users see and update only their own quizzes; INSERTs come from the edge
-- function via the service role, so no insert/delete policies for them.
drop policy if exists "weekly_quizzes_select_own" on public.weekly_quizzes;
create policy "weekly_quizzes_select_own"
  on public.weekly_quizzes for select
  using (auth.uid() = user_id);

drop policy if exists "weekly_quizzes_update_own" on public.weekly_quizzes;
create policy "weekly_quizzes_update_own"
  on public.weekly_quizzes for update
  using (auth.uid() = user_id);

-- Seed the WEEKLY_REVIEWER badge so the gamification bloc can light it up
-- when the user finishes their first weekly quiz.
insert into public.badges (code, name, description, rarity, xp_reward, criteria)
values (
  'WEEKLY_REVIEWER',
  'Weekly Reviewer',
  'Selesaikan quiz mingguan pertamamu.',
  'rare', 60,
  '{"type":"weekly_quiz_completed","min":1}'::jsonb
)
on conflict (code) do nothing;

-- RPC: atomically award XP for a completed quiz and unlock the
-- WEEKLY_REVIEWER badge (idempotent — `on conflict do nothing` handles
-- repeated calls within the same week).
--
-- Caller pattern (Flutter):
--   await supabase.rpc('award_quiz_completion', params: {
--     'quiz_id': quizId,
--     'earned_xp': earnedXp,
--   });
create or replace function public.award_quiz_completion(
  quiz_id    uuid,
  earned_xp  int
) returns void
language plpgsql security definer as $$
begin
  -- Defensively cap to keep someone abusing the RPC from blowing up XP.
  if earned_xp < 0 or earned_xp > 50 then
    earned_xp := least(greatest(earned_xp, 0), 50);
  end if;

  -- Increment XP + recalc level using the same formula the note trigger uses.
  update public.profiles
     set xp    = xp + earned_xp,
         level = greatest(1, 1 + floor((xp + earned_xp) / 100))
   where id = auth.uid();

  -- Award WEEKLY_REVIEWER (one-time). This also gives the badge XP via the
  -- normal evaluation flow on the next dashboard refresh.
  insert into public.user_badges (user_id, badge_id)
  select auth.uid(), id from public.badges where code = 'WEEKLY_REVIEWER'
  on conflict do nothing;
end; $$;

revoke all on function public.award_quiz_completion(uuid, int) from public;
grant execute on function public.award_quiz_completion(uuid, int) to authenticated;
