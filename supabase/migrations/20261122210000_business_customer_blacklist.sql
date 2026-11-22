-- Business-scoped customer blacklist with verified no-show tracking.
-- A customer's history at one business never affects another business.

create table if not exists public.business_customer_controls (
  business_id uuid not null references public.businesses(id) on delete cascade,
  customer_id uuid not null references public.profiles(id) on delete cascade,
  no_show_count integer not null default 0 check (no_show_count >= 0),
  is_blacklisted boolean not null default false,
  blacklist_reason text check (blacklist_reason in ('automatic', 'manual')),
  blacklisted_at timestamptz,
  updated_at timestamptz not null default now(),
  primary key (business_id, customer_id)
);

create index if not exists business_customer_controls_blacklist_idx
  on public.business_customer_controls (business_id, is_blacklisted, updated_at desc);

alter table public.business_customer_controls enable row level security;

drop policy if exists "business owners read their customer controls" on public.business_customer_controls;
create policy "business owners read their customer controls"
  on public.business_customer_controls
  for select to authenticated
  using (
    exists (
      select 1 from public.businesses b
      where b.id = business_customer_controls.business_id
        and b.owner_id = (select auth.uid())
    )
  );

grant select on public.business_customer_controls to authenticated;
revoke insert, update, delete on public.business_customer_controls from anon, authenticated;

-- Backfill the existing verified no-show history once, preserving business scope.
insert into public.business_customer_controls (
  business_id, customer_id, no_show_count, is_blacklisted,
  blacklist_reason, blacklisted_at, updated_at
)
select
  a.business_id,
  a.customer_id,
  count(*)::integer,
  count(*) >= 3,
  case when count(*) >= 3 then 'automatic' else null end,
  case when count(*) >= 3 then now() else null end,
  now()
from public.appointments a
where a.status = 'no_show'
group by a.business_id, a.customer_id
on conflict (business_id, customer_id) do update
set no_show_count = greatest(
      public.business_customer_controls.no_show_count,
      excluded.no_show_count
    ),
    is_blacklisted = public.business_customer_controls.is_blacklisted or excluded.is_blacklisted,
    blacklist_reason = case
      when public.business_customer_controls.is_blacklisted
        then public.business_customer_controls.blacklist_reason
      else excluded.blacklist_reason
    end,
    blacklisted_at = coalesce(
      public.business_customer_controls.blacklisted_at,
      excluded.blacklisted_at
    ),
    updated_at = now();

create or replace function private.track_customer_no_show()
returns trigger
language plpgsql
security definer
set search_path = ''
as $function$
begin
  if old.status is distinct from new.status and new.status = 'no_show' then
    insert into public.business_customer_controls (
      business_id, customer_id, no_show_count, is_blacklisted,
      blacklist_reason, blacklisted_at, updated_at
    )
    values (
      new.business_id, new.customer_id, 1, false, null, null, now()
    )
    on conflict (business_id, customer_id) do update
    set no_show_count = public.business_customer_controls.no_show_count + 1,
        is_blacklisted = public.business_customer_controls.is_blacklisted
          or public.business_customer_controls.no_show_count + 1 >= 3,
        blacklist_reason = case
          when public.business_customer_controls.is_blacklisted
            then public.business_customer_controls.blacklist_reason
          when public.business_customer_controls.no_show_count + 1 >= 3
            then 'automatic'
          else null
        end,
        blacklisted_at = case
          when public.business_customer_controls.is_blacklisted
            then public.business_customer_controls.blacklisted_at
          when public.business_customer_controls.no_show_count + 1 >= 3
            then now()
          else null
        end,
        updated_at = now();
  end if;

  return new;
end;
$function$;

drop trigger if exists appointments_track_customer_no_show on public.appointments;
create trigger appointments_track_customer_no_show
  after update of status on public.appointments
  for each row
  when (old.status is distinct from new.status and new.status = 'no_show')
  execute function private.track_customer_no_show();

