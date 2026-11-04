-- Fix tenant scoping in read policies and harden administrator review.
create schema if not exists private;
create or replace function private.is_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.profiles p
    where p.id = auth.uid() and p.is_admin = true
  );
$$;
revoke all on function private.is_admin() from public, anon;
grant execute on function private.is_admin() to authenticated;

drop policy if exists "employees visible to business members" on public.employees;
create policy "employees visible to business members" on public.employees
for select to authenticated using (
  exists (
    select 1 from public.business_memberships m
    join public.businesses b on b.id=m.business_id
    where m.business_id=employees.business_id
      and m.customer_id=(select auth.uid()) and b.status='active'
  )
  or exists(select 1 from public.businesses b where b.id=employees.business_id and b.owner_id=(select auth.uid()))
  or (select private.is_admin())
);

drop policy if exists "services visible to business members" on public.services;
create policy "services visible to business members" on public.services
for select to authenticated using (
  exists (
    select 1 from public.business_memberships m
    join public.businesses b on b.id=m.business_id
    where m.business_id=services.business_id
      and m.customer_id=(select auth.uid()) and b.status='active'
  )
  or exists(select 1 from public.businesses b where b.id=services.business_id and b.owner_id=(select auth.uid()))
  or (select private.is_admin())
);

drop policy if exists "hours visible to business members" on public.business_hours;
create policy "hours visible to business members" on public.business_hours
for select to authenticated using (
  exists (
    select 1 from public.business_memberships m
    join public.businesses b on b.id=m.business_id
    where m.business_id=business_hours.business_id
      and m.customer_id=(select auth.uid()) and b.status='active'
  )
  or exists(select 1 from public.businesses b where b.id=business_hours.business_id and b.owner_id=(select auth.uid()))
  or (select private.is_admin())
);

drop policy if exists "breaks visible to business members" on public.business_breaks;
create policy "breaks visible to business members" on public.business_breaks
for select to authenticated using (
  exists (
    select 1 from public.business_memberships m
    join public.businesses b on b.id=m.business_id
    where m.business_id=business_breaks.business_id
      and m.customer_id=(select auth.uid()) and b.status='active'
  )
  or exists(select 1 from public.businesses b where b.id=business_breaks.business_id and b.owner_id=(select auth.uid()))
  or (select private.is_admin())
);

-- create_business_application is intentionally defined in the base schema:
-- it atomically creates the business, its owner employee, and default opening hours.

create or replace function public.review_business(p_business_id uuid, p_status text)
returns void language plpgsql security definer set search_path = ''
as $$
begin
  if auth.uid() is null or not (select private.is_admin()) then raise exception 'Yönetici yetkisi gerekli'; end if;
  if p_status not in ('active','rejected','inactive') then raise exception 'İşletme durumu geçersiz'; end if;
  update public.businesses set status=p_status where id=p_business_id;
  if not found then raise exception 'İşletme bulunamadı'; end if;
end $$;
revoke all on function public.review_business(uuid,text) from public, anon;
grant execute on function public.review_business(uuid,text) to authenticated;

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  appointment_id uuid references public.appointments(id) on delete cascade,
  title text not null,
  body text not null,
  created_at timestamptz not null default now(),
  read_at timestamptz
);
alter table public.notifications enable row level security;
drop policy if exists "users read own notifications" on public.notifications;
create policy "users read own notifications" on public.notifications
for select to authenticated using (user_id=(select auth.uid()));
drop policy if exists "users mark own notifications read" on public.notifications;
create policy "users mark own notifications read" on public.notifications
for update to authenticated using (user_id=(select auth.uid()))
with check (user_id=(select auth.uid()));
revoke insert, update on public.notifications from authenticated;
grant select on public.notifications to authenticated;
grant update (read_at) on public.notifications to authenticated;

create or replace function private.notify_appointment_change()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare v_owner uuid; v_employee uuid; v_service text; v_when text;
begin
  select b.owner_id into v_owner from public.businesses b where b.id=new.business_id;
  select e.user_id into v_employee from public.employees e where e.id=new.employee_id;
  select s.name into v_service from public.services s where s.id=new.service_id;
  v_when:=to_char(new.starts_at at time zone 'Europe/Istanbul','DD.MM.YYYY HH24:MI');
  if tg_op='INSERT' then
    insert into public.notifications(user_id,appointment_id,title,body)
    values(new.customer_id,new.id,'Randevun onaylandı',coalesce(v_service,'Hizmet')||' için randevun: '||v_when);
    insert into public.notifications(user_id,appointment_id,title,body)
    values(v_owner,new.id,'Yeni randevu',coalesce(v_service,'Hizmet')||' için randevu: '||v_when);
    if v_employee is not null and v_employee<>v_owner then
      insert into public.notifications(user_id,appointment_id,title,body)
      values(v_employee,new.id,'Yeni randevu',coalesce(v_service,'Hizmet')||' için randevu: '||v_when);
    end if;
  elsif old.status='confirmed' and new.status='cancelled' then
    insert into public.notifications(user_id,appointment_id,title,body)
    values(new.customer_id,new.id,'Randevu iptal edildi','Randevunuz iptal edildi: '||v_when);
    if v_owner<>new.customer_id then
      insert into public.notifications(user_id,appointment_id,title,body)
      values(v_owner,new.id,'Randevu iptal edildi','Bir randevu iptal edildi: '||v_when);
    end if;
    if v_employee is not null and v_employee<>v_owner and v_employee<>new.customer_id then
      insert into public.notifications(user_id,appointment_id,title,body)
      values(v_employee,new.id,'Randevu iptal edildi','Bir randevu iptal edildi: '||v_when);
    end if;
  end if;
  return new;
end;
$$;
drop trigger if exists appointments_notify_change on public.appointments;
create trigger appointments_notify_change
after insert or update on public.appointments
for each row execute function private.notify_appointment_change();

create index if not exists notifications_appointment_id_idx on public.notifications(appointment_id);
create index if not exists notifications_user_created_idx on public.notifications(user_id, created_at desc);
