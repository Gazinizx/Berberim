alter table public.employees
  add column if not exists login_username text;

create unique index if not exists employees_login_username_lower_uidx
  on public.employees (lower(login_username))
  where login_username is not null;

create table if not exists public.employee_login_accounts (
  employee_id uuid primary key references public.employees(id) on delete cascade,
  login_username text not null unique,
  auth_email text not null unique,
  created_at timestamptz not null default now()
);

alter table public.employee_login_accounts enable row level security;
revoke all on table public.employee_login_accounts from anon, authenticated;
grant all on table public.employee_login_accounts to service_role;
