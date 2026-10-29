-- People who asked to try the Android beta, from the landing page
-- (landing/). Written only by the `beta-signup` edge function with the
-- service role; read from the dashboard when sending invites.
create table ingatanku.beta_signups (
  id          uuid primary key default gen_random_uuid(),
  -- Stored lower-case, so one address signs up once.
  email       text not null unique
              check (char_length(email) between 3 and 254 and email = lower(email)),
  name        text check (name is null or char_length(name) <= 60),
  locale      text check (locale in ('en', 'id')),
  -- A hash of the sender's IP (never the IP), to slow down floods.
  ip_hash     text,
  created_at  timestamptz not null default now(),
  -- Set by hand once they're added to the Play Store closed test.
  invited_at  timestamptz
);

create index beta_signups_ip_idx on ingatanku.beta_signups (ip_hash, created_at);

alter table ingatanku.beta_signups enable row level security;
-- No policies: the app's users never see it.
revoke all on ingatanku.beta_signups from anon, authenticated;
grant all on ingatanku.beta_signups to service_role;
