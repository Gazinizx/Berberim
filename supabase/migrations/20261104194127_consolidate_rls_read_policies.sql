drop policy if exists "admin reads all profiles" on public.profiles;
drop policy if exists "profiles read own row" on public.profiles;
create policy "profiles read own row or admin" on public.profiles for select to authenticated
using(id=(select auth.uid()) or (select private.is_admin()));
drop policy if exists "admin reads all businesses" on public.businesses;
drop policy if exists "businesses visible to owners and customers" on public.businesses;
create policy "businesses visible to owners customers or admin" on public.businesses for select to authenticated
using(owner_id=(select auth.uid()) or status='active' or (select private.is_admin()));
drop policy if exists "admin reads all memberships" on public.business_memberships;
drop policy if exists "memberships visible to parties" on public.business_memberships;
create policy "memberships visible to parties or admin" on public.business_memberships for select to authenticated
using(customer_id=(select auth.uid()) or exists(select 1 from public.businesses b where b.id=business_id and b.owner_id=(select auth.uid())) or (select private.is_admin()));
drop policy if exists "admin reads all appointments" on public.appointments;
drop policy if exists "appointment parties read appointments" on public.appointments;
create policy "appointment parties or admin read appointments" on public.appointments for select to authenticated
using(customer_id=(select auth.uid()) or exists(select 1 from public.employees e where e.id=employee_id and e.user_id=(select auth.uid())) or exists(select 1 from public.businesses b where b.id=business_id and b.owner_id=(select auth.uid())) or (select private.is_admin()));