-- Only the business owner can read the customer list and mutate blacklist state.
create or replace function private.get_business_customers(p_business_id uuid)
returns table (
  customer_id uuid,
  full_name text,
  phone text,
  joined_at timestamptz,
  no_show_count integer,
  is_blacklisted boolean,
  blacklist_reason text,
  last_appointment_at timestamptz,
  appointment_count bigint
)
language plpgsql
stable
security definer
set search_path = ''
as $function$
begin
  if auth.uid() is null then raise exception 'Giriş yapmalısınız'; end if;
  if exists (
    select 1 from public.profiles p
    where p.id = auth.uid() and p.is_blocked
  ) then raise exception 'Hesabınız geçici olarak kısıtlandı'; end if;
  if not exists (
    select 1 from public.businesses b
    where b.id = p_business_id and b.owner_id = auth.uid()
  ) then raise exception 'Müşteri listesini yalnızca işletme sahibi görebilir'; end if;

  return query
  with customer_source as (
    select m.customer_id, m.created_at as joined_at
    from public.business_memberships m
    where m.business_id = p_business_id
    union all
    select a.customer_id, null::timestamptz
    from public.appointments a
    where a.business_id = p_business_id
  ),
  customer_list as (
    select cs.customer_id, min(cs.joined_at) as joined_at
    from customer_source cs
    group by cs.customer_id
  )
  select
    cl.customer_id,
    coalesce(nullif(btrim(p.full_name), ''), 'Müşteri'),
    p.phone,
    cl.joined_at,
    coalesce(ctrl.no_show_count, 0),
    coalesce(ctrl.is_blacklisted, false),
    ctrl.blacklist_reason,
    stats.last_appointment_at,
    coalesce(stats.appointment_count, 0)
  from customer_list cl
  join public.profiles p on p.id = cl.customer_id
  left join public.business_customer_controls ctrl
    on ctrl.business_id = p_business_id and ctrl.customer_id = cl.customer_id
  left join lateral (
    select max(a.starts_at) as last_appointment_at, count(*)::bigint as appointment_count
    from public.appointments a
    where a.business_id = p_business_id and a.customer_id = cl.customer_id
  ) stats on true
  order by coalesce(ctrl.is_blacklisted, false) desc,
           stats.last_appointment_at desc nulls last,
           p.full_name asc;
end;
$function$;

revoke all on function private.get_business_customers(uuid) from public, anon;
grant execute on function private.get_business_customers(uuid) to authenticated;

create or replace function public.get_business_customers(p_business_id uuid)
returns table (
  customer_id uuid,
  full_name text,
  phone text,
  joined_at timestamptz,
  no_show_count integer,
  is_blacklisted boolean,
  blacklist_reason text,
  last_appointment_at timestamptz,
  appointment_count bigint
)
language sql
security invoker
set search_path = ''
as $function$
  select * from private.get_business_customers(p_business_id);
$function$;

revoke all on function public.get_business_customers(uuid) from public, anon;
grant execute on function public.get_business_customers(uuid) to authenticated;

