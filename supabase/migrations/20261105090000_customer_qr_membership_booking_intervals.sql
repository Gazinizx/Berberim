-- Customer QR membership, scoped appointment reads and configurable booking intervals.
alter table public.businesses add column appointment_interval_minutes smallint not null default 30;
alter table public.businesses add constraint businesses_appointment_interval_check check (appointment_interval_minutes in (10, 15, 20, 30, 45, 60));
create or replace function private.set_appointment_interval(p_business_id uuid, p_interval_minutes integer)
returns void language plpgsql security definer set search_path = ''
as $function$
begin
  if auth.uid() is null then raise exception 'Giriş yapmalısınız'; end if;
  if exists(select 1 from public.profiles p where p.id = auth.uid() and p.is_blocked) then
    raise exception 'Hesabınız geçici olarak kısıtlandı';
  end if;
  if p_interval_minutes not in (10, 15, 20, 30, 45, 60) then
    raise exception 'Geçersiz randevu aralığı';
  end if;
  update public.businesses
  set appointment_interval_minutes = p_interval_minutes::smallint
  where id = p_business_id and owner_id = auth.uid();
  if not found then raise exception 'Bu işletmenin ayarlarını değiştirme yetkiniz yok'; end if;
end;
$function$;
revoke all on function private.set_appointment_interval(uuid, integer) from public, anon;
grant execute on function private.set_appointment_interval(uuid, integer) to authenticated;
create or replace function public.update_appointment_interval(p_business_id uuid, p_interval_minutes integer)
returns void language sql security invoker set search_path = ''
as $function$ select private.set_appointment_interval(p_business_id, p_interval_minutes); $function$;
revoke all on function public.update_appointment_interval(uuid, integer) from public, anon;
grant execute on function public.update_appointment_interval(uuid, integer) to authenticated;

create or replace function private.leave_business(p_business_id uuid)
returns void language plpgsql security definer set search_path = ''
as $function$
begin
  if auth.uid() is null then raise exception 'Giriş yapmalısınız'; end if;
  if exists(select 1 from public.profiles p where p.id = auth.uid() and p.is_blocked) then raise exception 'Hesabınız geçici olarak kısıtlandı'; end if;
  if exists(select 1 from public.businesses b where b.id = p_business_id and b.owner_id = auth.uid()) then raise exception 'İşletme sahibi kendi işletmesinden bu işlemle ayrılamaz'; end if;
  delete from public.business_memberships m where m.business_id = p_business_id and m.customer_id = auth.uid();
  if not found then raise exception 'Bu işletmeye ait üyeliğiniz bulunamadı'; end if;
end;
$function$;
revoke all on function private.leave_business(uuid) from public, anon;
grant execute on function private.leave_business(uuid) to authenticated;
create or replace function public.leave_business(p_business_id uuid)
returns void language sql security invoker set search_path = ''
as $function$ select private.leave_business(p_business_id); $function$;
revoke all on function public.leave_business(uuid) from public, anon;
grant execute on function public.leave_business(uuid) to authenticated;

create or replace function private.get_business_appointments(p_business_id uuid, p_mine_only boolean default true)
returns table (appointment_id uuid, starts_at timestamptz, ends_at timestamptz, status text, customer_name text, service_name text, employee_name text, employee_id uuid)
language plpgsql security definer set search_path = ''
as $function$
declare v_is_owner boolean := false; v_employee_id uuid;
begin
  if auth.uid() is null then raise exception 'Giriş yapmalısınız'; end if;
  if exists(select 1 from public.profiles p where p.id = auth.uid() and p.is_blocked) then raise exception 'Hesabınız geçici olarak kısıtlandı'; end if;
  select exists(select 1 from public.businesses b where b.id = p_business_id and b.owner_id = auth.uid()) into v_is_owner;
  select e.id into v_employee_id from public.employees e
  where e.business_id = p_business_id and e.user_id = auth.uid() and e.is_active order by e.created_at limit 1;
  if not v_is_owner and v_employee_id is null then raise exception 'Bu işletmenin randevularını görme yetkiniz yok'; end if;
  if not p_mine_only and not v_is_owner then raise exception 'İşletmenin tüm randevularını yalnızca işletme sahibi görebilir'; end if;
  return query
  select a.id, a.starts_at, a.ends_at, a.status, coalesce(nullif(btrim(p.full_name), ''), 'Müşteri'), s.name, e.display_name, e.id
  from public.appointments a
  join public.profiles p on p.id = a.customer_id
  join public.services s on s.id = a.service_id
  join public.employees e on e.id = a.employee_id
  where a.business_id = p_business_id and (not p_mine_only or e.id = v_employee_id)
  order by a.starts_at asc;
