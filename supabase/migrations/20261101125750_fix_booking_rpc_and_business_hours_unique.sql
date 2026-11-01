alter table public.business_hours
  add constraint business_hours_business_weekday_key unique (business_id, weekday);

create or replace function public.book_appointment(
  p_business_id uuid,
  p_employee_id uuid,
  p_service_id uuid,
  p_starts_at timestamptz,
  p_customer_note text default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $function$
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
  select opens_at, closes_at into v_open, v_close
  from public.business_hours
  where business_id=p_business_id and weekday=v_weekday and not is_closed;
  if v_open is null or v_close is null or v_start_local::time < v_open or v_end_local::time > v_close then
    raise exception 'Randevu çalışma saatleri dışında';
  end if;
  if exists(
    select 1 from public.business_breaks
    where business_id=p_business_id and weekday=v_weekday
      and v_start_local::time < ends_at and v_end_local::time > starts_at
  ) then raise exception 'Seçilen saat mola aralığına denk geliyor'; end if;
  insert into public.appointments(
    business_id,customer_id,employee_id,service_id,starts_at,ends_at,status,customer_note
  ) values (
    p_business_id,auth.uid(),p_employee_id,p_service_id,p_starts_at,v_end,'confirmed',p_customer_note
  ) returning id into v_id;
  return v_id;
exception when exclusion_violation then
  raise exception 'Bu saat dolu; lütfen başka saat seçin';
end;
$function$;

revoke all on function public.book_appointment(uuid,uuid,uuid,timestamptz,text) from public, anon;
grant execute on function public.book_appointment(uuid,uuid,uuid,timestamptz,text) to authenticated;
