-- Require explicit business approval after three verified no-shows at that business.
alter table public.appointments
  add column if not exists requires_business_approval boolean not null default false;

create index if not exists appointments_customer_business_no_show_idx
  on public.appointments (business_id, customer_id)
  where status = 'no_show';

create or replace function private.book_appointment(
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
  v_interval integer;
  v_end timestamptz;
  v_weekday integer;
  v_open time;
  v_close time;
  v_start_local timestamp;
  v_end_local timestamp;
  v_no_show_count integer := 0;
  v_requires_approval boolean := false;
  v_id uuid;
begin
  if auth.uid() is null then raise exception 'Giriş yapmalısınız'; end if;
  if p_starts_at <= now() then raise exception 'Geçmiş bir saate randevu alınamaz'; end if;
  if exists(select 1 from public.profiles where id = auth.uid() and is_blocked) then
    raise exception 'Hesabınız geçici olarak kısıtlandı';
  end if;
  if not exists(select 1 from public.businesses where id = p_business_id and status = 'active') then
    raise exception 'İşletme aktif değil';
  end if;
  if not exists(select 1 from public.business_memberships where business_id = p_business_id and customer_id = auth.uid()) then
    raise exception 'Önce işletmeye katılmalısınız';
  end if;
  if not exists(select 1 from public.employees where id = p_employee_id and business_id = p_business_id and is_active) then
    raise exception 'Çalışan bulunamadı veya aktif değil';
  end if;
  select duration_minutes into v_duration
  from public.services
  where id = p_service_id and business_id = p_business_id and is_active;
  if v_duration is null then raise exception 'Hizmet bulunamadı veya aktif değil'; end if;

  select appointment_interval_minutes into v_interval
  from public.businesses where id = p_business_id;
  v_interval := coalesce(v_interval, 30);

  select count(*)::integer into v_no_show_count
  from public.appointments
  where business_id = p_business_id
    and customer_id = auth.uid()
    and status = 'no_show';
  v_requires_approval := v_no_show_count >= 3;

  v_end := p_starts_at + make_interval(mins => v_duration);
  v_start_local := p_starts_at at time zone 'Europe/Istanbul';
  v_end_local := v_end at time zone 'Europe/Istanbul';
  v_weekday := extract(dow from v_start_local)::integer;

  select opens_at, closes_at into v_open, v_close
  from public.business_hours
  where business_id = p_business_id and weekday = v_weekday and not is_closed;
  if v_open is null or v_close is null or v_start_local::time < v_open or v_end_local::time > v_close then
    raise exception 'Randevu çalışma saatleri dışında';
  end if;
  if mod(extract(epoch from (v_start_local::time - v_open))::integer, v_interval * 60) <> 0 then
    raise exception 'Seçilen saat işletmenin belirlediği randevu aralığına uygun değil';
  end if;
  if exists(
    select 1 from public.business_breaks
    where business_id = p_business_id and weekday = v_weekday
      and v_start_local::time < ends_at and v_end_local::time > starts_at
  ) then
    raise exception 'Seçilen saat mola aralığına denk geliyor';
  end if;

  insert into public.appointments(
    business_id, customer_id, employee_id, service_id,
    starts_at, ends_at, status, customer_note, requires_business_approval
  )
  values (
    p_business_id, auth.uid(), p_employee_id, p_service_id,
    p_starts_at, v_end,
    case when v_requires_approval then 'pending' else 'confirmed' end,
    p_customer_note,
    v_requires_approval
  )
  returning id into v_id;

  return v_id;
exception
  when exclusion_violation then raise exception 'Bu saat dolu; lütfen başka saat seçin';
end;
$function$;

revoke all on function private.book_appointment(uuid, uuid, uuid, timestamptz, text) from public, anon;
grant execute on function private.book_appointment(uuid, uuid, uuid, timestamptz, text) to authenticated;

create or replace function private.review_appointment_request(
  p_appointment_id uuid,
  p_decision text
)
returns void
language plpgsql
security definer
set search_path = ''
as $function$
begin
  if auth.uid() is null then raise exception 'Giriş yapmalısınız'; end if;
  if p_decision not in ('approve', 'reject') then raise exception 'Geçersiz onay kararı'; end if;
  if exists(select 1 from public.profiles where id = auth.uid() and is_blocked) then
    raise exception 'Hesabınız geçici olarak kısıtlandı';
  end if;

  update public.appointments a
  set status = case when p_decision = 'approve' then 'confirmed' else 'cancelled' end,
      requires_business_approval = false
  where a.id = p_appointment_id
    and a.status = 'pending'
    and a.requires_business_approval = true
    and exists (
      select 1 from public.businesses b
      where b.id = a.business_id and b.owner_id = auth.uid()
    );

  if not found then
    raise exception 'Özel onay talebi bulunamadı veya bu işlem için işletme sahibi yetkisi gerekli';
  end if;
end;
$function$;

revoke all on function private.review_appointment_request(uuid, text) from public, anon;
grant execute on function private.review_appointment_request(uuid, text) to authenticated;

create or replace function public.review_appointment_request(
  p_appointment_id uuid,
  p_decision text
)
returns void
language sql
security invoker
set search_path = ''
as $function$
  select private.review_appointment_request(p_appointment_id, p_decision);
$function$;

revoke all on function public.review_appointment_request(uuid, text) from public, anon;
grant execute on function public.review_appointment_request(uuid, text) to authenticated;

drop function if exists public.get_business_appointments(uuid, boolean);
drop function if exists private.get_business_appointments(uuid, boolean);

create function private.get_business_appointments(
  p_business_id uuid,
  p_mine_only boolean default true
)
returns table (
  appointment_id uuid,
  starts_at timestamptz,
  ends_at timestamptz,
  status text,
  customer_name text,
  service_name text,
  employee_name text,
  employee_id uuid,
  requires_business_approval boolean
)
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_is_owner boolean := false;
  v_employee_id uuid;
begin
  if auth.uid() is null then raise exception 'Giriş yapmalısınız'; end if;
  if exists(select 1 from public.profiles p where p.id = auth.uid() and p.is_blocked) then
    raise exception 'Hesabınız geçici olarak kısıtlandı';
  end if;

  select exists(
    select 1 from public.businesses b
    where b.id = p_business_id and b.owner_id = auth.uid()
  ) into v_is_owner;

  select e.id into v_employee_id
  from public.employees e
  where e.business_id = p_business_id and e.user_id = auth.uid() and e.is_active
  order by e.created_at limit 1;

  if not v_is_owner and v_employee_id is null then
    raise exception 'Bu işletmenin randevularını görme yetkiniz yok';
  end if;
  if not p_mine_only and not v_is_owner then
    raise exception 'İşletmenin tüm randevularını yalnızca işletme sahibi görebilir';
  end if;

  return query
  select
    a.id, a.starts_at, a.ends_at, a.status,
    coalesce(nullif(btrim(p.full_name), ''), 'Müşteri'),
    s.name, e.display_name, e.id, a.requires_business_approval
  from public.appointments a
  join public.profiles p on p.id = a.customer_id
  join public.services s on s.id = a.service_id
  join public.employees e on e.id = a.employee_id
  where a.business_id = p_business_id
    and (not p_mine_only or e.id = v_employee_id)
  order by a.starts_at asc;
end;
$function$;

revoke all on function private.get_business_appointments(uuid, boolean) from public, anon;
grant execute on function private.get_business_appointments(uuid, boolean) to authenticated;

create function public.get_business_appointments(
  p_business_id uuid,
  p_mine_only boolean default true
)
returns table (
  appointment_id uuid,
  starts_at timestamptz,
  ends_at timestamptz,
  status text,
  customer_name text,
  service_name text,
  employee_name text,
  employee_id uuid,
  requires_business_approval boolean
)
language sql
security invoker
set search_path = ''
as $function$
  select * from private.get_business_appointments(p_business_id, p_mine_only);
$function$;

revoke all on function public.get_business_appointments(uuid, boolean) from public, anon;
grant execute on function public.get_business_appointments(uuid, boolean) to authenticated;


-- Send explicit notifications for the special approval path while preserving
-- the existing notification behavior for normal appointments and status changes.
create or replace function private.notify_appointment_change()
returns trigger
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_owner uuid;
  v_employee uuid;
  v_service text;
  v_when text;
begin
  select b.owner_id into v_owner
  from public.businesses b where b.id = new.business_id;

  select e.user_id into v_employee
  from public.employees e where e.id = new.employee_id;

  select s.name into v_service
  from public.services s where s.id = new.service_id;

  v_when := to_char(new.starts_at at time zone 'Europe/Istanbul', 'DD.MM.YYYY HH24:MI');

  if tg_op = 'INSERT' then
    if new.requires_business_approval then
      insert into public.notifications(user_id, appointment_id, title, body)
      values (
        new.customer_id, new.id, 'İşletme onayı bekleniyor',
        'Üç kez randevuna gelmediğin için bu talep işletmenin özel onayına gönderildi: ' || v_when
      );

      insert into public.notifications(user_id, appointment_id, title, body)
      values (
        v_owner, new.id, 'Özel randevu onayı gerekli',
        coalesce(v_service, 'Hizmet') || ' için üç kez gelmeyen müşteriden özel onay talebi: ' || v_when
      );

      if v_employee is not null and v_employee <> v_owner then
        insert into public.notifications(user_id, appointment_id, title, body)
        values (
          v_employee, new.id, 'Özel onay bekleyen randevu',
          coalesce(v_service, 'Hizmet') || ' için işletme sahibinin onayı bekleniyor: ' || v_when
        );
      end if;
    else
      insert into public.notifications(user_id, appointment_id, title, body)
      values (
        new.customer_id, new.id, 'Randevu talebin alındı',
        coalesce(v_service, 'Hizmet') || ' için randevu talebin: ' || v_when
      );

      insert into public.notifications(user_id, appointment_id, title, body)
      values (
        v_owner, new.id, 'Yeni randevu talebi',
        coalesce(v_service, 'Hizmet') || ' için randevu: ' || v_when
      );

      if v_employee is not null and v_employee <> v_owner then
        insert into public.notifications(user_id, appointment_id, title, body)
        values (
          v_employee, new.id, 'Yeni randevu talebi',
          coalesce(v_service, 'Hizmet') || ' için randevu: ' || v_when
        );
      end if;
    end if;

  elsif old.status is distinct from new.status then
    if new.status = 'confirmed' then
      insert into public.notifications(user_id, appointment_id, title, body)
      values (
        new.customer_id, new.id, 'Randevun onaylandı',
        coalesce(v_service, 'Hizmet') || ' için randevun onaylandı: ' || v_when
      );

    elsif new.status = 'cancelled' then
      insert into public.notifications(user_id, appointment_id, title, body)
      values (
        new.customer_id, new.id, 'Randevu iptal edildi',
        'Randevunuz iptal edildi: ' || v_when
      );

      if v_owner is not null and v_owner <> new.customer_id then
        insert into public.notifications(user_id, appointment_id, title, body)
        values (v_owner, new.id, 'Randevu iptal edildi', 'Bir randevu iptal edildi: ' || v_when);
      end if;

      if v_employee is not null and v_employee <> v_owner and v_employee <> new.customer_id then
        insert into public.notifications(user_id, appointment_id, title, body)
        values (v_employee, new.id, 'Randevu iptal edildi', 'Bir randevu iptal edildi: ' || v_when);
      end if;

    elsif new.status = 'completed' then
      insert into public.notifications(user_id, appointment_id, title, body)
      values (
        new.customer_id, new.id, 'Randevun tamamlandı',
        coalesce(v_service, 'Hizmet') || ' randevun tamamlandı: ' || v_when
      );
    end if;
  end if;

  return new;
end;
$function$;