end;
$function$;
revoke all on function private.get_business_appointments(uuid, boolean) from public, anon;
grant execute on function private.get_business_appointments(uuid, boolean) to authenticated;
create or replace function public.get_business_appointments(p_business_id uuid, p_mine_only boolean default true)
returns table (appointment_id uuid, starts_at timestamptz, ends_at timestamptz, status text, customer_name text, service_name text, employee_name text, employee_id uuid)
language sql security invoker set search_path = ''
as $function$ select * from private.get_business_appointments(p_business_id, p_mine_only); $function$;
revoke all on function public.get_business_appointments(uuid, boolean) from public, anon;
grant execute on function public.get_business_appointments(uuid, boolean) to authenticated;

create or replace function private.get_available_slots(p_business_id uuid, p_employee_id uuid, p_service_id uuid, p_date date)
returns table(slot_start time without time zone)
language plpgsql security definer set search_path = ''
as $function$
declare v_duration integer; v_interval integer; v_weekday integer; v_open time; v_close time; v_closed boolean; v_slot time; v_start timestamptz; v_end timestamptz;
begin
  if auth.uid() is null then raise exception 'Giriş yapmalısınız'; end if;
  if exists(select 1 from public.profiles where id = auth.uid() and is_blocked) then raise exception 'Hesabınız geçici olarak kısıtlandı'; end if;
  if p_date < (now() at time zone 'Europe/Istanbul')::date or p_date > (now() at time zone 'Europe/Istanbul')::date + 90 then raise exception 'Randevu tarihi önümüzdeki 90 gün içinde olmalı'; end if;
  if not exists (select 1 from public.businesses b join public.business_memberships m on m.business_id = b.id where b.id = p_business_id and b.status = 'active' and m.customer_id = auth.uid()) then raise exception 'Önce aktif işletmeye katılmalısınız'; end if;
  if not exists(select 1 from public.employees where id = p_employee_id and business_id = p_business_id and is_active) then raise exception 'Çalışan bulunamadı veya aktif değil'; end if;
  select s.duration_minutes into v_duration from public.services s where s.id = p_service_id and s.business_id = p_business_id and s.is_active;
  if v_duration is null or v_duration < 1 then raise exception 'Hizmet bulunamadı veya aktif değil'; end if;
  select b.appointment_interval_minutes into v_interval from public.businesses b where b.id = p_business_id and b.status = 'active';
  v_interval := coalesce(v_interval, 30);
  v_weekday := extract(dow from p_date)::integer;
  select h.opens_at, h.closes_at, h.is_closed into v_open, v_close, v_closed from public.business_hours h where h.business_id = p_business_id and h.weekday = v_weekday;
  if not found or v_closed or v_open is null or v_close is null or v_open >= v_close then return; end if;
  for v_slot in select gs::time from generate_series(p_date + v_open, p_date + v_close - make_interval(mins => v_duration), make_interval(mins => v_interval)) as gs
  loop
    v_start := (p_date + v_slot) at time zone 'Europe/Istanbul';
    v_end := v_start + make_interval(mins => v_duration);
    if v_start > now()
      and not exists(select 1 from public.business_breaks bb where bb.business_id = p_business_id and bb.weekday = v_weekday and v_slot < bb.ends_at and (v_slot + make_interval(mins => v_duration)) > bb.starts_at)
      and not exists(select 1 from public.appointments a where a.employee_id = p_employee_id and a.status in ('pending', 'confirmed') and a.starts_at < v_end and a.ends_at > v_start)
    then slot_start := v_slot; return next; end if;
  end loop;
