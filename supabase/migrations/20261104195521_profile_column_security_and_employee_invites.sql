revoke update on table public.profiles from authenticated;
grant update (full_name, phone) on table public.profiles to authenticated;

drop policy if exists "employees read own linked row" on public.employees;
create policy "employees read own linked row"
on public.employees for select to authenticated
using (user_id = (select auth.uid()));

drop function if exists public.create_employee_invite(text);

create or replace function public.create_employee_invite(p_business_id uuid, p_display_name text)
returns text
language plpgsql
security definer
set search_path to ''
as $function$
declare
  v_employee_id uuid;
  v_code text;
begin
  if auth.uid() is null then raise exception 'Giriş yapmalısınız'; end if;
  if exists(select 1 from public.profiles where id=auth.uid() and is_blocked) then
    raise exception 'Hesabınız geçici olarak kısıtlandı';
  end if;
  if length(trim(coalesce(p_display_name,''))) < 1 then raise exception 'Çalışan adı gerekli'; end if;
  if not exists(select 1 from public.businesses where id=p_business_id and owner_id=auth.uid() and status='active') then
    raise exception 'Bu aktif işletme üzerinde yetkiniz yok';
  end if;
  insert into public.employees(business_id,display_name)
  values(p_business_id,trim(p_display_name))
  returning id into v_employee_id;
  insert into public.employee_invites(employee_id)
  values(v_employee_id)
  returning invite_code into v_code;
  return v_code;
end;
$function$;

create or replace function public.claim_employee_invite(p_code text)
returns uuid
language plpgsql
security definer
set search_path to ''
as $function$
declare
  v_invite_id uuid;
  v_employee_id uuid;
begin
  if auth.uid() is null then raise exception 'Giriş yapmalısınız'; end if;
  if exists(select 1 from public.profiles where id=auth.uid() and is_blocked) then
    raise exception 'Hesabınız geçici olarak kısıtlandı';
  end if;
  select i.id,e.id into v_invite_id,v_employee_id
  from public.employee_invites i
  join public.employees e on e.id=i.employee_id
  join public.businesses b on b.id=e.business_id
  where upper(i.invite_code)=upper(trim(coalesce(p_code,'')))
    and i.claimed_at is null and i.expires_at>now()
    and e.is_active and e.user_id is null and b.status='active'
  for update of i,e;
  if v_employee_id is null then
    raise exception 'Davet kodu geçersiz, süresi dolmuş veya daha önce kullanılmış';
  end if;
  update public.employees set user_id=auth.uid()
  where id=v_employee_id and user_id is null;
  if not found then raise exception 'Davet kodu başka bir hesap tarafından kullanıldı'; end if;
  update public.employee_invites set claimed_at=now() where id=v_invite_id and claimed_at is null;
  if not found then raise exception 'Davet kodu artık kullanılamıyor'; end if;
  return v_employee_id;
end;
$function$;

revoke all on function public.create_employee_invite(uuid,text) from public, anon;
grant execute on function public.create_employee_invite(uuid,text) to authenticated;
revoke all on function public.claim_employee_invite(text) from public, anon;
grant execute on function public.claim_employee_invite(text) to authenticated;
