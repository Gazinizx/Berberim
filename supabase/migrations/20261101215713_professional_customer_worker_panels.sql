alter table public.profiles drop constraint if exists profiles_account_type_check;
alter table public.profiles add constraint profiles_account_type_check check(account_type in ('customer','business_owner','worker'));

create table if not exists public.employee_invites(
 id uuid primary key default gen_random_uuid(), employee_id uuid not null references public.employees(id) on delete cascade,
 business_id uuid not null references public.businesses(id) on delete cascade, invite_code text not null unique,
 expires_at timestamptz not null default(now()+interval '7 days'), claimed_at timestamptz, created_at timestamptz not null default now()
);
create table if not exists public.employee_hours(
 id uuid primary key default gen_random_uuid(), employee_id uuid not null references public.employees(id) on delete cascade,
 weekday smallint not null check(weekday between 0 and 6), opens_at time, closes_at time, is_closed boolean not null default false,
 check(is_closed or (opens_at is not null and closes_at is not null and opens_at<closes_at)), unique(employee_id,weekday)
);
create table if not exists public.employee_breaks(
 id uuid primary key default gen_random_uuid(), employee_id uuid not null references public.employees(id) on delete cascade,
 weekday smallint not null check(weekday between 0 and 6), starts_at time not null, ends_at time not null, check(starts_at<ends_at)
);
create table if not exists public.employee_time_off(
 id uuid primary key default gen_random_uuid(), employee_id uuid not null references public.employees(id) on delete cascade,
 starts_at timestamptz not null, ends_at timestamptz not null, note text, created_at timestamptz not null default now(), check(ends_at>starts_at)
);
create index if not exists employee_time_off_period_idx on public.employee_time_off(employee_id,starts_at,ends_at);
create unique index if not exists employees_one_user_per_account_idx on public.employees(user_id) where user_id is not null;

alter table public.appointments drop constraint if exists appointments_status_check;
alter table public.appointments add constraint appointments_status_check check(status in ('pending','confirmed','cancelled','completed','no_show'));
alter table public.appointments drop constraint if exists appointments_no_employee_overlap;
alter table public.appointments add constraint appointments_no_employee_overlap exclude using gist(
 employee_id with =, tstzrange(starts_at,ends_at,'[)') with &&
) where(status in ('pending','confirmed'));

alter table public.employee_invites enable row level security;
alter table public.employee_hours enable row level security;
alter table public.employee_breaks enable row level security;
alter table public.employee_time_off enable row level security;

create policy "owners read employee invites" on public.employee_invites for select to authenticated
using(exists(select 1 from public.businesses b where b.id=business_id and b.owner_id=(select auth.uid())));
create policy "employee hours read" on public.employee_hours for select to authenticated using(
 exists(select 1 from public.employees e where e.id=employee_id and e.user_id=(select auth.uid()))
 or exists(select 1 from public.employees e join public.businesses b on b.id=e.business_id where e.id=employee_id and b.owner_id=(select auth.uid()))
 or exists(select 1 from public.employees e join public.business_memberships m on m.business_id=e.business_id where e.id=employee_id and m.customer_id=(select auth.uid()))
);
create policy "employee hours manage" on public.employee_hours for all to authenticated
using(exists(select 1 from public.employees e where e.id=employee_id and e.user_id=(select auth.uid()))
 or exists(select 1 from public.employees e join public.businesses b on b.id=e.business_id where e.id=employee_id and b.owner_id=(select auth.uid())))
with check(exists(select 1 from public.employees e where e.id=employee_id and e.user_id=(select auth.uid()))
 or exists(select 1 from public.employees e join public.businesses b on b.id=e.business_id where e.id=employee_id and b.owner_id=(select auth.uid())));
create policy "employee breaks read" on public.employee_breaks for select to authenticated using(
 exists(select 1 from public.employees e where e.id=employee_id and e.user_id=(select auth.uid()))
 or exists(select 1 from public.employees e join public.businesses b on b.id=e.business_id where e.id=employee_id and b.owner_id=(select auth.uid()))
 or exists(select 1 from public.employees e join public.business_memberships m on m.business_id=e.business_id where e.id=employee_id and m.customer_id=(select auth.uid()))
);
create policy "employee breaks manage" on public.employee_breaks for all to authenticated
using(exists(select 1 from public.employees e where e.id=employee_id and e.user_id=(select auth.uid()))
 or exists(select 1 from public.employees e join public.businesses b on b.id=e.business_id where e.id=employee_id and b.owner_id=(select auth.uid())))
