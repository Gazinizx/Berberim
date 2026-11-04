create extension if not exists btree_gist;
create schema if not exists private;

create table public.profiles (
 id uuid primary key references auth.users(id) on delete cascade,
 full_name text not null default '', email text, phone text,
 account_type text not null default 'customer',
 is_admin boolean not null default false, is_blocked boolean not null default false,
 created_at timestamptz not null default now()
);
create table public.businesses (
 id uuid primary key default gen_random_uuid(),
 owner_id uuid not null references public.profiles(id) on delete restrict,
 name text not null check(length(btrim(name))>=2), address text,
 status text not null default 'pending' check(status in ('pending','active','rejected','inactive')),
 join_code text not null unique default upper(substr(encode(gen_random_bytes(8),'hex'),1,10)),
 created_at timestamptz not null default now()
);
create table public.business_memberships (
 id uuid primary key default gen_random_uuid(),
 business_id uuid not null references public.businesses(id) on delete cascade,
 customer_id uuid not null references public.profiles(id) on delete cascade,
 created_at timestamptz not null default now(),
 constraint business_memberships_business_customer_key unique(business_id,customer_id)
);
create table public.employees (
 id uuid primary key default gen_random_uuid(),
 business_id uuid not null references public.businesses(id) on delete cascade,
 user_id uuid references public.profiles(id) on delete set null,
 display_name text not null check(length(btrim(display_name))>=1),
 is_active boolean not null default true, created_at timestamptz not null default now()
);
create table public.employee_invites (
 id uuid primary key default gen_random_uuid(),
 employee_id uuid not null references public.employees(id) on delete cascade,
 invite_code text not null unique default upper(substr(encode(gen_random_bytes(8),'hex'),1,10)),
 claimed_at timestamptz, expires_at timestamptz not null default(now()+interval '7 days'),
 created_at timestamptz not null default now()
);
create table public.services (
 id uuid primary key default gen_random_uuid(),
 business_id uuid not null references public.businesses(id) on delete cascade,
 name text not null check(length(btrim(name))>=1),
 price numeric(10,2) not null check(price>=0),
 duration_minutes integer not null check(duration_minutes between 5 and 480),
 is_active boolean not null default true, created_at timestamptz not null default now()
);
create table public.business_hours (
 id uuid primary key default gen_random_uuid(),
 business_id uuid not null references public.businesses(id) on delete cascade,
 weekday smallint not null check(weekday between 0 and 6),
 opens_at time not null default '09:00', closes_at time not null default '20:00',
 is_closed boolean not null default false, created_at timestamptz not null default now(),
 constraint business_hours_business_id_weekday_key unique(business_id,weekday),
 constraint business_hours_time_order check(is_closed or opens_at<closes_at)
);
create table public.business_breaks (
 id uuid primary key default gen_random_uuid(),
 business_id uuid not null references public.businesses(id) on delete cascade,
 weekday smallint not null check(weekday between 0 and 6),
 starts_at time not null, ends_at time not null, created_at timestamptz not null default now(),
 constraint business_breaks_time_order check(starts_at<ends_at)
);
create table public.appointments (
 id uuid primary key default gen_random_uuid(),
 business_id uuid not null references public.businesses(id) on delete restrict,
 customer_id uuid not null references public.profiles(id) on delete restrict,
 employee_id uuid not null references public.employees(id) on delete restrict,
 service_id uuid not null references public.services(id) on delete restrict,
 starts_at timestamptz not null, ends_at timestamptz not null,
 status text not null default 'confirmed' check(status in ('pending','confirmed','completed','cancelled','no_show')),
 customer_note text, created_at timestamptz not null default now(),
 constraint appointments_time_order check(starts_at<ends_at),
 constraint appointments_no_employee_overlap exclude using gist(
  employee_id with =, tstzrange(starts_at,ends_at,'[)') with &&
 ) where(status in ('pending','confirmed'))
);

create index businesses_owner_created_idx on public.businesses(owner_id,created_at desc);
create index businesses_status_created_idx on public.businesses(status,created_at desc);
create index memberships_customer_created_idx on public.business_memberships(customer_id,created_at desc);
create index memberships_business_idx on public.business_memberships(business_id);
create index employees_business_active_idx on public.employees(business_id,is_active);
create index employees_user_idx on public.employees(user_id) where user_id is not null;
create index employee_invites_employee_idx on public.employee_invites(employee_id,created_at desc);
create index services_business_active_idx on public.services(business_id,is_active);
create index business_breaks_business_weekday_idx on public.business_breaks(business_id,weekday);
create index appointments_customer_starts_idx on public.appointments(customer_id,starts_at desc);
create index appointments_business_starts_idx on public.appointments(business_id,starts_at desc);
create index appointments_employee_starts_idx on public.appointments(employee_id,starts_at desc);

