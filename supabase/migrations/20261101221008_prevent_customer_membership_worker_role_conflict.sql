create or replace function public.claim_employee_invite(p_code text) returns uuid language plpgsql security definer set search_path='' as $$
declare v_eid uuid; v_bid uuid;
begin
 if auth.uid() is null then raise exception 'Giriş yapıp hesap oluşturmalısınız'; end if;
 if exists(select 1 from public.employees where user_id=auth.uid()) then raise exception 'Hesap zaten çalışana bağlı'; end if;
 if not exists(select 1 from public.profiles where id=auth.uid() and account_type='customer') then raise exception 'Bu hesap çalışan olarak bağlanamaz'; end if;
 if exists(select 1 from public.business_memberships where customer_id=auth.uid()) then raise exception 'Çalışan hesabı bağlamadan önce müşteri işletme bağlantını kaldırmalısın'; end if;
 select i.employee_id,i.business_id into v_eid,v_bid from public.employee_invites i join public.employees e on e.id=i.employee_id and e.user_id is null and e.is_active join public.businesses b on b.id=i.business_id and b.status='active' where i.invite_code=upper(trim(p_code)) and i.claimed_at is null and i.expires_at>now() for update of i;
 if v_eid is null then raise exception 'Davet kodu geçersiz veya süresi dolmuş'; end if;
 update public.employees set user_id=auth.uid() where id=v_eid and user_id is null;
 if not found then raise exception 'Davet kodu başka hesap tarafından kullanıldı'; end if;
 update public.employee_invites set claimed_at=now() where employee_id=v_eid and invite_code=upper(trim(p_code));
 update public.profiles set account_type='worker' where id=auth.uid();
 return v_bid;
end $$;
