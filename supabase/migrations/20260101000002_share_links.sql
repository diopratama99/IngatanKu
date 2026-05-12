-- Adds optional public sharing via opaque tokens.
-- A note becomes shareable when share_token is set; anyone with the link can read it.

alter table public.content_vault
  add column if not exists share_token text unique,
  add column if not exists shared_at   timestamptz;

create index if not exists content_vault_share_token_idx
  on public.content_vault(share_token)
  where share_token is not null;

-- Public read policy: anyone (anon role) can read rows where a share_token is set.
-- Note: this OR'd with the existing "own notes all" policy that requires auth.uid() = user_id.
drop policy if exists "shared notes public read" on public.content_vault;
create policy "shared notes public read"
  on public.content_vault for select
  using (share_token is not null);

-- RPC: toggle / refresh a share link, returning the token.
create or replace function public.toggle_share(
  note_id uuid,
  enable  boolean default true
) returns text
language plpgsql security definer as $$
declare
  new_token text;
begin
  if not enable then
    update public.content_vault
       set share_token = null, shared_at = null
     where id = note_id and user_id = auth.uid();
    return null;
  end if;

  new_token := encode(gen_random_bytes(16), 'hex');
  update public.content_vault
     set share_token = new_token, shared_at = now()
   where id = note_id and user_id = auth.uid();
  return new_token;
end; $$;

revoke all on function public.toggle_share(uuid, boolean) from public;
grant execute on function public.toggle_share(uuid, boolean) to authenticated;
