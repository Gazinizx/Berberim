alter table public.profiles add column if not exists first_name text not null default '',add column if not exists last_name text not null default '',add column if not exists avatar_url text;
do $m$ declare r record; fn text[]:=array['Ahmet','Mehmet','Emre','Burak','Mert','Can','Ayşe','Fatma','Zeynep','Elif']; ln text[]:=array['Yılmaz','Kaya','Demir','Çelik','Şahin','Aydın','Arslan','Doğan','Kara','Koç']; f text;l text;ph text; begin
for r in select id,full_name,first_name,last_name,phone from public.profiles where account_type='customer' and is_blocked=false loop
f:=coalesce(nullif(btrim(r.first_name),''),nullif(split_part(btrim(coalesce(r.full_name,'')),' ',1),''),fn[1+floor(random()*array_length(fn,1))::int]);
l:=coalesce(nullif(btrim(r.last_name),''),nullif(btrim(substr(btrim(coalesce(r.full_name,'')),length(split_part(btrim(coalesce(r.full_name,'')),' ',1))+1)),''),ln[1+floor(random()*array_length(ln,1))::int]);
ph:=coalesce(nullif(btrim(r.phone),''),'TEST-'||upper(substr(replace(r.id::text,'-',''),1,8)));
update public.profiles set first_name=f,last_name=l,full_name=concat_ws(' ',f,l),phone=ph where id=r.id;end loop;end $m$;
create or replace function private.handle_new_user() returns trigger language plpgsql security definer set search_path='' as $f$
declare f text:=coalesce(nullif(btrim(new.raw_user_meta_data->>'first_name'),''),''); l text:=coalesce(nullif(btrim(new.raw_user_meta_data->>'last_name'),''),''); n text;
begin n:=coalesce(nullif(btrim(new.raw_user_meta_data->>'full_name'),''),nullif(concat_ws(' ',f,l),''),'');
insert into public.profiles(id,full_name,first_name,last_name,email,phone,account_type) values(new.id,n,f,l,new.email,nullif(btrim(new.raw_user_meta_data->>'phone'),''),case when new.raw_user_meta_data->>'account_type'='business_owner' then 'business_owner' else 'customer' end);return new;end;$f$;
revoke update on table public.profiles from authenticated;
grant update(full_name,first_name,last_name,phone,avatar_url) on public.profiles to authenticated;
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types) values('profile-photos','profile-photos',true,5242880,array['image/jpeg','image/png','image/webp']) on conflict(id) do update set public=true,file_size_limit=5242880,allowed_mime_types=array['image/jpeg','image/png','image/webp'];
drop policy if exists "Users upload own profile photo" on storage.objects;
create policy "Users upload own profile photo" on storage.objects for insert to authenticated with check(bucket_id='profile-photos' and (storage.foldername(name))[1]=(select auth.uid())::text);
drop policy if exists "Users update own profile photo" on storage.objects;
create policy "Users update own profile photo" on storage.objects for update to authenticated using(bucket_id='profile-photos' and (storage.foldername(name))[1]=(select auth.uid())::text) with check(bucket_id='profile-photos' and (storage.foldername(name))[1]=(select auth.uid())::text);
drop function if exists public.get_business_appointments(uuid,boolean);drop function if exists private.get_business_appointments(uuid,boolean);
create function private.get_business_appointments(p_business_id uuid,p_mine_only boolean default true) returns table(appointment_id uuid,starts_at timestamptz,ends_at timestamptz,status text,customer_name text,service_name text,employee_name text,employee_id uuid,requires_business_approval boolean,customer_id uuid,customer_phone text,customer_avatar_url text,is_owner_appointment boolean) language plpgsql security definer set search_path='' as $f$
declare owner_access boolean:=false; own_employee uuid;
begin if auth.uid() is null then raise exception 'Giriş yapmalısınız';end if;
if exists(select 1 from public.profiles p where p.id=auth.uid() and p.is_blocked) then raise exception 'Hesabınız geçici olarak kısıtlandı';end if;
select exists(select 1 from public.businesses b where b.id=p_business_id and b.owner_id=auth.uid()) into owner_access;
select e.id into own_employee from public.employees e where e.business_id=p_business_id and e.user_id=auth.uid() and e.is_active order by e.created_at limit 1;
if not owner_access and own_employee is null then raise exception 'Bu işletmenin randevularını görme yetkiniz yok';end if;
if not p_mine_only and not owner_access then raise exception 'İşletmenin tüm randevularını yalnızca işletme sahibi görebilir';end if;
return query select a.id,a.starts_at,a.ends_at,a.status,coalesce(nullif(btrim(p.full_name),''),'Müşteri'),s.name,e.display_name,e.id,a.requires_business_approval,p.id,p.phone,p.avatar_url,(e.user_id=auth.uid())
from public.appointments a join public.profiles p on p.id=a.customer_id join public.services s on s.id=a.service_id join public.employees e on e.id=a.employee_id where a.business_id=p_business_id and (not p_mine_only or e.id=own_employee) order by a.starts_at asc;end;$f$;
revoke all on function private.get_business_appointments(uuid,boolean) from public,anon;grant execute on function private.get_business_appointments(uuid,boolean) to authenticated;
create function public.get_business_appointments(p_business_id uuid,p_mine_only boolean default true) returns table(appointment_id uuid,starts_at timestamptz,ends_at timestamptz,status text,customer_name text,service_name text,employee_name text,employee_id uuid,requires_business_approval boolean,customer_id uuid,customer_phone text,customer_avatar_url text,is_owner_appointment boolean) language sql security invoker set search_path='' as $f$ select * from private.get_business_appointments(p_business_id,p_mine_only);$f$;
revoke all on function public.get_business_appointments(uuid,boolean) from public,anon;grant execute on function public.get_business_appointments(uuid,boolean) to authenticated;