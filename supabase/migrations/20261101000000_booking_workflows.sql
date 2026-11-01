-- Berberim workflow RPCs and appointment write hardening.
drop policy if exists "customer books own appointment" on public.appointments;
drop policy if exists "appointment parties cancel" on public.appointments;
revoke insert, update on public.appointments from authenticated;

create policy "admin reads all businesses" on public.businesses
for select to authenticated using (
  exists (select 1 from public.profiles p where p.id = (select auth.uid()) and p.is_admin)
);
create policy "admin reads all profiles" on public.profiles
for select to authenticated using (
  id = (select auth.uid()) or
  exists (select 1 from public.profiles p where p.id = (select auth.uid()) and p.is_admin)
);
create policy "admin reads all memberships" on public.business_memberships
for select to authenticated using (
  customer_id = (select auth.uid()) or
  exists (select 1 from public.businesses b where b.id = business_id and b.owner_id = (select auth.uid())) or
  exists (select 1 from public.profiles p where p.id = (select auth.uid()) and p.is_admin)
);

create or replace function public.create_business(p_name text, p_address text default null)
returns uuid language plpgsql security invoker set search_path = ''
as $$
declare v_id uuid;
begin
  if auth.uid() is null then raise exception 'Giriş yapmalısınız'; end if;
  if length(trim(coalesce(p_name,''))) < 2 then raise exception 'İşletme adı gerekli'; end if;
  insert into public.businesses(owner_id,name,address,status)
  values(auth.uid(),trim(p_name),nullif(trim(coalesce(p_address,'')),''),'pending')
  returning id into v_id;
  return v_id;
end $$;

create or replace function public.admin_review_business(p_business_id uuid, p_decision text)
returns void language plpgsql security definer set search_path = ''
as $$
begin
  if not exists(select 1 from public.profiles where id=auth.uid() and is_admin) then
    raise exception 'Yönetici yetkisi gerekli';
  end if;
  if p_decision not in ('active','rejected','inactive') then raise exception 'Karar geçersiz'; end if;
  update public.businesses set status=p_decision where id=p_business_id;
  if not found then raise exception 'İşletme bulunamadı'; end if;
end $$;

create or replace function public.book_appointment(
  p_business_id uuid, p_employee_id uuid, p_service_id uuid, p_starts_at timestamptz, p_customer_note text default null
) returns uuid language plpgsql security invoker set search_path = ''
as $$
declare
  v_duration integer;
  v_end timestamptz;
  v_weekday integer;
  v_open time;
  v_close time;
  v_start_local timestamp;
  v_end_local timestamp;
  v_id uuid;
begin
  if auth.uid() is null then raise exception 'Giriş yapmalısınız'; end if;
  if p_starts_at <= now() then raise exception 'Geçmiş bir saate randevu alınamaz'; end if;
  if not exists(select 1 from public.businesses where id=p_business_id and status='active') then raise exception 'İşletme aktif değil'; end if;
  if not exists(select 1 from public.business_memberships where business_id=p_business_id and customer_id=auth.uid()) then raise exception 'Önce işletmeye katılmalısınız'; end if;
  if not exists(select 1 from public.employees where id=p_employee_id and business_id=p_business_id and is_active) then raise exception 'Çalışan bulunamadı veya aktif değil'; end if;
  select duration_minutes into v_duration from public.services where id=p_service_id and business_id=p_business_id and is_active;
  if v_duration is null then raise exception 'Hizmet bulunamadı veya aktif değil'; end if;
  v_end := p_starts_at + make_interval(mins=>v_duration);
  v_start_local := p_starts_at at time zone 'Europe/Istanbul';
  v_end_local := v_end at time zone 'Europe/Istanbul';
  v_weekday := extract(dow from v_start_local)::integer;
  select opens_at, closes_at into v_open, v_close from public.business_hours where business_id=p_business_id and weekday=v_weekday and not is_closed;
  if v_open is null or v_start_local::time < v_open or v_end_local::time > v_close then raise exception 'Randevu çalışma saatleri dışında'; end if;
  if exists(select 1 from public.business_breaks where business_id=p_business_id and weekday=v_weekday and v_start_local::time < ends_at and v_end_local::time > starts_at) then raise exception 'Seçilen saat mola aralığına denk geliyor'; end if;
  insert into public.appointments(business_id,customer_id,employee_id,service_id,starts_at,ends_at,status,customer_note)
  values(p_business_id,auth.uid(),p_employee_id,p_service_id,p_starts_at,v_end,'confirmed',p_customer_note)
  returning id into v_id;
  return v_id;
exception when exclusion_violation then raise exception 'Bu saat dolu; lütfen başka saat seçin';
end $$;

create or replace function public.cancel_appointment(p_appointment_id uuid)
returns void language plpgsql security invoker set search_path = ''
as $$
begin
  update public.appointments a set status='cancelled'
  where a.id=p_appointment_id and a.status='confirmed'
   and (a.customer_id=auth.uid()
     or exists(select 1 from public.employees e where e.id=a.employee_id and e.user_id=auth.uid())
     or exists(select 1 from public.businesses b where b.id=a.business_id and b.owner_id=auth.uid()));
  if not found then raise exception 'Randevu bulunamadı veya iptal yetkiniz yok'; end if;
end $$;

grant execute on function public.create_business(text,text) to authenticated;
grant execute on function public.admin_review_business(uuid,text) to authenticated;
grant execute on function public.book_appointment(uuid,uuid,uuid,timestamptz,text) to authenticated;
grant execute on function public.cancel_appointment(uuid) to authenticated;
