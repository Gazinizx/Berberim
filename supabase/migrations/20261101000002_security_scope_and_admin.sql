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

create or replace function public.create_business_application(p_name text, p_address text default null)
returns uuid language sql security invoker set search_path = ''
as $$ select public.create_business(p_name, p_address); $$;
revoke all on function public.create_business_application(text,text) from public, anon;
grant execute on function public.create_business_application(text,text) to authenticated;

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

create index if not exists notifications_appointment_id_idx on public.notifications(appointment_id);
