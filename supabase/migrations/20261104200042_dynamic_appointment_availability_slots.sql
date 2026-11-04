create or replace function public.get_available_slots(
  p_business_id uuid,
  p_employee_id uuid,
  p_service_id uuid,
  p_date date
)
returns table(slot_start time without time zone)
language plpgsql
security definer
set search_path to ''
as $function$
declare
  v_duration integer;
  v_weekday integer;
  v_open time;
  v_close time;
  v_closed boolean;
  v_slot time;
  v_start timestamptz;
  v_end timestamptz;
begin
  if auth.uid() is null then raise exception 'Giriş yapmalısınız'; end if;
  if exists(select 1 from public.profiles where id=auth.uid() and is_blocked) then
    raise exception 'Hesabınız geçici olarak kısıtlandı';
  end if;
  if p_date < (now() at time zone 'Europe/Istanbul')::date
     or p_date > (now() at time zone 'Europe/Istanbul')::date + 90 then
    raise exception 'Randevu tarihi önümüzdeki 90 gün içinde olmalı';
  end if;
  if not exists(
    select 1 from public.businesses b
    join public.business_memberships m on m.business_id=b.id
    where b.id=p_business_id and b.status='active' and m.customer_id=auth.uid()
  ) then
    raise exception 'Önce aktif işletmeye katılmalısınız';
  end if;
  if not exists(select 1 from public.employees where id=p_employee_id and business_id=p_business_id and is_active) then
    raise exception 'Çalışan bulunamadı veya aktif değil';
  end if;
  select s.duration_minutes into v_duration
  from public.services s
  where s.id=p_service_id and s.business_id=p_business_id and s.is_active;
  if v_duration is null or v_duration < 1 then
    raise exception 'Hizmet bulunamadı veya aktif değil';
  end if;
  v_weekday := extract(dow from p_date)::integer;
  select h.opens_at,h.closes_at,h.is_closed
    into v_open,v_close,v_closed
  from public.business_hours h
  where h.business_id=p_business_id and h.weekday=v_weekday;
  if not found or v_closed or v_open is null or v_close is null or v_open >= v_close then
    return;
  end if;
  for v_slot in
    select gs::time
    from generate_series(
      p_date + v_open,
      p_date + v_close - make_interval(mins=>v_duration),
      interval '30 minutes'
    ) as gs
  loop
    v_start := (p_date + v_slot) at time zone 'Europe/Istanbul';
    v_end := v_start + make_interval(mins=>v_duration);
    if v_start > now()
      and not exists(
        select 1 from public.business_breaks bb
        where bb.business_id=p_business_id
          and bb.weekday=v_weekday
          and v_slot < bb.ends_at
          and (v_slot + make_interval(mins=>v_duration)) > bb.starts_at
      )
      and not exists(
        select 1 from public.appointments a
        where a.employee_id=p_employee_id
          and a.status in ('pending','confirmed')
          and a.starts_at < v_end
          and a.ends_at > v_start
      )
    then
      slot_start := v_slot;
      return next;
    end if;
  end loop;
end;
$function$;

revoke all on function public.get_available_slots(uuid,uuid,uuid,date) from public, anon;
grant execute on function public.get_available_slots(uuid,uuid,uuid,date) to authenticated;