with check(exists(select 1 from public.employees e where e.id=employee_id and e.user_id=(select auth.uid()))
 or exists(select 1 from public.employees e join public.businesses b on b.id=e.business_id where e.id=employee_id and b.owner_id=(select auth.uid())));
create policy "employee time off read" on public.employee_time_off for select to authenticated using(
 exists(select 1 from public.employees e where e.id=employee_id and e.user_id=(select auth.uid()))
 or exists(select 1 from public.employees e join public.businesses b on b.id=e.business_id where e.id=employee_id and b.owner_id=(select auth.uid()))
 or exists(select 1 from public.employees e join public.business_memberships m on m.business_id=e.business_id where e.id=employee_id and m.customer_id=(select auth.uid()))
);
create policy "employee time off manage" on public.employee_time_off for all to authenticated
using(exists(select 1 from public.employees e where e.id=employee_id and e.user_id=(select auth.uid()))
 or exists(select 1 from public.employees e join public.businesses b on b.id=e.business_id where e.id=employee_id and b.owner_id=(select auth.uid())))
with check(exists(select 1 from public.employees e where e.id=employee_id and e.user_id=(select auth.uid()))
 or exists(select 1 from public.employees e join public.businesses b on b.id=e.business_id where e.id=employee_id and b.owner_id=(select auth.uid())));
create policy "employee reads own row" on public.employees for select to authenticated using(user_id=(select auth.uid()));

create or replace function private.current_profile_account_type() returns text language sql stable security definer set search_path=''
as $$ select p.account_type from public.profiles p where p.id=(select auth.uid()) $$;
revoke all on function private.current_profile_account_type() from public,anon;
grant execute on function private.current_profile_account_type() to authenticated;
drop policy if exists "profile update self" on public.profiles;
create policy "profile update self" on public.profiles for update to authenticated
using(id=(select auth.uid())) with check(id=(select auth.uid()) and is_admin=false and account_type=private.current_profile_account_type());

create or replace function public.create_employee_invite(p_display_name text) returns text
language plpgsql security definer set search_path=''
as $$
declare v_bid uuid; v_eid uuid; v_code text;
begin
 if auth.uid() is null then raise exception 'Giriş yapmalısınız'; end if;
 if nullif(trim(p_display_name),'') is null then raise exception 'Çalışan adı boş olamaz'; end if;
 select id into v_bid from public.businesses where owner_id=auth.uid() and status='active' order by created_at limit 1;
 if v_bid is null then raise exception 'Aktif işletme bulunamadı'; end if;
 insert into public.employees(business_id,display_name) values(v_bid,trim(p_display_name)) returning id into v_eid;
 v_code:=upper(substr(encode(extensions.gen_random_bytes(6),'hex'),1,10));
 insert into public.employee_invites(employee_id,business_id,invite_code) values(v_eid,v_bid,v_code);
 return v_code;
end $$;

create or replace function public.claim_employee_invite(p_code text) returns uuid
language plpgsql security definer set search_path=''
as $$
declare v_eid uuid; v_bid uuid;
begin
 if auth.uid() is null then raise exception 'Giriş yapıp hesap oluşturmalısınız'; end if;
 if exists(select 1 from public.employees where user_id=auth.uid()) then raise exception 'Hesap zaten çalışana bağlı'; end if;
 if not exists(select 1 from public.profiles where id=auth.uid() and account_type='customer') then raise exception 'Bu hesap çalışan olarak bağlanamaz'; end if;
 select i.employee_id,i.business_id into v_eid,v_bid from public.employee_invites i
 join public.employees e on e.id=i.employee_id and e.user_id is null and e.is_active
 join public.businesses b on b.id=i.business_id and b.status='active'
 where i.invite_code=upper(trim(p_code)) and i.claimed_at is null and i.expires_at>now() for update of i;
 if v_eid is null then raise exception 'Davet kodu geçersiz veya süresi dolmuş'; end if;
 update public.employees set user_id=auth.uid() where id=v_eid and user_id is null;
 if not found then raise exception 'Davet kodu başka hesap tarafından kullanıldı'; end if;
 update public.employee_invites set claimed_at=now() where employee_id=v_eid and invite_code=upper(trim(p_code));
 update public.profiles set account_type='worker' where id=auth.uid();
 return v_bid;
end $$;

create or replace function public.leave_business() returns void language plpgsql security definer set search_path=''
as $$
begin
 if auth.uid() is null then raise exception 'Giriş yapmalısınız'; end if;
 delete from public.business_memberships where customer_id=auth.uid();
 if not found then raise exception 'Bağlı olduğunuz işletme bulunamadı'; end if;
