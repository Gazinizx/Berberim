drop policy if exists "workers read customers from own appointments" on public.profiles;
create policy "appointment parties read customer profiles" on public.profiles for select to authenticated
using(exists(select 1 from public.appointments a where a.customer_id=profiles.id and (
 exists(select 1 from public.employees e where e.id=a.employee_id and e.user_id=(select auth.uid()))
 or exists(select 1 from public.businesses b where b.id=a.business_id and b.owner_id=(select auth.uid()))
)));
create policy "customers read businesses from appointment history" on public.businesses for select to authenticated
using(exists(select 1 from public.appointments a where a.business_id=businesses.id and a.customer_id=(select auth.uid())));
create policy "customers read employees from appointment history" on public.employees for select to authenticated
using(exists(select 1 from public.appointments a where a.employee_id=employees.id and a.customer_id=(select auth.uid())));
create policy "customers read services from appointment history" on public.services for select to authenticated
using(exists(select 1 from public.appointments a where a.service_id=services.id and a.customer_id=(select auth.uid())));
