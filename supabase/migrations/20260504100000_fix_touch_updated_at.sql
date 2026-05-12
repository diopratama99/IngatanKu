-- Fix runtime trigger error:
-- PostgrestException: record "new" has no field "updated_at" (42703)
--
-- Root cause in existing projects:
-- table was created earlier without `updated_at`, while trigger function
-- `public.touch_updated_at()` still attempts to set NEW.updated_at.

-- 1) Ensure content_vault has the updated_at column.
alter table if exists public.content_vault
  add column if not exists updated_at timestamptz not null default now();

-- 2) Make trigger function defensive so it won't crash if accidentally
-- attached to a table that doesn't have updated_at.
create or replace function public.touch_updated_at()
returns trigger
language plpgsql
as $$
begin
  if to_jsonb(new) ? 'updated_at' then
    new.updated_at = now();
  end if;
  return new;
end;
$$;

-- 3) Recreate trigger on content_vault.
drop trigger if exists touch_content_vault on public.content_vault;
create trigger touch_content_vault
before update on public.content_vault
for each row execute function public.touch_updated_at();
