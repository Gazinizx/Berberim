drop policy if exists "employees read own linked row" on public.employees;
drop policy if exists "employees visible to business members" on public.employees;
create policy "employees visible to business members or linked user"
on public.employees for select to authenticated
using (
  user_id = (select auth.uid())
  or exists(
    select 1 from public.business_memberships m
    join public.businesses b on b.id=m.business_id
    where m.business_id=employees.business_id
      and m.customer_id=(select auth.uid())
      and b.status='active'
  )
  or exists(
    select 1 from public.businesses b
    where b.id=employees.business_id and b.owner_id=(select auth.uid())
  )
  or (select private.is_admin())
);