create or replace function private.is_admin()
returns boolean language sql stable security definer set search_path=''
as $$ select exists(select 1 from public.profiles p where p.id=(select auth.uid()) and p.is_admin); $$;
revoke all on function private.is_admin() from public,anon;
grant execute on function private.is_admin() to authenticated;

create or replace function private.handle_new_user()
returns trigger language plpgsql security definer set search_path=''
as $$
begin
 insert into public.profiles(id,full_name,email,account_type)
 values(new.id,coalesce(new.raw_user_meta_data->>'full_name',''),new.email,
 case when new.raw_user_meta_data->>'account_type'='business_owner' then 'business_owner' else 'customer' end);
 return new;
end; $$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users
for each row execute function private.handle_new_user();

alter table public.profiles enable row level security;
alter table public.businesses enable row level security;
alter table public.business_memberships enable row level security;
alter table public.employees enable row level security;
alter table public.employee_invites enable row level security;
alter table public.services enable row level security;
alter table public.business_hours enable row level security;
alter table public.business_breaks enable row level security;
alter table public.appointments enable row level security;

create policy "profiles read own row" on public.profiles for select to authenticated using(id=(select auth.uid()));
create policy "profiles update own row" on public.profiles for update to authenticated
using(id=(select auth.uid())) with check(id=(select auth.uid()));
create policy "businesses visible to owners and customers" on public.businesses
for select to authenticated using(owner_id=(select auth.uid()) or status='active');
create policy "owners create own businesses" on public.businesses
for insert to authenticated with check(owner_id=(select auth.uid()));
create policy "memberships visible to parties" on public.business_memberships
for select to authenticated using(customer_id=(select auth.uid()) or exists(
 select 1 from public.businesses b where b.id=business_id and b.owner_id=(select auth.uid())));
create policy "employees visible to business members" on public.employees
for select to authenticated using(
 exists(select 1 from public.business_memberships m where m.business_id=employees.business_id and m.customer_id=(select auth.uid())) or
 exists(select 1 from public.businesses b where b.id=employees.business_id and b.owner_id=(select auth.uid())));
create policy "employee invites visible to business owners" on public.employee_invites
for select to authenticated using(exists(select 1 from public.employees e join public.businesses b on b.id=e.business_id
 where e.id=employee_id and b.owner_id=(select auth.uid())));
create policy "services visible to business members" on public.services
for select to authenticated using(
 exists(select 1 from public.business_memberships m where m.business_id=services.business_id and m.customer_id=(select auth.uid())) or
 exists(select 1 from public.businesses b where b.id=services.business_id and b.owner_id=(select auth.uid())));
create policy "owners manage services" on public.services for all to authenticated
using(exists(select 1 from public.businesses b where b.id=services.business_id and b.owner_id=(select auth.uid())))
with check(exists(select 1 from public.businesses b where b.id=services.business_id and b.owner_id=(select auth.uid())));
create policy "hours visible to business members" on public.business_hours
for select to authenticated using(
 exists(select 1 from public.business_memberships m where m.business_id=business_hours.business_id and m.customer_id=(select auth.uid())) or
 exists(select 1 from public.businesses b where b.id=business_hours.business_id and b.owner_id=(select auth.uid())));
create policy "owners manage business hours" on public.business_hours for all to authenticated
using(exists(select 1 from public.businesses b where b.id=business_hours.business_id and b.owner_id=(select auth.uid())))
with check(exists(select 1 from public.businesses b where b.id=business_hours.business_id and b.owner_id=(select auth.uid())));
create policy "breaks visible to business members" on public.business_breaks
for select to authenticated using(
 exists(select 1 from public.business_memberships m where m.business_id=business_breaks.business_id and m.customer_id=(select auth.uid())) or
 exists(select 1 from public.businesses b where b.id=business_breaks.business_id and b.owner_id=(select auth.uid())));
create policy "owners manage business breaks" on public.business_breaks for all to authenticated
using(exists(select 1 from public.businesses b where b.id=business_breaks.business_id and b.owner_id=(select auth.uid())))
with check(exists(select 1 from public.businesses b where b.id=business_breaks.business_id and b.owner_id=(select auth.uid())));
create policy "appointment parties read appointments" on public.appointments
for select to authenticated using(
 customer_id=(select auth.uid()) or
 exists(select 1 from public.employees e where e.id=employee_id and e.user_id=(select auth.uid())) or
 exists(select 1 from public.businesses b where b.id=business_id and b.owner_id=(select auth.uid())) or
 (select private.is_admin()));