end;
$function$;
revoke all on function private.get_available_slots(uuid, uuid, uuid, date) from public, anon;
grant execute on function private.get_available_slots(uuid, uuid, uuid, date) to authenticated;

create or replace function private.book_appointment(p_business_id uuid, p_employee_id uuid, p_service_id uuid, p_starts_at timestamptz, p_customer_note text default null)
returns uuid language plpgsql security definer set search_path = ''
as $function$
declare v_duration integer; v_interval integer; v_end timestamptz; v_weekday integer; v_open time; v_close time; v_start_local timestamp; v_end_local timestamp; v_id uuid;
begin
  if auth.uid() is null then raise exception 'Giriş yapmalısınız'; end if;
  if p_starts_at <= now() then raise exception 'Geçmiş bir saate randevu alınamaz'; end if;
  if exists(select 1 from public.profiles where id = auth.uid() and is_blocked) then raise exception 'Hesabınız geçici olarak kısıtlandı'; end if;
  if not exists(select 1 from public.businesses where id = p_business_id and status = 'active') then raise exception 'İşletme aktif değil'; end if;
  if not exists(select 1 from public.business_memberships where business_id = p_business_id and customer_id = auth.uid()) then raise exception 'Önce işletmeye katılmalısınız'; end if;
  if not exists(select 1 from public.employees where id = p_employee_id and business_id = p_business_id and is_active) then raise exception 'Çalışan bulunamadı veya aktif değil'; end if;
  select duration_minutes into v_duration from public.services where id = p_service_id and business_id = p_business_id and is_active;
  if v_duration is null then raise exception 'Hizmet bulunamadı veya aktif değil'; end if;
  select appointment_interval_minutes into v_interval from public.businesses where id = p_business_id;
  v_interval := coalesce(v_interval, 30);
  v_end := p_starts_at + make_interval(mins => v_duration);
  v_start_local := p_starts_at at time zone 'Europe/Istanbul';
  v_end_local := v_end at time zone 'Europe/Istanbul';
  v_weekday := extract(dow from v_start_local)::integer;
  select opens_at, closes_at into v_open, v_close from public.business_hours where business_id = p_business_id and weekday = v_weekday and not is_closed;
  if v_open is null or v_close is null or v_start_local::time < v_open or v_end_local::time > v_close then raise exception 'Randevu çalışma saatleri dışında'; end if;
  if mod(extract(epoch from (v_start_local::time - v_open))::integer, v_interval * 60) <> 0 then raise exception 'Seçilen saat işletmenin belirlediği randevu aralığına uygun değil'; end if;
  if exists(select 1 from public.business_breaks where business_id = p_business_id and weekday = v_weekday and v_start_local::time < ends_at and v_end_local::time > starts_at) then raise exception 'Seçilen saat mola aralığına denk geliyor'; end if;
  insert into public.appointments(business_id, customer_id, employee_id, service_id, starts_at, ends_at, status, customer_note)
  values (p_business_id, auth.uid(), p_employee_id, p_service_id, p_starts_at, v_end, 'confirmed', p_customer_note)
  returning id into v_id;
  return v_id;
exception when exclusion_violation then raise exception 'Bu saat dolu; lütfen başka saat seçin';
end;
$function$;
revoke all on function private.book_appointment(uuid, uuid, uuid, timestamptz, text) from public, anon;
grant execute on function private.book_appointment(uuid, uuid, uuid, timestamptz, text) to authenticated;
