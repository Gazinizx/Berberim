create index if not exists employee_breaks_employee_id_idx on public.employee_breaks(employee_id);
create index if not exists employee_invites_employee_id_idx on public.employee_invites(employee_id);
create index if not exists employee_invites_business_id_idx on public.employee_invites(business_id);
