create or replace function private.set_user_blocked(p_user_id uuid,p_blocked boolean)
returns void language plpgsql security definer set search_path=''
as $$
begin
 if auth.uid() is null or not (select private.is_admin()) then raise exception 'Yönetici yetkisi gerekli'; end if;
 if p_user_id=auth.uid() then raise exception 'Yönetici kendi hesabını engelleyemez'; end if;
 update public.profiles set is_blocked=p_blocked where id=p_user_id;
 if not found then raise exception 'Kullanıcı bulunamadı'; end if;
end; $$;
grant usage on schema private to authenticated;
revoke all on function private.set_user_blocked(uuid,boolean) from public,anon;
grant execute on function private.set_user_blocked(uuid,boolean) to authenticated;
create or replace function public.admin_set_user_blocked(p_user_id uuid,p_blocked boolean)
returns void language sql security invoker set search_path=''
as $$ select private.set_user_blocked(p_user_id,p_blocked); $$;
revoke all on function public.admin_set_user_blocked(uuid,boolean) from public,anon;
grant execute on function public.admin_set_user_blocked(uuid,boolean) to authenticated;