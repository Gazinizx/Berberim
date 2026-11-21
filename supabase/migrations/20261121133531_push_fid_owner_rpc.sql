drop policy if exists "Users manage own push tokens" on public.push_tokens;

alter table public.push_tokens
  drop constraint if exists push_tokens_user_id_token_key;

alter table public.push_tokens
  add constraint push_tokens_fid_key unique (fid);

revoke all on table public.push_tokens from anon, authenticated;
grant all on table public.push_tokens to service_role;

create or replace function public.register_push_fid(
  p_fid text,
  p_platform text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
begin
  if v_user_id is null then
    raise exception 'Authentication required';
  end if;

  if p_fid is null or length(p_fid) < 10 or length(p_fid) > 256 then
    raise exception 'Invalid Firebase installation ID';
  end if;

  if p_platform not in ('android', 'ios') then
    raise exception 'Unsupported push platform';
  end if;

  insert into public.push_tokens (user_id, fid, platform, updated_at)
  values (v_user_id, p_fid, p_platform, now())
  on conflict (fid) do update
    set user_id = excluded.user_id,
        platform = excluded.platform,
        updated_at = now();
end;
$$;

create or replace function public.unregister_push_fid(p_fid text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
begin
  if v_user_id is null then
    raise exception 'Authentication required';
  end if;

  delete from public.push_tokens
  where user_id = v_user_id
    and fid = p_fid;
end;
$$;

revoke all on function public.register_push_fid(text, text)
  from public, anon;
revoke all on function public.unregister_push_fid(text)
  from public, anon;
grant execute on function public.register_push_fid(text, text)
  to authenticated;
grant execute on function public.unregister_push_fid(text)
  to authenticated;
