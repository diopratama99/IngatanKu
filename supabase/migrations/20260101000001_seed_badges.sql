-- Seed default badges
insert into public.badges (code, name, description, rarity, xp_reward, criteria) values
  ('BUG_HUNTER',
   'Bug Hunter',
   'Save 5 notes tagged with #debugging.',
   'rare', 50,
   '{"type":"tag_count","tag":"debugging","min":5}'::jsonb),

  ('FRAMEWORK_MASTER',
   'Framework Master',
   'Save 10 notes about a single framework.',
   'epic', 100,
   '{"type":"framework_count","min":10}'::jsonb),

  ('CONSISTENCY_KING',
   'Consistency King',
   'Save content 7 days in a row.',
   'epic', 120,
   '{"type":"streak_days","min":7}'::jsonb),

  ('MIDNIGHT_CODER',
   'Midnight Coder',
   'Save notes between 00:00 and 04:00 across 7 different days.',
   'rare', 80,
   '{"type":"midnight_days","min":7}'::jsonb),

  ('THE_ORACLE',
   'The Oracle',
   'Ask your AI brain 50 questions.',
   'epic', 150,
   '{"type":"chat_questions","min":50}'::jsonb),

  ('POLYGLOT',
   'The Polyglot',
   'Save notes covering 5 different programming languages.',
   'rare', 90,
   '{"type":"language_diversity","min":5}'::jsonb),

  ('KNOWLEDGE_CARTOGRAPHER',
   'Knowledge Cartographer',
   'Use 25 unique tags across your vault.',
   'legendary', 250,
   '{"type":"unique_tags","min":25}'::jsonb)
on conflict (code) do nothing;