end $$;

create or replace function public.join_business_by_code(p_code text) returns uuid
language plpgsql security definer set search_path=''
as $$
declare v_bid uuid;
begin
 if auth.uid() is null then raise exception 'Giriş yapmalısınız'; end if;
 if not exists(select 1 from public.profiles where id=auth.uid() and account_type='customer') then raise exception 'Yalnızca müşteri hesabı katılabilir'; end if;
 if exists(select 1 from public.business_memberships where customer_id=auth.uid()) then raise exception 'Yeni işletmeye katılmak için önce mevcut berberinizden ayrılın'; end if;
 select id into v_bid from public.businesses where join_code=upper(trim(p_code)) and status='active';
 if v_bid is null then raise exception 'İşletme kodu geçersiz veya işletme aktif değil'; end if;
 insert into public.business_memberships(business_id,customer_id) values(v_bid,auth.uid()) on conflict do nothing;
 return v_bid;
end $$;

create or replace function public.get_available_slots(p_employee_id uuid,p_service_id uuid,p_day date)
returns table(slot_start timestamptz) language plpgsql stable security definer set search_path=''
as $$
declare v_bid uuid; v_duration int; v_open time; v_close time; v_closed boolean; v_has_hours boolean;
begin
 if auth.uid() is null then raise exception 'Giriş yapmalısınız'; end if;
 select e.business_id into v_bid from public.employees e join public.businesses b on b.id=e.business_id and b.status='active'
 where e.id=p_employee_id and e.is_active;
 if v_bid is null then raise exception 'Çalışan bulunamadı'; end if;
 if not exists(select 1 from public.business_memberships where business_id=v_bid and customer_id=auth.uid()) then raise exception 'Önce işletmeye katılmalısınız'; end if;
 select duration_minutes into v_duration from public.services where id=p_service_id and business_id=v_bid and is_active;
 if v_duration is null then raise exception 'Hizmet bulunamadı'; end if;
 select exists(select 1 from public.employee_hours where employee_id=p_employee_id and weekday=extract(dow from p_day)::int) into v_has_hours;
 if v_has_hours then
  select opens_at,closes_at,is_closed into v_open,v_close,v_closed from public.employee_hours where employee_id=p_employee_id and weekday=extract(dow from p_day)::int;
 else
  select opens_at,closes_at,is_closed into v_open,v_close,v_closed from public.business_hours where business_id=v_bid and weekday=extract(dow from p_day)::int;
 end if;
 if coalesce(v_closed,true) or v_open is null or v_close is null then return; end if;
 return query with candidates as (
  select g local_start from generate_series(p_day::timestamp+v_open,p_day::timestamp+v_close-make_interval(mins=>v_duration),interval '30 minutes') g
 ), slots as (
  select (local_start at time zone 'Europe/Istanbul') s,(local_start at time zone 'Europe/Istanbul')+make_interval(mins=>v_duration) e,
   local_start::time st,(local_start+make_interval(mins=>v_duration))::time et from candidates
 )
 select s.s from slots s where s.s>now()
 and not exists(select 1 from public.appointments a where a.employee_id=p_employee_id and a.status in ('pending','confirmed') and tstzrange(a.starts_at,a.ends_at,'[)') && tstzrange(s.s,s.e,'[)'))
 and not exists(select 1 from public.business_breaks br where br.business_id=v_bid and br.weekday=extract(dow from p_day)::int and s.st<br.ends_at and s.et>br.starts_at)
 and not exists(select 1 from public.employee_breaks eb where eb.employee_id=p_employee_id and eb.weekday=extract(dow from p_day)::int and s.st<eb.ends_at and s.et>eb.starts_at)
 and not exists(select 1 from public.employee_time_off x where x.employee_id=p_employee_id and tstzrange(x.starts_at,x.ends_at,'[)') && tstzrange(s.s,s.e,'[)'))
 order by s.s;
end $$;

