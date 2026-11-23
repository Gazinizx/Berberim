create table if not exists public.business_customer_blacklist (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  customer_id uuid not null references public.profiles(id) on delete cascade,
  reason text not null default '',
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  constraint business_customer_blacklist_business_customer_key unique (business_id, customer_id),
  constraint business_customer_blacklist_reason_length check (char_length(reason) <= 300)
);

create index if not exists business_customer_blacklist_customer_idx
  on public.business_customer_blacklist(customer_id, business_id);

alter table public.business_customer_blacklist enable row level security;

grant select, insert, delete on public.business_customer_blacklist to authenticated;

drop policy if exists "Business owners read their customer blacklist" on public.business_customer_blacklist;
create policy "Business owners read their customer blacklist"
on public.business_customer_blacklist for select
to authenticated
using (
  exists (
    select 1 from public.businesses b
    where b.id = business_id and b.owner_id = (select auth.uid())
  )
);

drop policy if exists "Business owners add customers to their blacklist" on public.business_customer_blacklist;
create policy "Business owners add customers to their blacklist"
on public.business_customer_blacklist for insert
to authenticated
with check (
  created_by = (select auth.uid())
  and exists (
    select 1 from public.businesses b
    where b.id = business_id and b.owner_id = (select auth.uid())
  )
);

drop policy if exists "Business owners remove customers from their blacklist" on public.business_customer_blacklist;
create policy "Business owners remove customers from their blacklist"
on public.business_customer_blacklist for delete
to authenticated
using (
  exists (
    select 1 from public.businesses b
    where b.id = business_id and b.owner_id = (select auth.uid())
  )
);

create or replace function private.get_business_customers(p_business_id uuid)
returns table (
  customer_id uuid,
  first_name text,
  last_name text,
  full_name text,
  phone text,
  avatar_url text,
  is_blacklisted boolean,
  blacklist_reason text,
  blacklisted_at timestamptz
)
language plpgsql
security definer
set search_path = ''
as $function$
begin
  if auth.uid() is null or not exists (
    select 1 from public.businesses b
    where b.id = p_business_id and b.owner_id = auth.uid()
  ) then
    raise exception 'Bu işletmenin müşteri listesini görüntüleme yetkiniz yok';
  end if;

  return query
  select
    p.id,
    p.first_name,
    p.last_name,
    coalesce(
      nullif(btrim(concat_ws(' ', nullif(btrim(p.first_name), ''), nullif(btrim(p.last_name), ''))), ''),
      p.full_name
    ),
    p.phone,
    p.avatar_url,
    bc.customer_id is not null,
    coalesce(bc.reason, ''),
    bc.created_at
  from public.profiles p
  left join public.business_memberships bm
    on bm.customer_id = p.id and bm.business_id = p_business_id
  left join public.business_customer_blacklist bc
    on bc.customer_id = p.id and bc.business_id = p_business_id
  where bm.customer_id is not null or bc.customer_id is not null
  order by lower(coalesce(p.full_name, '')), p.id;
end;
$function$;

revoke all on function private.get_business_customers(uuid) from public;
grant execute on function private.get_business_customers(uuid) to authenticated;

create or replace function public.get_business_customers(p_business_id uuid)
returns table (
  customer_id uuid,
  first_name text,
  last_name text,
  full_name text,
  phone text,
  avatar_url text,
  is_blacklisted boolean,
  blacklist_reason text,
  blacklisted_at timestamptz
)
language sql
security invoker
set search_path = ''
as $function$
  select * from private.get_business_customers(p_business_id);
$function$;

revoke all on function public.get_business_customers(uuid) from public;
grant execute on function public.get_business_customers(uuid) to authenticated;

create or replace function private.book_appointment(
  p_business_id uuid,
  p_employee_id uuid,
  p_service_id uuid,
  p_starts_at timestamp with time zone,
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
  if exists (
    select 1 from public.business_customer_blacklist
    where business_id = p_business_id and customer_id = auth.uid()
  ) then
    raise exception 'Bu işletme tarafından kara listeye alındığınız için randevu alamazsınız';
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