grant usage on schema public to authenticated;
grant select on public.profiles,public.businesses,public.business_memberships,public.employees,public.employee_invites,
 public.services,public.business_hours,public.business_breaks,public.appointments to authenticated;
grant update(full_name,phone,account_type) on public.profiles to authenticated;
grant insert,update,delete on public.services to authenticated;
grant insert,update,delete on public.business_hours to authenticated;
grant insert,update,delete on public.business_breaks to authenticated;

create or replace function public.join_business_by_code(p_code text)
returns uuid language plpgsql security definer set search_path=''
as $$
declare v_business_id uuid;
begin
 if auth.uid() is null then raise exception 'Giriş yapmalısınız'; end if;
 select b.id into v_business_id from public.businesses b
 where upper(b.join_code)=upper(trim(p_code)) and b.status='active';
 if v_business_id is null then raise exception 'İşletme kodu bulunamadı veya işletme aktif değil'; end if;
 insert into public.business_memberships(business_id,customer_id) values(v_business_id,auth.uid())
 on conflict(business_id,customer_id) do nothing;
 return v_business_id;
end; $$;
revoke all on function public.join_business_by_code(text) from public,anon;
grant execute on function public.join_business_by_code(text) to authenticated;

create or replace function public.create_employee_invite(p_display_name text)
returns text language plpgsql security definer set search_path=''
as $$
declare v_business_id uuid; v_employee_id uuid; v_code text;
begin
 if auth.uid() is null then raise exception 'Giriş yapmalısınız'; end if;
 if length(trim(coalesce(p_display_name,'')))<1 then raise exception 'Çalışan adı gerekli'; end if;
 select b.id into v_business_id from public.businesses b where b.owner_id=auth.uid() and b.status='active'
 order by b.created_at asc limit 1;
 if v_business_id is null then raise exception 'Aktif işletmeniz bulunamadı'; end if;
 insert into public.employees(business_id,display_name) values(v_business_id,trim(p_display_name)) returning id into v_employee_id;
 insert into public.employee_invites(employee_id) values(v_employee_id) returning invite_code into v_code;
 return v_code;
end; $$;
revoke all on function public.create_employee_invite(text) from public,anon;
grant execute on function public.create_employee_invite(text) to authenticated;

create or replace function public.update_appointment_status(p_appointment_id uuid,p_status text)
returns void language plpgsql security definer set search_path=''
as $$
begin
 if auth.uid() is null then raise exception 'Giriş yapmalısınız'; end if;
 if p_status not in ('completed','no_show') then raise exception 'Geçersiz randevu durumu'; end if;
 update public.appointments a set status=p_status where a.id=p_appointment_id and a.status in ('pending','confirmed')
 and (exists(select 1 from public.businesses b where b.id=a.business_id and b.owner_id=auth.uid())
 or exists(select 1 from public.employees e where e.id=a.employee_id and e.user_id=auth.uid())
 or (select private.is_admin()));
 if not found then raise exception 'Randevu bulunamadı veya işlem yetkiniz yok'; end if;
end; $$;
revoke all on function public.update_appointment_status(uuid,text) from public,anon;
grant execute on function public.update_appointment_status(uuid,text) to authenticated;

create or replace function public.create_business_application(p_name text,p_address text default null)
returns uuid language plpgsql security definer set search_path=''
as $$
declare v_business_id uuid; v_owner_name text;
begin
 if auth.uid() is null then raise exception 'Giriş yapmalısınız'; end if;
 if length(trim(coalesce(p_name,'')))<2 then raise exception 'İşletme adı gerekli'; end if;
 select coalesce(nullif(p.full_name,''),'İşletme sahibi') into v_owner_name from public.profiles p where p.id=auth.uid();
 insert into public.businesses(owner_id,name,address,status)
 values(auth.uid(),trim(p_name),nullif(trim(coalesce(p_address,'')),''),'pending') returning id into v_business_id;
 insert into public.employees(business_id,user_id,display_name,is_active)
 values(v_business_id,auth.uid(),coalesce(v_owner_name,'İşletme sahibi'),true);
 insert into public.business_hours(business_id,weekday,opens_at,closes_at,is_closed)
 select v_business_id,d,'09:00','20:00',false from generate_series(0,6) as d;
 return v_business_id;
end; $$;
revoke all on function public.create_business_application(text,text) from public,anon;
grant execute on function public.create_business_application(text,text) to authenticated;