create or replace function public.book_appointment(p_business_id uuid,p_employee_id uuid,p_service_id uuid,p_starts_at timestamptz,p_customer_note text default null)
returns uuid language plpgsql security definer set search_path=''
as $$
declare v_duration int; v_end timestamptz; v_day int; v_open time; v_close time; v_start_local timestamp; v_end_local timestamp; v_id uuid; v_has_hours boolean; v_closed boolean;
begin
 if auth.uid() is null then raise exception 'Giriş yapmalısınız'; end if;
 if p_starts_at<=now() then raise exception 'Geçmiş bir saate randevu alınamaz'; end if;
 if not exists(select 1 from public.businesses where id=p_business_id and status='active') then raise exception 'İşletme aktif değil'; end if;
 if not exists(select 1 from public.business_memberships where business_id=p_business_id and customer_id=auth.uid()) then raise exception 'Önce işletmeye katılmalısınız'; end if;
 if not exists(select 1 from public.employees where id=p_employee_id and business_id=p_business_id and is_active) then raise exception 'Çalışan bulunamadı'; end if;
 select duration_minutes into v_duration from public.services where id=p_service_id and business_id=p_business_id and is_active;
 if v_duration is null then raise exception 'Hizmet bulunamadı'; end if;
 v_end:=p_starts_at+make_interval(mins=>v_duration);
 v_start_local:=p_starts_at at time zone 'Europe/Istanbul'; v_end_local:=v_end at time zone 'Europe/Istanbul'; v_day:=extract(dow from v_start_local)::int;
 select exists(select 1 from public.employee_hours where employee_id=p_employee_id and weekday=v_day) into v_has_hours;
 if v_has_hours then
  select opens_at,closes_at,is_closed into v_open,v_close,v_closed from public.employee_hours where employee_id=p_employee_id and weekday=v_day;
 else
  select opens_at,closes_at,is_closed into v_open,v_close,v_closed from public.business_hours where business_id=p_business_id and weekday=v_day;
 end if;
 if coalesce(v_closed,true) or v_open is null or v_close is null or v_start_local::time<v_open or v_end_local::time>v_close then raise exception 'Randevu çalışanın çalışma saatleri dışında'; end if;
 if exists(select 1 from public.business_breaks where business_id=p_business_id and weekday=v_day and v_start_local::time<ends_at and v_end_local::time>starts_at) then raise exception 'İşletme molasına denk geliyor'; end if;
 if exists(select 1 from public.employee_breaks where employee_id=p_employee_id and weekday=v_day and v_start_local::time<ends_at and v_end_local::time>starts_at) then raise exception 'Çalışan molasına denk geliyor'; end if;
 if exists(select 1 from public.employee_time_off where employee_id=p_employee_id and tstzrange(starts_at,ends_at,'[)') && tstzrange(p_starts_at,v_end,'[)')) then raise exception 'Çalışan bu tarihte izinli'; end if;
 insert into public.appointments(business_id,customer_id,employee_id,service_id,starts_at,ends_at,status,customer_note)
 values(p_business_id,auth.uid(),p_employee_id,p_service_id,p_starts_at,v_end,'confirmed',p_customer_note) returning id into v_id;
 return v_id;
exception when exclusion_violation then raise exception 'Bu çalışan bu saatlerde dolu; başka saat seçin';
end $$;

create or replace function public.update_appointment_status(p_appointment_id uuid,p_status text)
returns void language plpgsql security definer set search_path=''
as $$
begin
 if auth.uid() is null then raise exception 'Giriş yapmalısınız'; end if;
 if p_status not in ('confirmed','cancelled','completed','no_show') then raise exception 'Geçersiz durum'; end if;
 update public.appointments a set status=p_status where a.id=p_appointment_id and (
  exists(select 1 from public.businesses b where b.id=a.business_id and b.owner_id=auth.uid())
  or exists(select 1 from public.employees e where e.id=a.employee_id and e.user_id=auth.uid())
 );
 if not found then raise exception 'Randevu bulunamadı veya yetkiniz yok'; end if;
end $$;

revoke all on function public.create_employee_invite(text) from public,anon;
revoke all on function public.claim_employee_invite(text) from public,anon;
revoke all on function public.leave_business() from public,anon;
revoke all on function public.join_business_by_code(text) from public,anon;
revoke all on function public.get_available_slots(uuid,uuid,date) from public,anon;
revoke all on function public.book_appointment(uuid,uuid,uuid,timestamptz,text) from public,anon;
revoke all on function public.update_appointment_status(uuid,text) from public,anon;
grant execute on function public.create_employee_invite(text) to authenticated;
grant execute on function public.claim_employee_invite(text) to authenticated;
grant execute on function public.leave_business() to authenticated;
grant execute on function public.join_business_by_code(text) to authenticated;
grant execute on function public.get_available_slots(uuid,uuid,date) to authenticated;
grant execute on function public.book_appointment(uuid,uuid,uuid,timestamptz,text) to authenticated;
grant execute on function public.update_appointment_status(uuid,text) to authenticated;
