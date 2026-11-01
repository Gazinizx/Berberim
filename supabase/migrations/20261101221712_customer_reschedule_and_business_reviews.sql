create table if not exists public.business_reviews(
 id uuid primary key default gen_random_uuid(),
 appointment_id uuid not null unique references public.appointments(id) on delete cascade,
 business_id uuid not null references public.businesses(id) on delete cascade,
 customer_id uuid not null references public.profiles(id) on delete cascade,
 rating smallint not null check(rating between 1 and 5),
 comment text,
 created_at timestamptz not null default now()
);
alter table public.business_reviews enable row level security;
create or replace function private.can_read_business_review(p_business_id uuid,p_customer_id uuid,p_appointment_id uuid)
returns boolean language sql stable security definer set search_path=''
as $$ select p_customer_id=(select auth.uid())
 or exists(select 1 from public.businesses b where b.id=p_business_id and b.owner_id=(select auth.uid()))
 or exists(select 1 from public.appointments a join public.employees e on e.id=a.employee_id where a.id=p_appointment_id and e.user_id=(select auth.uid())) $$;
revoke all on function private.can_read_business_review(uuid,uuid,uuid) from public,anon;
grant execute on function private.can_read_business_review(uuid,uuid,uuid) to authenticated;
create policy "review parties read reviews" on public.business_reviews for select to authenticated
using(private.can_read_business_review(business_id,customer_id,appointment_id));
create or replace function public.submit_business_review(p_appointment_id uuid,p_rating integer,p_comment text default null)
returns uuid language plpgsql security definer set search_path=''
as $$
declare v_business_id uuid; v_review_id uuid;
begin
 if auth.uid() is null then raise exception 'Giriş yapmalısınız'; end if;
 if p_rating<1 or p_rating>5 then raise exception 'Puan 1 ile 5 arasında olmalı'; end if;
 select business_id into v_business_id from public.appointments where id=p_appointment_id and customer_id=auth.uid() and status='completed';
 if v_business_id is null then raise exception 'Yalnızca tamamlanan kendi randevunu değerlendirebilirsin'; end if;
 insert into public.business_reviews(appointment_id,business_id,customer_id,rating,comment)
 values(p_appointment_id,v_business_id,auth.uid(),p_rating,nullif(trim(p_comment),'')) returning id into v_review_id;
 return v_review_id;
exception when unique_violation then raise exception 'Bu randevu zaten değerlendirilmiş';
end $$;
create or replace function public.reschedule_appointment(p_appointment_id uuid,p_starts_at timestamptz)
returns void language plpgsql security definer set search_path=''
as $$
declare v_employee_id uuid; v_service_id uuid; v_duration integer; v_day date;
begin
 if auth.uid() is null then raise exception 'Giriş yapmalısınız'; end if;
 if p_starts_at<=now() then raise exception 'Geçmiş bir saate taşınamaz'; end if;
 select employee_id,service_id into v_employee_id,v_service_id from public.appointments where id=p_appointment_id and customer_id=auth.uid() and status='confirmed' for update;
 if v_employee_id is null then raise exception 'Yalnızca kendi onaylı randevunu değiştirebilirsin'; end if;
 v_day:=(p_starts_at at time zone 'Europe/Istanbul')::date;
 if not exists(select 1 from public.get_available_slots(v_employee_id,v_service_id,v_day) s where s.slot_start=p_starts_at) then raise exception 'Seçilen saat artık uygun değil; başka bir saat seç'; end if;
 select duration_minutes into v_duration from public.services where id=v_service_id;
 update public.appointments set starts_at=p_starts_at,ends_at=p_starts_at+make_interval(mins=>v_duration) where id=p_appointment_id and customer_id=auth.uid();
exception when exclusion_violation then raise exception 'Bu saat başka bir randevuyla çakışıyor';
end $$;
revoke all on function public.submit_business_review(uuid,integer,text) from public,anon;
revoke all on function public.reschedule_appointment(uuid,timestamptz) from public,anon;
grant execute on function public.submit_business_review(uuid,integer,text) to authenticated;
grant execute on function public.reschedule_appointment(uuid,timestamptz) to authenticated;
