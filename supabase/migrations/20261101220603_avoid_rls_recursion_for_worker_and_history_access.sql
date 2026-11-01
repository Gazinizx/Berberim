create or replace function private.is_linked_employee_of_business(p_business_id uuid) returns boolean language sql stable security definer set search_path='' as $$ select exists(select 1 from public.employees e where e.business_id=p_business_id and e.user_id=(select auth.uid())) $$;
create or replace function private.customer_has_appointment_business(p_business_id uuid) returns boolean language sql stable security definer set search_path='' as $$ select exists(select 1 from public.appointments a where a.business_id=p_business_id and a.customer_id=(select auth.uid())) $$;
create or replace function private.customer_has_appointment_employee(p_employee_id uuid) returns boolean language sql stable security definer set search_path='' as $$ select exists(select 1 from public.appointments a where a.employee_id=p_employee_id and a.customer_id=(select auth.uid())) $$;
create or replace function private.customer_has_appointment_service(p_service_id uuid) returns boolean language sql stable security definer set search_path='' as $$ select exists(select 1 from public.appointments a where a.service_id=p_service_id and a.customer_id=(select auth.uid())) $$;
create or replace function private.appointment_party_can_read_profile(p_profile_id uuid) returns boolean language sql stable security definer set search_path='' as $$ select exists(select 1 from public.appointments a where a.customer_id=p_profile_id and (
 exists(select 1 from public.employees e where e.id=a.employee_id and e.user_id=(select auth.uid()))
 or exists(select 1 from public.businesses b where b.id=a.business_id and b.owner_id=(select auth.uid()))
)) $$;
revoke all on function private.is_linked_employee_of_business(uuid) from public,anon;
revoke all on function private.customer_has_appointment_business(uuid) from public,anon;
revoke all on function private.customer_has_appointment_employee(uuid) from public,anon;
revoke all on function private.customer_has_appointment_service(uuid) from public,anon;
revoke all on function private.appointment_party_can_read_profile(uuid) from public,anon;
grant execute on function private.is_linked_employee_of_business(uuid) to authenticated;
grant execute on function private.customer_has_appointment_business(uuid) to authenticated;
grant execute on function private.customer_has_appointment_employee(uuid) to authenticated;
grant execute on function private.customer_has_appointment_service(uuid) to authenticated;
grant execute on function private.appointment_party_can_read_profile(uuid) to authenticated;
drop policy if exists "employees read their business" on public.businesses;
create policy "employees read their business" on public.businesses for select to authenticated using(private.is_linked_employee_of_business(id));
drop policy if exists "customers read businesses from appointment history" on public.businesses;
create policy "customers read businesses from appointment history" on public.businesses for select to authenticated using(private.customer_has_appointment_business(id));
drop policy if exists "customers read employees from appointment history" on public.employees;
create policy "customers read employees from appointment history" on public.employees for select to authenticated using(private.customer_has_appointment_employee(id));
drop policy if exists "customers read services from appointment history" on public.services;
create policy "customers read services from appointment history" on public.services for select to authenticated using(private.customer_has_appointment_service(id));
drop policy if exists "employees read their services" on public.services;
create policy "employees read their services" on public.services for select to authenticated using(exists(select 1 from public.employees e where e.business_id=services.business_id and e.user_id=(select auth.uid())));
drop policy if exists "appointment parties read customer profiles" on public.profiles;
create policy "appointment parties read customer profiles" on public.profiles for select to authenticated using(private.appointment_party_can_read_profile(id));
