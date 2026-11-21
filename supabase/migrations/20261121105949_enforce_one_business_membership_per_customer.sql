-- Enforce one active business membership per customer at the database boundary.
-- Existing memberships were checked before applying this migration; no duplicate customers were found.
create unique index if not exists business_memberships_one_per_customer_uidx
  on public.business_memberships (customer_id);

create or replace function private.join_business_by_code(p_code text)
returns uuid
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_business_id uuid;
  v_existing_business_id uuid;
begin
  if auth.uid() is null then
    raise exception 'Giriş yapmalısınız';
  end if;

  if exists (
    select 1
    from public.profiles p
    where p.id = auth.uid() and p.is_blocked
  ) then
    raise exception 'Hesabınız geçici olarak kısıtlandı';
  end if;

  select b.id
    into v_business_id
  from public.businesses b
  where upper(b.join_code) = upper(trim(coalesce(p_code, '')))
    and b.status = 'active';

  if v_business_id is null then
    raise exception 'İşletme kodu bulunamadı veya işletme aktif değil';
  end if;

  select m.business_id
    into v_existing_business_id
  from public.business_memberships m
  where m.customer_id = auth.uid();

  if v_existing_business_id is not null
     and v_existing_business_id <> v_business_id then
    raise exception 'Aynı anda yalnızca bir işletmeye katılabilirsiniz. Önce mevcut işletmenizden ayrılın.';
  end if;

  insert into public.business_memberships (business_id, customer_id)
  values (v_business_id, auth.uid())
  on conflict (business_id, customer_id) do nothing;

  return v_business_id;
exception
  when unique_violation then
    select m.business_id
      into v_existing_business_id
    from public.business_memberships m
    where m.customer_id = auth.uid();

    if v_existing_business_id = v_business_id then
      return v_business_id;
    end if;

    raise exception 'Aynı anda yalnızca bir işletmeye katılabilirsiniz. Önce mevcut işletmenizden ayrılın.';
end;
$function$;

revoke all on function private.join_business_by_code(text) from public, anon;
grant execute on function private.join_business_by_code(text) to authenticated;