create or replace function private.set_business_customer_blacklist(
  p_business_id uuid,
  p_customer_id uuid,
  p_blacklisted boolean
)
returns void
language plpgsql
security definer
set search_path = ''
as $function$
begin
  if auth.uid() is null then raise exception 'Giriş yapmalısınız'; end if;
  if p_blacklisted is null then raise exception 'Kara liste işlemi geçersiz'; end if;
  if exists (
    select 1 from public.profiles p
    where p.id = auth.uid() and p.is_blocked
  ) then raise exception 'Hesabınız geçici olarak kısıtlandı'; end if;
  if not exists (
    select 1 from public.businesses b
    where b.id = p_business_id and b.owner_id = auth.uid()
  ) then raise exception 'Bu işlem için işletme sahibi yetkisi gerekli'; end if;
  if not exists (
    select 1 from public.business_memberships m
    where m.business_id = p_business_id and m.customer_id = p_customer_id
    union all
    select 1 from public.appointments a
    where a.business_id = p_business_id and a.customer_id = p_customer_id
  ) then raise exception 'Müşteri bu işletmenin müşteri kayıtlarında bulunamadı'; end if;

  if p_blacklisted then
    insert into public.business_customer_controls (
      business_id, customer_id, no_show_count, is_blacklisted,
      blacklist_reason, blacklisted_at, updated_at
    )
    values (
      p_business_id, p_customer_id, 0, true, 'manual', now(), now()
    )
    on conflict (business_id, customer_id) do update
    set is_blacklisted = true,
        blacklist_reason = case
          when public.business_customer_controls.is_blacklisted
            then public.business_customer_controls.blacklist_reason
          else 'manual'
        end,
        blacklisted_at = coalesce(
          public.business_customer_controls.blacklisted_at,
          now()
        ),
        updated_at = now();
  else
    update public.business_customer_controls
    set is_blacklisted = false,
        no_show_count = 0,
        blacklist_reason = null,
        blacklisted_at = null,
        updated_at = now()
    where business_id = p_business_id and customer_id = p_customer_id;
  end if;
end;
$function$;

revoke all on function private.set_business_customer_blacklist(uuid, uuid, boolean) from public, anon;
grant execute on function private.set_business_customer_blacklist(uuid, uuid, boolean) to authenticated;

create or replace function public.set_business_customer_blacklist(
  p_business_id uuid,
  p_customer_id uuid,
  p_blacklisted boolean
)
returns void
language sql
security invoker
set search_path = ''
as $function$
  select private.set_business_customer_blacklist(
    p_business_id, p_customer_id, p_blacklisted
  );
$function$;

revoke all on function public.set_business_customer_blacklist(uuid, uuid, boolean) from public, anon;
grant execute on function public.set_business_customer_blacklist(uuid, uuid, boolean) to authenticated;

-- Booking uses the explicit business-scoped blacklist state, not the immutable
-- historical appointment count. This is what makes owner removal/reset effective.
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

  select coalesce(c.is_blacklisted, false) into v_requires_approval
  from (select 1) seed
  left join public.business_customer_controls c
    on c.business_id = p_business_id and c.customer_id = auth.uid();
  v_requires_approval := coalesce(v_requires_approval, false);

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

-- A future appointment cannot be recorded as a verified no-show.
create or replace function private.update_appointment_status(
  p_appointment_id uuid,
  p_status text
)
returns void
language plpgsql
security definer
set search_path = ''
as $function$
begin
  if auth.uid() is null then raise exception 'Giriş yapmalısınız'; end if;
  if p_status not in ('completed', 'no_show') then raise exception 'Geçersiz randevu durumu'; end if;

  update public.appointments a
  set status = p_status
  where a.id = p_appointment_id
    and a.status in ('pending', 'confirmed')
    and a.requires_business_approval = false
    and (p_status <> 'no_show' or a.starts_at <= now())
    and (
      exists(select 1 from public.businesses b where b.id = a.business_id and b.owner_id = auth.uid())
      or exists(select 1 from public.employees e where e.id = a.employee_id and e.user_id = auth.uid())
      or (select private.is_admin())
    );

  if not found then
    if p_status = 'no_show' and exists (
      select 1 from public.appointments a
      where a.id = p_appointment_id and a.starts_at > now()
    ) then
      raise exception 'Randevu saati gelmeden müşteri devamsız olarak işaretlenemez';
    end if;
    raise exception 'Randevu bulunamadı veya işlem yetkiniz yok';
  end if;
end;
$function$;

revoke all on function private.update_appointment_status(uuid, text) from public, anon;
grant execute on function private.update_appointment_status(uuid, text) to authenticated;

