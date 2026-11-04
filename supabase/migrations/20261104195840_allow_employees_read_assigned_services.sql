drop policy if exists "services visible to business members" on public.services;
create policy "services visible to business members owners employees or admin"
on public.services for select to authenticated
using (
  exists(
    select 1 from public.business_memberships m
    join public.businesses b on b.id=m.business_id
    where m.business_id=services.business_id
      and m.customer_id=(select auth.uid())
      and b.status='active'
  )
  or exists(
    select 1 from public.businesses b
    where b.id=services.business_id and b.owner_id=(select auth.uid())
  )
  or exists(
    select 1 from public.employees e
    where e.business_id=services.business_id
      and e.user_id=(select auth.uid())
      and e.is_active
  )
  or (select private.is_admin())
);